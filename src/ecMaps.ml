(* -------------------------------------------------------------------- *)
open EcUtils

(* -------------------------------------------------------------------- *)
module DSet = BatSet
module DMap = BatMap

(* -------------------------------------------------------------------- *)
module Map = struct
  module type OrderedType = Why3.Extmap.OrderedType

  module type S = sig
    include Why3.Extmap.S

    val odup : ('a -> key) -> 'a list -> ('a * 'a) option
    val to_stream : 'a t -> (key * 'a) Stream.t
  end

  module Make(O : OrderedType) : S with type key = O.t = struct
    include Why3.Extmap.Make(O)

    let odup (type a) (f : a -> key) (xs : a list) =
      let module E = struct exception Found of a * a end in
        try
          List.fold_left
            (fun sm x ->
               let key = f x in
                 match find_opt key sm with
                 | Some y -> raise (E.Found (y, x))
                 | None -> add (f x) x sm)
            empty xs
          |> ignore; None
        with E.Found (x, y) -> Some (x, y)

    let to_stream (m : 'a t) =
      let next =
        let enum = ref (start_enum m) in
          fun (_ : int) ->
            let aout = val_enum !enum in
              enum := next_enum !enum;
              aout
      in
        Stream.from next
  end

  module MakeBase(M : S) : Why3.Extmap.S
    with type    key         = M.key
     and type 'a t           = 'a M.t
     and type 'a enumeration = 'a M.enumeration
  =
  struct include M end
end

module Set = struct
  module type OrderedType = Why3.Extset.OrderedType

  module type S = sig
    include Why3.Extset.S

    val big_union : t list -> t
    val big_inter : t list -> t
    val map : (elt -> elt) -> t -> t
    val undup : elt list -> elt list
  end

  module MakeOfMap(M : Why3.Extmap.S) : S with module M = M = struct
    include Why3.Extset.MakeOfMap(M)

    let big_union (xs : t list) : t =
      List.fold_left union empty xs

    let big_inter (xs : t list) : t =
      match xs with
      | [] -> empty
      | x :: xs -> List.fold_left inter x xs

    let map f s =
      fold (fun k s -> add (f k) s) s empty

    let undup =
      let rec doit seen acc s =
        match s with
        | [] -> List.rev acc
        | x :: s ->
           if mem x seen then
             doit seen acc s
           else
             doit (add x seen) (x :: acc) s
      in fun (s : elt list) -> doit empty [] s
  end

  module Make(Ord : OrderedType) = MakeOfMap(Map.Make(Ord))
end

module EHashtbl = struct
  module type S = sig
    include Why3.Exthtbl.S
    val memo_rec : int -> ((key -> 'a) -> key -> 'a) -> key -> 'a
  end

  module Make(T : Why3.Wstdlib.OrderedHashedType) = struct
    include Why3.Exthtbl.Make(T)

    let memo_rec size f =
      let h = create size in
      let rec aux x =
        try find h x with Not_found -> let r = f aux x in add h x r; r in
      aux
  end
end

(* -------------------------------------------------------------------- *)
module MakeMSH (X : Why3.Wstdlib.TaggedType) : sig
  module M : Map.S with type key = X.t
  module S : Set.S with module M = Map.MakeBase(M)
  module H : EHashtbl.S with type key = X.t
end = struct
  module T = Why3.Wstdlib.OrderedHashed(X)
  module M = Map.Make(T)
  module S = Set.MakeOfMap(M)
  module H = EHashtbl.Make(T)
end

(* --------------------------------------------------------------------*)
module Int = struct
  type t = int
  let compare = (Stdlib.compare : t -> t -> int)
  let equal   = ((=) : t -> t -> bool)
  let hash    = (fun (x : t) -> x)
end

module Mint = Map.Make(Int)
module Sint = Set.MakeOfMap(Mint)
module Hint = EHashtbl.Make(Int)

(* --------------------------------------------------------------------*)
module DInt = struct
  type t = int * int
  let compare = (Stdlib.compare : t -> t -> int)
  let equal   = ((=) : t -> t -> bool)
  let hash    = (fun (x : t) -> Hashtbl.hash x)
end

module Mdint = Map.Make(DInt)
module Sdint = Set.MakeOfMap(Mdint)
module Hdint = EHashtbl.Make(DInt)

(* --------------------------------------------------------------------*)
module Mstr = Map.Make(String)
module Sstr = Set.MakeOfMap(Mstr)

(* --------------------------------------------------------------------*)
module Trie : sig
  type ('a, 'b) t

  val empty : ('a, 'b) t
  val add : 'a list -> 'b -> ('a, 'b) t -> ('a, 'b) t
  val iter : ('a list -> 'b list -> unit) -> ('a, 'b) t -> unit
end = struct
  module Map = BatMap

  type ('a, 'b) t =
    { children : ('a, ('a, 'b) t) Map.t
    ; value    : 'b list }

  let empty : ('a, 'b) t =
    { value = []; children = Map.empty; }

  let add (path : 'a list) (value : 'b) (t : ('a, 'b) t) =
    let rec doit (path : 'a list) (t : ('a, 'b) t) =
      match path with
      | [] ->
        { t with value = value :: t.value }
      | v :: path ->
        let children =
          t.children |> Map.update_stdlib v (fun children ->
            let subtrie = Option.value ~default:empty children in
            Some (doit path subtrie)
          )
        in { t with children }
    in doit path t

  let iter (f : 'a list -> 'b list -> unit) (t : ('a, 'b) t) =
    let rec doit (prefix : 'a list) (t : ('a, 'b) t) =
      if not (List.is_empty t.value) then
        f prefix t.value;
      Map.iter (fun k v -> doit (k :: prefix) v) t.children
    in
    
    doit [] t
end
