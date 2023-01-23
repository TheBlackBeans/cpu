exception Cycle
type mark = NotVisited | InProgress | Visited

type ('a, 'b) graph =
    { mutable g_nodes : 'a node list; g_comp : 'b -> 'a node -> bool }
and 'a node = {
  n_label : 'a;
  mutable n_mark : mark;
  mutable n_link_to : 'a node list;
  mutable n_linked_by : 'a node list;
}

let mk_graph comp =
  { g_nodes = []; g_comp = comp }

let add_node g x =
  let n = { n_label = x; n_mark = NotVisited; n_link_to = []; n_linked_by = [] } in
  g.g_nodes <- n :: g.g_nodes

let node_of_label g x =
  List.find (g.g_comp x) g.g_nodes

let add_edge g id1 id2 =
  try
    let n1 = node_of_label g id1 in
    let n2 = node_of_label g id2 in
    n1.n_link_to   <- n2 :: n1.n_link_to;
    n2.n_linked_by <- n1 :: n2.n_linked_by
  with Not_found -> Format.eprintf "Tried to add an edge between non-existing nodes"; raise Not_found

let clear_marks g =
  List.iter (fun n -> n.n_mark <- NotVisited) g.g_nodes

let find_roots g =
  List.filter (fun n -> n.n_linked_by = []) g.g_nodes

let has_cycle g =
  match g.g_nodes with
  | [] -> false
  | e :: _ ->
    clear_marks g;
    let rec inner acc = match acc with
      | [] -> false
      | ([], p) :: tl -> p.n_mark <- Visited; inner tl
      | (hd :: tl, p) :: tl2 -> match hd.n_mark with
        | Visited -> inner ((tl, p) :: tl2)
        | InProgress -> true
        | NotVisited ->
          hd.n_mark <- InProgress;
          inner ((hd.n_link_to, hd) :: (tl, p) :: tl2)
    in inner [g.g_nodes, e]

let topological g =
  if has_cycle g then raise Cycle else begin
    (* All nodes are "Visited" *)
    let rec inner acc newnode =
      if newnode.n_mark = NotVisited then acc
      else begin
        newnode.n_mark <- NotVisited;
        newnode.n_label :: List.fold_left inner acc newnode.n_link_to
      end
    in List.fold_left inner [] (find_roots g)
  end
