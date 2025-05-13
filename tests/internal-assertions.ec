module M = {
  proc f() : int = {
    var x : int;
    return 0;
  }
}.

lemma L0 : hoare[M.f : true ==> true].
proof.
abort.

lemma L1 : hoare[M.f : true ==> true | 1 -> true].
proof.
abort.

lemma L1 : hoare[M.f : true ==> true | 2 -> true].
proof.
abort.
