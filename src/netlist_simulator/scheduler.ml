open Netlist_ast
open Graph

exception Combinational_cycle

let read_exp (eq: equation): (ident * ident) list =
  let ofarg l lbl = function
    | Avar v -> lbl v :: l
    | _ -> l in
  let self v = fst eq, v in
  let other v = v, fst eq in
  let rec inner = function
    | Earg a -> ofarg [] self a
    | Ereg v -> [other v]
    | Enot a -> ofarg [] self a
    | Ebinop (_, a1, a2) -> ofarg (ofarg [] self a2) self a1
    | Emux (a1, a2, a3) ->
        ofarg (ofarg (ofarg [] self a3) self a2) self a1
    | Erom (_, _, a) -> ofarg [] self a
    | Eram (_, _, a1, a2, a3, a4) ->
        ofarg (ofarg (ofarg (ofarg [] other a4) other a3) other a2) self a1
    | Econcat (a1, a2) -> ofarg (ofarg [] self a2) self a1
    | Eslice (_, _, a) -> ofarg [] self a
    | Eselect (_, a) -> ofarg [] self a
  in inner (snd eq);;

let schedule p =
  let g = mk_graph (fun x n -> fst n.n_label = x) in
  Env.iter (fun id _ -> add_node g (id, ref None)) p.p_vars;
  List.iter (fun eq ->
    snd (node_of_label g (fst eq)).n_label := Some eq;
    List.iter (fun (v1, v2) -> add_edge g v1 v2) (read_exp eq)
  ) p.p_eqs;
  try
    let ret = topological g in
    { p
    with p_eqs =
      List.fold_left
        (fun acc v -> match !(snd v) with None -> acc | Some v -> v :: acc) [] ret }
  with Cycle -> raise Combinational_cycle;;
