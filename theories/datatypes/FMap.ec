require import AllCore SmtMap Finite List FSet Ring StdOrder.
(*---*) import IntID IntOrder.

import CoreMap.

(* ==================================================================== *)
type ('a, 'b) fmap.

op tomap ['a 'b] : ('a, 'b) fmap -> ('a, 'b option) map.
op ofmap ['a 'b] : ('a, 'b option) map -> ('a, 'b) fmap.

op "_.[_]" ['a 'b] (m : ('a, 'b) fmap) x =
  (tomap m).[x].

op "_.[_<-_]" ['a 'b] (m : ('a, 'b) fmap) x v =
  ofmap ((tomap m).[x <- Some v]).

op dom ['a 'b] (m : ('a, 'b) fmap) =
  fun x => m.[x] <> None.

lemma domE ['a 'b] (m : ('a, 'b) fmap) x :
  dom m x <=> m.[x] <> None.
proof. by []. qed.

abbrev (\in)    ['a 'b] x (m : ('a, 'b) fmap) = (dom m x).
abbrev (\notin) ['a 'b] x (m : ('a, 'b) fmap) = ! (dom m x).

op [opaque] rng ['a 'b] (m : ('a, 'b) fmap) = fun y => exists x, m.[x] = Some y.
lemma rngE (m : ('a, 'b) fmap): 
  rng m = fun y => exists x, m.[x] = Some y by rewrite /rng.

lemma get_none (m : ('a, 'b) fmap, x : 'a) :
  x \notin m => m.[x] = None.
proof. by rewrite domE. qed.

lemma get_some (m : ('a, 'b) fmap, x : 'a) :
  x \in m => m.[x] = Some (oget m.[x]).
proof. move=> /domE; by case m.[x]. qed.

lemma fmapP (m : ('a,'b) fmap) x : x \in m <=> exists y, m.[x] = Some y.
proof.
by split => [/get_some ?|[y @/dom -> //]]; 1: by exists (oget m.[x]).
qed.

(* -------------------------------------------------------------------- *)
lemma getE ['a 'b] (m : ('a, 'b) fmap) x : m.[x] = (tomap m).[x].
proof. by []. qed.

(* -------------------------------------------------------------------- *)
axiom tomapK ['a 'b] : cancel tomap ofmap<:'a, 'b>.

axiom ofmapK ['a 'b] (m : ('a, 'b option) map) :
  is_finite (fun x => m.[x] <> None) => tomap (ofmap m) = m.

axiom isfmap_offmap (m : ('a, 'b) fmap) :
  is_finite (fun x => (tomap m).[x] <> None).

(* -------------------------------------------------------------------- *)
lemma finite_dom ['a 'b] (m : ('a, 'b) fmap) :
  is_finite (dom m).
proof. exact/isfmap_offmap. qed.

(* -------------------------------------------------------------------- *)
lemma finite_rng ['a 'b] (m : ('a, 'b) fmap) : is_finite (rng m).
proof.
pose s := map (fun x => oget m.[x]) (to_seq (dom m)).
apply/finiteP; exists s => y; rewrite rngE /= => -[x mxE].
by apply/mapP; exists x => /=; rewrite mem_to_seq 1:finite_dom domE mxE.
qed.

(* -------------------------------------------------------------------- *)
lemma fmap_eqP ['a 'b] (m1 m2 : ('a, 'b) fmap) :
  (forall x, m1.[x] = m2.[x]) <=> m1 = m2.
proof.
split=> [pw_eq|->] //; rewrite -tomapK -(tomapK m2).
by congr; apply/SmtMap.map_eqP=> x; rewrite -!getE pw_eq.
qed.

(* -------------------------------------------------------------------- *)
op empty ['a 'b] : ('a, 'b) fmap = ofmap (cst None).

lemma empty_valE ['a, 'b] : tomap empty<:'a, 'b> = cst None.
proof.
by rewrite /empty ofmapK //; exists [] => /= *; rewrite SmtMap.cstE.
qed.

(* -------------------------------------------------------------------- *)
lemma emptyE ['a 'b] x : empty<:'a, 'b>.[x] = None.
proof. by rewrite getE empty_valE SmtMap.cstE. qed.

(* -------------------------------------------------------------------- *)
lemma mem_empty ['a 'b] x : x \notin empty<:'a, 'b>.
proof. by rewrite domE emptyE. qed.

(* -------------------------------------------------------------------- *)
lemma mem_rng_empty ['a 'b] y : !rng empty<:'a, 'b> y.
proof. by rewrite rngE /= negb_exists=> /= x; rewrite emptyE. qed.

(* -------------------------------------------------------------------- *)
lemma set_valE ['a 'b] (m : ('a, 'b) fmap) x v :
  tomap m.[x <- v] = (tomap m).[x <- Some v].
proof.
pose s := to_seq (fun x => (tomap m).[x] <> None).
rewrite /"_.[_<-_]" ofmapK //; apply/finiteP; exists (x :: s).
move=> y /=; rewrite SmtMap.get_setE; case: (y = x) => //=.
by move=> ne_yx h; apply/mem_to_seq/h/isfmap_offmap.
qed.

(* -------------------------------------------------------------------- *)
lemma domNE ['a 'b] (m : ('a, 'b) fmap, x : 'a) :
  x \notin m <=> m.[x] = None.
proof. by rewrite domE. qed.

(* --------------------------------------------------------------------- *)
lemma get_setE ['a 'b] (m : ('a, 'b) fmap) (x y : 'a) b :
  m.[x <- b].[y] = if y = x then Some b else m.[y].
proof. by rewrite /"_.[_]" /"_.[_<-_]" set_valE SmtMap.get_setE. qed.

(* -------------------------------------------------------------------- *)
lemma get_set_sameE (m : ('a,'b) fmap) (x : 'a) b :
  m.[x <- b].[x] = Some b.
proof. by rewrite get_setE. qed.

(* -------------------------------------------------------------------- *)
lemma get_set_eqE (m : ('a, 'b) fmap) (x y : 'a) b :
  y = x => m.[x <- b].[y] = Some b.
proof. by move=> <-; rewrite get_set_sameE. qed.

(* -------------------------------------------------------------------- *)
lemma get_set_neqE (m : ('a, 'b) fmap) (x y : 'a) b :
  y <> x => m.[x <- b].[y] = m.[y].
proof. by rewrite get_setE => ->. qed.

(* -------------------------------------------------------------------- *)
lemma get_set_id (m : ('a,'b) fmap) x y:
  m.[x] = Some y => m.[x <- y] = m.
proof.
move=> mxE; apply/fmap_eqP=> z; rewrite get_setE.
by case: (z = x) => [->|] //; rewrite mxE.
qed.

(* -------------------------------------------------------------------- *)
lemma set_setE ['a 'b] (m : ('a, 'b) fmap) x x' b b' :
  m.[x <- b].[x' <- b']
    = (x' = x) ? m.[x' <- b'] : m.[x' <- b'].[x <- b].
proof.
apply/fmap_eqP=> y; rewrite !get_setE; case: (x' = x)=> //= [<<-|].
+ by rewrite !get_setE; case: (y = x').
+ by rewrite !get_setE; case: (y = x')=> //= ->> ->.
qed.

(* -------------------------------------------------------------------- *)
lemma set_set_sameE ['a 'b] (m : ('a, 'b) fmap) (x : 'a) b b' :
  m.[x <- b].[x <- b'] = m.[x <- b'].
proof. by rewrite set_setE. qed.

(* -------------------------------------------------------------------- *)
lemma set_set_eqE ['a 'b] (m : ('a, 'b) fmap) (x x' : 'a) b b' :
  x' = x => m.[x <- b].[x' <- b'] = m.[x <- b'].
proof. by rewrite set_setE. qed.

(* -------------------------------------------------------------------- *)
lemma set_set_neqE ['a 'b] (m : ('a, 'b) fmap) (x x' : 'a) b b' :
  x' <> x => m.[x <- b].[x' <- b'] = m.[x' <- b'].[x <- b].
proof. by rewrite set_setE => ->. qed.

(* -------------------------------------------------------------------- *)
lemma set_get ['a 'b] (m : ('a, 'b) fmap, x : 'a) :
  x \in m => m.[x <- oget m.[x]] = m.
proof.
move=> x_in_m; apply/fmap_eqP=> y; rewrite get_setE.
by case: (y = x) => // ->>; rewrite -some_oget.
qed.

(* -------------------------------------------------------------------- *)
lemma set_get_eq ['a 'b] (m : ('a, 'b) fmap, x : 'a, y : 'b) :
  m.[x] = Some y => m.[x <- y] = m.
proof. by move=> mxE; rewrite -{2}[m](set_get _ x) ?domE // mxE. qed.

(* -------------------------------------------------------------------- *)
lemma mem_set ['a 'b] (m : ('a, 'b) fmap) x b y :
  y \in m.[x <- b] <=> (y \in m \/ y = x).
proof. by rewrite !domE get_setE; case: (y = x). qed.

(* -------------------------------------------------------------------- *)
op rem ['a 'b] (m : ('a, 'b) fmap) x =
  ofmap (tomap m).[x <- None].

(* -------------------------------------------------------------------- *)
lemma rem_valE ['a 'b] (m : ('a, 'b) fmap) x :
  tomap (rem m x) = (tomap m).[x <- None].
proof.
rewrite /rem ofmapK //; pose P z := (tomap m).[z] <> None.
apply/(finite_leq P)/isfmap_offmap => y @/P.
by rewrite !SmtMap.get_setE; case: (y = x).
qed.

(* -------------------------------------------------------------------- *)
lemma remE ['a 'b] (m : ('a, 'b) fmap) x y :
  (rem m x).[y] = if y = x then None else m.[y].
proof. by rewrite /rem /"_.[_]" rem_valE SmtMap.get_setE. qed.

lemma rem_set (m: ('a, 'b) fmap) x: x \in m => (rem m x).[x <- oget m.[x]] = m.
proof. move => x_in; apply fmap_eqP => y; rewrite get_setE remE /#. qed.

(* -------------------------------------------------------------------- *)
lemma mem_rem ['a 'b] (m : ('a, 'b) fmap) x y :
  y \in (rem m x) <=> (y \in m /\ y <> x).
proof. by rewrite !domE remE; case: (y = x) => //=. qed.

(* -------------------------------------------------------------------- *)
lemma rem_id (m : ('a, 'b) fmap, x : 'a) :
  x \notin m => rem m x = m.
proof.
move=> x_notin_m; apply/fmap_eqP => y; rewrite remE.
by case (y = x) => // ->>; apply/eq_sym/domNE.
qed.

(* -------------------------------------------------------------------- *)
lemma rng_set (m : ('a, 'b) fmap) (x : 'a) (y z : 'b) :
  rng m.[x <- y] z <=> rng (rem m x) z \/ z = y.
proof.
rewrite !rngE /=; split.
+ move=> [] r; rewrite get_setE; case: (r = x)=> />.
  by move=> r_neq_x m_r; left; exists r; rewrite remE r_neq_x /= m_r.
case=> [[] r rem_m_x_r|->>] />.
+ by exists r; move: rem_m_x_r; rewrite get_setE remE; case: (r = x).
+ by exists x; rewrite get_set_sameE.
qed.

lemma rng_set_notin (m : ('a, 'b) fmap) (x : 'a) (y z : 'b) :
     x \notin m
  => rng m.[x <- y] z <=> rng m z \/ z = y.
proof. by rewrite rng_set=> /rem_id ->. qed.

(* -------------------------------------------------------------------- *)
op eq_except ['a 'b] X (m1 m2 : ('a, 'b) fmap) =
  SmtMap.eq_except X (tomap m1) (tomap m2).

(* -------------------------------------------------------------------- *)
lemma eq_except_refl ['a 'b] X : reflexive (eq_except<:'a, 'b> X).
proof. by []. qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_sym ['a 'b] X (m1 m2 : ('a, 'b) fmap) :
  eq_except X m1 m2 => eq_except X m2 m1.
proof. by apply/SmtMap.eq_except_sym<:'a, 'b option>. qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_trans ['a 'b] X (m1 m2 m3 : ('a, 'b) fmap) :
  eq_except X m1 m2 => eq_except X m2 m3 => eq_except X m1 m3.
proof. by apply/SmtMap.eq_except_trans<:'a, 'b option>. qed.

lemma eq_except_sub ['a 'b] (X Y : 'a -> bool) (m1 m2 : ('a, 'b) fmap) :
   X <= Y => eq_except X m1 m2 => eq_except Y m1 m2.
proof. by apply/SmtMap.eq_except_sub<:'a, 'b option>. qed.

(* -------------------------------------------------------------------- *)
lemma eq_exceptP ['a 'b] X (m1 m2 : ('a, 'b) fmap) :
  eq_except X m1 m2 <=> (forall x, !X x => m1.[x] = m2.[x]).
proof. by split=> h x /h. qed.

(* -------------------------------------------------------------------- *)
lemma eq_except0 ['a 'b] (m1 m2 : ('a, 'b) fmap) :
  eq_except pred0 m1 m2 <=> m1 = m2.
proof. by rewrite eq_exceptP /pred0 /= fmap_eqP. qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_notp_in (X : 'a -> bool, y : 'a, m1 m2 : ('a, 'b) fmap) :
  eq_except X m1 m2 => ! X y => y \in m1 => y \in m2.
proof. move=> /eq_exceptP eq_exc not_X_y; by rewrite 2!domE eq_exc. qed.

(* -------------------------------------------------------------------- *)
lemma eq_exceptSm ['a 'b] X x y (m1 m2 : ('a, 'b) fmap) :
     eq_except X m1 m2
  => eq_except (predU X (pred1 x)) m1.[x <- y] m2.
proof.
move=> eqeX_m1_m2; rewrite eq_exceptP=> x0; rewrite get_setE /predU /pred1.
by move=> /negb_or []; move: eqeX_m1_m2=> /eq_exceptP h /h -> ->.
qed.

(* -------------------------------------------------------------------- *)
lemma eq_exceptmS ['a 'b] X x y (m1 m2 : ('a, 'b) fmap) :
     eq_except X m1 m2
  => eq_except (predU X (pred1 x)) m1 m2.[x <- y].
proof. by move=> h; apply/eq_except_sym/eq_exceptSm/eq_except_sym. qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_setl ['a 'b] x y (m : ('a, 'b) fmap) :
  eq_except (pred1 x) m.[x <- y] m.
proof.
have ->: pred1 x = predU pred0 (pred1 x) by exact/fun_ext.
by apply/eq_exceptSm/eq_except0.
qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_setr ['a 'b] x y (m : ('a, 'b) fmap) :
  eq_except (pred1 x) m m.[x <- y].
proof. by apply/eq_except_sym/eq_except_setl. qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_set ['a 'b] X x y y' (m1 m2 : ('a, 'b) fmap) :
  eq_except X m1 m2 =>
  eq_except ((y <> y') ? predU X (pred1 x) : X) m1.[x <- y] m2.[x <- y'].
proof.
move=> /eq_exceptP h; case: (y = y') => /= [<-|].
  by apply/eq_exceptP=> z ?; rewrite !get_setE h.
move=> ne_y_y'; apply/eq_exceptP=> z; rewrite negb_or.
by case=> /h; rewrite !get_setE => + @/pred1 -> - ->.
qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_set_eq ['a 'b] X x y (m1 m2 : ('a, 'b) fmap) :
  eq_except X m1 m2 => eq_except X m1.[x <- y] m2.[x <- y].
proof. by move=> /(@eq_except_set _ x y y). qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_set_same ['a 'b] X x y y' (m1 m2 : ('a, 'b) fmap) :
     y = y'
  => eq_except X m1 m2
  => eq_except X m1.[x <- y] m2.[x <- y'].
proof. by move=> <-; apply/eq_except_set_eq. qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_set_neq ['a 'b] X x y y' (m1 m2 : ('a, 'b) fmap) :
     y <> y'
  => eq_except X m1 m2
  => eq_except (predU X (pred1 x)) m1.[x <- y] m2.[x <- y'].
proof. by move=> + /(@eq_except_set _ x y y' _ _)=> ->. qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_set_getlr ['a 'b] (m1 m2 : ('a, 'b) fmap, x) :
     x \in m1
  => eq_except (pred1 x) m1 m2
  => m1 = m2.[x <- oget m1.[x]].
proof.
move=> x_in_m1 /eq_exceptP eqm; apply/fmap_eqP => x'; rewrite get_setE.
by case: (x' = x) => [->>|/eqm] //; apply/some_oget.
qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_setlr (X : 'a -> bool, m : ('a, 'b) fmap, x, b, b'):
  X x => eq_except X m.[x <- b] m.[x <- b'].
proof.
by move=> Xx; apply/eq_exceptP => x' NXx'; rewrite !get_setE; case: (x' = x).
qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_remr (X : 'a -> bool, m1 m2 : ('a,'b) fmap, x) :
   X x => eq_except X m1 m2 => eq_except X m1 (rem m2 x).
proof.
move=> Xx /eq_exceptP eqm; apply/eq_exceptP => y NXy.
by rewrite remE; case: (y = x) => // _; apply/eqm.
qed.

(* -------------------------------------------------------------------- *)
lemma eq_except_reml (X : 'a -> bool, m1 m2 : ('a,'b) fmap, x) :
   X x => eq_except X m1 m2 => eq_except X (rem m1 x) m2.
proof.
by move=> Xx /eq_except_sym ?; apply/eq_except_sym/eq_except_remr.
qed.

(* -------------------------------------------------------------------- *)
op map ['a 'b 'c] (f : 'a -> 'b -> 'c) (m : ('a, 'b) fmap) =
  ofmap (SmtMap.map (fun x => omap (f x)) (tomap m)).

(* -------------------------------------------------------------------- *)
lemma map_valE ['a 'b 'c] (f : 'a -> 'b -> 'c) m :
  tomap (map f m) = SmtMap.map (fun k => omap (f k)) (tomap m).
proof.
rewrite /map ofmapK //; pose P z := (tomap m).[z] <> None.
apply/(finite_leq P)/isfmap_offmap => y @/P.
by rewrite SmtMap.getE SmtMap.offunK /=; case: (tomap m).[y].
qed.

(* -------------------------------------------------------------------- *)
lemma mapE ['a 'b 'c] (f : 'a -> 'b -> 'c) m x :
  (map f m).[x] = omap (f x) m.[x].
proof. by rewrite /map /"_.[_]" map_valE SmtMap.mapE. qed.

(* -------------------------------------------------------------------- *)
lemma mem_map ['a 'b 'c] (f : 'a -> 'b -> 'c) m x :
  x \in map f m <=> x \in m.
proof. by rewrite !domE mapE iff_negb; case: (m.[x]). qed.

(* -------------------------------------------------------------------- *)
lemma map_set (f : 'a -> 'b -> 'c) m x b :
  map f (m.[x <- b]) = (map f m).[x <- f x b].
proof.
apply/fmap_eqP => y; rewrite mapE !get_setE.
by case: (y = x) => //; rewrite mapE.
qed.

(* -------------------------------------------------------------------- *)
lemma map_comp ['a 'b 'c 'd]
  (f : 'a -> 'b -> 'c) (g : 'a -> 'c -> 'd) m
: map g (map f m) = map (fun a b => g a (f a b)) m.
proof. by apply/fmap_eqP => a; rewrite !mapE; case: (m.[a]). qed.

(* -------------------------------------------------------------------- *)
lemma map_id (m : ('a,'b) fmap) :
  map (fun _ b => b) m = m.
proof. by apply/fmap_eqP => x; rewrite mapE /=; case: m.[x]. qed.

(* -------------------------------------------------------------------- *)
lemma map_empty (f : 'a -> 'b -> 'c) :
  map f empty = empty.
proof. by apply/fmap_eqP => x; rewrite mapE !emptyE. qed.

(* -------------------------------------------------------------------- *)
lemma map_rem (f:'a -> 'b -> 'c, m, x) :
  map f (rem m x) = rem (map f m) x.
proof.
by apply/fmap_eqP => z; rewrite !(mapE, remE) (fun_if (omap (f z))).
qed.

(* -------------------------------------------------------------------- *)
lemma oget_map (m : ('a,'b) fmap) (f : 'a -> 'b -> 'c) i :
  i \in m => oget (map f m).[i] = f i (oget m.[i]).
proof. by rewrite mapE fmapP => -[y ->]. qed.

(* -------------------------------------------------------------------- *)
op filter ['a 'b] (p : 'a -> 'b -> bool) m =
  ofmap (SmtMap.offun (fun x => oapp (p x) false m.[x] ? m.[x] : None)).

(* -------------------------------------------------------------------- *)
lemma filter_valE ['a 'b] (p : 'a -> 'b -> bool) m :
  tomap (filter p m) =
    SmtMap.offun (fun x => oapp (p x) false m.[x] ? m.[x] : None).
proof.
rewrite /filter ofmapK //; pose P z := (tomap m).[z] <> None.
apply/(finite_leq P)/isfmap_offmap => y @/P.
by rewrite !SmtMap.getE SmtMap.offunK -SmtMap.getE /= getE; case: (tomap m).[y].
qed.

(* -------------------------------------------------------------------- *)
lemma filterE ['a 'b] (p : 'a -> 'b -> bool) m x :
  (filter p m).[x] = oapp (p x) false m.[x] ? m.[x] : None.
proof. by rewrite /filter /"_.[_]" filter_valE SmtMap.offunE. qed.

lemma mem_filter (m : ('a,'b) fmap) (p : 'a -> 'b -> bool) x : 
   x \in filter p m <=> x \in m /\ p x (oget m.[x]).
proof. smt(filterE). qed.

lemma get_filter (m : ('a,'b) fmap) (p : 'a -> 'b -> bool) x : 
  x \in filter p m => (filter p m).[x] = m.[x].
proof. smt(filterE). qed.

lemma filter_empty (p:'a -> 'b -> bool) : filter p empty = empty.
proof. by apply/fmap_eqP => x; rewrite filterE emptyE. qed.

(* -------------------------------------------------------------------- *)
lemma eq_in_filter ['a 'b] (p1 p2 : 'a -> 'b -> bool) (m : ('a,'b) fmap) :
  (forall (x : 'a) y , m.[x] = Some y => p1 x y <=> p2 x y) => 
  filter p1 m = filter p2 m.
proof. 
move=> eq_p; apply/fmap_eqP => x; rewrite !filterE /#.
qed.

(* -------------------------------------------------------------------- *)
lemma rem_filter (m : ('a,'b) fmap) x (p : 'a -> 'b -> bool) :
  (forall y, !p x y) => rem (filter p m) x = filter p m.
proof.
move => Hpx; apply/fmap_eqP => z; rewrite remE. 
by case(z = x) => // ->; rewrite filterE /#. 
qed.

(* -------------------------------------------------------------------- *)
lemma filter_set (p : 'a -> 'b -> bool) m x b :
  filter p (m.[x <- b]) = p x b ? (filter p m).[x <- b] : rem (filter p m) x.
proof.
apply/fmap_eqP => y; rewrite !filterE !get_setE.
case: (y = x) => [->|] /=; case: (p x b) => /=.
+ by rewrite get_setE.
+ by rewrite remE.
+ by rewrite get_setE=> + -> /=; rewrite filterE.
+ by rewrite remE=> + -> /=; rewrite filterE.
qed.

(* ==================================================================== *)
op [opaque] fdom ['a 'b] (m : ('a, 'b) fmap) = oflist (to_seq (dom m)).
lemma fdomE (m : ('a, 'b) fmap): fdom m = oflist (to_seq (dom m)).
proof. by rewrite/fdom. qed.

(* -------------------------------------------------------------------- *)
lemma mem_fdom ['a 'b] (m : ('a, 'b) fmap) (x : 'a) :
  x \in fdom m <=> x \in m.
proof. by rewrite fdomE mem_oflist mem_to_seq ?isfmap_offmap. qed.

(* -------------------------------------------------------------------- *)
lemma fdomP ['a 'b] (m : ('a, 'b) fmap) (x : 'a) :
  x \in fdom m <=> m.[x] <> None.
proof. by rewrite mem_fdom. qed.

(* -------------------------------------------------------------------- *)
lemma fdom0 ['a 'b] : fdom empty<:'a, 'b> = fset0.
proof. by apply/fsetP=> x; rewrite mem_fdom mem_empty in_fset0. qed.

(* -------------------------------------------------------------------- *)
lemma fdom_eq0 ['a 'b] (m : ('a, 'b) fmap) : fdom m = fset0 => m = empty.
proof.
rewrite fsetP -fmap_eqP=> h x; rewrite emptyE.
have ->: m.[x] = None <=> x \notin m by done.
by rewrite -mem_fdom h in_fset0.
qed.

(* -------------------------------------------------------------------- *)
lemma fdom_set ['a 'b] (m : ('a, 'b) fmap) x v :
  fdom m.[x <- v] = fdom m `|` fset1 x.
proof.
by apply/fsetP=> y; rewrite in_fsetU1 !mem_fdom mem_set.
qed.

(* -------------------------------------------------------------------- *)
lemma fdom_rem ['a 'b] (m : ('a, 'b) fmap) x :
  fdom (rem m x) = fdom m `\` fset1 x.
proof.
by apply/fsetP=> y; rewrite in_fsetD1 !mem_fdom mem_rem.
qed.

(* -------------------------------------------------------------------- *)
lemma fdom_map ['a 'b 'c] (f : 'a -> 'b -> 'c) m :
  fdom (map f m) = fdom m.
proof. by apply/fsetP=> x; rewrite !mem_fdom mem_map. qed.

(* -------------------------------------------------------------------- *)
lemma mem_fdom_set ['a 'b] (m : ('a, 'b) fmap) x v y :
  y \in fdom m.[x <- v] <=> (y \in fdom m \/ y = x).
proof. by rewrite fdom_set in_fsetU1. qed.

lemma mem_fdom_rem ['a 'b] (m : ('a, 'b) fmap) x y :
  y \in fdom (rem m x) <=> (y \in fdom m /\ y <> x).
proof. by rewrite fdom_rem in_fsetD1. qed.

(* ==================================================================== *)
op offset (s: 'a fset): ('a, unit) fmap = 
  ofmap (offun (fun e => if e \in s then Some () else None)).

lemma mem_offset (s: 'a fset) x: x \in (offset s) <=> x \in s.
proof.
rewrite /dom getE ofmapK.
- move: (FSet.finite_mem s).
  apply/eq_ind/fun_ext => y.
  rewrite offunE /#.
rewrite offunE /#.
qed.

lemma offset_get s (e: 'a): (offset s).[e] = if e \in s then Some () else None.
proof.
rewrite getE /ofset ofmapK.
- move: (FSet.finite_mem s).
  apply/eq_ind/fun_ext => y.
  rewrite offunE /#.
rewrite offunE /#.
qed.

lemma offsetK: cancel offset fdom<:'a, unit>.
proof. move => s; rewrite fsetP => x; by rewrite mem_fdom mem_offset. qed.

(* ==================================================================== *)
op offsetmap (f: 'a -> 'b) (s: 'a fset) : ('a, 'b) fmap = 
  map (fun x y => f x) (offset s).

lemma offsetmapT (s: 'a fset) (f: 'a -> 'b) e: e \in s => (offsetmap f s).[e] = Some (f e).
proof. by move => e_in; rewrite /offsetmap mapE offset_get e_in. qed.

lemma offsetmapN (s: 'a fset) (f: 'a -> 'b) e: e \notin s => (offsetmap f s).[e] = None.
proof. by move => e_in; rewrite /offsetmap mapE offset_get e_in. qed.

lemma mem_offsetmap s (f: 'a -> 'b) e: e \in offsetmap f s <=> e \in s.
proof. by rewrite /offsetmap mem_map mem_offset. qed.

(* ==================================================================== *)
op [opaque] frng ['a 'b] (m : ('a, 'b) fmap) = oflist (to_seq (rng m)).
lemma frngE (m : ('a, 'b) fmap): frng m = oflist (to_seq (rng m)).
proof. by rewrite/frng. qed.

(* -------------------------------------------------------------------- *)
lemma mem_frng ['a 'b] (m : ('a, 'b) fmap) (y : 'b) :
  y \in frng m <=> rng m y.
proof. by rewrite frngE mem_oflist mem_to_seq ?finite_rng. qed.

(* -------------------------------------------------------------------- *)
lemma frng0 ['a 'b] : frng empty<:'a, 'b> = fset0.
proof. by apply/fsetP=> x; rewrite mem_frng mem_rng_empty in_fset0. qed.

(* -------------------------------------------------------------------- *)
lemma frng_set (m : ('a, 'b) fmap, x : 'a, y : 'b) :
  frng m.[x <- y] = frng (rem m x) `|` fset1 y.
proof.
apply/fsetP => z; rewrite in_fsetU in_fset1 !(mem_frng, rngE) /=.
case: (z = y) => [->>|neq_zy] /=; first by exists x; rewrite get_set_sameE.
apply/exists_eq => /= x'; rewrite remE !get_setE.
by case: (x' = x) => //= ->>; apply/negbTE; rewrite eq_sym.
qed.

(* ==================================================================== *)
lemma fmapW ['a 'b] (p : ('a, 'b) fmap -> bool) :
      p empty
   => (forall m k v, !k \in fdom m => p m => p m.[k <- v])
   => forall m, p m.
proof.
move=> h0 hS; suff: forall s, forall m, fdom m = s => p m.
+ by move=> h m; apply/(h (fdom m)).
elim/fset_ind => [|x s x_notin_s ih] m => [/fdom_eq0 ->//|].
move=> fdmE; have x_in_m: x \in fdom m by rewrite fdmE in_fsetU1.
have ->: m = (rem m x).[x <- oget m.[x]].
+ apply/fmap_eqP => y; case: (y = x) => [->|ne_xy].
  - by move/fdomP: x_in_m; rewrite get_set_sameE; case: m.[x].
  - by rewrite get_set_neqE // remE ne_xy.
apply/hS; first by rewrite mem_fdom_rem x_in_m.
apply/ih; rewrite fdom_rem fdmE fsetDK; apply/fsetP.
by move=> y; rewrite in_fsetD1 andb_idr //; apply/contraL.
qed.

(* -------------------------------------------------------------------- *)
lemma le_card_frng_fdom ['a 'b] (m : ('a, 'b) fmap) :
  card (frng m) <= card (fdom m).
proof.
elim/fmapW: m=> [| m k v k_notin_m ih].
+ by rewrite frng0 fdom0 !fcards0.
rewrite frng_set fdom_set rem_id -?mem_fdom //.
rewrite fcardU fcardUI_indep; first by rewrite fsetI1 k_notin_m.
by rewrite -addrA ler_add // !fcard1 ler_subl_addr ler_addl fcard_ge0.
qed.

(* ==================================================================== *)
op (+) (m1 m2 : ('a,'b) fmap) : ('a,'b) fmap =
  ofmap (SmtMap.offun (fun x=> if x \in m2 then m2.[x] else m1.[x])).

(* -------------------------------------------------------------------- *)
lemma joinE ['a 'b] (m1 m2 : ('a,'b) fmap) (x : 'a):
  (m1 + m2).[x] = if x \in m2 then m2.[x] else m1.[x].
proof.
rewrite /(+) getE ofmapK /= 2:SmtMap.getE 2:SmtMap.offunK //.
apply/finiteP=> /=; exists (elems (fdom m1) ++ elems (fdom m2))=> x0 /=.
rewrite SmtMap.getE SmtMap.offunK /= mem_cat -!memE !mem_fdom !domE.
by case: (m2.[x0]).
qed.

(* -------------------------------------------------------------------- *)
lemma mem_join ['a 'b] (m1 m2 : ('a,'b) fmap) (x : 'a):
  x \in (m1 + m2) <=> x \in m1 \/ x \in m2.
proof. by rewrite domE joinE !domE; case: (m2.[x]). qed.

lemma fdom_join ['a, 'b] (m1 m2 : ('a,'b) fmap):
 fdom (m1 + m2) = fdom m1 `|` fdom m2.
proof.
by apply/fsetP=> x; rewrite mem_fdom mem_join in_fsetU !mem_fdom.
qed.

(* -------------------------------------------------------------------- *)
op [opaque] has (P : 'a -> 'b -> bool) (m : ('a, 'b) fmap) =
  has (fun x=> P x (oget m.[x])) (elems (fdom m)).
lemma hasE (P : 'a -> 'b -> bool) m: 
  has P m = has (fun x=>P x (oget m.[x])) (elems (fdom m)) by rewrite/has.

(* -------------------------------------------------------------------- *)
lemma hasP (P : 'a -> 'b -> bool) (m : ('a, 'b) fmap):
  has P m <=> exists x y, m.[x] = Some y /\ P x y.
proof.
rewrite hasE hasP; apply/exists_iff=> x /=.
rewrite -memE mem_fdom domE; case: {-1}(m.[x]) (eq_refl m.[x])=> //= y mv.
by split=> [Pxy|/>]; exists y.
qed.

(* -------------------------------------------------------------------- *)
op [opaque] find (P : 'a -> 'b -> bool) (m : ('a, 'b) fmap) =
  onth (elems (fdom m)) (find (fun x=> P x (oget m.[x])) (elems (fdom m))).
lemma findE (P : 'a -> 'b -> bool) m: find P m =
  onth (elems (fdom m)) (find (fun x=> P x (oget m.[x])) (elems (fdom m))).
proof. by rewrite/find. qed.

(* -------------------------------------------------------------------- *)

lemma find_some (P : 'a -> 'b -> bool) (m : ('a, 'b) fmap) x:
  find P m = Some x => exists y, m.[x] = Some y /\ P x y.
proof.
rewrite findE => /onth_some.
pose s := elems _;  pose p := (fun (x0 : 'a) => P x0 (oget m.[x0])). 
move => [find0s def_x]. exists (oget m.[x]); rewrite get_some /=.
  by rewrite -mem_fdom memE -/s -def_x mem_nth find0s.
rewrite -/(p x) -def_x nth_find has_find /#.
qed.

lemma find_not_none (P : 'a -> 'b -> bool) (m : ('a,'b) fmap) : 
     find P m <> None 
  => exists x y, find P m = Some x /\ m.[x] = Some y /\ P x y.
proof. by case _ : (find P m) => // [x /find_some] /#. qed.

lemma find_eq_none (p : 'a -> 'b -> bool) (m : ('a,'b) fmap): 
  (forall x, x \in m => !p x (oget m.[x])) => find p m = None.
proof. by move=> np; apply contraT => /find_not_none /#. qed.

(* -------------------------------------------------------------------- *)
inductive find_spec (P : 'a -> 'b -> bool) (m : ('a, 'b) fmap) =
  | FindNotIn     of   (find P m = None)
                     & (forall x, x \in m => !P x (oget m.[x]))
  | FindIn    x y of   (find P m = Some x)
                     & (m.[x] = Some y)
                     & (P x y).

lemma findP (P : 'a -> 'b -> bool) (m : ('a, 'b) fmap): find_spec P m.
proof.
case: {-1}(find P m) (eq_refl (find P m))=> [|x ^] findPm.
+ apply/FindNotIn=> //= x; rewrite domE.
  case: {-1}(m.[x]) (eq_refl m.[x])=> //= y mx; rewrite -negP.
  move=> Pxy; move: findPm; rewrite findE /=.
  have i_in_list: find (fun x=> P x (oget m.[x])) (elems (fdom m))
                  < size (elems (fdom m)).
  + apply/has_find/List.hasP; exists x.
    by rewrite /= -memE mem_fdom domE mx oget_some.
  by rewrite (onth_nth witness) 1:find_ge0 //.
move=> /find_some [y] [] mx pxy.
exact/(FindIn _ _ x y).
qed.


(* -------------------------------------------------------------------- *)
lemma find_some_unique x0 x' P (m : ('a, 'b) fmap) :
  (forall x y, m.[x] = Some y => P x y => x = x0)
  => find P m = Some x'
  => x' = x0.
proof.
move=> unique; case: (findP P m)=> [->|] />.
by move=> x'' + -> - /> {x''}; exact/unique.
qed.

lemma uniq_find_eq_some z (P : 'a -> 'b -> bool) (m : ('a, 'b) fmap) :
  (forall (x : 'a) (y : 'b), m.[x] = Some y => P x y => x = z) =>
  z \in m => P z (oget m.[z]) => find P m = Some z.
proof.
move => uniq_m z_m p_z; case (findP P m) => [/#|x y fmx mx p_xy]. 
by have <- := find_some_unique _ _ _ _ uniq_m fmx.
qed.

(* -------------------------------------------------------------------- *)

lemma find_map (m : ('a, 'b) fmap) (f : 'a -> 'b -> 'c) P : 
  find P (map f m) = find (fun x y => P x (f x y)) m.
proof.
rewrite !findE fdom_map; congr; apply find_eq_in => x /=.
by rewrite -memE fdomP /= mapE; case(m.[x]).
qed.

(* ==================================================================== *)
op ofassoc ['a 'b] (xs : ('a * 'b) list) =
  ofmap (SmtMap.offun (fun k => List.assoc xs k)).

(* -------------------------------------------------------------------- *)
lemma ofassoc_get ['a 'b] (xs : ('a * 'b) list) k :
  (ofassoc xs).[k] = List.assoc xs k.
proof.
rewrite getE ofmapK /= 1:&(finiteP) 2:SmtMap.offunE //.
by exists (map fst xs) => a /=; rewrite SmtMap.offunE &(assocTP).
qed.

(* -------------------------------------------------------------------- *)
lemma mem_ofassoc ['a, 'b] (xs : ('a * 'b) list) k:
 k \in ofassoc xs <=> k \in map fst xs.
proof. by rewrite domE ofassoc_get &(assocTP). qed.

(* -------------------------------------------------------------------- *)
lemma fdom_ofassoc ['a 'b] (xs : ('a * 'b) list) :
  fdom (ofassoc xs) = oflist (map fst xs).
proof.
apply/fsetP=> a; rewrite mem_oflist mem_fdom.
by rewrite /(_ \in _) ofassoc_get &(assocTP).
qed.

(* ==================================================================== *)

op fsize (m : ('a,'b) fmap) : int = FSet.card (fdom m).

lemma fsize_empty ['a 'b] : fsize<:'a,'b> empty = 0. 
proof. by rewrite /fsize fdom0 fcards0. qed.

lemma ge0_fsize (m : ('a, 'b) fmap) : 0 <= fsize m.
proof. by rewrite fcard_ge0. qed. 

lemma fsize_set (m : ('a, 'b) fmap) k v : 
  fsize m.[k <- v] = b2i (k \notin m) + fsize m.
proof. by rewrite /fsize fdom_set fcardU1 mem_fdom. qed.

lemma fsize0_empty (m: ('a, 'b) fmap): fsize m = 0 => m = empty.
proof.
move: m; apply fmapW => [//| /= m k v].
rewrite mem_fdom fsize_set =>->_/=. 
smt(ge0_fsize).
qed.

lemma fsize_map m (f: 'a -> 'b -> 'c): fsize (map f m) = fsize m.
proof. by rewrite /fsize fdom_map. qed.

(* ==================================================================== *)

(* f-collisions (i.e. collisions under some function f) *)
op fcoll (f : 'b -> 'c) (m : ('a,'b) fmap)  =
  exists i j, i \in m /\ j \in m /\ i <> j /\ 
              f (oget m.[i]) = f (oget m.[j]).

lemma fcollPn (f : 'b -> 'c) (m : ('a,'b) fmap) : 
      !fcoll f m 
  <=> forall i j, i \in m => j \in m => 
        i <> j => f (oget m.[i]) <> f (oget m.[j]).
proof. smt(). qed.

(* -------------------------------------------------------------------- *)
(*                             Flagged Maps                             *)
(* -------------------------------------------------------------------- *)
op noflags ['k, 'v, 'f] (m : ('k, 'v * 'f) fmap) =
  map (fun _ (p : _ * _) => p.`1) m.

op in_dom_with ['k, 'v, 'f] (m : ('k, 'v * 'f) fmap) (x : 'k) (f : 'f) =
 dom m x /\ (oget (m.[x])).`2 = f.

op restr ['k, 'v, 'f] f (m : ('k, 'v * 'f) fmap) =
  let m = filter (fun _ (p : 'v * 'f) => p.`2 = f) m in
  noflags m.

lemma restrP ['k, 'v, 'f] (m : ('k, 'v * 'f) fmap) f x : (restr f m).[x] =
  obind (fun (p : _ * _) => if p.`2 = f then Some p.`1 else None) m.[x].
proof.
rewrite /restr /= mapE filterE /=.
by case (m.[x])=> //= -[x1 f'] /=; case (f' = f).
qed.

lemma dom_restr ['k, 'v, 'f] (m : ('k, 'v * 'f) fmap) f x :
  dom (restr f m) x <=> in_dom_with m x f.
proof.
rewrite /in_dom_with !domE; case: (m.[x]) (restrP m f x)=> //= -[t f'] /=.
by case (f' = f)=> [_ -> |].
qed.

lemma restr_set ['k, 'v, 'f] (m : ('k, 'v * 'f) fmap) f1 f2 x y :
  restr f1 m.[x <- (y, f2)]
    = if f1 = f2 then (restr f1 m).[x <- y] else rem (restr f1 m) x.
proof.
rewrite -fmap_eqP=> k; case: (f1 = f2) => [->|neq_f12].
+ by rewrite !(restrP, get_setE); case: (k = x).
rewrite !(restrP, get_setE); case: (k = x) => [->|ne_kx].
+ by rewrite (@eq_sym f2) neq_f12 /= remE.
by rewrite remE ne_kx /= restrP.
qed.

lemma restr_set_eq ['k, 'v, 'f] (m : ('k, 'v * 'f) fmap) f x y :
  restr f m.[x <- (y, f)] = (restr f m).[x <- y].
proof. by rewrite restr_set. qed.

lemma restr0 ['k, 'v, 'f] f : restr f empty<:'k, 'v * 'f> = empty.
proof. by apply fmap_eqP=> x; rewrite restrP !emptyE. qed.

lemma restr_set_neq ['k, 'v, 'f] f2 f1 (m : ('k, 'v * 'f) fmap) x y :
  ! dom m x => f2 <> f1 => restr f1 m.[x <- (y, f2)] = restr f1 m.
proof.
move=> Hm Hneq; rewrite restr_set (eq_sym f1) Hneq rem_id //.
by rewrite dom_restr /in_dom_with Hm.
qed.

lemma restr_rem ['k, 'v, 'f] (m : ('k, 'v * 'f) fmap) (x : 'k) f :
  restr f (rem m x)
    = (if in_dom_with m x f then rem (restr f m) x else restr f m).
proof.
rewrite -fmap_eqP => z; rewrite restrP; case: (in_dom_with m x f);
rewrite !(restrP, remE); rewrite /in_dom_with; case (z = x)=> // ->.
rewrite negb_and => -[Nxm|]; first by rewrite (iffLR _ _ (domNE m x)).
by case: m.[x] => //= x' ->.
qed.

(* --------------------------------------------------------------------------- *)
(*                         "Bounded" predicate                                 *)
(* --------------------------------------------------------------------------- *)

op bounded ['from 'to] (m : ('from, 'to) fmap) (size:int) = 
   card (fdom m) <= size.

lemma bounded_set ['from 'to] (m : ('from, 'to)fmap) (size:int) x e : 
  bounded m size => bounded (m.[x<-e]) (size + 1).
proof. by rewrite /bounded fdom_set fcardU fcard1; smt (fcard_ge0). qed.

lemma bounded_empty ['from 'to] : bounded empty<:'from, 'to> 0.
proof. by rewrite /bounded fdom0 fcards0. qed.

(* -------------------------------------------------------------------- *)
(*                             Merging map                              *)
(* -------------------------------------------------------------------- *)

op merge (f:'a -> 'b1 option -> 'b2 option -> 'b3 option)
         (m1 : ('a, 'b1)fmap) (m2: ('a,'b2)fmap) =
  ofmap (SmtMap.merge f (tomap m1) (tomap m2)).

lemma is_finite_merge (f:'a -> 'b1 option -> 'b2 option -> 'b3 option)
         (m1 : ('a, 'b1)fmap) (m2: ('a,'b2)fmap) :
  (forall a, f a None None = None) =>
  Finite.is_finite
     (fun (x0 : 'a) => (offun (fun (a : 'a) => f a (tomap m1).[a] (tomap m2).[a])).[x0] <> None).
proof.
  move=> hnone; apply (Finite.finite_leq (predU (dom m1) (dom m2))) => /=.
  + by move=> z /=; rewrite SmtMap.offunE /= /predU /dom getE /#.
  by apply Finite.finiteU; apply finite_dom.
qed.

lemma mergeE (f:'a -> 'b1 option -> 'b2 option -> 'b3 option) (m1 : ('a, 'b1)fmap) (m2: ('a,'b2)fmap) x:
  (forall a, f a None None = None) =>
  (merge f m1 m2).[x] = f x m1.[x] m2.[x].
proof.
  by move=> h; rewrite getE /merge ofmapK /= 1:is_finite_merge // SmtMap.offunE /= !getE.
qed.

lemma merge_empty (f:'a -> 'b1 option -> 'b2 option -> 'b3 option) :
  (forall a, f a None None = None) =>
  merge f empty empty = empty.
proof. by move=> h; apply fmap_eqP => x; rewrite mergeE //  !emptyE h. qed.

lemma rem_merge (f:'a -> 'b1 option -> 'b2 option -> 'b3 option) (m1 : ('a, 'b1)fmap) (m2: ('a,'b2)fmap) x:
  (forall a, f a None None = None) =>
  rem (merge f m1 m2) x = merge f (rem m1 x) (rem m2 x).
proof. move=> h; apply fmap_eqP => z; rewrite mergeE // !remE mergeE // /#. qed.

(* -------------------------------------------------------------------- *)
op o_union (_ : 'a) (x y : 'b option): 'b option = oapp (fun y=> Some y) y x.

lemma o_union_none a : o_union<:'a,'b> a None None = None.
proof. done. qed.

op union_map (m1 m2: ('a, 'b) fmap) = merge o_union m1 m2.

lemma set_union_map_l (m1 m2: ('a, 'b)fmap) x y: 
  (union_map m1 m2).[x <- y] = union_map m1.[x <- y] m2.
proof. 
  have hn := o_union_none <:'a, 'b>.
  by apply fmap_eqP => z; rewrite mergeE // !get_setE mergeE // /#. 
qed. 

lemma set_union_map_r (m1 m2: ('a, 'b)fmap) x y:
  x \notin m1 => 
  (union_map m1 m2).[x <- y] = union_map m1 m2.[x <- y].
proof.
by rewrite domE=> /= h; apply fmap_eqP=> z; rewrite mergeE // !get_setE //= mergeE /#.
qed. 

lemma mem_union_map (m1 m2:('a, 'b)fmap) x: (x \in union_map m1 m2) = (x \in m1 || x \in m2).
proof. by rewrite /dom mergeE // /#. qed. 

(* -------------------------------------------------------------------- *)
op o_pair (_ : 'a) (x : 'b1 option) (y : 'b2 option) =
  obind (fun x=> obind (fun y=> Some (x, y)) y) x.

lemma o_pair_none a : o_pair <:'a,'b1, 'b2> a None None = None.
proof. done. qed.

op pair_map (m1:('a, 'b1)fmap) (m2:('a, 'b2)fmap) = merge o_pair m1 m2.

lemma set_pair_map (m1: ('a, 'b1)fmap) (m2: ('a, 'b2)fmap) x y: 
  (pair_map m1 m2).[x <- y] = pair_map m1.[x <- y.`1] m2.[x <- y.`2].
proof. by apply fmap_eqP=> z; rewrite mergeE // !get_setE mergeE // /#. qed.

lemma mem_pair_map (m1: ('a, 'b1)fmap) (m2: ('a, 'b2)fmap) x:
  (x \in pair_map m1 m2) = (x \in m1 /\ x \in m2).
proof. by rewrite /dom mergeE // /#. qed.
