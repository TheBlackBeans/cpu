(*
TODO:
- `cbreak`/`nocbreak`-like esc. code
- Finish being able to set all the colors
- Compare with outputs in a file
*)

open Netlist_ast;;

(** Optimized values: booleans are converted to 1-sized arrays *)
type cvalue = bool array;;

(** Verbose levels: none, only output gates or every gates (in the order they are declared in) *)
type verbose_level = Quiet | Outputs | Everything;;
let level_allowed lv1 lv2 = match lv1, lv2 with
  | _, Quiet -> true
  | Quiet, _ -> false
  | _, Outputs -> true
  | Outputs, _ -> false
  | Everything, Everything -> true;;
(** Circuit options: contains everything related to the circuit *)
type circuit_options = {
  filename: string; (** Netlist filename *)
  
  use_prng: bool; (** Initialize gates to random values *)
  number_steps: int; (** Maximum number of steps *)
  force_proceed: bool; (** Force execution of the netlist, even in 'unsafe' states (eg, infinite loop with no input) *)
};;

(** Formatted '0' and '1' *)
type formatted_values = {
  formatted_0: string;
  formatted_1: string;
};;
(** Formatting options: contains everything UI-related *)
type formatting_options = {
  level: verbose_level; (** Verbose level *)
  format_step: int -> string; (** Formats the "Step xx:" line *)
  format_rom_header: ident (* gate name *) -> int (* address size *) -> int (* data size *) -> string; (** Formats the "ROM xxx:" line *)
  format_request: ident (* gate name *) -> int (* input size *) -> string; (** Formats the user prompt *)
  format_invalid_size: ident (* gate name *) -> int (* input size *) -> string; (** Formats the user prompt *)
  format_gate: ident (* gate name *) -> cvalue (* gate value *) -> string; (** Formats a gate output *)
  formatted: formatted_values;
};;

type options = {
  circuit_options: circuit_options; (** Circuit options *)
  
  roms_input: cvalue array Env.t option; (** ROMs values *)
  input_file: in_channel option; (** File to read from to get inputs *)
  
  fmt: formatting_options; (** Formatting options for stdout *)
  aux_output: (out_channel * formatting_options) option; (** Other output *)
};;
let get_input_stream opts = Option.value ~default:stdin opts.input_file;;
let close_input_stream opts = Option.iter (fun f -> close_in f) opts.input_file;;

(* Get a random boolean value *)
let get_prng options = if options.use_prng then Random.bool () else false;;

(** The user hit CTRL-D or entered 'q' *)
exception Request_early_break;;

(** Invalid program detected *)
exception InvalidProgram of string;;
(** Fail due to an invalid program detected, caused by an invalid operand *)
let invalid_operation eqno operation expected got =
  raise (
    InvalidProgram (
      "[" ^ (string_of_int eqno) ^ "]" ^
      operation ^ " expected " ^ expected ^ ", got " ^ got));;
(** Does the user want to quit? *)
let is_user_exit inp =
  (inp = "q") || (inp = "quit") ||
  (inp = "e") || (inp = "exit");;

let value_length_of_ty = function
  | TBit -> 1
  | TBitArray n -> n;;
(** Compiled variable references: variables are referenced by their kind and offset *)
type var_ref = InputVar of int | EqnVar of int;;
(** Compiled arguments *)
type carg =
  | CAvar of var_ref
  | CAconst of cvalue;;
(** Compiled expressions; note that ROM/RAM don't hold size infos anymore *)
type compiled_exp =
  | CEarg of carg
  | CEreg of var_ref
  | CEnot of carg
  | CEbinop of binop * carg * carg
  | CEmux of carg * carg * carg
  | CErom of int * carg
  | CEram of int * carg * carg * carg * carg
  | CEconcat of carg * carg
  | CEslice of int * int * carg
  | CEselect of int * carg;;

(** A compiled program *)
type compiled_program = {
  inputs: (ident * int) list;     (** (input, input_size) pair *)
  eqs: compiled_exp list;         (** Optimized expressions *)
  outputs: (ident * var_ref) list (** Output reference list *)
};;
(** The current state of a program *)
type state = {
  invars1: cvalue array;   (** Values assigned to input variables 1 *)
  invars2: cvalue array;   (** Values assigned to input variables 2 *)
  mutable active_in: bool; (** Is the active invars the invars2 array? *)
  eqvars: cvalue array;    (** Values assigned to equation variables *)
  mems: cvalue array array (** Memories (ROM and RAM) values *)
};;
(** Update the state with v as the new value for the value reference k *)
let update_state (st: state) (k: var_ref) (v: bool array): unit = match k with
  | InputVar i -> if st.active_in then st.invars2.(i) <- v else st.invars1.(i) <- v
  | EqnVar i -> st.eqvars.(i) <- v;;
(** Get the state of the value reference k *)
let get_state (st: state) (k: var_ref) (is_old: bool): bool array = match k with
  | InputVar i -> if is_old = st.active_in then st.invars1.(i) else st.invars2.(i)
  | EqnVar i -> st.eqvars.(i);;

(** Bit/bitarray initializers *)
let init_random_bit copts = [|get_prng copts|];;
let init_random_bitvec copts n = Array.init n (fun _ -> get_prng copts);;
let init_random_of_type copts = function
  | TBit -> init_random_bit copts
  | TBitArray n -> init_random_bitvec copts n

(** Convenience functions to convert to/from string from/to bit/bitarrays *)
let bit_of_string s =
  if s = "0" then Some false
  else if s = "1" then Some true
  else None;;
let bitarray_of_string s l =
  if String.length s = l then
    try Some (Array.init
      (String.length s)
      (fun i -> match s.[i] with '0' -> false | '1' -> true | _ -> invalid_arg ""))
    with Invalid_argument _ -> None
  else None;;
let string_of_bit fmt b = if b then fmt.formatted_1 else fmt.formatted_0;;
let string_of_value fmt a =
  String.of_seq
    (Seq.concat_map
      (fun b -> String.to_seq (string_of_bit fmt b))
      (Array.to_seq a));;

(** Convert a bit vector to an integer *)
let int_of_bitvec a = Array.fold_left (fun acc b -> if b then 2*acc + 1 else 2*acc) 0 a;;
(** Convert an integer to a len-sized bit vector string *)
let string_bitvec_of_int fmt i len =
  String.of_seq (Seq.concat (Seq.init len (fun j -> String.to_seq (string_of_bit fmt (i land (1 lsl (len - 1 - j)) <> 0)))));;

(** Request the value for varname with the variable being of size varsz *)
let rec request_input input_file fopts varname varsz =
  let rec get_raw_input () =
    print_string (fopts.format_request varname varsz);
    try match input_file with Some f -> input_line f | None -> read_line ()
    with
    | End_of_file ->
      if Option.is_none input_file then print_newline (); (* ^D *)
      raise Request_early_break
    | _ ->
      print_string (fopts.format_invalid_size varname varsz);
      get_raw_input ()
  in let userin = get_raw_input () in
  
  if is_user_exit userin then raise Request_early_break
  else begin
    match bitarray_of_string userin varsz with
    | None ->
      print_string (fopts.format_invalid_size varname varsz);
      request_input input_file fopts varname varsz
    | Some bs -> bs
  end;;

(** Request the value for a ROM *)
let request_rom opts name addrsz datasz =
  match opts.roms_input with
  | None ->
      print_string (opts.fmt.format_rom_header name addrsz datasz);
      Array.init
        (1 lsl addrsz)
        (fun i ->
          request_input None
            opts.fmt
            ("ROM " ^ name ^ "[" ^ (string_bitvec_of_int opts.fmt.formatted i addrsz) ^ "]")
            datasz)
  | Some m ->
      match Env.find_opt name m with
      | None -> failwith ("ROM file does not contain ROM '" ^ name ^ "'")
      | Some arr ->
          if Array.length arr < 1 lsl addrsz then
            failwith ("ROM '" ^ name ^ "' doesn't have enough data")
          else if Array.length arr > 1 lsl addrsz then
            failwith ("ROM '" ^ name ^ "' has too much data")
          else if Array.length arr.(0) <> datasz then
            failwith ("ROM '" ^ name ^ "' has a different data size than in the file")
          else arr;;

(** Generate a starting state from a program *)
let prepare_program opts prg =
  let inputs =
    List.map
      (fun v ->
        v,
        value_length_of_ty (
          match Env.find_opt v prg.p_vars with
          | Some value -> value
          | None ->
              raise (
                InvalidProgram (
                  "variable " ^ v ^ " is an input but is not declared"))))
      prg.p_inputs in
  let var_env =
    Env.mapi
      (fun v t ->
        let rec inner i inp = match inp with
          | (id, l) :: tl ->
            if v = id then ((InputVar i), (assert (value_length_of_ty t = l); l))
            else inner (i + 1) tl
          | [] -> (* v is a variable set by an equation *)
              let rec inner2 i eqs = match eqs with
                | hd :: tl ->
                    if v = fst hd then ((EqnVar i), value_length_of_ty t)
                    else inner2 (i + 1) tl
                | [] -> (* Oops, v is not a variable that is ever set *)
                    raise (InvalidProgram ("variable " ^ v ^ " is never set"))
              in inner2 0 prg.p_eqs
        in inner 0 inputs)
      prg.p_vars in
  
  (* Every variable appear either in an input variable, or an equation.
     What about the reciprocals? *)
  (* An input cannot be duplicated. *)
  List.iteri (fun i v -> match Env.find_opt v var_env with
      | None -> failwith "unreachable"
      | Some (InputVar j, _) when i <> j ->
          raise (
            InvalidProgram
              ("variable " ^ v ^ " is declared as an input multiple times"))
      | Some (InputVar _, _) -> ()
      | Some (EqnVar _, _) -> failwith "unreachable2")
    prg.p_inputs;
  (* A variable cannot be an input and assigned.
     The output of an equation must be a declared variable.
     A variable cannot be assigned multiple times.
     (Note that the last one gets removed by the scheduler, thus never happens.) *)
  List.iteri (fun i (v, _) -> match Env.find_opt v var_env with
      | None ->
          raise (InvalidProgram ("variable " ^ v ^ " is never declared"))
      | Some (InputVar _, _) ->
          raise (InvalidProgram ("variable " ^ v ^ " is an input but is also assigned"))
      | Some (EqnVar j, _) when i <> j -> (* Never happens *)
          raise (InvalidProgram ("variable " ^ v ^ " is assigned more than once"))
      | Some (EqnVar _, _) -> ())
    prg.p_eqs;
  
  let mems = Array.make (List.length prg.p_eqs) [||] in
  let map_var v = fst (Env.find v var_env) in
  let var_length v = snd (Env.find v var_env) in
  let convert_arg = function
    | Avar v -> CAvar (map_var v)
    | Aconst (VBit b) -> CAconst [|b|]
    | Aconst (VBitArray a) -> CAconst a
  in let arg_len = function
    | Avar v -> var_length v
    | Aconst (VBit _) -> 1
    | Aconst (VBitArray a) -> Array.length a
  in let lastmemid = ref 0
  in let convert_exp_raw name i = function
    | Earg a -> CEarg (convert_arg a), arg_len a
    | Ereg v -> CEreg (map_var v), var_length v
    | Enot a -> CEnot (convert_arg a), arg_len a
    | Ebinop (op, a1, a2) ->
        let alen1 = arg_len a1 in
        let alen2 = arg_len a2 in
        if alen1 <> alen2 then
          raise (
            invalid_operation
              i
              (match op with Or -> "or" | Xor -> "xor" | And -> "and" | Nand -> "nand")
              "two arguments of the same size"
              (  "argument 1 of size " ^ (string_of_int alen1)
              ^", argument 2 of size " ^ (string_of_int alen2)))
        else CEbinop (op, convert_arg a1, convert_arg a2), alen1
    | Emux (a1, a2, a3) ->
        let alen1 = arg_len a1 in
        let alen2 = arg_len a2 in
        let alen3 = arg_len a3 in
        if alen1 <> 1 then
          raise (
            invalid_operation
              i
              "Mux"
              "a selector bit"
              ("a selector of size " ^ (string_of_int alen1)))
        else if alen2 <> alen3 then
          raise (
            invalid_operation
              i
              "Mux"
              "two arguments of the same size"
              (  "argument 1 of size " ^ (string_of_int alen2)
              ^", argument 2 of size " ^ (string_of_int alen3)))
        else CEmux (convert_arg a1, convert_arg a2, convert_arg a3), alen2
    | Erom (addrsz, datasz, a) ->
        mems.(!lastmemid) <- request_rom opts name addrsz datasz;
        let alen = arg_len a in
        if alen <> addrsz then
          raise (
            invalid_operation
              i
              "ROM"
              ("an address of size " ^ (string_of_int addrsz))
              ("an address of size " ^ (string_of_int alen)))
        else (incr lastmemid; CErom (!lastmemid - 1, convert_arg a), datasz)
    | Eram (addrsz, datasz, a1, a2, a3, a4) ->
        mems.(!lastmemid) <-
          Array.init (1 lsl addrsz) (fun _ -> init_random_bitvec opts.circuit_options datasz);
        let ralen = arg_len a1 in
        let walen = arg_len a3 in
        let welen = arg_len a2 in
        let dlen = arg_len a4 in
        if ralen <> addrsz then
          raise (
            invalid_operation
              i
              "RAM"
              ("a read address of size " ^ (string_of_int addrsz))
              ("a read address of size " ^ (string_of_int ralen)))
        else if walen <> addrsz then
          raise (
            invalid_operation
              i
              "RAM"
              ("a write address of size " ^ (string_of_int addrsz))
              ("a write address of size " ^ (string_of_int walen)))
        else if dlen <> datasz then
          raise (
            invalid_operation
              i
              "RAM"
              ("a data bus of size " ^ (string_of_int datasz))
              ("a data bus of size " ^ (string_of_int dlen)))
        else if welen <> 1 then
          raise (
            invalid_operation
              i
              "RAM"
              "a write enable bit"
              ("a bus of size " ^ (string_of_int dlen)))
        else (incr lastmemid;
          CEram (
            !lastmemid - 1,
            convert_arg a1, convert_arg a2, convert_arg a3, convert_arg a4), datasz)
    | Econcat (a1, a2) ->
        let alen1 = arg_len a1 in
        let alen2 = arg_len a2 in
        CEconcat (convert_arg a1, convert_arg a2), alen1 + alen2
    | Eslice (st, en, a) ->
        let alen = arg_len a in
        if alen < en then
          raise (
            invalid_operation
              i
              "slice"
              ("a bus of length at least " ^ (string_of_int en))
              ("a bus of size " ^ (string_of_int alen)))
        else CEslice (st, en, convert_arg a), en - st + 1
    | Eselect (b, a) ->
        let alen = arg_len a in
        if alen < b then
          raise (
            invalid_operation
              i
              "select"
              ("a bus of length at least " ^ (string_of_int b))
              ("a bus of size " ^ (string_of_int alen)))
        else CEselect (b, convert_arg a), 1
  in let convert_exp i (v, exp) =
    let newexp, len = convert_exp_raw v i exp in
    let vlen = var_length v in
    if len <> vlen then
      raise (
        InvalidProgram
          ("variable " ^ v ^ " has a length of " ^ (string_of_int len)
          ^" but its expression has a length of " ^ (string_of_int vlen)))
    else newexp, len in
  let eqs = List.mapi convert_exp prg.p_eqs in
  
  {
    inputs = inputs;
    eqs = List.map fst eqs;
    outputs = List.map (fun v -> v, map_var v) prg.p_outputs
  }, {
    invars1 = Array.of_list (List.map (fun (_, l) -> init_random_bitvec opts.circuit_options l) inputs);
    invars2 = Array.of_list (List.map (fun (_, l) -> init_random_bitvec opts.circuit_options l) inputs);
    active_in = true;
    eqvars = Array.of_list (List.map (fun (_, l) -> init_random_bitvec opts.circuit_options l) eqs);
    mems = mems
  };;

(** Get inputs for a new step *)
let inputs_for_new_step input_file fopts prg st =
  st.active_in <- not st.active_in;
  List.iteri
    (fun i (v, l) ->
      update_state st (InputVar i) (request_input input_file fopts v l))
    prg.inputs;;
(** Simulate a single step of a program from the given state *)
let simulate_step prg st =
  let get_var v = get_state st v false in
  let get_old_var v = get_state st v true in
  let get_arg = function
    | CAvar v -> get_var v
    | CAconst c -> c in
  let get_old_arg = function
    | CAvar v -> get_old_var v
    | CAconst c -> c in
  List.iteri (fun i eq ->
    match eq with
    | CEarg a ->
      update_state st (EqnVar i) (get_arg a)
    | CEreg v2 ->
      update_state st (EqnVar i) (get_old_var v2)
    | CEnot a ->
      let va = get_arg a in
      update_state st (EqnVar i) (Array.map not va)
    | CEbinop (op, arg1, arg2) -> begin
      let a1 = get_arg arg1 in
      let a2 = get_arg arg2 in
      update_state st (EqnVar i)
        (Array.map2
          (match op with
          | Or -> fun b1 b2 -> b1 || b2
          | Xor -> fun b1 b2 -> b1 <> b2
          | And -> fun b1 b2 -> b1 && b2
          | Nand -> fun b1 b2 -> not (b1 && b2)) a1 a2) end
    | CEmux (a1, a2, a3) ->
      let v1 = get_arg a1 in
      update_state st (EqnVar i) (if v1.(0) then get_arg a3 else get_arg a2)
    | CErom (mid, read_addr) ->
      let vra = get_arg read_addr in
      let raddr = int_of_bitvec vra in
      update_state st (EqnVar i) st.mems.(mid).(raddr)
    | CEram (mid, read_addr, write_enable, write_addr, data) ->
      (* We should have written the old values in RAM on the previous cycle, but everything happens here in the next cycle
       * The scheduler put the write-related stuff updated *after* here just so we can update using the old values now
       * (which doesn't change the logic as the RAM can only be accessed from here) *)
      let we = get_old_arg write_enable in
      if we.(0) then begin
        let vd = get_old_arg data in
        let vwa = get_old_arg write_addr in
        let waddr = int_of_bitvec vwa in
        st.mems.(mid).(waddr) <- vd
      end;
      let vra = get_arg read_addr in
      let raddr = int_of_bitvec vra in
      update_state st (EqnVar i) st.mems.(mid).(raddr)
    | CEconcat (a1, a2) ->
      let v1 = get_arg a1 in
      let v2 = get_arg a2 in
      update_state st (EqnVar i) (Array.append v1 v2)
    | CEslice (bg, ed, a) ->
      let v1 = get_arg a in
      update_state st (EqnVar i) (Array.sub v1 bg (ed - bg + 1))
    | CEselect (j, a) ->
      let v1 = get_arg a in
      update_state st (EqnVar i) [|v1.(j)|]
  ) prg.eqs;;

let print_gates opts prg st orig_eqs =
  begin match opts.fmt.level with
  | Quiet -> ()
  | Outputs -> List.iter (fun (v, k) ->
      print_string (opts.fmt.format_gate v (get_state st k false))) prg.outputs
  | Everything -> ignore (List.fold_left (fun i (n, _) ->
      print_string (opts.fmt.format_gate n st.eqvars.(i)); i + 1) 0 orig_eqs);
    List.iter2 (fun (n, _) b -> match b with | CEram (i, _, _, _, _) ->
      Array.iteri (fun j v -> print_string (opts.fmt.format_gate (n ^ "[" ^ (string_of_int j) ^ "]") v)) st.mems.(i) | _ -> ()) orig_eqs prg.eqs
  end;
  begin match opts.aux_output with
  | None | Some (_, {level = Quiet}) -> ()
  | Some (f, {level = Outputs; format_gate = fmtg}) -> List.iter (fun (v, k) ->
      output_string f (fmtg v (get_state st k false))) prg.outputs
  | Some (f, {level = Everything; format_gate = fmtg}) -> ignore (List.fold_left (fun i (n, _) ->
      output_string f (fmtg n st.eqvars.(i)); i + 1) 0 orig_eqs);
    List.iter2 (fun (n, _) b -> match b with | CEram (i, _, _, _, _) ->
      Array.iteri (fun j v -> output_string f (fmtg (n ^ "[" ^ (string_of_int j) ^ "]") v)) st.mems.(i) | _ -> ()) orig_eqs prg.eqs
  end;;

(** Simulate number_steps steps of the given program *)
let simulator opts program =
  (* If the program has no input and runs endlessly, ask for confirmation before *)
  let is_safe = (program.p_inputs <> []) || (opts.circuit_options.number_steps <> -1) in
  let user_ok = is_safe || (opts.circuit_options.force_proceed) || (
    if level_allowed opts.fmt.level Outputs then print_string
      ("Warning: you are about to start endlessly executing a"
      ^" program with no input.\nProceed? (Enter 'y'<enter> to continue) ");
    let user_in = read_line () in
    user_in = "y"
  ) in
  
  if user_ok then try
    let prg, st = prepare_program opts program in
    
    let rec inner i =
      if (i >= opts.circuit_options.number_steps) && (opts.circuit_options.number_steps <> -1) then ()
      else begin
        print_string (opts.fmt.format_step (i + 1));
        
        inputs_for_new_step opts.input_file opts.fmt prg st;
        simulate_step                                prg st;
        print_gates         opts                     prg st program.p_eqs;
        
        inner (i + 1)
      end
    in try inner 0 with Request_early_break -> ()
  with Request_early_break -> ();;

(** Load and execute netlist file named filename *)
let compile options =
  try
    let p = Netlist.read_file options.circuit_options.filename in
    begin try
        let p = Scheduler.schedule p in
        simulator options p
      with
        | Scheduler.Combinational_cycle ->
            Format.eprintf "The netlist has a combinatory cycle.@.";
    end;
  with
    | Netlist.Parse_error s -> Format.eprintf "An error accurred: %s@." s; exit 2
    | InvalidProgram s -> Format.eprintf "Invalid program detected: %s@." s; exit 2

type wipoptions = {
  optfilename: string option;
  randinit: bool;
  nsteps: int option;
  ignoreinfloop: bool;
  in_fn: string option;
  stdout_level: verbose_level;
  aux_fn: string option;
  aux_level: verbose_level;
  rom_fn: string option;
  hascolors: bool;
  color0: string option;
  color1: string option;
  stepfmt: string; gatefmt: string;
  auxstepfmt: string; auxgatefmt: string
};;
let () =
  let print_help omsg =
    Option.iter (fun msg -> print_endline msg; print_newline ()) omsg;
    print_endline ("Usage: " ^ Sys.argv.(0) ^ " filename");
    print_endline "    -h  --help                 Display this help";
    print_endline "";
    print_endline "        --no-random-init       Disable random initialization of the gates";
    print_endline "        --random-init          Enable random initialization of the gates (default)";
    print_endline "";
    print_endline "    -n  --step-count n         Number of steps to simulate (default: -1, which means infinitely many)";
    print_endline "        --proceed              Simulate the circuit, even if no limit is set and the circuit has no input";
    print_endline "";
    print_endline "        --inputs filename      Read the inputs from the filename instead of stdin (reads in the same order but doesn't print queries)";
    print_endline "";
    print_endline "    -q  --quiet                Don't print anything to standard output (overrides eveything)";
    print_endline "        --no-step-number       Disable displaying the step number to standard output";
    print_endline "        --all-gates-stdout     Print every gate to standard output";
    print_endline "        --gate-format fmt      Custom gate output formatting to standard output";
    print_endline "";
    print_endline "    -o  --aux-output filename  Auxiliary output file (which does not and cannot have any color)";
    print_endline "    -g  --all-gates-aux        Print every gate to the auxiliary output file";
    print_endline "        --aux-gate-format fmt  Custom gate output formatting to the auxiliary output";
    print_endline "";
    print_endline "        --rom filename         Read the ROM values from the file";
    print_endline "";
    print_endline "        --no-color             Disable every color (overriden by --color-0 and --color-1 if they are placed after)";
    print_endline "        --default-colors       Revert to the default colors";
    print_endline ("        --color-0 ansicode     Specify the ANSI color code (\\e[\027[1mxx\027[mm) with which to display the character '0' in stdout");
    print_endline ("        --color-1 ansicode     Specify the ANSI color code (\\e[\027[1mxx\027[mm) with which to display the character '1' in stdout");
    print_endline "";
    print_endline "";
    print_endline "Coloring options are evaluated left to right.";
    print_endline "";
    print_endline "The gate format is a string copied as-is, except that '%n' is replaced by the name of the gate and '%v' by the value.";
    print_endline "Colors for the gate value is provided by the coloring options.";
    print_endline "Note that '%%' is replaced by '%'.";
    print_endline "";
    print_endline "The ROM file is in the following format: every ROM is in a separate line, and every line is in one of:";
    print_endline "<ROM name> <ROM data at 0b0 in LSBF> <ROM data at 0b01 in LSBF> ... <ROM data at 0b11...11 in LSBF>";
    print_endline "<ROM name> out-of-line-lsbf <realtive or absolute ROM data file>";
    print_endline "<ROM name> out-of-line-msbf <realtive or absolute ROM data file>";
    print_endline "(Note that the spaces are exact: they must be present exactly once per separation.)";
    print_endline "";
    print_endline "The ROM data file with the MSBF specifier is in the following format:";
    print_endline "<ROM data at 0b0 in LSBF><separator(s)><ROM data at 0b01 in LSBF><separator(s)>...<separator(s)><ROM data at 0b11...11 in LSBF>";
    print_endline "where the valid separators are spaces, horizontal tabs, new lines and carriage returns.";
    print_endline "The ROM data file with the LSBF specifier is the same but the address is 0, then 0b100...0, then 0b010...0, then 0b110...0 up to 0b11...1.";
    exit (if Option.is_none omsg then 0 else 2)
  in let rec parse_args i optopts =
    if i >= Array.length Sys.argv then begin
      let fn = match optopts.optfilename with None -> print_help (Some "No filename provided") | Some fn -> fn in
      let auxf =
        try Option.map open_out optopts.aux_fn
        with Sys_error e -> print_endline ("Failed to open auxiliary output file: " ^ e); exit 2 in
      let inf =
        try Option.map open_in optopts.in_fn
        with Sys_error e -> print_endline ("Failed to open input file: " ^ e); exit 2 in
      try
        let roms_in = match optopts.rom_fn with
          | None -> None
          | Some fn ->
              let prefix = match String.rindex_opt fn '/' with
                | Some i -> String.sub fn 0 (i + 1)
                | None -> "" in
              let f = open_in fn in
              try
                let rec inner roms =
                  let so = try Some (input_line f) with End_of_file -> None in
                  match so with
                  | None -> close_in f; Some roms
                  | Some s ->
                    match String.split_on_char ' ' s with
                    | [] -> inner roms
                    | "" :: tl -> print_endline "A ROM doesn't have a name in the ROM file"; exit 2
                    | s :: ("out-of-line-lsbf" as s1) :: tl
                    | s :: ("out-of-line-msbf" as s1) :: tl ->
                        let needs_reverse_addresses = s1 = "out-of-line-lsbf" in
                        if Env.mem s roms then begin
                          print_endline ("ROM '" ^ (String.escaped s) ^ "' appears multiple times in the ROM file"); exit 2 end;
                        let newdata =
                          let oolfn = String.concat " " tl in
                          let oolf = open_in (if oolfn.[0] = '/' then oolfn else (prefix ^ oolfn)) in
                          begin try
                            let rec inner acc1 acc2 =
                              try
                                let c = input_char oolf in
                                match c with
                                | '0' | '1' -> inner (c :: acc1) acc2
                                | ' ' | '\t' | '\n' | '\r' ->
                                    if acc1 = [] then inner acc1 acc2
                                    else inner [] (List.rev acc1 :: acc2)
                                | _ -> print_endline ("ROM '" ^ (String.escaped s) ^ "' has invalid characters in the data file");
                                    exit 2
                              with End_of_file -> if acc1 = [] then acc2 else (List.rev acc1) :: acc2
                            in let v = inner [] [] in
                            Array.map (fun v ->
                              let sv = String.of_seq (List.to_seq v) in match bitarray_of_string sv (String.length sv) with
                              | None -> print_endline ("ROM '" ^ (String.escaped s) ^ "' has invalid data"); exit 2
                              | Some bs -> bs) (Array.of_list (List.rev v))
                          with e -> close_in f; raise e end in
                        let k =
                          let rec inner i =
                            if 1 lsl i > Array.length newdata then begin
                              print_endline ("ROM '" ^ (String.escaped s) ^ "' has a non-power-of-two number of data"); exit 2 end
                            else if 1 lsl i < Array.length newdata then inner (i + 1)
                            else i in
                          inner 0 in
                        if needs_reverse_addresses then
                          for i = 0 to k do
                            let j =
                              let rec inner acc tst rev =
                                if tst = 0 then acc
                                else inner (if i land tst <> 0 then (acc + rev) else acc) (tst lsr 1) (rev lsl 1)
                              in inner 0 (1 lsl (k - 1)) 1
                            in if i < j then
                              let tmp = newdata.(i) in
                              (newdata.(i) <- newdata.(j); newdata.(j) <- tmp)
                          done;
                        Array.iter (fun d -> if Array.length d <> Array.length newdata.(0) then begin
                          print_endline ("ROM '" ^ (String.escaped s) ^ "' doesn't have data of the same size in different addresses");
                          exit 2 end) newdata;
                        inner (Env.add s newdata roms)
                    | s :: tl ->
                      if Env.mem s roms then begin
                        print_endline ("ROM '" ^ (String.escaped s) ^ "' appears multiple times in the ROM file"); exit 2 end;
                      let newdata = Array.map
                        (fun v -> match bitarray_of_string v (String.length v) with
                        | None -> print_endline ("ROM '" ^ (String.escaped s) ^ "' has invalid data"); exit 2
                        | Some bs -> bs) (Array.of_list tl) in
                      Array.iter (fun d -> if Array.length d <> Array.length newdata.(0) then begin
                        print_endline ("ROM '" ^ (String.escaped s) ^ "' doesn't have data of the same size in different addresses");
                        exit 2 end) newdata;
                      inner (Env.add s newdata roms)
                in inner (Env.empty)
              with e -> close_in f; raise e in
        let stdoutfmtd = {
          formatted_0 = Option.fold ~none:(if optopts.hascolors then "\027[91m0\027[m" else "0") ~some:(fun c -> "\027[" ^ c ^ "m") optopts.color0;
          formatted_1 = Option.fold ~none:(if optopts.hascolors then "\027[92m1\027[m" else "1") ~some:(fun c -> "\027[" ^ c ^ "m") optopts.color1;
        } in
        compile {
          circuit_options = {
            filename = fn;
            use_prng = optopts.randinit;
            number_steps = Option.value ~default:(-1) optopts.nsteps;
            force_proceed = optopts.ignoreinfloop
          };
          
          roms_input = roms_in;
          input_file = inf;
          
          aux_output = Option.map (fun a -> a, {
            level = optopts.aux_level;
            format_step = (fun i -> Printf.sprintf "Step %d\n" i);
            format_rom_header = (fun _ _ _ -> "");
            format_request = (fun _ _ -> "");
            format_invalid_size = (fun _ _ -> "");
            format_gate =
              (let lgatefmt = List.rev (snd (String.fold_left (fun (ispercent, acc) c -> match ispercent, acc, c with
                | _, [], _ -> failwith "Internal error" (* Cannot happen *)
                | false, (isname, hd) :: tl, '%' -> true, (isname, hd) :: tl
                | false, (isname, hd) :: tl, c -> false, (isname, hd ^ (String.make 1 c)) :: tl
                | true, (isname, hd) :: tl, '%' -> false, (isname, hd ^ "%") :: tl
                | true, (isname, hd) :: tl, 'n' -> false, (true, "") :: (isname, hd) :: tl
                | true, (isname, hd) :: tl, 'v' -> false, (false, "") :: (isname, hd) :: tl
                | true, (isname, hd) :: tl, c -> false, (isname, hd ^ "%" ^ (String.make 1 c)) :: tl) (false, [false, ""]) optopts.auxgatefmt)) in
              fun gatename value ->
                let strval = string_of_value { formatted_0 = "0"; formatted_1 = "1" } value in
                List.fold_left (fun acc (isname, newstr) ->
                  acc ^ (if isname then gatename else strval) ^ newstr) (snd (List.hd lgatefmt)) (List.tl lgatefmt))
                   (* Note that lgatefmt always has at least one element*);
            formatted = {
              formatted_0 = "0";
              formatted_1 = "1";
            };
          }) auxf;
          fmt = {
            level = optopts.stdout_level;
            format_step =
              (let lstepfmt = List.rev (snd (String.fold_left (fun (ispercent, acc) c -> match ispercent, acc, c with
                | _, [], _ -> failwith "Internal error" (* Cannot happen *)
                | false, hd :: tl, '%' -> true, hd :: tl
                | false, hd :: tl, c -> false, (hd ^ (String.make 1 c)) :: tl
                | true, hd :: tl, '%' -> false, (hd ^ "%") :: tl
                | true, hd :: tl, 'd' -> false, "" :: hd :: tl
                | true, hd :: tl, c -> false, (hd ^ "%" ^ (String.make 1 c)) :: tl) (false, [""]) optopts.stepfmt)) in
              fun step ->
                String.concat (string_of_int step) lstepfmt);
            format_rom_header =
              if Option.is_none roms_in then (fun name _addrsz datasz -> Printf.sprintf "Enter ROM '%s' values (data size is %d):\n" name datasz)
              else (fun _ _ _ -> "");
            format_request =
              if Option.is_none inf then
                if optopts.hascolors then (fun name datasz -> "\027[95m" ^ name ^ "\027[0;90m(\027[0;37m" ^ (string_of_int datasz) ^ "\027[0;90m)\027[0;32m: \027[m")
                else (fun name datasz -> name ^ "(" ^ (string_of_int datasz) ^ "): ")
              else (fun _ _ -> "");
            format_invalid_size =
              if Option.is_none inf then
                if optopts.hascolors then (fun _name datasz -> Printf.sprintf "\027[1;31mInvalid input (expected %d bits)\027[m\n" datasz)
                else (fun _name datasz -> Printf.sprintf "Invalid input (expected %d bits)\n" datasz)
              else (fun _ _ -> "");
            format_gate =
              (let lgatefmt = List.rev (snd (String.fold_left (fun (ispercent, acc) c -> match ispercent, acc, c with
                | _, [], _ -> failwith "Internal error" (* Cannot happen *)
                | false, (isname, hd) :: tl, '%' -> true, (isname, hd) :: tl
                | false, (isname, hd) :: tl, c -> false, (isname, hd ^ (String.make 1 c)) :: tl
                | true, (isname, hd) :: tl, '%' -> false, (isname, hd ^ "%") :: tl
                | true, (isname, hd) :: tl, 'n' -> false, (true, "") :: (isname, hd) :: tl
                | true, (isname, hd) :: tl, 'v' -> false, (false, "") :: (isname, hd) :: tl
                | true, (isname, hd) :: tl, c -> false, (isname, hd ^ "%" ^ (String.make 1 c)) :: tl) (false, [false, ""]) optopts.gatefmt)) in
              fun gatename value ->
                let strval = string_of_value stdoutfmtd value in
                List.fold_left (fun acc (isname, newstr) ->
                  acc ^ (if isname then gatename else strval) ^ newstr) (snd (List.hd lgatefmt)) (List.tl lgatefmt))
                   (* Note that lgatefmt always has at least one element*);
            formatted = stdoutfmtd;
          }
        };
        Option.iter close_in_noerr inf;
        Option.iter close_out_noerr auxf
      with e -> Option.iter close_in_noerr inf; Option.iter close_out_noerr auxf; raise e
    end else match Sys.argv.(i) with
      | "-h" | "--help" -> print_help None
      | "--no-random-init" -> parse_args (i + 1) { optopts with randinit = false }
      | "--random-init" -> parse_args (i + 1) { optopts with randinit = true }
      | "-n" | "--step-count" -> begin
          if Array.length Sys.argv = i + 1 then print_help (Some "Number of steps expected")
          else if Option.is_some optopts.nsteps then print_help (Some "Number of steps provided twice")
          else match int_of_string_opt Sys.argv.(i + 1) with
          | Some n when n >= -1 -> parse_args (i + 2) { optopts with nsteps = Some n }
          | Some _ | None -> print_help (Some ("Number of steps expected, got '" ^ (String.escaped Sys.argv.(i + 1)) ^ "'"))
          end
      | "--proceed" -> parse_args (i + 1) { optopts with ignoreinfloop = true }
      | "--inputs" ->
          if Array.length Sys.argv = i + 1 then print_help (Some "Input filename expected")
          else if Option.is_some optopts.in_fn then print_help (Some "Inputs file provided twice")
          else parse_args (i + 2) { optopts with in_fn = Some Sys.argv.(i + 1) }
      | "-q" | "--quiet" -> parse_args (i + 1) { optopts with stdout_level = Quiet; stepfmt = "" }
      | "--no-step-number" -> parse_args (i + 1) { optopts with stepfmt = "" }
      | "--all-gates-stdout" -> parse_args (i + 1) { optopts with stdout_level = Everything }
      | "--gate-format" ->
          if Array.length Sys.argv = i + 1 then print_help (Some "Gate format string expected")
          else parse_args (i + 2) { optopts with gatefmt = Sys.argv.(i + 1) }
      | "-o" | "--aux-output" ->
          if Array.length Sys.argv = i + 1 then print_help (Some "Auxiliary output filename expected")
          else if Option.is_some optopts.aux_fn then print_help (Some "Auxiliary output file provided twice")
          else parse_args (i + 2) { optopts with aux_fn = Some Sys.argv.(i + 1) }
      | "-g" | "--all-gates-aux" -> parse_args (i + 1) { optopts with aux_level = Everything }
      | "--aux-gate-format" ->
          if Array.length Sys.argv = i + 1 then print_help (Some "Gate format string expected")
          else parse_args (i + 2) { optopts with auxgatefmt = Sys.argv.(i + 1) }
      | "--rom" ->
          if Array.length Sys.argv = i + 1 then print_help (Some "ROM data file expected")
          else if Option.is_some optopts.rom_fn then print_help (Some "ROM data file provided twice")
          else parse_args (i + 2) { optopts with rom_fn = Some Sys.argv.(i + 1) }
      | "--no-color" -> parse_args (i + 1) { optopts with hascolors = false;
            color0 = None;
            color1 = None;
            stepfmt = "Step %d\n";
            gatefmt = "=> %n: %v\n" }
      | "--default-colors" -> parse_args (i + 1) { optopts with hascolors = true;
            color0 = None;
            color1 = None;
            stepfmt = "\027[1mStep \027[0;33m%d\027[m\n";
            gatefmt = "\027[34m=> \027[0;95m%n\027[0;32m: \027[m%v\027[m\n" }
      | "--color-0" ->
          if Array.length Sys.argv = i + 1 then print_help (Some "ANSI color code expected")
          else parse_args (i + 2) { optopts with color0 = Some Sys.argv.(i + 1) }
      | "--color-1" ->
          if Array.length Sys.argv = i + 1 then print_help (Some "ANSI color code expected")
          else parse_args (i + 2) { optopts with color1 = Some Sys.argv.(i + 1) }
      | _ ->
        if Option.is_none optopts.optfilename then parse_args (i + 1) { optopts with optfilename = Some Sys.argv.(i) }
        else if Option.get optopts.optfilename = Sys.argv.(i - 1) then
          print_help (Some ("One of the two is unknown: '" ^ (String.escaped Sys.argv.(i - 1)) ^ "' or '" ^ (String.escaped Sys.argv.(i)) ^ "'"))
        else print_help (Some ("Unknown argument: '" ^ (String.escaped Sys.argv.(i)) ^ "'"))
  in parse_args 1 {
    optfilename = None;
    randinit = true;
    nsteps = None;
    ignoreinfloop = false;
    in_fn = None;
    stdout_level = Outputs;
    aux_fn = None;
    aux_level = Quiet;
    rom_fn = None;
    hascolors = true;
    color0 = None;
    color1 = None;
    stepfmt = "\027[1mStep \027[0;33m%d\027[m\n";
    gatefmt = "\027[34m=> \027[0;95m%n\027[0;32m: \027[m%v\027[m\n";
    auxstepfmt = "Step %d\n";
    auxgatefmt = "=> %n: %v\n"
  };;
