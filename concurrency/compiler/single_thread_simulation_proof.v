Require Import Omega.

Require Import Coq.Classes.Morphisms.
Require Import Relation_Definitions.

Require Import compcert.common.Globalenvs.
Require Import compcert.common.ExposedSimulations.
Require Import compcert.common.Values.
Require Import compcert.common.Memory.
Require Import compcert.lib.Coqlib.

Require Import VST.concurrency.lib.tactics.
Require Import VST.concurrency.common.permissions. Import permissions.
Require Import VST.concurrency.common.semantics. 
Require Import VST.concurrency.compiler.concurrent_compiler_simulation.
Require Import VST.concurrency.compiler.sequential_compiler_correct.
Require Import VST.concurrency.compiler.CoreSemantics_sum.
Require Import VST.concurrency.common.HybridMachine.
Require Import VST.concurrency.compiler.HybridMachine_simulation.

Require Import VST.concurrency.compiler.Clight_self_simulation.
Require Import VST.concurrency.compiler.Asm_self_simulation.
Require Import VST.concurrency.compiler.diagrams.
Require Import VST.concurrency.compiler.mem_equiv.
Require Import VST.concurrency.compiler.pair.


Require Import VST.concurrency.memsem_lemmas.
Import BinNums.
Import BinInt.
Import List.
Import Integers.
Import Ptrofs.
Import Basics.
Import FunctionalExtensionality.

Set Nested Proofs Allowed.
Set Bullet Behavior "Strict Subproofs".

(*Clight Machine *)
Require Import VST.concurrency.common.ClightMachine.
(*Asm Machine*)
Require Import VST.concurrency.common.x86_context.
Require Import VST.concurrency.compiler.concurrent_compiler_simulation_definitions.

Notation delta_perm_map:=(PTree.t (Z -> option (option permission))).
Module ThreadedSimulation (CC_correct: CompCert_correctness)(Args: ThreadSimulationArguments).

  Module MyThreadSimulationDefinitions := ThreadSimulationDefinitions CC_correct Args.
  Export MyThreadSimulationDefinitions.
  Import HybridMachineSig.
  Import DryHybridMachine.
  Import self_simulation. 

  Existing Instance OrdinalPool.OrdinalThreadPool.
  Existing Instance HybridMachineSig.HybridCoarseMachine.DilMem.

  Section ThreadedSimulation.

    (* Here where the ThreadSimulationDefinitions *)

    (* End of ThreadSimulationDefinitions *)
    

  Section CompileOneThread.
    Import OrdinalPool.
    
    Context (hb: nat).
    Definition SemTop: Semantics:= (HybridSem (Some hb)).
    Definition SemBot: Semantics:= (HybridSem (Some (S hb))).
    
    Inductive match_thread
              {sem1 sem2: Semantics}
              (state_type1: @semC sem1 -> state_sum (@semC CSem) (@semC AsmSem))
              (state_type2: @semC sem2 -> state_sum (@semC CSem) (@semC AsmSem))
              (match_state : meminj -> @semC sem1 -> mem -> @semC sem2 -> mem -> Prop) :
      meminj ->
      @ctl (@semC SemTop) -> mem ->
      @ctl (@semC SemBot) -> mem -> Prop  :=
    | Thread_Running: forall j code1 m1 code2 m2,
        match_state j code1 m1 code2 m2 ->
        match_thread state_type1 state_type2 match_state j (Krun (state_type1 code1)) m1
                     (Krun (state_type2 code2)) m2
    | Thread_Blocked: forall j code1 m1 code2 m2,
        match_state j code1 m1 code2 m2 ->
        match_thread state_type1 state_type2 match_state j (Kblocked (state_type1 code1)) m1
                     (Kblocked (state_type2 code2)) m2
    | Thread_Resume: forall j code1 m1 code2 m2 v v',
        match_state j code1 m1 code2 m2 ->
        match_thread state_type1 state_type2 match_state j (Kresume (state_type1 code1) v) m1
                     (Kresume (state_type2 code2) v') m2
    | Thread_Init: forall j m1 m2 v1 v1' v2 v2',
          Val.inject j v1 v2 ->
          Val.inject j v1' v2' ->
          match_thread state_type1 state_type2 match_state j (Kinit v1 v1') m1
                       (Kinit v1 v1') m2.
      
      Definition SST := SState (@semC CSem) (@semC AsmSem).
      Definition TST := TState (@semC CSem) (@semC AsmSem).
      
      Definition match_thread_source:
        meminj -> @ctl (@semC SemTop) -> mem -> @ctl (@semC SemBot) -> mem -> Prop:=
        match_thread SST SST Clight_match.
      Definition match_thread_target:
        meminj -> @ctl (@semC SemTop) -> mem -> @ctl (@semC SemBot) -> mem -> Prop:=
        match_thread TST TST Asm_match.

      Definition loc_readable_cur (m: mem) (b: block) (ofs: Z) : Prop :=
        Mem.perm m b ofs Cur Readable.




      
      (** *mem_interference with mem_effect *)
      Section MemInterference.
      Definition mem_effect_forward: mem -> Events.mem_effect -> mem -> Prop.
      (* Definition mem_effect_forward m ev m':= 
         execute ev in m, without checking for permissions.
       *)
      Admitted.
      
      Inductive mem_interference: mem -> list Events.mem_effect -> mem -> Prop:=
      | Nil_mem_interference: forall m, mem_interference m nil m
      | Build_mem_interference: forall m m' m'' ev lev,
          mem_effect_forward m ev m' ->
          mem_interference m' lev m'' ->
          mem_interference m (ev::lev) m''.
      (* OLD_mem_interference:= Mem.unchanged_on (loc_readable_cur m) m *)

      Lemma mem_interference_one:
        forall m m' ev, 
          mem_effect_forward m ev m' ->
          mem_interference m (ev::nil) m'.
      Proof. intros; econstructor; [eauto| econstructor].
      Qed.

      Lemma mem_interference_trans:
        forall lev lev' m m' m'', 
          mem_interference m lev m' ->
          mem_interference m' lev' m'' ->
          mem_interference m (lev ++ lev') m''.
      Proof.
        induction lev.
        - simpl; intros.
          inversion H; subst; auto.
        - simpl; intros.
          inversion H; subst; auto.
          econstructor; eauto.
      Qed.

      Lemma mem_effect_forward_determ:
        forall eff m m1' m2',
          mem_effect_forward m eff m1' -> 
          mem_effect_forward m eff m2' ->
          m1' = m2'.
      Proof.
        intros. 
      Admitted.
      Lemma mem_interference_determ:
        forall lev m m1' m2',
          mem_interference m lev m1' -> 
          mem_interference m lev m2' ->
          m1' = m2'.
      Proof.
        intros lev; induction lev; intros.
        - inversion H; subst;
            inversion H0; subst; reflexivity.
        - inversion H; subst; inversion H0; subst.
          pose proof (mem_effect_forward_determ
                        _ _ _ _
                        H4 H5); subst.
          eapply IHlev; eassumption.
      Qed.

      End MemInterference.

      
      (* This definition is similar to Events.list_inject_mem_effect but stronger:
       it specifies that j' is just an increment to j by adding the newly 
       allocated blocks (in lev1). It also implies that:
       Events.list_inject_mem_effect j' lev1 lev2. 
       But most importantly it implies that j' is sub_injection of all
       injections that map lev1 to lev2 and increment j.
       *)

      Inductive match_thread_compiled:
        option compiler_index ->
        meminj ->
        @ctl (@semC SemTop) -> mem ->
        @ctl (@semC SemBot) -> mem -> Prop  :=
      | CThread_Running: forall i j code1 m1 code2 m2,
          compiler_match i j code1 m1 code2 m2 ->
          match_thread_compiled (Some i) j (Krun (SST code1)) m1
                                (Krun (TST code2)) m2
      | CThread_Blocked: forall i j j' code1 m1 m1' code2 m2 m2' lev1 lev2,
          compiler_match i j code1 m1 code2 m2 ->
          strict_injection_evolution j j' lev1 lev2 ->
          (*Events.list_inject_mem_effect j lev1 lev2 -> *)
          mem_interference m1 lev1 m1' ->
          mem_interference m2 lev2 m2' ->
          match_thread_compiled (Some i) j' (Kblocked (SST code1)) m1'
                                (Kblocked (TST code2)) m2'
      | CThread_Resume: forall j' cd code1 m1 code2 m2 v v',
          (* there are some extra conditions  
           for the next steps.
           *)
          (forall  j'' s1' m1' m2' lev1'' lev2'',
              strict_injection_evolution j' j'' lev1'' lev2'' ->
              mem_interference m1 lev1'' m1' ->
              mem_interference m2 lev2'' m2' ->
              Smallstep.after_external
                (Smallstep.part_sem (Clight.semantics2 C_program))
                None code1 m1' = Some s1' ->
              exists cd' j''' s2',
                (Smallstep.after_external
                   (Asm.part_semantics Asm_g)
                   None code2 m2' = Some s2' /\
                 inject_incr j' j''' /\
                 compiler_match cd' j''' s1' (*Smallstep.get_mem s1'*) m1' s2' (*Smallstep.get_mem s2'*) m2' )) ->
          match_thread_compiled (Some cd) j' (Kresume (SST code1) v) m1
                                (Kresume (TST code2) v') m2
      | CThread_Init: forall j m1 m2 v1 v1' v2 v2',
          Val.inject j v1 v2 ->
          Val.inject j v1' v2' ->
          match_thread_compiled None j (Kinit v1 v1') m1
                                (Kinit v1 v1') m2.

      Section VirtueInject.
      Definition merge_func {A} (f1 f2:Z -> option A):
        (BinNums.Z -> option A):=
        fun ofs =>
          if f1 ofs then f1 ofs else f2 ofs.

      Fixpoint build_function_for_a_block
               (mu:meminj) {A} (b: positive) (ls: list (positive * (Z -> option A))):
        Z -> option A:=
        match ls with
        | nil => (fun _ => None)
        | (b0, fb)::ls' =>
          match mu b0 with
          | Some (b1, delt) =>
            if PMap.elt_eq b b1 then
              merge_func (fun p => (fb (p - delt)%Z)) (build_function_for_a_block mu b ls')
            else  (build_function_for_a_block mu b ls')
          | None => (build_function_for_a_block mu b ls') 
          end
        end.
      
      Definition tree_map_inject_over_tree {A B}
                 (t:PTree.t (Z -> option B))(mu:meminj) (map:PTree.t (Z -> option A)):
        PTree.t (Z -> option A):=
        PTree.map (fun b _ => build_function_for_a_block mu b (PTree.elements map)) t.

      Definition tree_map_inject_over_mem {A} m mu map:
        PTree.t (Z -> option A) :=
        tree_map_inject_over_tree (snd (getMaxPerm m)) mu map.
      
      (* apply an injections to the elements of a tree. *)
      Fixpoint apply_injection_elements {A}
               (mu:meminj) (ls: list (positive * (Z -> option A)))
        : list (positive * (Z -> option A)) :=
        match ls with
          nil => nil
        | cons (b, ofs_f) ls' =>
          match (mu b) with
          | None => apply_injection_elements mu ls'
          | Some (b',d) =>
            cons (b', fun ofs => ofs_f (ofs-d)%Z)
                 (apply_injection_elements mu ls')
          end
        end.
      Fixpoint extract_function_for_block
               {A} (b: positive) (ls: list (positive * (Z -> option A)))
        : Z -> option A :=
        match ls with
          nil => fun _ => None
        | cons (b', ofs_f') ls' =>
          if (Pos.eq_dec b b') then
            merge_func ofs_f' (extract_function_for_block b ls')
          else (extract_function_for_block b ls')
        end.

      Fixpoint map_from_list
               {A:Type}
               (mu:meminj) (ls: list (positive * (Z -> option A))):
        PTree.t (Z -> option A) :=
        match ls with
          nil => @PTree.empty (BinNums.Z -> option A)
        | cons (b, ofs_f) ls =>
          let t:= map_from_list mu ls in
          match mu b with
            None => t
          | Some (b',d) =>
            match PTree.get b' t with
              None => PTree.set b' (fun ofs => ofs_f (ofs-d)%Z) t
            | Some f_old =>
              PTree.set b' (merge_func (fun ofs => ofs_f (ofs-d)%Z) f_old) t
            end
          end
        end.

      
      Definition tree_map_inject {A}(mu:meminj) (map:PTree.t (Z -> option A)):
        PTree.t (Z -> option A):=
        map_from_list mu (PTree.elements map).
      Definition virtueThread_inject m (mu:meminj) (virtue:delta_map * delta_map):
        delta_map * delta_map:=
        let (m1,m2):= virtue in
        (tree_map_inject_over_mem m mu m1, tree_map_inject_over_mem m mu m2).

      Definition access_map_injected m (mu:meminj) (map:access_map): access_map:=
        (fst map, tree_map_inject_over_mem m mu (snd map)).
      
      Definition virtueLP_inject m (mu:meminj):
        (Pair access_map) -> Pair access_map :=
        pair1 (access_map_injected m mu).

      End VirtueInject.

      
      (* Inject the value in lock locations *)
      Definition inject_lock' size mu (b_lock:block) (ofs_lock: Z) (m1 m2:mem):=
        exists b_lock' delt,
          mu b_lock = Some (b_lock', delt) /\ 
          ( forall ofs0,
              Intv.In ofs0 (ofs_lock, (ofs_lock + size)%Z) ->
              memval_inject mu
                            (ZMap.get ofs0 (Mem.mem_contents m1) !! b_lock)
                            (ZMap.get (ofs0 + delt)%Z
                                      (Mem.mem_contents m2) !! b_lock')).
      Definition inject_lock := inject_lock' LKSIZE.
      Lemma inject_lock_morphism':
        Proper (Logic.eq ==> Logic.eq ==> Logic.eq ==>
                         content_equiv ==> content_equiv ==> Basics.impl) inject_lock.
      Proof.
        intros ??????????????? (b' & delt & Hinj & HH) ; subst.
        repeat (econstructor; eauto).
        intros ? H. eapply HH in H.
        rewrite <- H2, <- H3; assumption.
      Qed.
      Instance inject_lock_morphism:
        Proper (Logic.eq ==> Logic.eq ==> Logic.eq ==>
                         content_equiv ==> content_equiv ==> iff) inject_lock.
      Proof. split; eapply inject_lock_morphism'; eauto; symmetry; auto. Qed.

      
      Notation thread_perms cnt:= (fst (getThreadR cnt)).
      Notation lock_perms cnt:= (snd (getThreadR cnt)).
      Record thread_compat {Sem st i}
             (cnt:containsThread(resources:=dryResources)(Sem:=Sem) st i) m:=
        { th_comp: permMapLt (thread_perms cnt) (getMaxPerm m);
          lock_comp: permMapLt (lock_perms cnt) (getMaxPerm m)}.
      Arguments th_comp {_ _ _ _ _}.
      Arguments lock_comp {_ _ _ _ _}.
      
      Lemma mem_compatible_thread_compat:
        forall n (st1 : ThreadPool.t(ThreadPool:=TP n)) (m1 : mem) (tid : nat)
          (cnt1 : containsThread st1 tid),
          mem_compatible st1 m1 -> thread_compat cnt1 m1.
      Proof. intros * H; constructor; apply H. Qed.
      

      
      
      (* OLD version*)
      (*
       *)
      
      Definition PTree_get2 (a: access_map * access_map) b ofs:=
        pair1 (fun x => (x !! b) ofs) a.
      Infix "!!!":=PTree_get2 (at level 1).
      Definition Ple2 := (pair2_prop Mem.perm_order'').
      
      Record concur_match (ocd: option compiler_index)
             (j:meminj) (cstate1: ThreadPool (Some hb)) (m1: Mem.mem) (cstate2: ThreadPool(Some (S hb))) (m2: mem):=
        { same_length: num_threads cstate1 = num_threads cstate2
          ; full_inj: Events.injection_full j m1 (* this is needed until we can prove 
                                                    permission transfer is not deleted*)
          ; memcompat1: mem_compatible cstate1 m1
          ; memcompat2: mem_compatible cstate2 m2
          ; INJ: Mem.inject j m1 m2
          ; lock_perm_preimage:
              forall i (cnt1: ThreadPool.containsThread cstate1 i)
                (cnt2: ThreadPool.containsThread cstate2 i),
              perm_preimage j (lock_perms cnt1) (lock_perms cnt2)
          ; INJ_threads:
              forall i (cnt1: ThreadPool.containsThread cstate1 i)
                (cnt2: ThreadPool.containsThread cstate2 i)
                Hlt1 Hlt2,
                     Mem.inject j
                     (@restrPermMap (fst (ThreadPool.getThreadR cnt1)) m1 Hlt1)
                     (@restrPermMap (fst (ThreadPool.getThreadR cnt2)) m2 Hlt2)
          ; INJ_locks:
              forall i (cnt1: ThreadPool.containsThread cstate1 i)
                (cnt2: ThreadPool.containsThread cstate2 i)
                Hlt1 Hlt2,
                     Mem.inject j
                     (@restrPermMap (snd (ThreadPool.getThreadR cnt1)) m1 Hlt1)
                     (@restrPermMap (snd (ThreadPool.getThreadR cnt2)) m2 Hlt2)
          ; INJ_lock_permissions:
              forall b b' delt rmap,
                j b = Some (b', delt) ->
                forall ofs, lockRes cstate1 (b, unsigned ofs) = Some rmap ->
                       lockRes cstate2 (b', unsigned (add ofs (repr delt))) =
                       Some (virtueLP_inject m2 j rmap)
          ; INJ_lock_content:
              forall b ofs rmap,
                lockRes cstate1 (b, ofs) = Some rmap ->
                inject_lock j b ofs m1 m2    
          ; target_invariant: invariant cstate2
          ; mtch_source:
              forall (i:nat),
                (i > hb)%nat ->
                forall  (cnt1: ThreadPool.containsThread cstate1 i)
                   (cnt2: ThreadPool.containsThread cstate2 i)
                   Hlt1 Hlt2,
                  match_thread_source j
                                      (getThreadC cnt1)
                                      (@restrPermMap (fst (ThreadPool.getThreadR cnt1)) m1 Hlt1)
                                      (getThreadC cnt2)
                                      (@restrPermMap (fst (ThreadPool.getThreadR cnt2)) m2 Hlt2)
          ; mtch_target:
              forall (i:nat),
                (i < hb)%nat ->
                forall (cnt1: ThreadPool.containsThread cstate1 i)
                   (cnt2: ThreadPool.containsThread cstate2 i)
                  Hlt1 Hlt2,
                  match_thread_target  j
                                       (getThreadC cnt1)
                                      (@restrPermMap (fst (ThreadPool.getThreadR cnt1)) m1 Hlt1)
                                       (getThreadC cnt2)
                                      (@restrPermMap (fst (ThreadPool.getThreadR cnt2)) m2 Hlt2)
          ; mtch_compiled:
              forall (i:nat),
                (i = hb)%nat ->
                forall (cnt1: ThreadPool.containsThread cstate1 i)
                  (cnt2: ThreadPool.containsThread cstate2 i)
                  Hlt1 Hlt2,
                  match_thread_compiled ocd j
                                        (getThreadC cnt1)
                                        (@restrPermMap (fst (ThreadPool.getThreadR cnt1)) m1 Hlt1)
                                        (getThreadC cnt2)
                                        (@restrPermMap (fst (ThreadPool.getThreadR cnt2)) m2 Hlt2) }.
      Arguments memcompat1 {ocd j cstate1 m1 cstate2 m2}. 
      Arguments memcompat2 {ocd j cstate1 m1 cstate2 m2}.

      
      Ltac forget_memcompat1:=
        match goal with
        | [ H: context[memcompat1 ?CM] |- _ ] =>
          let HH:= fresh "HH" in
          let Hcmpt:= fresh "Hcmpt" in
          remember (memcompat1 CM) as Hcmpt eqn:HH; clear HH 
        | [ |-  context[memcompat1 ?CM] ] =>
          let HH:= fresh "HH" in
          let Hcmpt:= fresh "Hcmpt" in
          remember (memcompat1 CM) as Hcmpt eqn:HH; clear HH 
        end.

      
      Ltac forget_memcompat2:=
        match goal with
        | [ H: context[memcompat2 ?CM] |- _ ] =>
          let HH:= fresh "HH" in
          let Hcmpt:= fresh "Hcmpt" in
          remember (memcompat2 CM) as Hcmpt eqn:HH; clear HH
        | [  |- context[memcompat2 ?CM] ] =>
          let HH:= fresh "HH" in
          let Hcmpt:= fresh "Hcmpt" in
          remember (memcompat2 CM) as Hcmpt eqn:HH; clear HH 
        end.

      Ltac consolidate_mem_compatible:=
        repeat match goal with
               | [ H1: mem_compatible ?st ?m,
                       H2: mem_compatible ?st ?m |- _ ] =>
                 replace H2 with H1 in * by ( apply Axioms.proof_irr); clear H2
               end.

      Ltac clean_cmpt:=
        try forget_memcompat1;
        try forget_memcompat2;
        consolidate_mem_compatible.
      
      Ltac clean_cmpt':=
        match goal with
        | [ CMatch: concur_match _ _ _ _ _ _,
                    Hcmpt:mem_compatible ?st ?m |- _ ] =>
          repeat(
              match goal with
              | [   |- context[Hcmpt] ] =>
                replace Hcmpt with (memcompat1 CMatch)
                  by apply Axioms.proof_irr
              | [ HH:context[Hcmpt]  |- _ ] =>
                replace Hcmpt with (memcompat1 CMatch) in HH
                  by apply Axioms.proof_irr
              end)
        end.

      Lemma mem_compat_restrPermMap:
        forall sem tpool m perms st (permMapLt: permMapLt perms (getMaxPerm m)),
          (mem_compatible(Sem:=sem)(tpool:=tpool) st m) ->
          (mem_compatible st (restrPermMap permMapLt)).
      Proof.
        intros.
        inversion H.
        econstructor.
        - intros; unfold permissions.permMapLt.
          split; intros;
            erewrite getMax_restr; 
            eapply compat_th0.
        - intros; unfold permissions.permMapLt.
          split; intros;
            erewrite getMax_restr; 
            eapply compat_lp0; eauto.
        - intros. eapply restrPermMap_valid; eauto.
      Qed.
      
      Lemma concur_match_perm_restrict:
        forall cd j st1 m1 st2 m2,
          concur_match cd j st1 m1 st2 m2 ->
          forall perms1 perms2 (permMapLt1: permMapLt perms1 (getMaxPerm m1))
            (permMapLt2: permMapLt perms2 (getMaxPerm m2)),
            concur_match cd j st1 (restrPermMap permMapLt1) st2 (restrPermMap permMapLt2).
      Proof.
        intros.
        inversion H.

        (* Move this lemma to where mem_compatible is defined. *)
        
        assert (memcompat3': mem_compatible st1 (restrPermMap permMapLt1)) by
            (eapply mem_compat_restrPermMap; eauto).
        assert (memcompat4': mem_compatible st2 (restrPermMap permMapLt2)) by
            (eapply mem_compat_restrPermMap; eauto).
        eapply Build_concur_match; eauto.
        - intros; simpl.
          destruct memcompat3';
            destruct memcompat4';
            destruct memcompat3;
            destruct memcompat4; simpl in *.
          
      Admitted.

      

      
      Lemma contains12:
        forall {data j cstate1 m1 cstate2 m2},
          concur_match data j cstate1 m1 cstate2 m2 ->
          forall {i:nat} (cnti1: containsThread cstate1 i),
            containsThread cstate2 i.
      Proof.
        unfold containsThread.
        intros ? ? ? ? ? ? H. destruct H.
        rewrite same_length0; auto.
      Qed.

      Lemma contains21:
        forall {data j cstate1 m1 cstate2 m2},
          concur_match data j cstate1 m1 cstate2 m2 ->
          forall {i:nat} (cnti1: containsThread cstate2 i),
            containsThread cstate1 i.
      Proof.
        unfold containsThread.
        intros ? ? ? ? ? ? H. destruct H.
        rewrite same_length0; auto.
      Qed.

      Ltac forget_contains12:=
        match goal with
        | [ H: context[@contains12 _ _ _ _ _ _ ?CM ?i ?cnt1] |- _ ] =>
          let HH:= fresh "HH" in
          let Hcnt:= fresh "Hcnt" in
          remember (@contains12 _ _ _ _ _ _ CM i cnt1) as Hcnt eqn:HH; clear HH 
        | [ |- context[@contains12 _ _ _ _ _ _ ?CM ?i ?cnt1] ] =>
          let HH:= fresh "HH" in
          let Hcnt:= fresh "Hcnt" in
          remember (@contains12 _ _ _ _ _ _ CM i cnt1) as Hcnt eqn:HH; clear HH 
        end.

      Ltac forget_contains21:=
        match goal with
        | [ H: context[@contains21 _ _ _ _ _ _ ?CM ?i ?cnt1] |- _ ] =>
          let HH:= fresh "HH" in
          let Hcnt:= fresh "Hcnt" in
          remember (@contains21 _ _ _ _ _ _ CM i cnt1) as Hcnt eqn:HH; clear HH 
        | [ |- context[@contains21 _ _ _ _ _ _ ?CM ?i ?cnt1] ] =>
          let HH:= fresh "HH" in
          let Hcnt:= fresh "Hcnt" in
          remember (@contains21 _ _ _ _ _ _ CM i cnt1) as Hcnt eqn:HH; clear HH 
        end.

      Ltac consolidate_containsThread:=
        repeat match goal with
               | [ H: ThreadPool.containsThread _ _ |- _ ] => simpl in H
               end;
        repeat match goal with
               | [ H1: containsThread ?st ?i,
                       H2: containsThread ?st ?i |- _ ] =>
                 replace H2 with H1 in * by ( apply Axioms.proof_irr); clear H2
               end.

      Ltac clean_cnt:=
        try forget_contains12;
        try forget_contains21;
        consolidate_containsThread.
      
      Ltac clean_cnt':=
        match goal with
        | [ CMatch: concur_match _ _ ?st1 _ ?st2 _ |- _] =>
          match goal with
          | [ Hcnt1: containsThread st1 ?i,
                     Hcnt2: containsThread st2 ?i |- _ ] =>
            (*Check if contains12 or contains21 is already used. *)
            first [match goal with
                   | [ HH: context[contains21] |- _ ] =>  idtac
                   | [  |- context[contains21] ] =>  idtac
                   | _ => fail 1
                   end; 
                   repeat(
                       match goal with
                       | [   |- context[Hcnt1] ] =>
                         replace Hcnt1 with (contains21 CMatch Hcnt2)
                           by apply Axioms.proof_irr
                       | [ HH:context[Hcnt1]  |- _ ] =>
                         replace Hcnt1 with (contains21 CMatch Hcnt2) in HH
                           by apply Axioms.proof_irr
                       end) |
                   repeat(
                       match goal with
                       | [   |- context[Hcnt2] ] =>
                         replace Hcnt2 with (contains12 CMatch Hcnt1)
                           by apply Axioms.proof_irr
                       | [ HH:context[Hcnt2]  |- _ ] =>
                         replace Hcnt2 with (contains12 CMatch Hcnt1) in HH
                           by apply Axioms.proof_irr
                       end) ]
          end
        end.
      
      Lemma concur_match_same_running:
        forall (m : option mem) (cd : option compiler_index) (mu : meminj)
          (c1 : ThreadPool (Some hb)) (m1 : mem) (c2 : ThreadPool (Some (S hb))) 
          (m2 : mem),
          concur_match cd mu c1 m1 c2 m2 ->
          forall i : nat,
            machine_semantics.running_thread (HybConcSem (Some hb) m) c1 i <->
            machine_semantics.running_thread (HybConcSem (Some (S hb)) m) c2 i.
      Proof.
        intros.
        pose proof (@contains12 _ _ _ _ _ _ H) as CNT12.
        pose proof (@contains21 _ _ _ _ _ _ H) as CNT21.
        inversion H; simpl.
        split; intros H0 ? ? ? ?.
        - destruct (Compare_dec.lt_eq_lt_dec j hb) as [[?|?]|?].  
          + specialize (mtch_target0 j l (CNT21 _ cnti) cnti).
      Admitted.

      Inductive ord_opt {A} (ord: A -> A -> Prop): option A -> option A -> Prop:=
      | Some_ord:
          forall x y, ord x y -> ord_opt ord (Some x) (Some y).
      
      Lemma option_wf:
        forall A (ord: A -> A -> Prop),
          well_founded ord ->
          well_founded (ord_opt ord).
      Proof.
        unfold well_founded.
        intros.
        destruct a.
        2: econstructor; intros; inversion H0.
        specialize (H a).
        induction H.
        econstructor; intros.
        inversion H1; subst.
        eapply H0; eauto.
      Qed.


      
      Inductive individual_match i:
        meminj -> ctl -> mem -> ctl -> mem -> Prop:= 
      |individual_mtch_source:
         (i > hb)%nat ->
         forall j s1 m1 s2 m2,
           match_thread_source j s1 m1 s2 m2 ->
           individual_match i j s1 m1 s2 m2
      |individual_mtch_target:
         (i < hb)%nat ->
         forall j s1 m1 s2 m2,
           match_thread_target j s1 m1 s2 m2 ->
           individual_match i j s1 m1 s2 m2
      | individual_mtch_compiled:
          (i = hb)%nat ->
          forall cd j s1 m1 s2 m2,
            match_thread_compiled cd j s1 m1 s2 m2 ->
            individual_match i j s1 m1 s2 m2.

      Lemma simulation_equivlanence:
        forall s3 t s2 cd cd0,
          (Smallstep.plus (Asm.step (Genv.globalenv Asm_program)) 
                          s3 t s2 \/
           Smallstep.star (Asm.step (Genv.globalenv Asm_program)) 
                          s3 t s2 /\ InjorderX compiler_sim cd cd0) ->
          Smallstep.plus (Asm.step (Genv.globalenv Asm_program)) 
                         s3 t s2 \/
          t = Events.E0 /\
          s2 = s3 /\
          InjorderX compiler_sim cd cd0.
      Proof.
        intros. destruct H; eauto.
        destruct H.
        inversion H; subst; eauto.
        left. econstructor; eauto.
      Qed.
      
      (* This lemma is only used when updating non compiled threads *)
      Lemma Concur_update:
        forall (st1: ThreadPool.t) (m1 m1' : mem) (tid : nat) (Htid : ThreadPool.containsThread st1 tid)
          c1 (cd cd' : option compiler_index) (st2 : ThreadPool.t) 
          (mu : meminj) (m2 : mem)
          c2
          (f' : meminj) (m2' : mem) (Htid' : ThreadPool.containsThread st2 tid)
          (mcompat1: mem_compatible st1 m1)
          (mcompat2: mem_compatible st2 m2),
          semantics.mem_step
            (restrPermMap (proj1 (mcompat1 tid Htid))) m1' ->
          semantics.mem_step
            (restrPermMap (proj1 (mcompat2 tid Htid'))) m2' ->
          invariant st1 ->
          invariant st2 ->
          concur_match cd mu st1 m1 st2 m2 ->
          individual_match tid f' c1 m1' c2 m2' ->
          self_simulation.is_ext mu (Mem.nextblock m1) f' (Mem.nextblock m2) ->
          concur_match cd' f'
                       (updThread Htid c1
                                  (getCurPerm m1', snd (getThreadR Htid))) m1'
                       (updThread Htid' c2
                                  (getCurPerm m2', snd (getThreadR Htid'))) m2'.
      Proof.
      Admitted.

      (*This lemma is used when the compiled thread steps*)
      
      Lemma Concur_update_compiled:
        forall (st1 : ThreadPool.t) (m1 m1' : mem) (Htid : ThreadPool.containsThread st1 hb) 
          (st2 : ThreadPool.t) (mu : meminj) (m2 : mem) (cd : option compiler_index),
          concur_match (cd) mu st1 m1 st2 m2 ->
          forall (s' : Clight.state) (j1' : meminj) (cd' : InjindexX compiler_sim)
            (j2' : meminj) (s4' : Asm.state) (j3' : meminj) (m2' : mem)
            (Htid' : containsThread st2 hb)
            (mcompat1: mem_compatible st1 m1)
            (mcompat2: mem_compatible st2 m2),
            semantics.mem_step
              (restrPermMap (proj1 (mcompat1 hb Htid))) m1' ->
            semantics.mem_step
              (restrPermMap (proj1 (mcompat2 hb Htid'))) m2' ->
            invariant st1 ->
            invariant st2 ->
            match_thread_compiled cd (compose_meminj (compose_meminj j1' j2') j3')
                                  (Krun (SState Clight.state Asm.state s')) m1'
                                  (Krun (TState Clight.state Asm.state s4')) m2' ->
            concur_match (Some cd') (compose_meminj (compose_meminj j1' j2') j3')
                         (updThread Htid (Krun (SState Clight.state Asm.state s'))
                                    (getCurPerm m1', snd (getThreadR Htid))) m1'
                         (updThread Htid' (Krun (TState Clight.state Asm.state s4'))
                                    (getCurPerm m2', snd (getThreadR Htid'))) m2'.
      Proof.
        (*There is probably a relation missing from m1 m' m2 m2' *)
        (* Probably it's mem_step which is provable from where this lemma is used. *)
      Admitted.

      
      Lemma Concur_update_compiled':
        forall (st1 : ThreadPool.t) (m1 m1' : mem) (Htid : ThreadPool.containsThread st1 hb) 
          (st2 : ThreadPool.t) (mu : meminj) (m2 : mem) (cd : option compiler_index),
          concur_match (cd) mu st1 m1 st2 m2 ->
          forall (s' : Clight.state) (j1' : meminj) (cd' : InjindexX compiler_sim)
            (j2' : meminj) (s4 : Asm.state) (j3' : meminj)
            (Htid' : containsThread st2 hb)
            (mcompat1: mem_compatible st1 m1)
            (mcompat2: mem_compatible st2 m2),
            semantics.mem_step
              (restrPermMap (proj1 (mcompat1 hb Htid))) m1' ->
            invariant st1 ->
            invariant st2 ->
            match_thread_compiled cd (compose_meminj (compose_meminj j1' j2') j3')
                                  (Krun (SState Clight.state Asm.state s')) m1'
                                  (Krun (TState Clight.state Asm.state s4))
                                  (restrPermMap (proj1 (mcompat2 hb Htid'))) ->
            concur_match (Some cd') (compose_meminj (compose_meminj j1' j2') j3')
                         (updThread Htid (Krun (SState Clight.state Asm.state s'))
                                    (getCurPerm m1', snd (getThreadR Htid))) m1'
                         st2 m2.
      Proof.
        (*There is probably a relation missing from m1 m' m2 m2' *)
        (* Probably it's mem_step which is provable from where this lemma is used. *)
      Admitted.
      
      Ltac exploit_match tac:=  
        unfold match_thread_target,match_thread_source in *;
        repeat match goal with
            | [ H: ThreadPool.getThreadC ?i = _ ?c |- _] => simpl in H
               end;
        match goal with
        | [ H: getThreadC ?i = _ ?c,
               H0: context[match_thread] |- _ ] =>
          match type of H0 with
          | forall (_: ?Hlt1Type) (_: ?Hlt2Type), _ =>
            assert (Hlt1:Hlt1Type); [
              first [eassumption | tac | idtac]|
            assert (Hlt2:Hlt2Type); [
              first [eassumption | tac | idtac]|
              specialize (H0 Hlt1 Hlt2);
              rewrite H in H0; inversion H0; subst; simpl in *; clear H0
            ]]
          end

          | [ H: getThreadC ?i = _ ?c,
                 H0: context[match_thread_compiled] |- _ ] =>
            match type of H0 with
            | forall (_: ?Hlt1Type) (_: ?Hlt2Type), _ =>
              assert (Hlt1:Hlt1Type); [
                first [eassumption | tac | idtac]|
                assert (Hlt2:Hlt2Type); [
                  first [eassumption | tac | idtac]|
                  specialize (H0 Hlt1 Hlt2);
                  rewrite H in H0; inversion H0; subst; simpl in *; clear H0
              ]]
            end
          end;
          fold match_thread_target in *;
          fold match_thread_source in *.

      (* Build the concur_match *)
      Ltac destroy_ev_step_sum:=
        match goal with
        | [ H: ev_step_sum _ _ _ _ _ _ _ |- _ ] => inversion H; clear H
        end.

      Lemma self_simulation_plus:
        forall state coresem
          (SIM: self_simulation.self_simulation state coresem),
        forall (f : meminj) (t : Events.trace) (c1 : state) 
          (m1 : mem) (c2 : state) (m2 : mem),
          self_simulation.match_self (self_simulation.code_inject _ _ SIM) f c1 m1 c2 m2 ->
          forall (c1' : state) (m1' : mem),
            (corestep_plus coresem) c1 m1 c1' m1' ->
            exists (c2' : state) (f' : meminj) (t' : Events.trace) 
              (m2' : mem),
              (corestep_plus coresem) c2 m2 c2' m2' /\
              self_simulation.match_self (self_simulation.code_inject _ _ SIM) f' c1' m1' c2' m2' /\
              inject_incr f f' /\
              self_simulation.is_ext f (Mem.nextblock m1) f' (Mem.nextblock m2) /\
              Events.inject_trace f' t t'.
      Admitted.

      
      Lemma thread_step_plus_from_corestep:
        forall (m : option mem) (tge : ClightSemanticsForMachines.G * Asm.genv)
          (U : list nat) (st1 : t) (m1 : mem) (Htid : containsThread st1 hb) 
          (st2 : t) (mu : meminj) (m2 : mem) (cd0 : compiler_index)
          (H0 : concur_match (Some cd0) mu st1 m1 st2 m2) (code2 : Asm.state)
          (s4' : Smallstep.state (Asm.part_semantics Asm_g)) 
          (m4' : mem),
          corestep_plus (Asm_core.Asm_core_sem Asm_g) code2
                        (restrPermMap
                           (proj1 ((memcompat2 H0) hb (contains12 H0 Htid))))
                        s4' m4' ->
          forall Htid' : containsThread st2 hb,
            machine_semantics_lemmas.thread_step_plus (HybConcSem (Some (S hb)) m) tge U st2
                                                      m2
                                                      (updThread Htid' (Krun (TState Clight.state Asm.state s4'))
                                                                 (getCurPerm m4', snd (getThreadR Htid'))) m4'.
      Proof.
      (** NOTE: This might be missing that the corestep never reaches an at_external
                  If this is the case, we might need to thread that through the compiler...
                  although it should be easy, I would prefere if there is any other way...
       *)
      Admitted.

      (** *Need an extra fact about simulations*)
      Lemma step2corestep_plus:
        forall (s1 s2: Smallstep.state (Asm.part_semantics Asm_g)) m1 t,
          Smallstep.plus
            (Asm.step (Genv.globalenv Asm_program))
            (Smallstep.set_mem s1 m1) t s2 ->
          (corestep_plus (Asm_core.Asm_core_sem Asm_g))
            s1 m1 s2 (Smallstep.get_mem s2).
      (* This in principle is not provable. We should get it somehow from the simulation.
              Possibly, by showing that the (internal) Clight step has no traces and allo
              external function calls have traces, so the "matching" Asm execution must be
              all internal steps (because otherwise the traces wouldn't match).
       *)
      Admitted.

      Lemma Forall2_impl: forall {A B} (P Q : A -> B -> Prop) l1 l2,
          (forall a b, P a b -> Q a b) -> List.Forall2 P l1 l2 -> List.Forall2 Q l1 l2.
      Proof.
        induction 2; constructor; auto.
      Qed.
      
      Lemma inject_incr_trace:
        forall (tr1 tr2 : list Events.machine_event) (mu f' : meminj),
          inject_incr mu f' ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          List.Forall2 (inject_mevent f') tr1 tr2.
      Proof.
        intros. eapply Forall2_impl; try eassumption.
        - intros. admit.
      Admitted.
      
      (* When a thread takes an internal step (i.e. not changing the schedule) *)
      Lemma internal_step_diagram:
        forall (m : option mem) (sge tge : HybridMachineSig.G) (U : list nat) tr1
          (st1 : ThreadPool (Some hb)) m1 (st1' : ThreadPool (Some hb)) m1',
          machine_semantics.thread_step (HybConcSem (Some hb) m) sge U st1 m1 st1' m1' ->
          forall cd tr2 (st2 : ThreadPool (Some (S hb))) mu m2,
            concur_match cd mu st1 m1 st2 m2 ->
            forall (Hmatch_event : List.Forall2 (inject_mevent mu) tr1 tr2),
            exists (st2' : ThreadPool (Some (S hb))) m2' cd' mu',
              concur_match cd' mu' st1' m1' st2' m2' /\
              List.Forall2 (inject_mevent mu') tr1 tr2 /\
              (machine_semantics_lemmas.thread_step_plus
                 (HybConcSem (Some (S hb)) m) tge U st2 m2 st2' m2' \/
               machine_semantics_lemmas.thread_step_star
                 (HybConcSem (Some (S hb)) m) tge U st2 m2 st2' m2' /\
               ord_opt (InjorderX compiler_sim) cd' cd).
      Proof.
        intros.
        inversion H; subst.
        inversion Htstep; subst.
        destruct (Compare_dec.lt_eq_lt_dec tid hb) as [[?|?]|?].  
        - (* tid < hb *)
          pose proof (mtch_target _ _ _ _ _ _ H0 _ l Htid (contains12 H0 Htid)) as HH.
          simpl in *.

          exploit_match ltac:(apply H0).
          destroy_ev_step_sum; subst; simpl in *; simpl.
          eapply Asm_event.asm_ev_ax1 in H2.
          clean_cmpt.
          instantiate (1:=Asm_genv_safe) in H2.
          
          eapply Aself_simulation in H5; eauto.
          destruct H5 as (c2' & f' & t' & m2' & (CoreStep & MATCH & Hincr & is_ext & inj_trace)).

          eapply Asm_event.asm_ev_ax2 in CoreStep; try eapply Asm_genv_safe.
          destruct CoreStep as (?&?); eauto.
          
          (* contains.*)
          pose proof (@contains12  _ _ _ _ _ _  H0 _ Htid) as Htid'.

          (* Construct the new thread pool *)
          exists (updThread Htid' (Krun (TState Clight.state Asm.state c2'))
                       (getCurPerm m2', snd (getThreadR Htid'))).
          (* new memory is given by the self_simulation. *)
          exists m2', cd, f'. split; [|split; [|left]].
          
          + (*Reestablish the concur_match *)
            simpl.
            move H0 at bottom.
            
            eapply Concur_update; eauto.
            { eapply semantics.corestep_mem in H2.
              eapply H2. }
            { eapply Asm_event.asm_ev_ax1 in H1.
              eapply semantics.corestep_mem.
              clean_cnt.
              erewrite restr_proof_irr.
              eassumption.
            }
            { apply H0. }

            (*The compiler match*)
            econstructor 2; eauto.
            simpl in MATCH.
            unfold match_thread_target; simpl.
            constructor.
            exact MATCH.
            
          + (* Reestablish inject_mevent *)
            eapply inject_incr_trace; eauto.
          + (* Construct the step *)
            exists 0%nat; simpl.
            do 2 eexists; split; [|reflexivity].
            replace m2' with (HybridMachineSig.diluteMem m2') by reflexivity.
            econstructor; eauto; simpl.
            econstructor; eauto.
            * simpl in *.
              eapply H0.
            * simpl; erewrite restr_proof_irr; econstructor; eauto.
            * simpl; repeat (f_equal; try eapply Axioms.proof_irr).
          + erewrite restr_proof_irr; eassumption.
              
              
        - (*  tid = hb*)
          pose proof (mtch_compiled _ _ _ _ _ _ H0 _ e Htid (contains12 H0 Htid)) as HH.
          subst.
          simpl in *.

          exploit_match ltac:(apply H0).

          
          (* This takes three steps:
           1. Simulation of the Clight semantics  
           2. Simulation of the compiler (Clight and Asm) 
           3. Simulation of the Asm semantics 
           *)

          rename H6 into Compiler_Match; simpl in *.
          
          (* (1) Clight step *)
          destroy_ev_step_sum. subst m'0 t0 s.
          eapply (event_semantics.ev_step_ax1 (@semSem CSem)) in H2; eauto.
          
          (* (2) Compiler step/s *)
          rename H2 into CoreStep.
          inversion CoreStep. subst s1 m0 s2.
          clean_cmpt.
          eapply compiler_sim in H1; simpl in *; eauto.
          2: { erewrite restr_proof_irr; eassumption. }
          destruct H1 as (cd' & s2' & j2' & t'' & step & comp_match & Hincr2 & inj_event).

          eapply simulation_equivlanence in step.
          assert ( HH: Asm.state =
                       Smallstep.state (Asm.part_semantics Asm_g)) by
              reflexivity.
          remember (@Smallstep.get_mem (Asm.part_semantics Asm_g) s2') as m2'.
          pose proof (@contains12  _ _ _ _ _ _  H0 _ Htid) as Htid'.

          destruct step as [plus_step | (? & ? & ?)].
          + exists (updThread Htid' (Krun (TState Clight.state Asm.state s2'))
                         (getCurPerm m2', snd (getThreadR Htid'))), m2', (Some i), mu.
            split; [|split].
            * assert (CMatch := H0). inversion H0; subst.
              admit. (*reestablish concur*)
            * eapply inject_incr_trace; try eassumption.
              apply inject_incr_refl.
            * left.
              eapply thread_step_plus_from_corestep; eauto.
              eauto; simpl.
              subst m2'.
              instantiate(1:=Htid).
              instantiate(21:=code2).
              instantiate (5:=H0).
              erewrite restr_proof_irr; eauto.
              eapply step2corestep_plus; eassumption.
              
          + exists st2, m2, (Some cd'), mu.
            split; [|split].
            * assert (CMatch := H0). inversion H0; subst.
              admit. (*reestablish concur*)
            * eapply inject_incr_trace; try eassumption.
              apply inject_incr_refl.
            * right; split.
              { (*zero steps*)
                exists 0%nat; simpl; auto. }
              { (*order of the index*)
                constructor; auto.  }
              
        - (* tid > hb *)
          pose proof (mtch_source _ _ _ _ _ _ H0 _ l Htid (contains12 H0 Htid)) as HH.
          simpl in *.
          exploit_match ltac:(apply H0).
          destroy_ev_step_sum; subst; simpl in *.
          simpl.
          eapply (event_semantics.ev_step_ax1 (@semSem CSem)) in H2; eauto.
          replace Hcmpt with (memcompat1 H0) in H2
            by eapply Axioms.proof_irr.
          
          eapply Cself_simulation in H5; eauto.
          destruct H5 as (c2' & f' & t' & m2' & (CoreStep & MATCH & Hincr & His_ext & Htrace)).
          
          eapply (event_semantics.ev_step_ax2 (@semSem CSem)) in CoreStep.
          destruct CoreStep as (?&?); eauto.
          
          (* contains.*)
          pose proof (@contains12  _ _ _ _ _ _  H0 _ Htid) as Htid'.

          (* Construct the new thread pool *)
          exists (updThread Htid' (Krun (SState Clight.state Asm.state c2'))
                       (getCurPerm m2', snd (getThreadR Htid'))).
          (* new memory is given by the self_simulation. *)
          exists m2', cd, f'. split; [|split; [|left]].
          
          + (*Reestablish the concur_match *)
            simpl.
            move H0 at bottom.
            eapply Concur_update; eauto.
            { eapply semantics.corestep_mem in H2.
              eapply H2. }
            { eapply (event_semantics.ev_step_ax1 (@semSem CSem)) in H1.
              eapply semantics.corestep_mem in H1.
              clean_cnt.
              erewrite restr_proof_irr.
              eassumption.
            }
            { apply H0. }
            
            econstructor 1; eauto.
            simpl in MATCH.
            unfold match_thread_source; simpl.
            constructor.
            exact MATCH.
          + eapply inject_incr_trace; try eassumption. 
          + (* Construct the step *)
            exists 0%nat; simpl.
            do 2 eexists; split; [|reflexivity].
            replace m2' with (HybridMachineSig.diluteMem m2') by reflexivity.
            econstructor; eauto; simpl.
            econstructor; eauto.
            * simpl in *.
              eapply H0.
            * simpl. 
              erewrite restr_proof_irr.
              econstructor; eauto.
            * simpl; repeat (f_equal; try eapply Axioms.proof_irr).
          + erewrite restr_proof_irr.
            eassumption.


            Unshelve. all: auto.
            (*This shouldn't be her e*) 
            all: try (exact nil).
            all: try (eapply H0).
            eapply Asm_genv_safe.
            
      Admitted. (* TODO: there is only one admit: reestablish the concur_match*)


      (** *Diagrams for machine steps*)



      (** *Lemmas about map, map1, bounded_maps.strong_tree_leq *)
      Lemma map_map1:
        forall {A B} f m,
          @PTree.map1 A B f m = PTree.map (fun _=> f) m.
      Proof.
        intros. unfold PTree.map.
        remember 1%positive as p eqn:Heq.
        clear Heq; revert p.
        induction m; try reflexivity.
        intros; simpl; rewrite <- IHm1.
        destruct o; simpl; (*2 goals*)
          rewrite <- IHm2; auto.
      Qed.
      Lemma strong_tree_leq_xmap:
        forall {A B} f1 f2 t (leq: option B -> option A -> Prop),
          (forall a p, leq (Some (f1 p a)) (Some (f2 p a))) ->
          leq None None ->
          forall p,
            bounded_maps.strong_tree_leq
              (PTree.xmap f1 t p)
              (@PTree.xmap A A f2 t p)
              leq.
      Proof.
        intros; revert p.
        induction t0; simpl; auto.
        repeat split; eauto.
        - destruct o; auto.
      Qed.
      Lemma strong_tree_leq_map:
        forall {A B} f1 f2 t (leq: option B -> option A -> Prop),
          (forall a p, leq (Some (f1 p a)) (Some (f2 p a))) ->
          leq None None ->
          bounded_maps.strong_tree_leq
            (@PTree.map A B f1 t)
            (@PTree.map A A f2 t)
            leq.
      Proof. intros; eapply strong_tree_leq_xmap; eauto. Qed.

      Lemma strong_tree_leq_xmap':
        forall {A B} f1 f2 t (leq: option B -> option A -> Prop),
        forall p,
          (forall a p0,
              PTree.get p0 t = Some a ->
              leq (Some (f1 (PTree.prev_append p p0)%positive a))
                  (Some (f2 (PTree.prev_append p p0)%positive a))) ->
          leq None None ->
          bounded_maps.strong_tree_leq
            (@PTree.xmap A B f1 t p)
            (@PTree.xmap A A f2 t p)
            leq.
      Proof.
        intros. revert p H.
        induction t0. simpl; auto.
        intros.
        repeat split.
        - destruct o; auto.
          move H at bottom.
          assert ((PTree.Node t0_1 (Some a) t0_2) ! 1%positive = Some a)
            by reflexivity.
          eapply H in H1. auto.
        -  eapply IHt0_1.
           intros; specialize (H a (p0~0)%positive).
           eapply H; auto.
        -  eapply IHt0_2.
           intros; specialize (H a (p0~1)%positive).
           eapply H; auto.
      Qed.
      
      Lemma strong_tree_leq_map':
        forall {A B} f1 f2 t (leq: option B -> option A -> Prop),
          (forall a p0,
              PTree.get p0 t = Some a ->
              leq (Some (f1 (PTree.prev_append 1 p0)%positive a))
                  (Some (f2 (PTree.prev_append 1 p0)%positive a))) ->
          leq None None ->
          bounded_maps.strong_tree_leq
            (@PTree.map A B f1 t)
            (@PTree.map A A f2 t)
            leq.
      Proof. intros; eapply strong_tree_leq_xmap'; eauto. Qed.




      
      (** * Lemmas for relase diagram*)
      Definition access_map_inject (f:meminj) (pmap1 pmap2: access_map):=
        forall (b1 b2 : block) (delt ofs: Z),
          f b1 = Some (b2, delt) ->
          Mem.perm_order'' (pmap2 !! b2 (ofs+delt)%Z) (pmap1 !! b1 ofs).
      Lemma access_map_inject_morphism':
        Proper (Logic.eq ==> access_map_equiv  ==> access_map_equiv ==> Basics.impl)
               access_map_inject.
      Proof.
        intros ????????? HH ?????; subst.
        rewrite <- H1, <- H0.
        eapply HH; eauto.
      Qed.
      Instance access_map_inject_morphism:
        Proper (Logic.eq ==> access_map_equiv  ==> access_map_equiv ==> Logic.iff)
               access_map_inject.
      Proof. split; eapply access_map_inject_morphism'; auto; symmetry; auto. Qed.
      (*
            Lemma access_map_injected_extentional1:
              forall f pm1 pm1' pm2,
                access_map_inject f pm1 pm2 ->
            (forall b, pm1 !! b = pm1' !! b) ->
            access_map_inject f pm1' pm2.
            Proof. intros. intros ????. rewrite <- H0. auto. Qed.
            Lemma access_map_injected_extentional2:
              forall f pm1 pm2 pm2',
                access_map_inject f pm1 pm2 ->
            (forall b , pm2 !! b = pm2' !! b) ->
            access_map_inject f pm1 pm2'.
            Proof.
              intros. intros ????. rewrite <- H0. auto. Qed. *)
      Lemma access_map_injected_getMaxPerm:
        forall f m1 m2,
          Mem.inject f m1 m2 ->
          access_map_inject f (getMaxPerm m1) (getMaxPerm m2).
        intros. intros ?????.
        do 2 rewrite getMaxPerm_correct.
        destruct (permission_at m1 b1 ofs Max) eqn:HH.
        - rewrite <- mem_lemmas.po_oo.
          eapply Mem.mi_perm; eauto.
          + apply H.
          + unfold Mem.perm.
            unfold permission_at in HH;
              rewrite HH.
            simpl.
            apply perm_refl.
        - apply event_semantics.po_None.
      Qed.
      Lemma access_map_injected_getCurPerm:
        forall f m1 m2,
          Mem.inject f m1 m2 ->
          access_map_inject f (getCurPerm m1) (getCurPerm m2).
        intros. intros ?????.
        do 2 rewrite getCurPerm_correct.
        destruct (permission_at m1 b1 ofs Cur) eqn:HH.
        - rewrite <- mem_lemmas.po_oo.
          eapply Mem.mi_perm; eauto.
          + apply H.
          + unfold Mem.perm.
            unfold permission_at in HH;
              rewrite HH.
            simpl.
            apply perm_refl.
        - apply event_semantics.po_None.
      Qed.
      
      Lemma setPermBlock_inject_permMapLt:
        forall n (NZ: (0 < n)%nat)
          (m1 m2 : mem) 
          (mu : meminj) cur_perm1 cur_perm2 max_perm1 max_perm2
          (b : block) (ofs : ptrofs) P,
          permMapLt
            (setPermBlock P b (unsigned ofs) cur_perm1 n)
            max_perm1 ->
          Mem.inject mu m1 m2 ->
          access_map_inject mu max_perm1 max_perm2 -> 
          forall (b' : block) (delt : Z),
            mu b = Some (b', delt) ->
            permMapLt cur_perm2 max_perm2 ->
            permMapLt
              (setPermBlock P b' (unsigned ofs + delt)
                            cur_perm2 n) max_perm2.
      Proof.
        intros; intros b0 ofs0.
        destruct (Clight_lemmas.block_eq_dec b' b0);
          [destruct (Intv.In_dec ofs0 ((unsigned ofs + delt)%Z, (unsigned ofs + delt + (Z.of_nat n))%Z))|
          ].
        - subst. unfold Intv.In in i; simpl in *.
          rewrite setPermBlock_same; auto.
          replace ofs0 with ((ofs0 - delt) + delt)%Z by omega.
          eapply juicy_mem.perm_order''_trans.

          2:{ unfold permMapLt in H.
              specialize (H b (ofs0 - delt)%Z).
              rewrite setPermBlock_same in H; auto; try omega.
              eauto. }
          
          + eapply H1; auto.
        - subst.
          rewrite setPermBlock_other_1; eauto.
          eapply Intv.range_notin in n0; auto; simpl.
          eapply inj_lt in NZ. rewrite Nat2Z.inj_0 in NZ.
          omega.
        - subst.
          rewrite setPermBlock_other_2; eauto.
      Qed.
      Lemma setPermBlock_inject_permMapLt':
        forall {Sem1 Sem2} (n:nat) (NZ: (0 < n)%nat) 
          (st1 : t(resources:=dryResources)(Sem:=Sem1)) (m1 : mem) (tid : nat) 
          (st2 : t(resources:=dryResources)(Sem:=Sem2)) (mu : meminj) (m2 : mem) (Htid1 : containsThread st1 tid)
          (b : block) (ofs : ptrofs),
          permMapLt
            (setPermBlock (Some Writable) b (unsigned ofs) (snd (getThreadR Htid1)) n)
            (getMaxPerm m1) ->
          Mem.inject mu m1 m2 ->
          forall (b' : block) (delt : Z),
            mu b = Some (b', delt) ->
            forall Htid2 : containsThread st2 tid,
              permMapLt (snd (getThreadR Htid2)) (getMaxPerm m2) ->
              permMapLt
                (setPermBlock (Some Writable) b' (unsigned ofs + delt)
                              (snd (getThreadR Htid2)) n) (getMaxPerm m2).
      Proof.

        intros; intros b0 ofs0. 
        destruct (Clight_lemmas.block_eq_dec b' b0);
          [destruct (Intv.In_dec ofs0 ((unsigned ofs + delt)%Z, (unsigned ofs + delt + (Z.of_nat n))%Z))|
          ].
        - subst. unfold Intv.In in i; simpl in *.
          rewrite setPermBlock_same; auto.
          replace ofs0 with ((ofs0 - delt) + delt)%Z by omega.
          eapply juicy_mem.perm_order''_trans.

          + rewrite getMaxPerm_correct; unfold permission_at.
            eapply mem_lemmas.inject_permorder; eauto.

          + specialize (H b (ofs0 - delt)%Z).
            rewrite getMaxPerm_correct in H; unfold permission_at in H.
            rewrite setPermBlock_same in H.
            assumption.
            omega.
        - subst.
          rewrite setPermBlock_other_1; eauto.
          eapply Intv.range_notin in n0; auto; simpl.
          eapply inj_lt in NZ. rewrite Nat2Z.inj_0 in NZ.
          omega.
        - subst.
          rewrite setPermBlock_other_2; eauto.
      Qed.

      Lemma permMapLt_extensional1:
        forall p1 p2 p3,
          (forall b, p2 !! b = p3 !! b) -> 
          permMapLt p1 p2 ->
          permMapLt p1 p3.
      Proof. intros; intros ??. rewrite <- H. eapply H0. Qed.
      Lemma permMapLt_extensional2:
        forall p1 p2 p3,
          (forall b, p1 !! b = p2 !! b) -> 
          permMapLt p1 p3 ->
          permMapLt p2 p3.
      Proof. intros; intros ??. rewrite <- H. eapply H0. Qed.
      
      Lemma cat_app:
        forall {T} (l1 l2:list T),
          seq.cat l1 l2 = app l1 l2.
      Proof. intros. induction l1; eauto. Qed.

      (* MAPS! *)
      Lemma strong_tree_leq_spec:
        forall {A B} (leq: option A -> option B -> Prop),
          leq None None ->
          forall t1 t2,
            bounded_maps.strong_tree_leq t1 t2 leq ->
            forall b, leq (@PTree.get A b t1) 
                     (@PTree.get B b t2).
      Proof.
        intros A B leq Hleq t1.
        induction t1; eauto.
        - intros.
          destruct t2; try solve[inversion H].
          destruct b; simpl; auto.
        - intros t2 HH.
          destruct t2; try solve[inversion HH].
          destruct HH as (INEQ&L&R).
          destruct b; simpl; eauto.
      Qed.
      Lemma trivial_map1:
        forall {A} (t : PTree.t A),
          PTree.map1 (fun (a : A) => a) t = t.
      Proof.
        intros ? t; induction t; auto.
        simpl; f_equal; eauto.
        destruct o; reflexivity.
      Qed.
      Lemma trivial_map:
        forall {A} (t : PTree.t A),
          PTree.map (fun (_ : positive) (a : A) => a) t = t.
      Proof.
        intros; rewrite <- map_map1; eapply trivial_map1.
      Qed.

      
      Lemma inject_virtue_sub_map:
        forall (m1 m2 : mem)
          (mu : meminj)
          {A} (virtue1 : PTree.t (Z -> option A))
          perm1 perm2 Hlt1 Hlt2,
          Mem.inject mu (@restrPermMap perm1 m1 Hlt1 ) 
                        (@restrPermMap perm2 m2 Hlt2 ) ->
          bounded_maps.sub_map virtue1 (snd (getMaxPerm m1)) ->
          bounded_maps.sub_map (tree_map_inject_over_mem m2 mu virtue1) (snd (getMaxPerm m2)).
      Proof.
        intros m1 m2 mu AT virtue1 perm1 perm2 Hlt1 Hlt2 injmem A.

        replace  (snd (getMaxPerm m2)) with
            (PTree.map (fun _ a => a)  (snd (getMaxPerm m2)))
          by eapply trivial_map.
        unfold tree_map_inject_over_mem, tree_map_inject_over_tree.


        pose proof (@strong_tree_leq_map') as HHH.
        specialize (HHH _ (Z -> option AT)
                        (fun (b : positive) _ =>
                           build_function_for_a_block mu b (PTree.elements virtue1))
                        (fun (_ : positive) a => a)
                        (snd (getMaxPerm m2))
                        bounded_maps.fun_leq
                   ).
        unfold bounded_maps.sub_map.
        eapply HHH; eauto; try constructor.
        clear HHH.
        
        intros; simpl. intros p HH.
        
        pose proof (PTree.elements_complete virtue1).
        remember (PTree.elements virtue1) as Velmts.
        clear HeqVelmts.
        induction Velmts as [|[b0 fb]]; try solve[inversion HH].
        simpl in HH.
        destruct (mu b0) as [[b1 delt]|] eqn:Hinj.
        * unfold merge_func in HH.

          destruct (PMap.elt_eq p0 b1); subst.
          destruct (fb (p-delt)%Z) eqn:Hfbp.
          
          -- specialize (H0 b0 fb ltac:(left; auto)).
             clear HH.
             cbv beta zeta iota delta[fst] in A.
             pose proof (strong_tree_leq_spec
                           bounded_maps.fun_leq
                           ltac:(simpl; auto)
                                  virtue1 (snd (getMaxPerm m1)) A b0).
             rewrite H0 in H1.
             unfold bounded_maps.fun_leq in H1.
             destruct ((snd (getMaxPerm m1)) ! b0) eqn:Heqn;
               try solve[inversion H1].
             specialize (H1 (p - delt)%Z ltac:(rewrite Hfbp; auto)).
             eapply Mem.mi_perm in Hinj; try apply injmem.
             
             
             2: {
               
               clear IHVelmts Velmts Hinj.
               clear Hfbp A a b1 H.

               instantiate (2:= Max).
               instantiate (2:= (p - delt)%Z).
               instantiate (1:= Nonempty).
               unfold Mem.perm.
               pose proof restrPermMap_Max as H3.
               unfold permission_at in H3.
               rewrite H3; clear H3.
               unfold PMap.get.
               rewrite Heqn.
               
               destruct (o (p - delt)%Z); try solve[inversion H1].
               destruct p; try constructor.
             }

             
             unfold Mem.perm in Hinj.
             pose proof restrPermMap_Max as H2.
             unfold permission_at in H2.
             rewrite H2 in Hinj.
             unfold PMap.get in Hinj.
             rewrite H in Hinj.
             replace (p - delt + delt)%Z with p in Hinj by omega.
             destruct (a p); inversion Hinj; auto.

          -- eapply IHVelmts in HH; auto.
             intros; eapply H0; right.
             auto.

          -- eapply IHVelmts in HH; auto.
             intros; eapply H0.
             right; auto.

        * (* mu b0 = None *)
          eapply IHVelmts in HH; auto.
          intros; eapply H0.
          right; auto.
      Qed.
      
      Lemma setPermBlock_extensionality:
        forall perm b ofs perm_map1 perm_map2 n,
          (0 < n)%nat ->
          (forall b0, perm_map1 !! b0 = perm_map2 !! b0) -> 
          forall b0, (setPermBlock perm b ofs perm_map1 n) !! b0=
                (setPermBlock perm b ofs perm_map2 n) !! b0.
      Proof.
        intros.
        extensionality ofs0.
        destruct_address_range b ofs b0 ofs0 n.
        - do 2 (rewrite setPermBlock_same; auto).
        - eapply Intv.range_notin in Hrange;
            try (simpl; omega).
          do 2 (erewrite setPermBlock_other_1; auto).
          rewrite (H0 b); auto.
        - do 2 (rewrite setPermBlock_other_2; auto).
          rewrite H0; auto.
      Qed.
      Lemma LKSIZE_nat_pos: (0 < LKSIZE_nat)%nat.
      Proof.
        replace 0%nat with (Z.to_nat 0)%Z by reflexivity.
        unfold LKSIZE_nat, LKSIZE.
        rewrite size_chunk_Mptr.
        destruct Archi.ptr64;
          eapply Z2Nat.inj_lt; eauto; try omega.
      Qed.
      Hint Resolve LKSIZE_nat_pos.

      (** * The following lemmas prove the injection 
                  of memories unfer setPermBlock.
       *)


      Lemma setPermBlock_mi_perm_Cur:
        forall (mu : meminj) (m1 m2 : mem) (b b' : block) (ofs delt : Z) 
          (n : nat),
          (0 < n)%nat ->
          forall (Hno_overlap:Mem.meminj_no_overlap mu m1)
            (Hlt1 : permMapLt (setPermBlock (Some Writable)
                                            b ofs (getCurPerm m1) n) (getMaxPerm m1))
            (Hlt2 : permMapLt (setPermBlock (Some Writable)
                                            b' (ofs + delt) (getCurPerm m2) n)
                              (getMaxPerm m2)),
            mu b = Some (b', delt) ->
            Mem.mem_inj mu m1 m2 ->
            forall (b1 b2 : block) (delta ofs0 : Z) (p : permission),
              mu b1 = Some (b2, delta) ->
              Mem.perm_order' ((getCurPerm (restrPermMap Hlt1)) !! b1 ofs0) p ->
              Mem.perm_order' ((getCurPerm (restrPermMap Hlt2)) !! b2 (ofs0 + delta)%Z) p.
      Proof.
        intros mu m1 m2 b b' ofs delt n Neq
               Hno_overlap Hlt1 Hlt2 H0 H1 b1 b2 delta ofs0 p H2 H3.
        
        rewrite getCur_restr in *.
        destruct_address_range b1 ofs b ofs0 n.
        - rewrite setPermBlock_same in H3; auto.
          rewrite H2 in H0; inversion H0; subst.
          rewrite setPermBlock_same; auto.
          unfold Intv.In in Hrange; simpl in Hrange.
          omega.
        - eapply Intv.range_notin in Hrange;
            try (simpl; omega).
          erewrite setPermBlock_other_1 in H3; auto.
          rewrite H2 in H0; inversion H0; subst.
          erewrite setPermBlock_other_1; auto.
          + rewrite getCurPerm_correct in *.
            eapply H1; eauto.
          + destruct Hrange; simpl in *; [left | right]; omega.
            
        - rewrite setPermBlock_other_2 in H3; auto.
          
          pose proof (Classical_Prop.classic
                        (Mem.perm_order'' (Some p) (Some Nonempty))) as [HH|HH].
          2: { destruct p; try solve[contradict HH; constructor]. }
          
          assert (HNoneempty:Mem.perm m1 b1 ofs0 Max Nonempty).
          { unfold Mem.perm. rewrite mem_lemmas.po_oo in *.
            eapply juicy_mem.perm_order''_trans; eauto.
            eapply juicy_mem.perm_order''_trans; eauto.
            rewrite getCurPerm_correct.
            eapply Mem.access_max. }

          assert (Hrange_no_overlap := Hneq).
          eapply setPermBLock_no_overlap in Hrange_no_overlap; eauto.
          
          destruct Hrange_no_overlap as [H | [H H']]; eauto.
          
          --  erewrite setPermBlock_other_2; auto.
              rewrite getCurPerm_correct.
              eapply H1; eauto.
              unfold Mem.perm. rewrite_getPerm; auto.
          -- subst; erewrite setPermBlock_other_1; auto.
             rewrite getCurPerm_correct.
             eapply H1; eauto.
             unfold Mem.perm. rewrite_getPerm; auto.
             eapply Intv.range_notin in H'; auto.
             simpl; omega.
      Qed.

      Definition inject_lock_simpl
                 size mu (b_lock:block) (ofs_lock: Z) (m1 m2:mem):=
        forall b_lock' delt,
          mu b_lock = Some (b_lock', delt) -> 
          ( forall ofs0,
              Intv.In ofs0 (ofs_lock, (ofs_lock + size)%Z) ->
              memval_inject mu
                            (ZMap.get ofs0 (Mem.mem_contents m1) !! b_lock)
                            (ZMap.get (ofs0 + delt)%Z
                                      (Mem.mem_contents m2) !! b_lock')).
      Lemma inject_lock_simplification:
        forall n mu b_lock ofs_lock m1 m2,
          inject_lock' n mu b_lock ofs_lock m1 m2 ->
          inject_lock_simpl n mu b_lock ofs_lock m1 m2.
      Proof. intros. destruct H as (? &? &?&HH).
             unfold inject_lock_simpl; intros.
             rewrite H in H0; inversion H0; subst.
             eauto.
      Qed.
      Lemma setPermBlock_mem_inj:
        forall mu m1 m2 b b' ofs delt n,
          (0 < n)%nat ->
          forall (Hinject_lock: inject_lock' (Z.of_nat n) mu b ofs m1 m2)
            (Hno_overlap:Mem.meminj_no_overlap mu m1)
            (Hlt1: permMapLt
                     (setPermBlock (Some Writable) b ofs
                                   (getCurPerm m1)
                                   n) (getMaxPerm m1))
            
            (Hlt2: permMapLt
                     (setPermBlock (Some Writable) b' (ofs + delt)
                                   (getCurPerm m2)
                                   n) (getMaxPerm m2)),
            mu b = Some (b', delt) ->
            Mem.mem_inj mu m1 m2 ->
            Mem.mem_inj mu (restrPermMap Hlt1) (restrPermMap Hlt2).
      Proof.
        intros; econstructor.
        - unfold Mem.perm; intros.
          destruct k.
          + repeat rewrite_getPerm.
            rewrite getMax_restr in *.
            rewrite getMaxPerm_correct in *.
            eapply H1; eauto.
          + repeat rewrite_getPerm.
            eapply setPermBlock_mi_perm_Cur; eauto.
        - intros.
          eapply H1; eauto.
          unfold Mem.range_perm, Mem.perm in *.
          intros.
          specialize (H3 _ H4).
          repeat rewrite_getPerm.
          rewrite getMax_restr in H3; eauto.
        - intros; simpl.
          unfold Mem.perm in *. 
          repeat rewrite_getPerm.
          rewrite getCur_restr in H3.
          destruct_address_range b ofs b1 ofs0 n.

          + eapply inject_lock_simplification; eauto.

          + eapply H1; auto.
            rewrite setPermBlock_other_1 in H3; auto.
            unfold Mem.perm; rewrite_getPerm; auto.
            eapply Intv.range_notin in Hrange; simpl; auto.
            omega.
            
          + eapply H1; auto.
            rewrite setPermBlock_other_2 in H3; auto.
            unfold Mem.perm; rewrite_getPerm; auto.
      Qed.

      (* Last case for Mem.inject,
                       using setPermBlock with Cur
                       Helper lemma for setPermBlock_mem_inject
       *)
      Lemma setPermBlock_mi_perm_inv_Cur:
        forall b1 b1' ofs delt1 m1 m2 n mu,
          (0 < n)%nat -> 
          forall (Hlt1: permMapLt
                     (setPermBlock (Some Writable)
                                   b1 ofs (getCurPerm m1) n)
                     (getMaxPerm m1))
            (Hlt2: permMapLt
                     (setPermBlock (Some Writable)
                                   b1' (ofs + delt1) (getCurPerm m2) n)
                     (getMaxPerm m2))
            (Hinject:Mem.inject mu m1 m2)
          ,                           mu b1 = Some (b1', delt1) -> 
                                      forall b2 b2' ofs0 delt2 p,
                                        let m1_restr := (restrPermMap Hlt1) in
                                        let m2_restr := (restrPermMap Hlt2) in
                                        mu b2 = Some (b2', delt2) ->
                                        Mem.perm m2_restr b2' (ofs0 + delt2) Cur p ->
                                        Mem.perm m1_restr b2 ofs0 Cur p \/
                                        ~ Mem.perm m1_restr b2 ofs0 Max Nonempty.
      Proof.
        intros.
        unfold Mem.perm in *.
        repeat rewrite_getPerm.
        subst m1_restr m2_restr; rewrite getCur_restr in *.
        rewrite getMax_restr.
        (* try to do it backwards: destruct source blocks first*)
        destruct_address_range
          b1 (ofs)%Z b2 (ofs0)%Z n.
        - rewrite H0 in H1; inversion H1; subst.
          rewrite setPermBlock_same.
          2: { unfold Intv.In in *; auto. }
          rewrite setPermBlock_same in H2.
          2: { unfold Intv.In in *; simpl in *; omega. } 
          auto.
        - rewrite H0 in H1; inversion H1; subst.
          rewrite setPermBlock_other_1.
          2: { eapply Intv.range_notin in Hrange; eauto.
               simpl; omega. }
          rewrite setPermBlock_other_1 in H2.
          2: { eapply Intv.range_notin in Hrange; eauto;
               simpl in *; omega. }
          rewrite getCurPerm_correct, getMaxPerm_correct in *.
          eapply Hinject; eauto.
        - pose proof (Classical_Prop.classic
                        (Mem.perm_order' ((getMaxPerm m1) !! b2 ofs0) Nonempty))
            as [HH|HH]; try eauto.
          rewrite setPermBlock_other_2; eauto.
          rewrite getCurPerm_correct, getMaxPerm_correct in *.
          eapply Hinject; eauto.
          unfold Mem.perm in *; rewrite_getPerm.
          
          (* now destruct the addresses for the target blocks*)
          destruct_address_range
            b1' (ofs+delt1)%Z b2' (ofs0 + delt2)%Z n.
          + exploit (@range_no_overlap mu m1 b2 b1' b1 b1');
              try apply Hneq; eauto.
            * eapply Hinject.
            * eapply setPermBlock_range_perm in Hlt1.
              eapply range_perm_trans; eauto.
              constructor.
            * intros [?|[? ?]].
              -- contradict H3; auto.
              -- contradict H4; eassumption.
          + rewrite setPermBlock_other_1 in H2; eauto.
            eapply Intv.range_notin in Hrange; simpl in *; omega.
          + rewrite setPermBlock_other_2 in H2; eauto.
      Qed.
      
      Lemma setPermBlock_mem_inject:
        forall mu m1 m2 b b' ofs delt LKSIZE_nat,
          (0 < LKSIZE_nat)%nat ->
          forall (Hinject_lock: inject_lock' (Z.of_nat LKSIZE_nat) mu b ofs m1 m2)
            (Hlt1: permMapLt
                     (setPermBlock (Some Writable) b ofs
                                   (getCurPerm m1)
                                   LKSIZE_nat) (getMaxPerm m1))
            
            (Hlt2: permMapLt
                     (setPermBlock (Some Writable) b' (ofs + delt)
                                   (getCurPerm m2)
                                   LKSIZE_nat) (getMaxPerm m2)),
            mu b = Some (b', delt) ->
            Mem.inject mu m1 m2 ->
            Mem.inject mu (restrPermMap Hlt1) (restrPermMap Hlt2).
      Proof.
        intros; econstructor.
        - eapply setPermBlock_mem_inj; auto; eapply H1.
        - intros ?; rewrite restrPermMap_valid.
          eapply H1. 
        - intros. apply restrPermMap_valid.
          eapply H1; eauto.
        - pose proof (restr_Max_equiv Hlt1).
          eapply Proper_no_overlap_max_equiv; eauto.
          eapply H1.
        - intros ????? ?. 
          eapply H1; eauto.
          pose proof (restr_Max_equiv Hlt1) as HH.
          destruct H3 as [H3|H3];
          eapply (Proper_perm_max) in H3;
            try (symmetry; apply restr_Max_equiv);
            try eassumption;
            try solve[econstructor];
            auto.
        - intros.
          pose proof (restr_Max_equiv Hlt1) as HH1.
          pose proof (restr_Max_equiv Hlt2) as HH2.
          destruct k.
          + eapply (Proper_perm_max) in H3;
              try (symmetry; apply restr_Max_equiv);
              try eassumption;
              eauto.
            eapply H1 in H3; eauto.
            destruct H3 as [H3|H3].
            * left; eapply Proper_perm_max;
                try eassumption;
                try solve[econstructor];
                auto.
            * right; intros ?; apply H3.
              eapply (Proper_perm_max) in H4;
                try eassumption; eauto.
              symmetry; apply restr_Max_equiv.
          + eapply setPermBlock_mi_perm_inv_Cur; eauto.
      Qed.

      Definition mi_perm_perm f perm1 perm2:=
        forall (b1 b2 : block) (delta ofs : Z)(p : permission),
          f b1 = Some (b2, delta) ->
          Mem.perm_order' (perm1 !! b1 ofs) p ->
          Mem.perm_order' (perm2 !! b2 (ofs + delta)) p.
      Definition mi_align_perm f perm1 cont1 cont2:=
        forall b1 b2 delta ofs,
          f b1 = Some (b2, delta) ->
          Mem.perm_order' (perm1 !! b1 ofs) Readable ->
          memval_inject f (ZMap.get ofs cont1 !! b1)
                        (ZMap.get (ofs + delta) cont2 !! b2).
      Lemma mem_inj_restr:
        forall mu m1 m2 perm1 perm2,
        forall (Hlt1: permMapLt perm1 (getMaxPerm m1))
          (Hlt2: permMapLt perm2 (getMaxPerm m2)),
          mi_perm_perm mu perm1 perm2 ->
          mi_align_perm mu perm1 (Mem.mem_contents m1) (Mem.mem_contents m2) ->
          Mem.mem_inj mu m1 m2 ->
          Mem.mem_inj mu (restrPermMap Hlt1) (restrPermMap Hlt2).
      Proof.
        intros * Hmi_perm Hmi_align H; econstructor.
        - unfold Mem.perm; intros.
          destruct k; repeat rewrite_getPerm.
          + (* Max *)
            rewrite getMax_restr in *.
            eapply H with (k:=Max) in H0;
              unfold Mem.perm in *; repeat rewrite_getPerm; eauto.
          + rewrite getCur_restr in *.
            eapply Hmi_perm; eassumption.
        - intros * ?. 
          rewrite restr_Max_equiv.
          eapply H; eassumption.
        - intros *; simpl.
          unfold Mem.perm.
          rewrite_getPerm.
          rewrite getCur_restr.
          apply Hmi_align.
      Qed.
      
      Definition mi_perm_inv_perm f perm1 perm2 m1:=
        forall (b1 : block) (ofs : Z) (b2 : block) 
          (delta : Z) (p : permission),
          f b1 = Some (b2, delta) ->
          Mem.perm_order' (perm2 !! b2 (ofs + delta)) p ->
          Mem.perm_order' (perm1 !! b1 ofs) p
          \/ ~ Mem.perm m1 b1 ofs Max Nonempty.      
      Lemma inject_restr:
        forall mu m1 m2 perm1 perm2,
          forall (Hlt1: permMapLt perm1 (getMaxPerm m1))
            (Hlt2: permMapLt perm2 (getMaxPerm m2)),
            mi_perm_perm mu perm1 perm2 ->
            mi_align_perm mu perm1 (Mem.mem_contents m1) (Mem.mem_contents m2) ->
            mi_perm_inv_perm mu perm1 perm2 m1 ->
            Mem.inject mu m1 m2 ->
            Mem.inject mu (restrPermMap Hlt1) (restrPermMap Hlt2).
      Proof.
        intros * Hmi_perm Hmi_align Hmi_perm_inv; econstructor.
        - apply mem_inj_restr; try assumption. apply H.
        - intros ? Hnot_valid; apply H.
          eauto using restrPermMap_valid.
        - intros.
          eapply restrPermMap_valid. eapply H. eassumption.
        - rewrite restr_Max_equiv. apply H.
        - intros. rewrite restr_Max_equiv in H1.
          eapply H; eauto.
        - intros until delta.
          intros [] *.
          + repeat rewrite restr_Max_equiv.
            eapply H; eauto.
          + unfold Mem.perm; repeat rewrite_getPerm.
            repeat rewrite getCur_restr;
              rewrite getMax_restr.
            rewrite getMaxPerm_correct.
            eapply Hmi_perm_inv.
      Qed.
        
      Lemma setPermBlock_mem_inject_lock:
        forall mu m1 m2 b b' ofs delt LKSIZE_nat,
          (0 < LKSIZE_nat)%nat ->
          forall (Hinject_lock: inject_lock' (Z.of_nat LKSIZE_nat) mu b ofs m1 m2)
            (Hlt1: permMapLt
                     (setPermBlock (Some Writable) b ofs
                                   (getCurPerm m1)
                                   LKSIZE_nat) (getMaxPerm m1))
            
            (Hlt2: permMapLt
                     (setPermBlock (Some Writable) b' (ofs + delt)
                                   (getCurPerm m2)
                                   LKSIZE_nat) (getMaxPerm m2)),
            mu b = Some (b', delt) ->
            Mem.inject mu m1 m2 ->
            Mem.inject mu (restrPermMap Hlt1) (restrPermMap Hlt2).
      Proof.
        intros; econstructor.
        - eapply setPermBlock_mem_inj; auto;
            eapply H1.
        - intros ?.
          rewrite restrPermMap_valid.
          eapply H1. 
        - intros. apply restrPermMap_valid.
          eapply H1; eauto.
        - 
          
          pose proof (restr_Max_equiv Hlt1).
          eapply Proper_no_overlap_max_equiv; eauto.
          eapply H1.
        - intros ?????.
          

          intros ?.
          eapply H1; eauto.

          pose proof (restr_Max_equiv Hlt1) as HH.
          destruct H3 as [H3|H3];
          eapply (Proper_perm_max) in H3;
            try (symmetry; apply restr_Max_equiv);
            try eassumption;
            try solve[econstructor];
            auto.

        - intros.
          pose proof (restr_Max_equiv Hlt1) as HH1.
          pose proof (restr_Max_equiv Hlt2) as HH2.
          destruct k.
          + eapply (Proper_perm_max) in H3;
              try (symmetry; apply restr_Max_equiv);
              try eassumption;
              eauto.
            eapply H1 in H3; eauto.
            destruct H3 as [H3|H3].
            * left; eapply Proper_perm_max;
                try eassumption;
                try solve[econstructor];
                auto.
            * right; intros ?; apply H3.
              eapply (Proper_perm_max) in H4;
                try eassumption; eauto.
              symmetry; apply restr_Max_equiv.
          + eapply setPermBlock_mi_perm_inv_Cur; eauto.
      Qed.
      
      Lemma setPermBlock_mem_inject_lock':
        forall mu m1 m2 b b' ofs delt LKSIZE_nat,
          (0 < LKSIZE_nat)%nat ->
          forall (Hinject_lock: inject_lock' (Z.of_nat LKSIZE_nat) mu b ofs m1 m2)
            perm1 perm2
            (Hlt1': permMapLt perm1 (getMaxPerm m1))
            (Hlt2': permMapLt perm2 (getMaxPerm m2))
            (Hlt1: permMapLt
                     (setPermBlock (Some Writable) b ofs
                                   perm1
                                   LKSIZE_nat) (getMaxPerm m1))
            
            (Hlt2: permMapLt
                     (setPermBlock (Some Writable) b' (ofs + delt)
                                   perm2
                                   LKSIZE_nat) (getMaxPerm m2)),
            mu b = Some (b', delt) ->
            Mem.inject mu m1 m2 ->
            Mem.inject mu (restrPermMap Hlt1) (restrPermMap Hlt2).
      Proof.
        intros until perm2; intros ??.
        assert (Max_equiv (restrPermMap Hlt1') m1) by apply restr_Max_equiv.
        assert (Max_equiv (restrPermMap Hlt2') m2) by apply restr_Max_equiv.
        remember (restrPermMap Hlt1') as m_perm1.
        remember (restrPermMap Hlt2') as m_perm2.
        intros ? ? Hmu Hinj.
        eapply mem_inject_equiv.
        - reflexivity.
        - unshelve(instantiate(1:= (@restrPermMap
                                      (setPermBlock (@Some permission Writable)
                                                    b ofs perm1 LKSIZE_nat)
                                         ((@restrPermMap perm1 m1 Hlt1')) _))).
          admit.
          constructor.
          + admit.
          + admit.
          + admit.
          + reflexivity.
      - unshelve(instantiate(1:= (@restrPermMap (setPermBlock (@Some permission Writable) b ofs perm2 LKSIZE_nat)
                                                  ((@restrPermMap perm2 m2 Hlt2')) _))).
          (*just like above. *) admit. admit.
      - admit.
      Admitted.
       
      
      Definition computeMap_pair:= pair2 computeMap.
      Hint Unfold computeMap_pair: pair.
      Record virtue:=
        { virtueThread:
            PTree.t (Z -> option (option permission)) *
            PTree.t (Z -> option (option permission));
          virtueLP: access_map * access_map }.
      Definition inject_virtue (m: mem) (mu: meminj) (angel:virtue):=
          Build_virtue
            (virtueThread_inject m mu (virtueThread angel))
            (virtueLP_inject m mu (virtueLP angel)).
        Definition build_release_event addr dmap m:=
          Events.release addr (Some (build_delta_content dmap m)).
        Definition build_acquire_event addr dmap m:=
          Events.acquire addr (Some (build_delta_content dmap m)).

        Definition pair21 {A B C} (f: A -> B -> C) (aa:Pair A) (b: B): Pair C :=
          pair1 (fun a => f a b) aa.
        Hint Unfold pair21: pair.
        Definition pair21_prop {A B} (f: A -> B -> Prop) (aa:Pair A) (b: B):Prop :=
          pair1_prop (fun a => f a b) aa.
        Hint Unfold pair21_prop: pair.
        Definition permMapLt_pair1:= pair21_prop permMapLt.
        Hint Unfold permMapLt_pair1: pair.
        (*
        Definition deltaMapLt_pair1:= pair21_prop deltaMapLt. 
        pair1_prop (fun A => deltaMapLt A m).
          Hint Unfold deltaMapLt_pair1: pair.
         *)

        (*Take just the tree*)
        Definition sub_map' {A A' B} (a:A'* _) b:=
          @bounded_maps.sub_map A B (snd a) b. 
      Record sub_map_virtue (v:virtue)(m:access_map):=
        { virtueThread_sub_map:
            pair21_prop bounded_maps.sub_map (virtueThread v) (snd m);
          virtueLP_sub_map:
            bounded_maps.map_empty_def (fst (virtueLP v)) /\
            bounded_maps.map_empty_def (snd (virtueLP v)) /\
            pair21_prop sub_map' (virtueLP v) (snd m)
        }.
      
      (*  *)
      Definition writeable_lock b ofs perm1 m1:=
        permMapLt (setPermBlock (Some Writable) b ofs perm1 LKSIZE_nat) (getMaxPerm m1).
      Definition thread_mems {Sem st i m}
                     {cnt:containsThread(resources:=dryResources)(Sem:=Sem) st i}
                     (th_compat: thread_compat cnt m):=
            (restrPermMap (th_comp th_compat),restrPermMap (lock_comp th_compat)).
      Definition permMapJoin_pair:= pair3_prop permMapJoin.
      Hint Unfold permMapJoin_pair: pair.
            
      Definition is_empty_map (am:access_map):=
        forall b ofs, am !! b ofs = None.
      Definition empty_doublemap:=
        pair1_prop is_empty_map.
      Lemma inject_empty_maps:
        forall empty_perms m mu
          (Hempty_map : empty_doublemap empty_perms),
          empty_doublemap (virtueLP_inject m mu empty_perms).
      Proof.
      Admitted.
      Lemma empty_map_useful:
        (* Transforms empty_doublemap into the 
               form used by step *)
        forall am,
          empty_doublemap am <->
          forall b ofs, (fst am) !! b ofs = None /\ (snd am) !! b ofs = None.
      Proof. split; intros HH; split; try intros ??; eapply HH. Qed.
      

      
      (** * End of Lemmas for relase diagram*)

      Infix "++":= seq.cat.
      Lemma release_step_diagram:
        let hybrid_sem:= (sem_coresem (HybridSem (Some hb))) in 
        forall (angel: virtue) (U : list nat) (tid : nat) (cd : option compiler_index)
          (HSched: HybridMachineSig.schedPeek U = Some tid)
          (mu : meminj)
          (st1 : ThreadPool (Some hb)) (m1 m1' : mem) 
          (tr1 tr2 : HybridMachineSig.event_trace)
          (st2 : ThreadPool (Some (S hb))) (m2 : mem)
          (cnt1 : containsThread(Sem:=HybridSem (Some hb)) st1 tid)
          (c : semC) (b : block) (ofs : int)
          (rmap : lock_info)
          (Hwritable_lock1 : writeable_lock b (unsigned ofs) (snd (getThreadR cnt1)) m1)
          (Hcmpt : mem_compatible st1 m1)
          (thread_compat1: thread_compat cnt1 m1),
          let m_writable_lock_1:= restrPermMap Hwritable_lock1 in
          let th_mem1 :=  fst (thread_mems thread_compat1) in
          let locks_mem1:= snd (thread_mems thread_compat1) in
          let newThreadPerm1:= (computeMap_pair (getThreadR cnt1) (virtueThread angel)) in
          let virtueThread:= virtueThread angel in
          let virtueLP := virtueLP angel in
          forall (CMatch:concur_match cd mu st1 m1 st2 m2)
          (HTraceInj: List.Forall2 (inject_mevent mu) tr1 tr2)
          (Hangel_bound: sub_map_virtue angel (getMaxPerm m1))
          (Hinv: invariant st1)
          (Hcode: getThreadC cnt1 = Kblocked c)
          (Hat_external: semantics.at_external hybrid_sem c th_mem1 =
                         Some (UNLOCK, (Vptr b ofs :: nil)%list))
          (Hload: Mem.load AST.Mint32 locks_mem1 b (unsigned ofs) = Some (Vint Integers.Int.zero))
          (Haccess: Mem.range_perm locks_mem1 b (unsigned ofs)
                      (Z.add (unsigned ofs) LKSIZE) Cur Readable)
          (Hstore: Mem.store AST.Mint32 m_writable_lock_1 b
                             (unsigned ofs) (Vint Int.one) = Some m1')
          (HisLock: ThreadPool.lockRes st1 (b, unsigned ofs) = Some rmap)
          (Hrmap: empty_doublemap rmap)
          (Hjoin_angel: permMapJoin_pair newThreadPerm1 virtueLP (getThreadR cnt1)),
        exists
          evnt' (st2' : t) (m2' : mem) (cd' : option compiler_index)(mu' : meminj),
          let evnt:= (Events.release (b, unsigned ofs) (Some (build_delta_content (fst virtueThread) m1'))) in 
          concur_match cd' mu'
                       (updLockSet
                          (updThread cnt1 (Kresume c Vundef)
                                     (computeMap_pair (getThreadR cnt1) (virtueThread)))
                          (b, unsigned ofs) virtueLP) m1' st2' m2' /\
          List.Forall2 (inject_mevent mu')
                       (tr1 ++ (Events.external tid evnt :: nil))
                       (tr2 ++ (Events.external tid evnt' :: nil)) /\
          HybridMachineSig.external_step
            (scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler)
            U tr2 st2 m2 (HybridMachineSig.schedSkip U)
            (tr2 ++ (Events.external tid evnt' :: nil)) st2' m2'.
      Proof.
        intros; simpl in *.
        
        (* destruct {tid < hb} + {tid = hb} + {hb < tid}  *)
        destruct (Compare_dec.lt_eq_lt_dec tid hb) as [[?|?]|?].

        (** * tid < hb *)
        - (* Virtue is the permissions transfered by the angel:
             VirtueThread: the permissions transfered to the thread
             VirtueLP: the permissions transfered to the lockpool
           *)
  
        Inductive coerce_state_type  {a b T}: forall t, @state_sum a b -> t -> T -> T -> T ->  Prop:=
        | SourceCoerce_T: forall t1 t2 c, coerce_state_type a (@SState _ _ c) c t1 t2 t1
        | TargetCoerce_T: forall t1 t2 c, coerce_state_type b (@TState _ _ c) c t1 t2 t2.
        Definition mach_state n:= ThreadPool (Some n).

          Definition no_overlap_perms' (mu:meminj) (p p': access_map):=
            forall b1 b1' b2 delt delt',
              mu b1 = Some(b2, delt) ->
              mu b1' = Some(b2, delt') ->
              forall ofs ofs',
                Mem.perm_order' (p !! b1 ofs) Nonempty ->
                Mem.perm_order' (p' !! b1' ofs') Nonempty ->
                ofs + delt = ofs' + delt' ->
                b1 = b1'.
          Definition no_overlap_perms (mu:meminj) (p p': access_map):=
            forall b1 b1' b2 delt delt',
              mu b1 = Some(b2, delt) ->
              mu b1' = Some(b2, delt') ->
              forall ofs ofs',
                Mem.perm_order' (p !! b1 ofs) Nonempty ->
                Mem.perm_order' (p' !! b1' ofs') Nonempty ->
                ofs + delt = ofs' + delt' ->
                b1 = b1' /\ ofs = ofs' /\ delt = delt' .
          
          Lemma no_overlap_perms_iff:
            forall mu p1 p2,
              no_overlap_perms' mu p1 p2 <-> no_overlap_perms mu p1 p2.
          Proof.
            intros; unfold no_overlap_perms, no_overlap_perms';
              split; intros HH b1 b1' **; exploit (HH b1 b1');
                eauto; intros HH'; destruct_and; auto.
            - !goal (_/\_/\_).
              subst. rewrite H in H0; inversion H0; subst.
              reduce_and; auto; omega.
          Qed.
          (* Use no_overlap_perms when possible*)
          Definition perm_image_full (f:meminj) (a1 a2: access_map): Prop:=
            forall b1 ofs,
              Mem.perm_order' (a1 !! b1 ofs) (Nonempty) ->
              exists b2 delta,
                f b1 = Some (b2, delta) /\
                a1 !! b1 ofs = a2 !! b2 (ofs + delta).
          Definition perfect_image (f:meminj) (a1 a2: access_map): Prop:=
            forall b1 b2 delt,
              f b1 = Some (b2, delt) ->
              forall ofs, a1 !! b1 ofs = a2 !! b2 (ofs + delt).
          (* TODO: change the names 
             perm_image_full -> perm_inj
             perm_preimage -> perm_surj
             pimage -> pimage  
             p_image -> prem_inj
             ppre_perfect_image -> prem_surj
           *)    
          Record perm_perfect_image mu a1 a2:=
            { (* pimage: perfect_image mu a1 a2; *) (* Too strong*)
              p_image: perm_image_full mu a1 a2;
              ppre_perfect_image: perm_preimage mu a1 a2}.
          Arguments pimage {_ _ _}.
          Arguments p_image {_ _ _}.
          Arguments ppre_perfect_image {_ _ _}.
          Local Ltac exploit_p_image H:=
            let b:=fresh "b" in
            let delt:=fresh "delt" in
            let Hinj:=fresh "Hinj" in
            destruct
              (p_image H _ _ ltac:(eapply perm_order_from_map; eauto))
            as (b&delt&Hinj&?); subst.
          Local Ltac exploit_ppre_image H:=
            let b:=fresh "b" in
            let ofs:=fresh "ofs" in
            let delt:=fresh "delt" in
            let Hinj:=fresh "Hinj" in
            destruct
              (ppre_perfect_image H _ _ ltac:(eapply perm_order_from_map; eauto))
            as (b&ofs&delt&Hinj&?&?); subst.
          Local Ltac exploit_perfect_image H:=
            first [exploit_p_image H | exploit_ppre_image H]. (*
            progress (try (exploit_p_image H); try (exploit_ppre_image H)). *) 
          Local Ltac exploit_no_overlap_perm H:=
            (* TODO: remove coqlib*)
            ( Coqlib.exploit H;
              try (eapply perm_order_from_map; eauto);
              eauto;
              intros ?; destruct_and; subst
            ).
          
          Local Ltac unify_injection:=
            match goal with
              [H: ?mu ?x = _,H0: ?mu ?x = _ |- _] =>
              match type of mu with
              | meminj => rewrite H in H0; invert H0
              end
            end.
          
          Local Ltac unify_mapping:=
            match goal with
              [H: ?a !! ?x ?y = Some _ ,
                  H0: ?a !! ?x ?y = _ |- _] => rewrite H in H0
            | [H: ?a !! ?x ?y = None ,
                  H0: ?a !! ?x ?y = _ |- _] => rewrite H in H0
            | [H: ?a !! ?x ?y = Some _ ,
                  H0: _ = ?a !! ?x ?y |- _] => rewrite H in H0
            | [H: ?a !! ?x ?y = None ,
                  H0: _ = ?a !! ?x ?y |- _] => rewrite H in H0
            end.
          
          Lemma permMapJoin_inject:
            forall mu a1 a2 b1 b2 c1 c2,
              no_overlap_perms mu a1 b1 ->
              no_overlap_perms mu b1 c1 ->
              no_overlap_perms mu c1 a1 ->
              perm_perfect_image mu a1 a2 ->
              perm_perfect_image mu b1 b2 ->
              perm_perfect_image mu c1 c2 ->
              permMapJoin a1 b1 c1 ->
              permMapJoin a2 b2 c2.
          Proof.
            intros * H12 H23 H31 Ha Hb Hc HH ??.
            destruct (a2 !! b ofs) eqn:AA; 
              destruct (b2 !! b ofs) eqn:BB; 
              destruct (c2 !! b ofs) eqn:CC;
              try exploit_perfect_image Ha;
              try exploit_perfect_image Hb;
              try exploit_perfect_image Hc;
              repeat unify_mapping;
              (* use no_pverlap_mem to set which blocks and ofsets are equal*)
              try (exploit_no_overlap_perm H12);
              try (exploit_no_overlap_perm H23);
              try (exploit_no_overlap_perm H31);
              !goal (permjoin_def.permjoin _ _ _);

              (* inistantiate hypothesis wiith permMapJoin *)
              try (match goal with
                   |[H: mu ?b = _, _:Some _ = ?a !! ?b ?ofs |-_] => specialize (HH b ofs)
                   end;
                   (*rewriite the values ini the joiin*)
                   repeat match goal with
                          | [ H: Some _ = _ |- _] => rewrite <- H in HH
                          end; auto);

              (*destruct the parts that are not mapped*)
              repeat match type of HH with
                       context[?a !! ?b ?ofs] =>
                       let H1:= fresh in 
                       destruct (a !! b ofs) eqn:H1
                     end; try eassumption;

                (* map the ones that are not mapped yet (and show a contradictoni)*)
                try exploit_perfect_image Ha;
                try exploit_perfect_image Hb;
                try exploit_perfect_image Hc;
                repeat unify_injection;
                repeat unify_mapping;
                try discriminate.
            - !goal (permjoin_def.permjoin None None None).
              constructor.
          Qed.

          
          Definition perm_perfect_image_pair mu:=
            pair2_prop (perm_perfect_image mu).
          Hint Unfold perm_perfect_image_pair: pair.
      
          Definition no_overlap_perms_pair mu:=
            pair2_prop (no_overlap_perms mu).
          Hint Unfold no_overlap_perms_pair: pair.
          
          Definition pmaps_lt_pair:= pair2_prop permMapLt.
          Hint Unfold pmaps_lt_pair: pair.
          
          Lemma permMapJoin_lt_pair1:
            forall p1 p2 p3 (Hjoin: permMapJoin_pair p1 p2 p3), pmaps_lt_pair p1 p3.
          Proof. solve_pair; eapply permMapJoin_lt. Qed.
          
          
          Lemma permMapJoin_lt_pair2:
            forall p1 p2 p3
              (Hjoin: permMapJoin_pair p1 p2 p3), pmaps_lt_pair p2 p3.
          Proof.
            solve_pair;intros.
            eapply permMapJoin_comm in H;
            eapply permMapJoin_lt; eauto.
          Qed.

          
          Definition permMapLt_pair2:= pair2_prop permMapLt.
          Hint Unfold permMapLt_pair2: pair.
          
          Lemma permMapJoin_pair_inject:
            forall mu a1 a2 b1 b2 c1 c2,
              no_overlap_perms_pair mu a1 b1 -> 
              no_overlap_perms_pair mu b1 c1 ->
              no_overlap_perms_pair mu c1 a1 ->
              perm_perfect_image_pair mu a1 a2 ->
              perm_perfect_image_pair mu b1 b2 ->
              perm_perfect_image_pair mu c1 c2 ->
              permMapJoin_pair a1 b1 c1 ->
              permMapJoin_pair a2 b2 c2.
          Proof.
            intros ?; solve_pair.
            apply permMapJoin_inject.
          Qed.

          Definition permMapLt_pair pp1 p2:=
            permMapLt_pair2 pp1 (pair0 p2).
          Hint Unfold permMapLt_pair: pair.
          
          Lemma permMapLt_trans:
            transitive _ permMapLt.
          Proof. unfold permMapLt; intros ? **.
                 eapply mem_lemmas.po_trans; eauto.
          Qed.
          Lemma permMapLt_pair_trans211:
            forall pa pb c,
              permMapLt_pair2 pa pb ->
              permMapLt_pair pb c ->
              permMapLt_pair pa c.
          Proof.
            unfold permMapLt_pair; intros;
              eapply impr_rel_trans; eauto.
            eapply permMapLt_trans.
          Qed.
          
          Lemma no_overlap_perms_under_mem:
            forall mu a1 a2 m,
              Mem.meminj_no_overlap mu m ->
              permMapLt a1 (getMaxPerm m) ->
              permMapLt a2 (getMaxPerm m) ->
              no_overlap_perms mu a1 a2.
          Proof.
            intros ** ????????????.
            destruct (Clight_lemmas.block_eq_dec b1 b1').
            - subst; unify_injection.
              repeat (split; auto); omega.
            - exfalso.
              exploit H; eauto; unfold Mem.perm;
                try (rewrite_getPerm_goal; eapply perm_order_trans211).
              2: exact H4.
              3: exact H5.
              + eapply H0.
              + eapply H1.
              + intros [?| ?]; tauto.
          Qed.
          Lemma no_overlap_perms_under_mem_pair:
            forall mu a1 a2 m,
              Mem.meminj_no_overlap mu m ->
              permMapLt_pair a1 (getMaxPerm m) ->
              permMapLt_pair a2 (getMaxPerm m) ->
              no_overlap_perms_pair mu a1 a2.
          Proof.
            intros; split;
              eapply no_overlap_perms_under_mem; eauto;
                first [eapply H0 | eapply H1].
          Qed.
          Lemma compat_permMapLt:
            forall Sem st i cnt m,
              @thread_compat Sem st i cnt m <->
              permMapLt_pair (getThreadR cnt) (getMaxPerm m).
          Proof. intros; split; intros [X1 X2]; split; auto. Qed.
          
          Lemma permMapJoin_pair_comm:
            forall AA BB CC,
              permMapJoin_pair AA BB CC ->
              permMapJoin_pair BB AA CC.
          Proof. solve_pair; apply permMapJoin_comm. Qed.
          
          Lemma permMapLt_pair_trans:
            transitive _ permMapLt_pair2.
          Proof. unfold transitive; solve_pair.
                 eapply permMapLt_trans.
          Qed.

          Definition dmap_get (dm:delta_map) b ofs:=
            match dm ! b with
              Some f =>
              match f ofs with
                Some p => Some p
              | None => None 
              end
            |None => None
            end.
          Lemma dmap_get_Some:
            forall dm b ofs p,
              dmap_get dm b ofs = Some p ->
              exists f, dm ! b = Some f /\
                   f ofs = Some p.
          Proof.
            intros * H.
            unfold dmap_get in *.
            destruct (dm ! b) eqn:HH1; try solve[inversion H].
            destruct (o ofs) eqn: HH2; inv H.
            do 2 econstructor; eauto.
          Qed.
          Lemma dmap_get_copmute_Some:
            forall C A b ofs p,
              dmap_get A b ofs = Some p ->
              (computeMap C A) !! b ofs = p.
          Proof.
            intros; unfold dmap_get in H.
            destruct (A ! b) eqn:Ab; try solve[inversion H].
            destruct (o ofs) eqn:oofs; try solve[inversion H].
            erewrite computeMap_1; eauto.
            rewrite oofs; assumption.
          Qed.
          Lemma dmap_get_copmute_None:
            forall C A b ofs,
              dmap_get A b ofs = None ->
              (computeMap C A) !! b ofs = C !! b ofs.
          Proof.
            intros.
            unfold dmap_get in H.
            destruct (A ! b) eqn:Ab.
            destruct (o ofs) eqn:oofs; try solve[inversion H].
            - erewrite computeMap_2; eauto.
            - erewrite computeMap_3; eauto.
          Qed.

          (* Why is subsummed different to submap?*)
          Inductive subsumed: option permission -> option permission -> Prop:=
          | subsumedNone: forall x, subsumed None x
          | subsumedNENE: subsumed (Some Nonempty) (Some Nonempty)
          | subsumedNER: subsumed (Some Nonempty) (Some Readable)
          | subsumedNEW: subsumed (Some Nonempty) (Some Writable)
          | subsumedRR: subsumed (Some Readable) (Some Readable)
          | subsumedRW: subsumed (Some Readable) (Some Writable).

          Lemma subsumed_order:
            forall b c, subsumed b c -> Mem.perm_order'' c b.
          Proof. intros b c H; destruct b, c; inv H; constructor. Qed.

          Lemma subsume_same_join:
            forall x y, subsumed x y <->
                   permjoin_def.permjoin y x y.
          Proof.
            intros x y; split;
              intros HH; inversion HH; subst; constructor.
          Qed.

          
          Inductive option_join :
            option (option permission) ->
            option permission ->
            option permission -> Prop :=
          | NoneJoin: forall l c,
              subsumed l c -> (* why subsumed? *)
              option_join None l c
          | SomeJoin: forall a b c,
              permjoin_def.permjoin a b c ->
              option_join (Some a) b c.
          
          Definition delta_map_join
                     (A: delta_map)
                     (B: access_map)
                     (C: access_map):=
            forall b ofs,
              option_join (dmap_get A b ofs)
                          (B !! b ofs)
                          (C !! b ofs).
          Definition delta_map_join_pair:= pair3_prop delta_map_join.
          Hint Unfold delta_map_join_pair: pair.

          
          Lemma compute_map_join:
            forall A B C,
              delta_map_join A B C <->
              permMapJoin
                (computeMap C A) B C.
          Proof.
            split;
              intros ** b ofs.
            
            { !goal(permjoin_def.permjoin _ _ _).
              specialize (H b ofs); inversion H; subst.
              - unfold dmap_get in H0.
                destruct (A ! b) eqn:Ab.
                + destruct (o ofs) eqn:oofs; try inversion H0.
                  erewrite computeMap_2; eauto.
                  eapply subsume_same_join; auto.
                + erewrite computeMap_3; eauto.
                  eapply subsume_same_join; auto. 
              - unfold dmap_get in H0.
                destruct (A ! b) eqn:HH; try solve[inversion H0].
                erewrite computeMap_1.
                1, 2: eauto.
                destruct (o ofs) eqn:HH'; inversion H0; auto. }
            
            { !goal (option_join _ _ _ ).
              destruct (dmap_get A b ofs) eqn:HH.
              - eapply dmap_get_copmute_Some in HH.
                rewrite <- HH.
                econstructor; eauto.
              - eapply dmap_get_copmute_None in HH.
                econstructor.
                specialize (H b ofs).
                rewrite HH in H.
                eapply subsume_same_join; assumption.
            }
          Qed.
          Lemma compute_map_join_pair:
            forall AA BB CC,
              delta_map_join_pair AA BB CC <->
              permMapJoin_pair
                (computeMap_pair CC AA) BB CC.
          Proof. solve_pair; apply compute_map_join. Qed.


          
          Inductive option_relation {A}  (r: relation A): relation (option A):=
          | SomeOrder:forall a b,
                r a b -> option_relation r (Some a) (Some b)
          | NoneOrder:
              forall p,
              option_relation r p None.
          Definition perm_image_full_dmap f dm1 dm2:=
            forall b1 ofs,
              (option_relation Mem.perm_order''
                               (dmap_get dm1 b1 ofs)
                               (Some (*Some Nonempty*) None )) ->
              exists b2 delta,
                f b1 = Some (b2, delta) /\
                (dmap_get dm1 b1 ofs) = (dmap_get dm2 b2 (ofs + delta)).
          Definition perm_preimage_dmap f dm1 dm2:=
            forall b2 ofs_delt,
              (option_relation Mem.perm_order''
                               (dmap_get dm2 b2 ofs_delt)
                               (Some (*Some Nonempty*) None)) ->
              exists (b1 : block) (ofs delt : Z),
                f b1 = Some (b2, delt) /\
                ofs_delt = ofs + delt /\
                (dmap_get dm2 b2 ofs_delt) = (dmap_get dm1 b1 ofs).
           Definition perfect_image_dmap (f:meminj) (a1 a2: delta_map): Prop:=
            forall b1 b2 delt,
              f b1 = Some (b2, delt) ->
              forall ofs, dmap_get a1 b1 ofs = dmap_get a2 b2 (ofs + delt).
          (* TODO: change the names 
             perm_image_full -> perm_inj
             perm_preimage -> perm_surj
             pimage_dmap -> pimage  
             p_image_dmap -> prem_inj
             ppre_perfect_image__dmap -> prem_surj
           *) 
          Record perm_perfect_image_dmap (mu : meminj) (a1 a2 : delta_map) : Prop
          := { pimage_dmap: perfect_image_dmap mu a1 a2;
               p_image_dmap : perm_image_full_dmap mu a1 a2;
               ppre_perfect_image_dmap : perm_preimage_dmap mu a1 a2 }.
          Arguments pimage_dmap {_ _ _}.
          Arguments p_image_dmap {_ _ _}.
          Arguments ppre_perfect_image_dmap {_ _ _}.
          Lemma perm_order_from_dmap:
         forall dmap b (ofs : Z) p,
           dmap_get  dmap b ofs  = Some (Some p) ->
           option_relation Mem.perm_order''  (dmap_get  dmap b ofs)
                           (Some (Some Nonempty)).
          Proof. intros * H; rewrite H; repeat constructor. Qed.
           Lemma perm_order_from_dmap':
         forall dmap b (ofs : Z) p,
           dmap_get  dmap b ofs  = Some p ->
           option_relation Mem.perm_order''  (dmap_get  dmap b ofs)
                           (Some None).
          Proof. intros * H; rewrite H;  destruct p; repeat constructor. Qed.
            Local Ltac exploit_p_image_dmap H:=
            let b:=fresh "b" in
            let delt:=fresh "delt" in
            let Hinj:=fresh "Hinj" in
            destruct
              (p_image_dmap H _ _ ltac:(eapply perm_order_from_dmap'; eauto))
            as (b&delt&Hinj&?); subst.
          Local Ltac exploit_ppre_image_dmap H:=
            let b:=fresh "b" in
            let ofs:=fresh "ofs" in
            let delt:=fresh "delt" in
            let Hinj:=fresh "Hinj" in
            destruct
              (ppre_perfect_image_dmap H _ _ ltac:(eapply perm_order_from_dmap'; eauto))
            as (b&ofs&delt&Hinj&?&?); subst.
          Local Ltac exploit_perfect_image_dmap H:=
            first [exploit_p_image_dmap H| exploit_ppre_image_dmap H]. (*
            progress (try (exploit_p_image_dmap H); try (exploit_ppre_image_dmap H)).*)

          
          Definition no_overlap_contrapositive f m:=
            forall (b1 b1':block) delta1 b2 b2' delta2 ofs1 ofs2,
              b1' = b2' /\ ofs1 + delta1 = ofs2 + delta2 ->
              f b1 = Some (b1', delta1) ->
              f b2 = Some (b2', delta2) ->
              Mem.perm m b1 ofs1 Max Nonempty ->
              Mem.perm m b2 ofs2 Max Nonempty -> b1 = b2. 
          
          
          Lemma no_overlap_contrapositive_iff:
            forall f m,
              Mem.meminj_no_overlap f m <-> no_overlap_contrapositive f m.
          Proof.
            intros **. split; intros H.
            - intros ? **. destruct H0; subst.
              destruct (Clight_lemmas.block_eq_dec b1 b2); auto.
              exploit H; eauto.
              intros [? | ?]; congruence.
            - intros ? **. 
              destruct (Clight_lemmas.block_eq_dec b1' b2'); auto.
              destruct (Z_noteq_dec (ofs1 + delta1) (ofs2 + delta2)); auto.
              exploit H; eauto.
          Qed.
          Definition deltaMapLt (dmap: delta_map) (pmap : access_map) : Prop :=
            forall b ofs,
              option_relation
                Mem.perm_order''
                (Some (Maps.PMap.get b pmap ofs))
                (dmap_get dmap b ofs).
          Ltac Note str:=
            assert (str: True) by auto;
            move str at top.
          
          Definition almost_perfect_image mu (max a1 a2: access_map):=
            forall b1 b2 delt,
              mu b1 = Some (b2, delt) ->
              forall ofs,
               Mem.perm_order'' (max !! b1 ofs) (Some Nonempty) ->
                       a1 !! b1 ofs = a2 !! b2 (ofs + delt).
          
          Ltac unfold_getMaxPerm:=
            repeat rewrite getMaxPerm_correct in *;
            unfold permission_at in *.
          Ltac unfold_getCurPerm:=
            repeat rewrite getCurPerm_correct in *;
            unfold permission_at in *.
          Lemma injection_perfect_image:
            forall mu m1 m2,
              Mem.inject mu m1 m2 ->
              almost_perfect_image mu (getMaxPerm m1) (getCurPerm m1) (getCurPerm m2).
          Proof.
            intros * Hinj ??? Hmu ? Hmax.
            dup Hmu as Hmu'.
            pose proof (Mem.mi_perm_inv _ _ _ Hinj) as H1.
            assert (H2:
                      forall p,
                        Mem.perm m2 b2 (ofs + delt) Cur p ->
                        Mem.perm m1 b1 ofs Cur p \/ ~ Mem.perm m1 b1 ofs Max Nonempty).
            { intros ?; eapply H1; eauto. } clear H1.
            assert (Hr: forall p,
                       Mem.perm m2 b2 (ofs + delt) Cur p ->
                       Mem.perm m1 b1 ofs Cur p).
            { intros ? HHH. eapply H2 in HHH. destruct HHH; auto.
              contradict H. unfold Mem.perm.
              unfold_getMaxPerm. rewrite mem_lemmas.po_oo; auto. } clear H2.
            assert (Hl: forall p,
                       Mem.perm m1 b1 ofs Cur p ->
                       Mem.perm m2 b2 (ofs + delt) Cur p).
            { intros ?. eapply Mem.mi_perm; eauto; try apply Hinj. }
            match goal with
              |- ?L = ?R =>
              destruct L as [pl|] eqn:LHS;
                destruct R as [pr|] eqn:RHS; auto;
                  try (specialize (Hl pl);
                       unfold Mem.perm in Hl;
                       unfold_getCurPerm;
                       rewrite LHS in *
                       ;specialize (Hl ltac:(simpl; eapply perm_refl))
                      );
                  try (specialize (Hr pr);
                       unfold Mem.perm in Hr;
                       unfold_getCurPerm;
                       rewrite RHS in *;
                       specialize (Hr ltac:(eapply perm_refl))
                      );
                  try rewrite LHS in *;
                  try rewrite RHS in *;
                  try solve[inv Hl];
                  try solve [inv Hr]
            end.
            - simpl in *; clear - Hr Hl.
              destruct pl, pr; auto;
                inversion Hr; inversion Hl.
          Qed.

          Lemma r_dmap_join_lt:
            forall A B C,
              delta_map_join A B C->
              permMapLt B C.
          Proof.
            intros ??? H b ofs. specialize (H b ofs).
            inv H.
            - apply subsumed_order; assumption.
            - apply permjoin_def.permjoin_order in H1 as [? ?]; auto.
          Qed.
          Definition dmap_vis_filtered (dmap:delta_map) (m:mem) :=
            forall b ofs p,
              dmap_get dmap b ofs = Some p ->
              Mem.perm m b ofs Max Nonempty. 
          Lemma delta_map_join_inject:
            forall m f A1 A2 B1 B2 C1 C2,
              Mem.meminj_no_overlap f m ->
              dmap_vis_filtered A1 m ->
              (*deltaMapLt A1 (getMaxPerm m) ->
              permMapLt B1  (getMaxPerm m) -> *)
              permMapLt C1  (getMaxPerm m) ->
              perm_perfect_image_dmap f A1 A2 ->
              perm_perfect_image f B1 B2 ->
              almost_perfect_image f (getMaxPerm m) C1 C2 ->
              (* perm_perfect_image f C1 C2 -> *)
              delta_map_join A1 B1 C1 ->
              delta_map_join A2 B2 C2.
          Proof.
            intros * Hno_overlap Hfilter HltC  HppiA HppiB HppiC Hjoin b2 ofs_delta.
            assert (HltB : permMapLt B1 (getMaxPerm m)).
            { intros b ofs. eapply perm_order''_trans.
              - eapply HltC.
              - revert b ofs.
                apply r_dmap_join_lt with A1; assumption. }
            
            
            
            (* Ltacs for this goal *)
            

            Local Ltac rewrite_double:=
              match goal with
              | [ H: ?L = ?R, H0: ?L = Some _  |- _ ] =>
                rewrite H0 in H; try rewrite <- H in *; symmetry in H
              | [ H: ?R = ?L, H0: ?L = Some _  |- _ ] =>
                rewrite H0 in H; try rewrite H in *
              | [ H: ?L = ?R, H0: ?L = None  |- _ ] =>
                rewrite H0 in H; try rewrite <- H in *; symmetry in H
              | [ H: ?R = ?L, H0: ?L = None  |- _ ] =>
                rewrite H0 in H; try rewrite H in *
              end.
            
            Ltac auto_exploit_pimage :=
              match goal with
              | [ H: perm_perfect_image_dmap _ _ _ |- _ ] =>
                exploit_perfect_image_dmap H; clear H
              | [ H: perm_perfect_image _ _ _ |- _ ] => 
                exploit_perfect_image H; clear H
              end ; repeat rewrite_double. 
            
            
            (* Case analysis on first term*)
            match goal with
            | [ |- option_join _ ?B _ ] => destruct B as [o|] eqn:HB2 
            end.
            - (*B2 -> Some *)
              Note B2_Some.
              auto_exploit_pimage.
              dup Hinj as Hinj'. 
              eapply pimage_dmap in Hinj'; [rewrite <- Hinj'; clear Hinj'|]; eauto.

              assert (Mem.perm_order'' ((getMaxPerm m) !! b ofs) (Some Nonempty)).
                { eapply perm_order_trans211.
                  - eapply HltC.
                  - eapply perm_order_trans211.
                    + eapply r_dmap_join_lt; eauto.
                    + rewrite H0; constructor. }
                match goal with
                | [ |- option_join _ _ ?C ] => destruct C eqn:HC2 
                end.
              * (*C2 Some *)
                eapply HppiC in H; eauto.
                rewrite_double.
                specialize (Hjoin b ofs).
                rewrite H0, H in Hjoin; auto.
              * eapply HppiC in H; eauto.
                rewrite_double.
                specialize (Hjoin b ofs).
                rewrite H0, H in Hjoin; auto.
            - match goal with
              | [ |- option_join ?A _ _ ] => destruct A as [o|] eqn:HA2 
              end.
              + auto_exploit_pimage.
                specialize (Hjoin b ofs).
                assert (HB1:B1 !! b ofs = None).
                { match goal with
                    |- ?L = ?R => destruct L eqn:HB1 end; auto.
                  auto_exploit_pimage.
                  inv Hinj.
                  rewrite_double; auto. }
                rewrite H0, HB1 in Hjoin.
                inv Hjoin. assert ((C1 !! b ofs) = o) by (inv H1; auto).
                constructor.
                (* Case 
                   A2 = A1 = Some o
                   B2 = B1 = None 
                   C1 = o
                   
                 *)
                (* Maybe this is the problem. 
                   If C2 !! b2 (ofs+delt) is newly allocated, 
                   there is nothing transfered, and the injection
                   doesn't map anything in B.


                 *)
                exploit HppiC; eauto.  
                * rewrite <- mem_lemmas.po_oo. 
                  eapply Hfilter in H0.
                  unfold Mem.perm in H0.
                  rewrite_getPerm; eauto.
                * intros <-; auto.
              + do 2 constructor.
                
          Qed.       
          

          Definition perm_perfect_image_dmap_pair f:=
            pair2_prop (perm_perfect_image_dmap f).
          Hint Unfold perm_perfect_image_dmap_pair: pair.

          Definition deltaMapLt_pair1:= pair21_prop deltaMapLt.
          Hint Unfold deltaMapLt_pair1: pair.
          Definition dmap_vis_filtered_pair:= pair21_prop dmap_vis_filtered.
          Hint Unfold dmap_vis_filtered_pair: pair.
          Definition almost_perfect_image_pair f max_perm:=
            pair2_prop (almost_perfect_image f max_perm).
          Hint Unfold almost_perfect_image_pair: pair.
          Lemma delta_map_join_inject_pair (m:mem) f:
            forall A1 A2 B1 B2 C1 C2,
              Mem.meminj_no_overlap f m ->
              dmap_vis_filtered_pair A1 m ->
              (*deltaMapLt_pair1 A1 (getMaxPerm m) ->
              permMapLt_pair1 B1 (getMaxPerm m) -> *)
              permMapLt_pair C1 (getMaxPerm m) ->
               perm_perfect_image_dmap_pair f A1 A2 ->
               perm_perfect_image_pair f B1 B2 ->
               almost_perfect_image_pair f (getMaxPerm m) C1 C2 -> 
              delta_map_join_pair A1 B1 C1 ->
              delta_map_join_pair A2 B2 C2.
          Proof. solve_pair; eapply delta_map_join_inject. Qed.
          
          Inductive injects (mu:meminj) (b:block): Prop:=
          | InjectsBlock: forall b2 delta,
              mu b = Some (b2, delta) -> injects mu b.
          Definition injects_map mu (m:access_map): Prop := forall b ofs p,
              m !! b ofs = Some p ->
              injects mu b.
          Definition injects_map_pair mu:= pair1_prop (injects_map mu).
          Hint Unfold injects_map_pair: pair.
          Definition injects_dmap mu (m:delta_map) := forall b ofs p,
              dmap_get m b ofs = Some p ->
              injects mu b.
          Definition injects_dmap_pair mu:= pair1_prop (injects_dmap mu).
          Hint Unfold injects_dmap_pair: pair.
          
          Lemma inject_virtue_perm_perfect_image_dmap:
            forall mu angel m2,
              injects_dmap_pair mu (virtueThread angel) ->
              perm_perfect_image_dmap_pair mu (virtueThread angel)
                                           (virtueThread (inject_virtue m2 mu angel)).
          Proof.
            intros mu ? ? [? ?].
            econstructor; simpl in *.
            - econstructor; simpl.
              + intros ? **.
                
                
          Admitted.

          Definition dmap_valid (m:mem) (dm:delta_map) :=
            forall b ofs p,
              dmap_get dm b ofs = Some p ->
              Mem.valid_block m b.
          
          Definition map_valid (m:mem) (am:access_map) :=
            forall b ofs p,
              am !! b ofs = Some p ->
              Mem.valid_block m b.
          
          Lemma full_inject_dmap:
            forall f m dm,
              Events.injection_full f m ->
              dmap_valid m dm ->
              injects_dmap f dm.
          Proof.
            intros ** ? **.
            eapply H0 in H1.
            eapply H in H1.
            destruct (f b) as [[? ?]|] eqn:HHH; try contradiction.
            econstructor; eauto.
          Qed.
          Definition dmap_valid_pair m:=
            pair1_prop (dmap_valid m).
          Hint Unfold dmap_valid_pair: pair.
          Lemma full_inject_dmap_pair:
            forall f m dm,
              Events.injection_full f m ->
              dmap_valid_pair m dm ->
              injects_dmap_pair f dm.
          Proof. intros ??; solve_pair; eapply full_inject_dmap. Qed.
          
          Lemma join_dmap_valid:
            forall m (a:delta_map),
              bounded_maps.sub_map ( a) (snd (getMaxPerm m)) ->
              dmap_valid m a.
          Proof.
            intros ** ? **.
            
            unfold bounded_maps.sub_map in H.
            eapply strong_tree_leq_spec in H; try constructor.
            instantiate (1:=b) in H.
            eapply dmap_get_Some in H0;
              destruct H0 as [f [H0 ?]].
            rewrite H0 in H.
            destruct ((snd (getMaxPerm m)) ! b) eqn:HH1; try solve[ inversion H].
            specialize (H ofs ltac:(rewrite H1; auto)).
            destruct (o ofs) eqn:HH2; try solve[inversion H].
            assert ((getMaxPerm m) !! b ofs = Some p0).
            { unfold PMap.get; rewrite HH1; assumption. }
            rewrite getMaxPerm_correct in H2.
            unfold permission_at in H2.

            destruct (mem_lemmas.valid_block_dec m b); auto.
            eapply m in n.
            rewrite H2 in n; congruence.
          Qed.
          Lemma join_dmap_valid_pair:
            forall m (aa:Pair delta_map),
              pair1_prop
                (fun a => bounded_maps.sub_map a (snd (getMaxPerm m))) aa ->
              dmap_valid_pair m aa.
          Proof.
            intros ?; solve_pair. apply join_dmap_valid.
          Qed.
          
          
          Lemma inject_virtue_perm_perfect_image:
            forall mu angel m2,
              injects_map_pair mu (virtueLP angel) ->
              perm_perfect_image_pair mu (virtueLP angel)
                                      (virtueLP (inject_virtue m2 mu angel)).
          Proof.
            intros.
            
          Admitted.
          Definition map_valid_pair m:= pair1_prop (map_valid m).
          Hint Unfold map_valid_pair: pair.
          Lemma full_inject_map:
            forall f m dm,
              Events.injection_full f m ->
              map_valid m dm ->
              injects_map f dm.
          Proof.
            intros ** ? **.
            eapply H0 in H1.
            eapply H in H1.
            destruct (f b) as [[? ?]| ?] eqn:HHH; try contradiction.
            econstructor; eauto.
          Qed.
          Lemma full_inject_map_pair:
            forall f m dm,
              Events.injection_full f m ->
              map_valid_pair m dm ->
              injects_map_pair f dm.
          Proof.
            intros ??; solve_pair. eapply full_inject_map.
          Qed.
          Lemma sub_map_valid:
            forall m (a:access_map),
              (fun a => bounded_maps.sub_map (snd a) (snd (getMaxPerm m))) a ->
              map_valid m a.
          Proof.
            intros ** ? **.
            unfold bounded_maps.sub_map in H.
            eapply strong_tree_leq_spec in H; try constructor.
            instantiate (1:=b) in H.
          (*
                        eapply map_get_Some in H0;
                          destruct H0 as [f [H0 ?]].
                        rewrite H0 in H.
                        destruct ((snd (getMaxPerm m)) ! b) eqn:HH1; try solve[ inversion H].
                        specialize (H ofs ltac:(rewrite H1; auto)).
                        destruct (o ofs) eqn:HH2; try solve[inversion H].
                        assert ((getMaxPerm m) !! b ofs = Some p0).
                        { unfold PMap.get; rewrite HH1; assumption. }
                        rewrite getMaxPerm_correct in H2.
                        unfold permission_at in H2.

                        destruct (mem_lemmas.valid_block_dec m b); auto.
                        eapply m in n.
                        rewrite H2 in n; congruence.*)
          Admitted.
          Lemma sub_map_valid_pair:
            forall m (aa:Pair access_map),
              pair1_prop
                (fun a => bounded_maps.sub_map (snd a) (snd (getMaxPerm m))) aa ->
              map_valid_pair m aa.
          Proof.
            intros m; solve_pair. eapply sub_map_valid.
          Qed.

          (*We need to filter the dmap, to remove redundant changes.
            We only need to do that where Max is None.
           *)
          (* ACCTUALLY this might not be needed.
          Definition dmap_filter (dmap:delta_map) (m:mem): delta_map.
          (* Filter removes all empy modifications (i.e. Some None)
                        where the Max permission is None 
                        That's because we know that in such locations, 
                        nothing is cahnging.
           *)
          Admitted.
          Lemma dmap_filter_filtered:
            forall m dmap,
              dmap_vis_filtered (dmap_filter dmap m) m.
          Admitted.
          Definition dmap_filter_pair:= pair21 dmap_filter.
          Hint Unfold dmap_filter_pair: pair.
          Lemma dmap_filter_filtered_pair:
            forall m dmap,
              dmap_vis_filtered_pair (dmap_filter_pair dmap m) m.
          Proof. intros ?.
                 solve_pair.
                 apply dmap_filter_filtered.
          Qed.
           *)
          
          Lemma release_step_diagram_self Sem:
            let CoreSem:= sem_coresem Sem in
            forall (SelfSim: (self_simulation (@semC Sem) CoreSem))
              (st1 : mach_state hb) (st2 : mach_state (S hb))
              (Hinv1: invariant st1) (Hinv2: invariant st2)
              (m1 m1' m2 : mem) (mu : meminj) tid i b b' ofs delt
              (Hinj_b : mu b = Some (b', delt))
              (Hcmpt2: mem_compatible st2 m2) (*this can't be remove because ext_step requires it*)
              (cnt1 : ThreadPool.containsThread st1 tid) (cnt2 : ThreadPool.containsThread st2 tid)
              (thread_compat1: thread_compat cnt1 m1) (thread_compat2: thread_compat cnt2 m2)
              (CMatch: concur_match i mu st1 m1 st2 m2)
              (* Thread states *)
              (th_state1: @semC Sem) th_state2 sum_state1 sum_state2
              (HState1: coerce_state_type _ sum_state1 th_state1  
                                          (CSem, Clight.state) (AsmSem,Asm.state) (Sem,@semC Sem))
              (HState2: coerce_state_type _ sum_state2 th_state2
                                          (CSem, Clight.state) (AsmSem,Asm.state) (Sem,@semC Sem))
              (Hget_th_state1: getThreadC cnt1 = Kblocked sum_state1)
              (Hget_th_state2 : getThreadC cnt2 = Kblocked sum_state2)
              (* angel,lock permissions and new thread permissions *)
              (angel: virtue) empty_perms
              (Hempty_map: empty_doublemap empty_perms)
              (HisLock: lockRes st1 (b, Integers.Ptrofs.unsigned ofs) = Some empty_perms)
              (Hangel_bound: sub_map_virtue angel (getMaxPerm m1))
              (Hwritable_lock1 : writeable_lock b (unsigned ofs) (snd (getThreadR cnt1)) m1),
              let m_writable_lock_1:= restrPermMap Hwritable_lock1 in
              let th_mem1:= fst (thread_mems thread_compat1) in
              let locks_mem1:= snd (thread_mems thread_compat1) in
              let th_mem2:= fst (thread_mems thread_compat2) in
              let locks_mem2:= snd (thread_mems thread_compat2) in
              let newThreadPerm1:= (computeMap_pair (getThreadR cnt1) (virtueThread angel)) in
              forall (Hjoin_angel: permMapJoin_pair newThreadPerm1 (virtueLP angel) (getThreadR cnt1))
                (Hinj_lock: Mem.inject mu locks_mem1 locks_mem2)
                (Hat_external: semantics.at_external CoreSem th_state1 th_mem1 =
                               Some (UNLOCK, (Vptr b ofs :: nil)%list))
                (Hload: Mem.load AST.Mint32 locks_mem1 b (unsigned ofs) = Some (Vint Integers.Int.zero))
                (Haccess: Mem.range_perm locks_mem1 b (unsigned ofs) (Z.add (unsigned ofs) LKSIZE) Cur Readable)
                (Hstore: Mem.store AST.Mint32 (m_writable_lock_1) b (unsigned ofs) (Vint Int.one) = 
                         Some m1')
                (Amatch : match_self (code_inject _ _ SelfSim) mu th_state1 th_mem1 th_state2 th_mem2),
                let event1 := build_release_event (b, unsigned ofs) (fst (virtueThread angel)) m1' in
                exists event2 (m2' : mem),
                  match_self (code_inject _ _ SelfSim) mu th_state1 th_mem1 th_state2 th_mem2 /\
                  (inject_mevent mu) (Events.external tid event1) (Events.external tid event2) /\
                  let angel2:= inject_virtue m2 mu angel in
                  let newThreadPerm2:= (computeMap_pair (getThreadR cnt2) (virtueThread angel2)) in
                  let st2':= updThread(tp:=st2) cnt2 (Kresume sum_state2 Vundef) newThreadPerm2 in
                  let st2'':=updLockSet st2' (b', unsigned (add ofs (repr delt))) (virtueLP angel2) in
                  syncStep(Sem:=HybridSem (Some (S hb))) true cnt2 Hcmpt2 st2'' m2' event2.
          Proof.
            intros; simpl in *.
            inversion Amatch; clear Amatch.

            (* Add the filters. *)

                     
            remember (inject_virtue m2 mu angel) as angel2.
            
            remember (virtueThread angel2) as angelThread2.
            remember (virtueLP angel2) as angelLP2.
            
            assert (Hstore':
                      exists (Hlt_setBlock2: writeable_lock b' (unsigned ofs + delt)%Z (lock_perms cnt2) m2),
                        exists n2, Mem.store AST.Mint32 (restrPermMap Hlt_setBlock2) b' 
                                        (unsigned ofs + delt) (Vint Int.one) = Some n2 /\ 
                              Mem.inject mu m1' n2).
            {
              
              (** *Constructing the target objects: events, thread_pool, mem, meminj and index*)

              (** *virtueThread*)
              (*First construct the virtueThread:
                the permissions passed from the thread to the lock. *)

              (* Construct the memory with permissions to write in the lock*)
              assert (Hwritable_lock2:
                        writeable_lock b' (unsigned ofs + delt)%Z (lock_perms cnt2) m2).
              { 
                eapply setPermBlock_inject_permMapLt; simpl in *; eauto.
                (* Mem.inject access_map_inejct mu b permMapLt *)
                erewrite <- (getMax_restr _ _ (lock_comp thread_compat1)).
                erewrite <- (getMax_restr _ _ (lock_comp thread_compat2)).
                subst locks_mem1 locks_mem2.
                subst th_mem1.
                eapply access_map_injected_getMaxPerm; eassumption.
                eapply thread_compat2.
              }
              
              exists Hwritable_lock2.
              
              (* Construct new memory and new injection *)
              eapply Mem.store_mapped_inject in Hstore; eauto.

              unfold m_writable_lock_1.
              remember (useful_permMapLt_trans (lock_comp thread_compat1) Hwritable_lock1)
                as Hlt_restr_setBlock1 eqn:HH; clear HH.
              remember (useful_permMapLt_trans (lock_comp thread_compat2) Hwritable_lock2)
                as Hlt_restr_setBlock2 eqn:HH; clear HH.
              
              rewrite (restrPermMap_idempotent _ Hwritable_lock1 Hlt_restr_setBlock1).
              rewrite (restrPermMap_idempotent _ Hwritable_lock2 Hlt_restr_setBlock2).
              
              (* m1 *)
              assert (Hlt_setBlock1': writeable_lock b (unsigned ofs) (getCurPerm locks_mem1) locks_mem1).
              { intros; subst th_mem1 locks_mem1.
                unfold writeable_lock.
                rewrite getMax_restr, getCur_restr; eauto. }
              
              assert (HH1:mem_equiv (restrPermMap Hlt_restr_setBlock1) (restrPermMap Hlt_setBlock1')).
              { eapply restrPermMap_equiv.
                - eapply restr_proof_irr_equiv.
                - eapply setPermBlock_access_map_equiv; try reflexivity.
                  + subst; symmetry.
                    apply getCur_restr.
                  + econstructor; auto.
              }
              rewrite HH1.
              
              
              (* m2 *)
              assert(Hlt_setBlock2':
                       writeable_lock b' (unsigned ofs + delt) (getCurPerm locks_mem2) locks_mem2).
              { intros; subst.
                subst locks_mem2.
                unfold writeable_lock.
                rewrite getMax_restr, getCur_restr; eauto. }
              
              assert (HH2:mem_equiv (restrPermMap Hlt_restr_setBlock2) (restrPermMap Hlt_setBlock2')).
              { eapply restrPermMap_equiv.
                - eapply restr_proof_irr_equiv.
                - eapply setPermBlock_access_map_equiv; try reflexivity.
                  + subst; symmetry.
                    apply getCur_restr.
                  + econstructor; auto. }
              rewrite HH2.

              subst th_mem1 locks_mem1 th_mem2 locks_mem2.
              eapply setPermBlock_mem_inject; eauto.
              - unfold LKSIZE_nat. rewrite Z2Nat.id.
                2: { pose proof LKSIZE_pos; omega. }
                rewrite (restr_content_equiv (lock_comp thread_compat1)).
                rewrite (restr_content_equiv (lock_comp thread_compat2)).
                eapply CMatch; auto.
                simpl in *; eassumption.
            }
            destruct Hstore' as (Hlt_setBlock2 & m2' & Hstore2 & Hinj2).
            
            
            remember (build_release_event (b', unsigned ofs + delt ) (fst (virtueThread angel2)) m2')
              as event2. 
            
            (* Instantiate some of the existensials *)
            exists event2; exists m2'.  
            split; [|split]. (* 4 goal*)
            
            + (* Goal:  match_self code_inject *)
              constructor; eassumption.
              
            + (*Goal: Inject the trace*)
              subst event1 event2.
              do 2 econstructor. 
              * constructor; eauto.
              * unfold inject_delta_content.
                (* todo, redefine inject_delta_content *)
                constructor.
                
            + !goal (syncStep _ _ _ _ _ _).
              (* Goal: show the source-external-step*)
              (* get the memory and injection *)
              
              assert(Heq: unsigned (add ofs (repr delt)) = (unsigned ofs + delt)%Z ).
              { unfold add.
                eapply Mem.address_inject; eauto.
                eapply Mem.perm_store_1; eauto.
                eapply Mem.store_valid_access_3 in Hstore.
                destruct Hstore as [Hperm ?].
                specialize (Hperm (unsigned ofs)).
                move Hperm at bottom.
                eapply Hperm.
                replace unsigned with unsigned by reflexivity.
                pose proof (size_chunk_pos AST.Mint32).
                omega.
              }
              
              subst event2 ; unfold build_release_event.
              rewrite <-  Heq.

                                                          (*Prove that the new ThreadVirtue Joins in the right way:
                old_thread "+" delta_map = new_thread.
               *)
              set (newThreadPerm2 := computeMap_pair (getThreadR cnt2) (virtueThread angel2)).

                                                                                                                   assert (permMapJoin_pair newThreadPerm2 (virtueLP angel2) (getThreadR cnt2)).
              {  subst newThreadPerm2; simpl.
                 apply compute_map_join_pair.
                 eapply delta_map_join_inject_pair.
                 - !goal (Mem.meminj_no_overlap _ _).
                   instantiate (1:= m1).
                   instantiate (1:= mu).
                   assert (Max_equiv m1 m1').
                   { etransitivity.
                     - symmetry.
                       eapply restr_Max_equiv. 
                     - eapply Mem.store_access in Hstore.
                       symmetry in Hstore.
                       (* Move to compiler/mem_equiv.v *)
                       Lemma mem_access_max_equiv:
                         forall m1 m2, Mem.mem_access m1 =
                                  Mem.mem_access m2 ->
                                  Max_equiv m1 m2.
                       Proof. intros ** ?.
                              unfold getMaxPerm; simpl.
                              rewrite H; reflexivity.
                       Qed.
                       Lemma mem_access_cur_equiv:
                         forall m1 m2, Mem.mem_access m1 =
                                  Mem.mem_access m2 ->
                                  Cur_equiv m1 m2.
                       Proof. intros ** ?.
                              unfold getCurPerm; simpl.
                              rewrite H; reflexivity.
                       Qed.
                       subst m_writable_lock_1.
                       apply mem_access_max_equiv; eauto.
                   }
                   rewrite H; apply Hinj2.
                   
                 - clear -Hangel_bound.
                   move Hangel_bound at bottom.
                   instantiate(1:=(virtueThread angel)).
                   pose proof (virtueThread_sub_map _ _ Hangel_bound).
                   Lemma sub_map_filtered:
                     forall m a,
                       bounded_maps.sub_map a (snd (getMaxPerm m)) ->
                       dmap_vis_filtered a m.
                   Proof.
                     unfold dmap_vis_filtered, Mem.perm.
                     Lemma sub_map_lt:
                       forall {A B} dmap amap,
                         @bounded_maps.sub_map A B dmap (amap) ->
                         forall b,
                           bounded_maps.fun_leq (dmap ! b) (amap ! b).
                     Proof.
                       intros. eapply strong_tree_leq_spec; try constructor.
                       eapply H.
                     Qed.
                     intros. 
                     intros; eapply sub_map_lt in H.
                     instantiate(1:=b) in H.
                     rewrite_getPerm.
                     unfold PMap.get.
                     unfold dmap_get in H0.
                     destruct (a ! b) ; try solve[inv H0].
                     destruct ((snd (getMaxPerm m)) ! b) eqn:HMax;
                       try solve[inv H].
                     simpl in H.
                     exploit H.
                     - destruct (o ofs) eqn:HH; try congruence.
                       rewrite HH; auto.
                     - intros HH; destruct (o0 ofs); inv HH.
                       constructor.
                   Qed.
                   Lemma sub_map_filtered_pair:
                     forall m a,
                       pair21_prop bounded_maps.sub_map a (snd (getMaxPerm m)) ->
                       dmap_vis_filtered_pair a m.
                   Proof. intros m; solve_pair.
                          eapply sub_map_filtered. Qed.
                   eapply sub_map_filtered_pair.
                   eauto.
                   
                 - !goal (permMapLt_pair1 _ _).
                   instantiate(1:=(getThreadR cnt1)).
                   apply compat_permMapLt; assumption.
                 - !goal (perm_perfect_image_dmap_pair _ _ _).
                   (* instantiate (2:=mu).
                   instantiate (1:=virtueThread angel).*)
                   subst angel2.
                   
                   eapply inject_virtue_perm_perfect_image_dmap.
                   eapply full_inject_dmap_pair.
                   
                   + !goal (Events.injection_full mu _ ).
                     eapply CMatch.
                   + !goal (dmap_valid_pair _ _).
                     apply join_dmap_valid_pair.
                     eapply Hangel_bound.
                 - !goal (perm_perfect_image_pair _ _ _).
                   subst angel2.
                   eapply inject_virtue_perm_perfect_image.
                   eapply full_inject_map_pair.
                   + !goal (Events.injection_full mu _ ).
                     eapply CMatch.
                   + eapply sub_map_valid_pair.
                     eapply Hangel_bound.
                 - !goal (almost_perfect_image_pair _ _ _ _).
                   Lemma inject_almost_perfect:
                     forall f m1 m2,
                       Mem.inject f m1 m2 ->
                       almost_perfect_image f
                                            (getMaxPerm m1) (getCurPerm m1) (getCurPerm m2).
                   Admitted.
                   pose proof (memcompat1 CMatch) as H.
                   eapply compat_th in H as [Hlt11 Hlt12].
                   pose proof (memcompat2 CMatch) as H.
                   eapply compat_th in H as [Hlt21 Hlt22].
                   split; simpl.
                   + 
                   
unshelve exploit INJ_threads (*INJ_locks*); eauto.
                   intros HH; apply inject_almost_perfect in HH.
                   
                   Lemma almost_perfect_image_proper:
                     Proper (Logic.eq ==> access_map_equiv
                                      ==> access_map_equiv
                                      ==> access_map_equiv
                                      ==> iff) almost_perfect_image.
                   Proof.
                     setoid_help.proper_iff;
                       setoid_help.proper_intros; subst.
                     intros ? **.
                     rewrite <- H0, <- H1, <- H2  in *; auto.
                   Qed.
                   eapply almost_perfect_image_proper; eauto.
                   * symmetry; eapply restr_Max_equiv.
                   * symmetry; eapply getCur_restr.
                   * symmetry; eapply getCur_restr.
                       
                   + unshelve exploit INJ_locks; eauto.
                     intros HH; apply inject_almost_perfect in HH.
                     eapply almost_perfect_image_proper; eauto.
                     * symmetry; eapply restr_Max_equiv.
                     * symmetry; eapply getCur_restr.
                     * symmetry; eapply getCur_restr.
                 -  eapply compute_map_join_pair.
                    subst newThreadPerm1.
                    eapply Hjoin_angel.
              }
              
              eapply step_release with
                  (b0:= b')(m':=m2')
                  (virtueThread:=(virtueThread angel2))
                  (virtueLP:=angelLP2)
                  (rmap:=virtueLP_inject m2 mu empty_perms)
              ; eauto; try reflexivity. 
              
              (* 10 goals produced. *)
              
              * destruct Hangel_bound as ((A&B)&?).
                subst angelThread2 angel2.
                destruct angel as (virtueT&?); destruct virtueT as (virtueT_A & virtueT_B). 
                remember (snd (getMaxPerm m2)) as TEMP.
                simpl; subst TEMP.
                split; eapply inject_virtue_sub_map; eauto.
                
              * unfold HybridMachineSig.isCoarse,
                HybridMachineSig.HybridCoarseMachine.scheduler.
                destruct Hangel_bound as (?&(?&?&?&?)).
                subst.
                eapply (proj1 (Logic.and_assoc _ _ _)).
                
                split.
                -- unfold virtueLP_inject,
                   bounded_maps.map_empty_def, access_map_injected; auto.
                -- split; eapply inject_virtue_sub_map; eauto.
                   
              * !goal (semantics.at_external _ _ _ = Some (UNLOCK, _)).
                { clean_cnt.
                  eapply ssim_preserves_atx in Hat_external.
                  2: { constructor; eauto. }
                  destruct Hat_external as (args' & Hat_external2 & val_inj).
                  replace ( Vptr b' (add ofs (repr delt)) :: nil) with args'.
                  
                  simpl; unfold at_external_sum, sum_func.
                  subst CoreSem. 
                  subst th_mem2.
                  rewrite <- (restr_proof_irr (th_comp thread_compat2)).
                  rewrite <- Hat_external2; simpl.
                  clear - HState2.
                  
                  inversion HState2; subst.
                  - simpl; repeat f_equal.
                    eapply (Extensionality.EqdepTh.inj_pair2 Type (fun x => x)); auto.
                  - simpl; repeat f_equal.
                    eapply (Extensionality.EqdepTh.inj_pair2 Type (fun x => x)); auto.
                  - clear - val_inj Hinj_b.
                    inversion val_inj; subst.
                    inversion H3; f_equal.
                    inversion H1; subst.
                    rewrite Hinj_b in H4; inversion H4; subst.
                    reflexivity. }
                
              * (* Prove I can read the lock. *)
                clean_cmpt.
                
                assert (Hperm_range:=Hinj_lock).
                eapply Mem.range_perm_inject in Hperm_range; eauto.
                simpl.
                clean_cnt.
                erewrite Mem.address_inject; try eapply Hinj_lock; eauto.
                2: {
                  specialize(Haccess (unsigned ofs)).
                  eapply Haccess.
                  unfold unsigned; split; try omega.
                  eapply Z.lt_add_pos_r.
                  unfold LKSIZE.
                  rewrite size_chunk_Mptr.
                  destruct Archi.ptr64; omega.
                }
                replace (unsigned ofs + delt + LKSIZE)%Z with (unsigned ofs + LKSIZE + delt)%Z
                  by omega.
                eassumption.

              * (* Prove the load succeeds. *)
                !goal (Mem.load _ _ b' _ = _).
                move Hload at bottom.
                clean_cmpt.
                eapply Mem.load_inject in Hload; eauto.
                
                destruct Hload as (v2& Hload & Hval_inj); simpl.
                erewrite Mem.address_inject;
                  try eapply Hinj_lock; eauto.
                (* instantiate(1:=Hcmpt2). *)
                inversion Hval_inj; subst; eauto.
                
                (* solve the arithmetic subgoal*)
                {
                  specialize(Haccess (unsigned ofs)).
                  eapply Haccess.
                  unfold unsigned; split; try omega.
                  eapply Z.lt_add_pos_r.
                  unfold LKSIZE.
                  rewrite size_chunk_Mptr.
                  destruct Archi.ptr64; omega.
                }

              * !goal (Mem.store _ _ b' _ _ = _).
                move Hstore2 at bottom.
                match goal with
                | [  |- context[restrPermMap ?X] ] =>
                  replace (restrPermMap X) with (restrPermMap Hlt_setBlock2)
                end.
                -- replace intval with unsigned by reflexivity.
                   rewrite Heq; assumption.
                -- clear - Hlt_setBlock2 Heq.
                   apply restrPermMap_rewrite_strong.
                   
              * !goal (lockRes _ (b',_) = Some _).
                eapply INJ_lock_permissions; eauto.
              * (* new lock is empty *)
                eapply empty_map_useful.
                eapply inject_empty_maps; assumption.
                
              * (* Claims the transfered resources join in the appropriate way *)
                simpl.
                subst newThreadPerm2 angelLP2; eapply H.
                
                
              * (* Claims the transfered resources join in the appropriate way *)
                subst newThreadPerm2 angelLP2; eapply H.

              * subst; simpl; repeat f_equal.

                Unshelve. {
                  clear - Hlt_setBlock2 Heq.
                  f_equal; auto.
                }
          Qed.    (* release_step_diagram_self *)
          
          pose proof (mtch_target _ _ _ _ _ _ CMatch _ l cnt1 (contains12 CMatch cnt1)) as match_thread.
          simpl in Hcode; exploit_match ltac:(apply CMatch).
          inversion H3. (* Asm_match *)
          
          (*Destruct the values of the self simulation *)
          pose proof (self_simulation.minject _ _ _ matchmem) as Hinj.
          assert (Hinj':=Hinj).
          pose proof (self_simulation.ssim_external _ _ Aself_simulation) as sim_atx.
          eapply sim_atx in Hinj'; eauto.
          2: { (*at_external*)
               clean_cmpt.
               erewrite restr_proof_irr; simpl; eauto.
          }
          clear sim_atx.
          destruct Hinj' as (b' & delt & Hinj_b & Hat_external2); eauto.
          
          (edestruct (release_step_diagram_self AsmSem) as
              (e' & m2' & Hthread_match & Htrace_inj & external_step);
           first[ eassumption|
                  econstructor; eassumption|
                  solve[econstructor; eauto] |
                  eauto]).

          + (* invariant st2 *) 
            eapply CMatch.
            (*
          + (* sub_map *)
            clean_cmpt.
            instantiate (1:=Build_virtue virtueThread virtueLP).
            econstructor; auto.
             
          + (*permMapJoin_pair*)
            econstructor; simpl; eauto.
             *)
            
          + (*Mem.inject *)
            eapply CMatch.
          + (*at external *)
            clean_cmpt. unfold thread_mems.
            erewrite restr_proof_irr; simpl; eassumption. 
          + (*match_self*)
            econstructor.
            * eapply H3.
            * simpl; clean_cmpt.
              erewrite <- (restr_proof_irr Hlt1).
              erewrite <- (restr_proof_irr Hlt2).
              assumption.
         + exists e'. eexists. exists m2', cd, mu.
           split ; [|split].
           * (* reestablish concur *)
             rename b into BB.
             Lemma concur_match_update:
               forall cd mu st1 m1 st2 m2,
                 concur_match cd mu st1 m1 st2 m2 ->
                 forall i (cnt1:containsThread st1 i)(cnt2:containsThread st2 i)
                   code1 perm1 code2 perm2,
                   getThreadC cnt1 = Kblocked code1 ->
                   getThreadR cnt1 = perm1 ->
                   getThreadC cnt2 = Kblocked code2 ->
                   getThreadR cnt2 = perm2 ->
                   forall b b' ofs delt,
                     mu b = Some (b', delt) -> 
                     (* Stuff about the lock*)
                     forall virtueThread1 virtueLP1 virtueThread2 virtueLP2,
                       (*Stuff over virtues*)
                       forall m1' m2',
                   concur_match cd mu
                                (updLockSet
                                   (updThread cnt1 (Kresume code1 Vundef)
                                   (computeMap_pair perm1 virtueThread1))
                                   (b, unsigned ofs) virtueLP1) m1'
                                (updLockSet
                                   (updThread cnt2 (Kresume code2 Vundef)
                                   (computeMap_pair perm2 virtueThread2))
                                   (b', unsigned (add ofs (repr delt))) virtueLP2) m2'.
             Admitted.
             eapply concur_match_update.
(*updLockSet
    (updThread (contains12 CMatch cnt1) (Kresume (TState semC semC code2) Vundef)
       (computeMap_pair (getThreadR (contains12 CMatch cnt1))
          (virtueThread (inject_virtue m2 mu angel)))) (b', unsigned (add ofs (repr delt)))
    (virtueLP (inject_virtue m2 mu angel)) = *)
             -- (*concur_match*) eassumption.
             -- (*getThreadC cnt1*) eassumption.
             -- (*getThreadR cnt1*) reflexivity.
             -- (*getThreadC cnt2*)
               symmetry; eassumption.
             -- (*getThreadR cnt2*)
               reflexivity.
             -- eassumption.
                
           * eapply List.Forall2_app.
             -- eapply inject_incr_trace; eauto.     
             -- econstructor; try solve[constructor]; eauto.
           * econstructor; eauto.
             
        (** *tid = hb*)
        - subst tid. (*HERE*)
          
          (*
          st2 : @t dryResources (HybridSem (@Some nat (S hb)))
           Hcmpt2 : @mem_compatible (HybridSem (@Some nat (S hb))) (TP (@Some nat (S hb))) st2 m2
           *)
            
          (* rename the memories, to show that they have been modified, 
               since the execution of this thread stopped. *)
          rename m1' into m1''.
          rename m1 into m1'.
          rename m2 into m2'.
          
          (* Retrieve the match relation for this thread *)
          pose proof (mtch_compiled _ _ _ _ _ _ CMatch _ ltac:
                      (reflexivity)
                        cnt1 (contains12 CMatch cnt1)) as Hmatch.
          
          exploit_match ltac:(apply CMatch).
          
          rename H5 into Hinterference1.
          rename H7 into Hinterference2.
          rename H1 into Hcomp_match.
          rename H2 into Hstrict_evolution.
          
          rename cnt1 into Hcnt1.
          (*rename Hlt' into Hlt_setbBlock1. *)
          remember (virtueThread angel) as virtueThread1.
          remember (virtueLP angel) as virtueLP1.
          rename Hat_external into Hat_external1.
          rename b into b1.
          rename Hstore into Hstore1.
          
            (* to remove until 'end to remove'*)
            rename rmap into lock_map.
            subst virtueThread0.

            (* end to remove *)


            (*

Lemmas that where moved:        
             *)
            
            Definition same_visible: mem -> mem -> Prop.
            Admitted.
            Lemma interference_same_visible:
              forall m m' lev, mem_interference m lev m' ->
              same_visible m m'.
            Admitted.

            (* this lemma should be included in the self simulation. *)
            Lemma same_visible_at_external:
              forall C (sem: semantics.CoreSemantics C mem), 
                self_simulation _ sem ->
                forall c m m' f_and_args, 
                  semantics.at_external sem c m = Some f_and_args->
                  semantics.at_external sem c m' = Some f_and_args.
            Admitted.

            
            Definition permMapLt_range (perms:access_map) b lo hi p:=
              forall ofs : Z, lo <= ofs < hi ->
                         Mem.perm_order'' (perms !! b ofs) p.

            (*Lookup : 
                setPermBlock_range_perm  *)
              Lemma permMapLt_setPermBlock:
              forall perm1 perm2 op b ofs sz,
              permMapLt_range perm2 b ofs (ofs + Z.of_nat sz) op  ->
              permMapLt perm1 perm2 ->
              permMapLt (setPermBlock op b ofs perm1 sz) perm2.
              Proof. Admitted.
              
              Lemma mem_compatible_lock_writable:
                (* This might need to be included into mem_compatible.
                   That would break many things, but all those things should be
                   easy to fix.
                 *)
                forall {sem TP} tp m,
                  @mem_compatible sem TP tp m ->
                  forall (l : Address.address) (rmap : lock_info),
                    ThreadPool.lockRes tp l = Some rmap ->
                    permMapLt_range (getMaxPerm m) (fst l) (snd l)
                                    ((snd l) + LKSIZE) (Some Writable).
              Proof.
              Admitted.
              
                Lemma address_inject_max:
                  forall f m1 m2 b1 ofs1 b2 delta p,
                    Mem.inject f m1 m2 ->
                    Mem.perm m1 b1 (Ptrofs.unsigned ofs1) Max p ->
                    f b1 = Some (b2, delta) ->
                    unsigned (add ofs1 (Ptrofs.repr delta)) =
                    unsigned ofs1 + delta.
                Proof.
                  intros.
                  assert (Mem.perm m1 b1 (Ptrofs.unsigned ofs1) Max Nonempty)
                    by eauto with mem.
                  exploit Mem.mi_representable; eauto. intros [A B].
                  assert (0 <= delta <= Ptrofs.max_unsigned).
                  generalize (Ptrofs.unsigned_range ofs1). omega.
                  unfold Ptrofs.add. repeat rewrite Ptrofs.unsigned_repr; omega.
                Qed.
                Lemma Cur_equiv_restr:
                  forall p1 p2 m1 m2 Hlt1 Hlt2,
                    access_map_equiv p1 p2 ->
                    Cur_equiv (@restrPermMap p1 m1 Hlt1)
                              (@restrPermMap p2 m2 Hlt2).
                Proof. unfold Cur_equiv; intros.
                       do 2 rewrite getCur_restr; assumption. Qed.
                Lemma Max_equiv_restr:
                  forall p1 p2 m1 m2 Hlt1 Hlt2,
                    Max_equiv m1 m2 ->
                    Max_equiv (@restrPermMap p1 m1 Hlt1)
                              (@restrPermMap p2 m2 Hlt2).
                Proof. unfold Max_equiv; intros.
                       do 2 rewrite getMax_restr; assumption. Qed.

                

              Lemma mem_compat_Max:
              forall Sem Tp st m m',
                Max_equiv m m' ->
                Mem.nextblock m = Mem.nextblock m' ->
              @mem_compatible Sem Tp st m ->
              @mem_compatible Sem Tp st m'.
            Proof.
              intros * Hmax Hnb H.
              assert (Hmax':access_map_equiv (getMaxPerm m) (getMaxPerm m'))
                by eapply Hmax.
              constructor; intros;
                repeat rewrite <- Hmax';
                try eapply H; eauto.
              unfold Mem.valid_block; rewrite <- Hnb;
                eapply H; eauto.
            Qed.
            Lemma store_max_equiv:
              forall sz m b ofs v m',
                Mem.store sz m b ofs v = Some m' ->
                Max_equiv m m'.
            Proof.
              intros. intros ?.
              extensionality ofs'.
              eapply memory_lemmas.MemoryLemmas.mem_store_max.
              eassumption.
            Qed.
            Lemma mem_compatible_updLock:
              forall Sem Tp m st st' l lock_info,
                permMapLt_pair lock_info (getMaxPerm m) ->
                Mem.valid_block m (fst l) ->
              st' = ThreadPool.updLockSet(resources:=dryResources) st l lock_info ->
              @mem_compatible Sem Tp st m ->
              @mem_compatible Sem Tp st' m.
            Proof.
              intros * Hlt Hvalid HH Hcmpt.
              subst st'; constructor; intros.
              - erewrite ThreadPool.gLockSetRes. apply Hcmpt.
              - (*Two cases, one of which goes by Hlt*)
                admit.
              - (*Two cases, one of which goes by Hvalid*)
                admit.
            Admitted.
            Lemma mem_compatible_updthread:
              forall Sem Tp m st st' i (cnt:ThreadPool.containsThread st i) c res,
              permMapLt_pair res (getMaxPerm m) ->
              st' = ThreadPool.updThread(resources:=dryResources) cnt c res ->
              @mem_compatible Sem Tp st m ->
              @mem_compatible Sem Tp st' m.
            Proof.
              intros * Hlt HH Hcmpt.
              subst st'; constructor; intros.
              - (*Two cases, one of which goes by Hlt*)
                admit.
              - rewrite ThreadPool.gsoThreadLPool in H.
                eapply Hcmpt; eassumption.
              -  rewrite ThreadPool.gsoThreadLPool in H.
                 eapply Hcmpt; eassumption.
            Admitted.

            Ltac same_types H1 H2:=
                match type of H1 with
                | ?T1 =>
                  match type of H2 with
                  | ?T2 =>
                    let HH:=fresh "HH" in 
                    assert (HH:T1 = T2) by reflexivity;
                    try (dependent rewrite HH in H1;
                         clear HH)
                  end
                end.

            
                  Inductive release: val -> mem -> delta_perm_map ->  mem -> Prop  :=
                  | ReleaseAngel:
                      forall b ofs m dpm m',
                        True ->
                        (* This shall codify, the change in permissions
                       and changing the  lock value to 1.
                         *)
                        release (Vptr b ofs) m dpm m'.

                  Inductive extcall_release: Events.extcall_sem:=
                  | ExtCallRelease:
                      forall ge m m' m'' m''' b ofs e dpm e',
                        mem_interference m e m' ->
                        release (Vptr b ofs) m' dpm m'' ->
                        mem_interference m'' e' m''' ->
                        extcall_release ge (Vptr b ofs :: nil) m
                                        (Events.Event_acq_rel e dpm e' :: nil)
                                        Vundef m'''.
                  Lemma extcall_properties_release:
                    Events.extcall_properties extcall_release UNLOCK_SIG.
                  Proof.
                  (* this is given axiomatically in compcert, 
                     but we must prove it*)
                  Admitted.
                  Axiom ReleaseExists:
                    forall ge args m ev r m',
                      Events.external_functions_sem "release" UNLOCK_SIG
                                                    ge args m ev r m' =
                      extcall_release ge args m ev r m'.

                  Lemma interference_consecutive: forall m lev m',
                  mem_interference m lev m' ->
                  consecutive (Mem.nextblock m) lev.
                Proof.
                  intros. induction lev; try econstructor.
                Admitted.
            (* Lemmas end *)
                
          
                (** *Diagram No.0*)
                Definition expl_restrPermMap p m Hlt:=
                      @restrPermMap p m Hlt.
                    Lemma expl_restr:
                      forall p m Hlt,
                        restrPermMap Hlt = expl_restrPermMap p m Hlt.
                    Proof. reflexivity. Qed.


                    Ltac clean_proofs:=
                      match goal with
                      | [A: ?T, B: ?T |- _] =>
                        match type of T with
                        | Prop => assert (A = B) by apply Axioms.proof_irr;
                              subst A
                        end
                      end.
            
          Lemma release_step_diagram_compiled:
        let hybrid_sem:= (sem_coresem (HybridSem (Some hb))) in 
        forall (angel: virtue) (U : list nat) (cd : compiler_index)
          (virtueThread1 : Pair delta_perm_map)
          (virtueLP1 : Pair access_map)
          (Hangel_eq: angel = Build_virtue virtueThread1 virtueLP1)
          (HSched: HybridMachineSig.schedPeek U = Some hb)
          (mu : meminj)
          (st1 : ThreadPool (Some hb)) (m1 m1' m1'' : mem) 
          (tr1 tr2 : HybridMachineSig.event_trace)
          (st2 : ThreadPool (Some (S hb))) (m2' : mem)
          (Hcnt1 : containsThread(Sem:=HybridSem (Some hb)) st1 hb)
          (b1 : block) (ofs : int)
          (lock_map : lock_info)
          (Hwritable_lock1 : writeable_lock b1 (unsigned ofs) (snd (getThreadR Hcnt1)) m1')
          (Hcmpt : mem_compatible st1 m1')
          (code1 : semC) 
          (thread_compat1: thread_compat Hcnt1 m1'),
          let m_writable_lock_1:= restrPermMap Hwritable_lock1 in
          let th_mem1 :=  fst (thread_mems thread_compat1) in
          let locks_mem1:= snd (thread_mems thread_compat1) in
          let virtueThread:= virtueThread angel in
          let virtueLP := virtueLP angel in
          let newThreadPerm1:= (computeMap_pair (getThreadR Hcnt1) virtueThread) in
          forall (CMatch:concur_match (Some cd) mu st1 m1' st2 m2')
          (HTraceInj: List.Forall2 (inject_mevent mu) tr1 tr2)
          (Hangel_bound: sub_map_virtue angel (getMaxPerm m1'))
          (Hinv: invariant st1)
          (Hcode: getThreadC Hcnt1 = Kblocked (SST code1))
          (Hat_external1: semantics.at_external hybrid_sem (SST code1) th_mem1 =
                         Some (UNLOCK, (Vptr b1 ofs :: nil)%list))
          (Hstore1: Mem.store AST.Mint32 m_writable_lock_1 b1
                             (unsigned ofs) (Vint Int.one) = Some m1'')
          (Haccess: Mem.range_perm locks_mem1 b1 (unsigned ofs)
                      (Z.add (unsigned ofs) LKSIZE) Cur Readable)
          (Hload: Mem.load AST.Mint32 locks_mem1 b1 (unsigned ofs) =
                  Some (Vint Integers.Int.zero))
          (HisLock: ThreadPool.lockRes st1 (b1, unsigned ofs) = Some lock_map)
          (Hrmap: empty_doublemap lock_map)
          (Hjoin_angel: permMapJoin_pair newThreadPerm1 virtueLP (getThreadR Hcnt1))

          (Hlt1 : permMapLt (thread_perms Hcnt1) (getMaxPerm m1'))
          (Hlt2 : permMapLt (thread_perms (contains12 CMatch Hcnt1)) (getMaxPerm m2'))
          (j : meminj)
          (code2 : Asm.state)
          (m2 : mem)
          (lev1 lev2 : list Events.mem_effect)
          (Hcomp_match : compiler_match (cd) j code1 m1 code2 m2)
          (Hstrict_evolution : strict_injection_evolution j mu lev1 lev2)
          (Hinterference1 : mem_interference m1 lev1 (restrPermMap Hlt1))
          (Hinterference2 : mem_interference m2 lev2 (restrPermMap Hlt2))
          (H0 : Kblocked (TST code2) = getThreadC (contains12 CMatch Hcnt1)),
        exists
          evnt' (st2' : t) (m2'' : mem) (cd' : option compiler_index)(mu' : meminj),
          let evnt:= (Events.release (b1, unsigned ofs) (Some (build_delta_content (fst virtueThread) m1''))) in 
          concur_match cd' mu'
                       (updLockSet
                          (updThread Hcnt1 (Kresume (SST code1) Vundef)
                                     (computeMap_pair (getThreadR Hcnt1) (virtueThread)))
                          (b1, unsigned ofs) virtueLP) m1'' st2' m2'' /\
          List.Forall2 (inject_mevent mu')
                       (tr1 ++ (Events.external hb evnt :: nil))
                       (tr2 ++ (Events.external hb evnt' :: nil)) /\
          HybridMachineSig.external_step
            (scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler)
            U tr2 st2 m2' (HybridMachineSig.schedSkip U)
            (tr2 ++ (Events.external hb evnt' :: nil)) st2' m2''.
          Proof.
            intros.
            assert (Hcmpt2: mem_compatible(tpool:=OrdinalThreadPool) st2 m2').
            { inversion CMatch.
              assumption. }

          
          assert (Hcnt2: containsThread st2 hb).
          { eapply contains12; eauto. }

          assert (Hinj2: Mem.inject j m1 m2).
            { clear - Hcomp_match.
              pose proof (Injfsim_match_meminjX compiler_sim _ _ _ _ Hcomp_match).
              destruct code1, code2; auto. } 

          
            remember (virtueThread_inject m2' mu virtueThread1)  as virtueThread2.
            remember (virtueLP_inject m2' mu virtueLP1) as virtueLP2.

            
            
            simpl in Hat_external1.
            assert (Hat_external1': Smallstep.at_external
                                      (Smallstep.part_sem (Clight.semantics2 C_program))
                                      (Clight.set_mem code1 m1) = Some (UNLOCK, Vptr b1 ofs :: nil)).
          { (* This follows from self simulation:
                   interferences, preserves at_external.
             *)
            (* Things we know *)
            (* th_mem1 =  (m1')|(thread_perms Hcnt1)   *)
            (*
              m1 --lev1--> (m1')|(thread_perms Hcnt1)
             *)
            replace (restrPermMap Hlt1) with th_mem1 in Hinterference1
            by eapply restr_proof_irr.
            (*The hard part here is to prove the injection of the old memories... 
              but maybe I have that?
             *)
            (* Definition that defines memoryes 
               that are equal in all visible locations.

               Can be define generically or by using mem_interference.
               (using memn_interference is more restrictive, but 
               might be enough.)
             *)

            
            exploit same_visible_at_external.
            - exact Cself_simulation.
            - apply Hat_external1.
            - simpl; eauto. 
          }
          
          
          assert (H: exists b2 delt2,
                     mu b1 = Some (b2, delt2) /\
                     j b1 = Some (b2, delt2) /\
                     semantics.at_external CoreAsmSem (code2) m2 =
                     Some (UNLOCK, Vptr b2 (add ofs (repr delt2)) :: nil)
                 ).
          {
            pose proof (Injsim_atxX compiler_sim _ _ _ _ Hcomp_match Hat_external1')
              as Hatx.
            destruct Hatx as (args' & Hat_external2 & list_inj).
            inversion list_inj; subst.
            inversion H2; inversion H4; subst.
            exists b2, delta; repeat (split; auto).
            eapply evolution_inject_incr; eassumption.
          }
          destruct H as (b2&delt2&Hinj_b2&Hinj_b2'&Hat_external2).


                    assert (Hat_external2': 
                    semantics.at_external CoreAsmSem code2
                      (restrPermMap (proj1 (Hcmpt2 hb (contains12 CMatch Hcnt1)))) =
                    Some (UNLOCK, Vptr b2 (add ofs (repr delt2)) :: nil)
                         
                 ).

          { (* This follows from self simulation:
                 interferences, preserves at_external.
             *)
            
            exploit same_visible_at_external.
            - exact Aself_simulation.
            - apply Hat_external2.
            - simpl; eauto. 

          }

          
          assert (Hlt_setbBlock2: permMapLt
                           (setPermBlock (Some Writable) b2 (unsigned ofs + delt2)
                                         (snd (getThreadR Hcnt2)) LKSIZE_nat) 
                           (getMaxPerm m2')).
          { move Hinj2 at bottom.
            exploit (@compat_th _ _  _ _ Hcmpt2 hb ltac:((simpl; auto)));
              simpl; intros [? ?].


              eapply permMapLt_setPermBlock; eauto.

              intros ??.
              exploit (mem_compatible_lock_writable _ _ Hcmpt2 (b2,unsigned ofs + delt2));
                simpl; eauto.
            - exploit INJ_lock_permissions; eauto.
              simpl in HisLock; eauto.
              intros HH; rewrite <- HH.
              repeat f_equal.
              { (* Make this a lemma? *) 
                symmetry.
                unfold add.
                (* eapply Mem.address_inject; eauto; simpl.
                match goal with
                  |- Mem.perm ?m _ _ _ _ =>
                  replace m with m1 end.
                2: destruct code1; auto.
                instantiate(2:=b1).
                2:instantiate(1:=b2). *)
                eapply address_inject_max; try apply Hinj2; eauto.
                match goal with
                  |- Mem.perm ?m _ _ _ _ =>
                  replace m with m1 by (destruct code1; auto)
                end.
                unfold Mem.perm.
                rewrite_getPerm.
                clear - Hwritable_lock1.
                move Hwritable_lock1 at bottom.
                unfold writeable_lock in Hwritable_lock1.
                admit. }
          }

                    
          (* build m2' *)
          assert (Hstore2:=Hstore1).
          eapply (Mem.store_mapped_inject mu) in Hstore2; eauto.
          2: {
            (* TODO : Clean this admits here and all useless definitions *)
            instantiate (1:= (restrPermMap Hlt_setbBlock2)).
            (* This goal requires that the injection holds 
                 even after the lock's Cur permission is set 
                 to Writable (in both memories). 
                 This is probably a simple general lemma, about
                 changing Cur memories in two injected memories.
             *)
            subst m_writable_lock_1.
            (*useful? setPermBlock_mem_inject*)
            (* m1|_(lp1 + setPerm) -j->  m2|_(lp2 + setPerm)  *)
            
            (* Construct locks_perm_as_cur*)
            assert (locks_perm_lt1: permMapLt (lock_perms Hcnt1) (getMaxPerm m1')).
            { admit. }
            remember (restrPermMap locks_perm_lt1) as m1'_lock_perms.
            remember (getCurPerm m1'_lock_perms) as locks_perm_as_cur1.
            assert (access_map_equiv locks_perm_as_cur1 (lock_perms Hcnt1)).
            { subst m1'_lock_perms locks_perm_as_cur1; eapply getCur_restr. }

            assert (locks_perm_lt2: permMapLt (lock_perms Hcnt2) (getMaxPerm m2')).
            { admit. }
            remember (restrPermMap locks_perm_lt2) as m2'_lock_perms.
            remember (getCurPerm m2'_lock_perms) as locks_perm_as_cur2.
            assert (access_map_equiv locks_perm_as_cur2 (lock_perms Hcnt2)).
            { subst m2'_lock_perms locks_perm_as_cur2; eapply getCur_restr. }
            
            (* Construct the Hwritable_lock1 using locks_perm_as_cur*)
            assert (Hwritable_lock1':
                      writeable_lock b1 (unsigned ofs) locks_perm_as_cur1 m1').
            { unfold writeable_lock.  rewrite H. assumption. }
            assert (Hlt_setbBlock2':
                      writeable_lock b2 (unsigned ofs+ delt2) locks_perm_as_cur2 m2').
            { unfold writeable_lock.  rewrite H1; assumption. }

                                  
            assert (Hwritable_lock1'': writeable_lock b1 (unsigned ofs)
                                                      locks_perm_as_cur1
                                                      m1'_lock_perms).
            { admit. }
            assert (Hwritable_lock2'': writeable_lock b2 (unsigned ofs+ delt2)
                                                      locks_perm_as_cur2
                                                      m2'_lock_perms).
            { admit. }
            
            cut (Mem.inject mu
                            (restrPermMap Hwritable_lock1'')
                            (restrPermMap Hwritable_lock2'')).
            { apply mem_inject_equiv; auto.
              - subst m1'_lock_perms; constructor.
                + apply Cur_equiv_restr. auto. rewrite H. reflexivity.
                + apply Max_equiv_restr. 
                  symmetry. apply getMax_restr.
                + do 3 rewrite restr_content_equiv.
                  reflexivity.
                + reflexivity.
                    
              - subst m2'_lock_perms; constructor.
                + apply Cur_equiv_restr. auto. rewrite H1. reflexivity.
                + apply Max_equiv_restr.
                  symmetry. apply getMax_restr.
                + do 3 rewrite restr_content_equiv.
                  reflexivity.
                + reflexivity.
            }
            
    
            subst locks_perm_as_cur1 locks_perm_as_cur2.
            eapply setPermBlock_mem_inject.
            - admit.
            - do 2 eexists.
              split; eauto. admit.
            - assumption.
            - subst m1'_lock_perms m2'_lock_perms.
              eapply INJ_locks; eauto.
          }

          
          destruct Hstore2 as (m2''& Hstore2 & Hinj2').
          
          remember (add ofs (repr delt2)) as ofs2.
          remember (computeMap (fst (getThreadR Hcnt2)) (fst virtueThread2),
                    computeMap (snd (getThreadR Hcnt2)) (snd virtueThread2)) as new_cur2.
          remember ((updLockSet
                       (updThread Hcnt2 (Kresume (TST code2) Vundef) new_cur2)
                       (b2, unsigned ofs2) virtueLP2)) as st2'.
          
          match goal with
            [|- context[concur_match _ _ ?st1 ?m1 _ _] ] =>
            remember st1 as st1'
          end. 

          
            
          assert (Hcmpt1': mem_compatible(tpool:=OrdinalThreadPool) st1' m1'').
          { 
            eapply mem_compat_Max.
            eapply store_max_equiv.
            eassumption.
            symmetry;
              eapply Mem.nextblock_store; eauto.
            subst m_writable_lock_1.
            eapply (mem_compat_Max _ _ _ m1').
            symmetry. apply restr_Max_equiv.
            reflexivity.
             
            eapply mem_compatible_updLock; eauto.
            - cut (permMapLt_pair virtueLP0  (getMaxPerm m1')).
              { auto. }
              apply (permMapLt_pair_trans211 _ (getThreadR Hcnt1)).
              eapply permMapJoin_lt_pair2. eauto.
              eapply Hcmpt.
            - simpl.
              pose proof (INJ _ _ _ _ _ _ CMatch).
              destruct (mem_lemmas.valid_block_dec m1' b1); auto.
              eapply Mem.mi_freeblocks in n; eauto.
              unify_injection.
            -
              eapply mem_compatible_updthread.
              2: reflexivity.
              fold newThreadPerm1.
              apply (permMapLt_pair_trans211 _ (getThreadR Hcnt1)).
              eapply permMapJoin_lt_pair1. eauto.
              eapply Hcmpt.

            assumption.
            
          }
          assert (H: ThreadPool (Some (S hb)) =
                     @t dryResources (HybridSem (@Some nat (S hb)))).
          { reflexivity. }
          dependent rewrite <- H in st2'. clear H.
          assert (Hcmpt2': mem_compatible st2' m2'').
          {
            admit. (*TODO: from Hcmpt2 *)
          }

          
          
          eexists.
          exists st2', m2'', (Some cd), mu.
          split; [|split].
          
          + eapply Build_concur_match
            ; simpl;
              try assumption;
              try (subst st2' st1'; apply CMatch).
            * !goal (Events.injection_full mu m1'').
              { pose (full_inj _ _ _ _ _ _  CMatch) as Hfull_inj.
                (* Mem.store should preserve Events.injection_full *)
                admit.
              }

            * !context_goal perm_preimage.
              admit.
            * admit. (*inject threads*)
            * admit. (*inject locks*)
            * admit. (*inject lock permission*)
            * admit. (*inject lock content*)
            * admit. (* invariant is preserved! *)
            * admit. (* thread_match source*)
            * admit. (* thread_match target. *)
            * (* thread_match compiled. *)

              intros thread HH Hcnt1_dup Hcnt2_dup.
              subst thread.
              
              
              subst st1'.
              same_types Hcnt1_dup Hcnt1.
              subst st2'.
              same_types Hcnt2_dup Hcnt2.
              clean_cnt.
              
              intros ? ?.
              
              match goal with
              | [|- match_thread_compiled _ _ ?X _ ?Y _] =>
                let HH1:= fresh "HH1" in 
                assert (HH1: X = Kresume (SST code1) Vundef)
                  by
                    (simpl; rewrite eqtype.eq_refl; reflexivity);
                  let HH2:= fresh "HH2" in
                  assert (HH2: Y = Kresume (TST code2) Vundef) by
                      (simpl; rewrite eqtype.eq_refl; reflexivity)
                        
              end.
              
              rewrite HH1; clear HH1.
              rewrite HH2; clear HH2.
              
              econstructor.
              intros j'' s1' m1''' m2''' lev1' lev2'.
              intros Hstrict_evolution' (*Hincr'*) Hinterference1' Hinterference2'
                     Hafter_ext.
              assert (Hincr':= evolution_inject_incr _ _ _ _  Hstrict_evolution').
              remember (fst virtueThread1) as dpm1.
              remember (Events.Event_acq_rel lev1 dpm1 lev1' :: nil) as rel_trace.

                           
              
              (*
                Prove that this is a CompCert step (en external step).
               *)
              assert (Hstep: Smallstep.step
                               (Clight.part_semantics2 Clight_g)
                               (Clight.set_mem code1 m1)
                               rel_trace
                               (Clight.set_mem s1' m1''')).
              {
                simpl in Hafter_ext. unfold Clight.after_external in Hafter_ext.
                move Hat_external1 at bottom.
                unfold Clight.at_external in Hat_external1.
                destruct code1 eqn:Hcallstate; try discriminate.
                simpl in Hat_external1.
                destruct fd eqn:Hext_func; try discriminate.
                (* inversion Hat_external1; clear Hat_external1; subst. *)
                inversion Hat_external1. subst e args. simpl.
                pose proof (Clight.step_external_function
                              Clight_g (Clight.function_entry2 Clight_g)
                              UNLOCK t0 t1 c (Vptr b1 ofs :: nil) k m1 Vundef
                              rel_trace
                              m1''') as HH.
                assert (Hextcall: Events.external_call
                                    UNLOCK (Clight.genv_genv Clight_g)
                                    (Vptr b1 ofs :: nil) m1
                                    rel_trace
                                    Vundef m1''').
                { simpl.
                  (* This function is given axiomaticall in CompCert. *)
                  
                  rewrite ReleaseExists.
                  subst rel_trace; econstructor.
                  - eassumption.
                  - constructor; auto.
                  - eassumption.
                }
                eapply HH in Hextcall; auto.
                inversion Hafter_ext.
                unfold Clight.step2; auto.
              }

              unfold compiler_match in Hcomp_match.
              eapply (Injsim_simulation_atxX compiler_sim) in Hstep; simpl in *; eauto.
              specialize (Hstep _ _ _ Hcomp_match).
              destruct Hstep as (j2'&Hincr&Hstep_str&Hstep).

              idtac "Over here maybe do it slowly!".

              
              destruct Hstep_str as
                  (i2_str&s2_str&t_str&Hstep_str&Hmatch_str&Hinj_trace_str).
              remember 
                (Events.Event_acq_rel lev2 (fst virtueThread2) lev2' :: nil)  as rel_trace2.
              assert (Htrace_str : exists lev2_str dpm_str lev2_str',
                         t_str =
                         Events.Event_acq_rel lev2_str
                                              dpm_str
                                              lev2_str' :: nil).
              { subst. inversion Hinj_trace_str; subst.
                inversion H4; subst.
                inversion H2; subst.
                do 3 eexists. f_equal.
              }
              destruct Htrace_str as (lev2_str&dpm_str&lev2_str'&Htrace_str).

              assert (Hconsecutive:
                        consecutive (Mem.nextblock m2) lev2).
              { eapply interference_consecutive; eassumption.
              }

              assert (Hconsecutive': consecutive (Mem.nextblock m2'') lev2').
              { erewrite <- restrPermMap_nextblock.
                eapply interference_consecutive; eassumption.
              }

              (** *Left Diagrams *)
              pose proof (principled_diagram_exists
                            _ _ _ _ _
                            Hstrict_evolution Hconsecutive) as
                  Pdiagram.
              destruct Pdiagram as (lev20&Hprincipled&Hlessdef).
              assert (Hdiagram: diagram (Mem.nextblock m2) j j2' lev1 lev2_str).
              { econstructor.
                - eauto.
                - subst rel_trace t_str;
                    inversion Hinj_trace_str; subst.
                  inversion H3; subst. auto.
                  Lemma list_inject_weaken: 
                    forall j lev1 lev2,
                      Events.list_inject_mem_effect_strong j lev1 lev2 ->
                      Events.list_inject_mem_effect j lev1 lev2.
                  Proof.
                    intros. inversion H; subst; constructor.
                    -
                  Admitted.

                  eapply list_inject_weaken; auto.
                - Lemma Asm_step_consecutive:
                    forall ge st m t st',
                    Asm.step ge (Asm.set_mem st m) t st' ->
                    forall lev dpm lev' t',
                      t = Events.Event_acq_rel lev dpm lev' :: t' ->
                      consecutive (Mem.nextblock m) lev.
                  Admitted.
                  eapply Asm_step_consecutive; eassumption.
              }
              destruct (principled_diagram_correct
                          _ _ _ _ _ _ _ Hprincipled Hdiagram)
                as (Hincr_mu & lessdef_str).

              (** *Right Diagrams*)
              pose proof (principled_diagram_exists
                            _ _ _ _ _
                            Hstrict_evolution' Hconsecutive') as
                  Pdiagram'.
              destruct Pdiagram' as (lev20'&Hprincipled'&Hlessdef').

              
              assert (Hdiagram':
                        diagram (Mem.nextblock m2'') mu j2' lev1' lev2_str').
              { econstructor.
                - eauto.
                - subst rel_trace t_str;
                    inversion Hinj_trace_str; subst.
                  inversion H3; subst. 
                  eapply list_inject_weaken; auto.
                - (* Go back and do that with *)
                  admit. (* follows from the syntax. *)
              }
              destruct (principled_diagram_correct
                          _ _ _ _ _ _ _ Hprincipled' Hdiagram')
                as (Hincr_mu_j2' & lessdef_str').
              
              
              assert (Hinj_trace: Events.inject_trace j2' rel_trace rel_trace2).
              { subst rel_trace rel_trace2.
                econstructor; try solve[constructor].
                econstructor; try eassumption.
                - emonotonicity; eauto.
                  emonotonicity; eauto.
                  eapply evolution_list_inject_mem; eauto.
                - emonotonicity; eauto.
                  subst dpm1. admit. (* proof constructions correct*)
                - emonotonicity; eauto.
                  eapply evolution_list_inject_mem in Hstrict_evolution'; eauto.
              }
              
              destruct  (Hstep _ Hinj_trace)
                as (cd' & s2' & step & comp_match ).


              (* We prove that code2 must do an external step. *)
              (* Note: no need for a { here. 
                 TODO: better formating *)
              { move Hat_external2' at bottom.
                unfold Asm.at_external in Hat_external2'.
                destruct code2 eqn:Code.
                simpl in Hat_external2'.
                destruct (r Asm.PC) eqn:rPC; try discriminate.
                destruct (eq_dec i zero) eqn:i0_0; try discriminate.
                unfold Asm_g.
                destruct (Genv.find_funct_ptr the_ge b) eqn:func_lookup; try discriminate.
                destruct f; try discriminate.
                
                
                inversion step; subst; try solve[inversion H5] .
                - rewrite rPC in H2; inversion H2; subst.
                  unfold the_ge in func_lookup.
                  rewrite func_lookup in H3.
                  inversion H3; discriminate.
                (*  - rewrite rPC in H2; inversion H2; subst.
                    unfold the_ge in func_lookup.
                    rewrite func_lookup in H3.
                    inversion H3 discriminate. *)
                - rename m' into m21'''.
                  (* NOTE: 
                       - the s2' (i.e. target state) in comp_match, 
                       results from inverting the step.
                       - the st'2 (i.e. target state) in the goal,
                       results from Asm.after_external. 
                   *)
                  unfold Asm.after_external.
                  unfold Asm.after_external_regset.
                  rewrite rPC, i0_0, func_lookup.
                  (* Show that target program is executing the same function*)
                  assert (FUNeq:e0 = ef ).
                  { assert (BB0: b0 = b)
                      by (rewrite rPC in H2; inversion H2; reflexivity).
                    subst b0. unfold the_ge in func_lookup.
                    rewrite func_lookup in H3; inversion H3.
                    reflexivity.
                  } subst e0.
                  
                  (* Show that the function is UNLOCK*)
                  match type of Hat_external2' with
                  | match ?x with _ => _ end = _ =>
                    destruct x eqn:HH; try discriminate
                  end.

                  inversion Hat_external2'. subst.
                  do 3 eexists; repeat split; eauto.
                  unfold compiler_match.
                  move comp_match at bottom.
                  simpl.
                  
                  instantiate(1:=cd').
                  replace (Clight.set_mem s1' (Clight.get_mem s1')) with s1'
                    by (destruct s1'; reflexivity).
                  simpl in comp_match.
                  
                  (*This should be generalizable*)
                  unfold Asm.loc_external_result,Conventions1.loc_result in comp_match.
                  replace Archi.ptr64 with false in comp_match by reflexivity. 
                  simpl in comp_match.
                  
                  assert (Hres: res = Vundef).
                  { unfold Events.external_call in *.
                    rewrite ReleaseExists in H5.
                    inversion H5. reflexivity.
                  }
                  subst res.
                  (* Here *)
                  replace m2''' with m21'''. auto.
                  
                  (*  m21''' = m2''' *)
                  simpl in H5.
                  rewrite ReleaseExists in H5.
                  inversion H5; subst.
                  rename m' into m21'.
                  rename m'' into m21''.
                  rename H10 into Hinterference21.
                  rename H11 into Hrelease.
                  
                  move Hinterference2' at bottom.

                  (*
                     m1 -lev1-> m1' -dpm-> m1'' -lev1'-> m1'''
                     |          |         |            |
                     |          |         |            |
                     m2 -lev2-> m2' -dpm-> m2'' -lev2'-> m2'''
                     !          !         !            !     
                     m2 -lev2-> m21'-dpm-> m21''-lev2'-> m21'''
                   *)
                  
                  assert (m21' =
                          (restrPermMap (proj1 ((memcompat2 CMatch) hb Hcnt2)))).
                  { move Hinterference2 at bottom.
                    move Hinterference21 at bottom.
                    eapply mem_interference_determ. eassumption.
                    repeat clean_proofs.
                    erewrite restr_proof_irr; eauto.
                  }
                  
                  assert (m21'' = (restrPermMap (proj1 (Hcmpt2' hb Hcnt2)))).
                  { move Hstore2 at bottom.
                    move Hrelease at bottom.
                    admit.
                  (* Sketch: release has to be defined.
                          it should modify content without touching permissions.
                          then show: 
                          m2' -release-> m2''
                          (or their restrictions to the cur)
                          release is deterministic and so the result follows. *)
                  }
                  (*  m21''' = m2''' *)
                  eapply mem_interference_determ; subst; try eassumption.
                  erewrite restr_proof_irr; eauto.
              }
              
          + eapply List.Forall2_app.
            * eauto.
            * econstructor; try solve[constructor].
              simpl.
              econstructor.
              admit.
          (* injection of the event*)
          (* Should be obvious by construction *)
          + (* HybridMachineSig.external_step *)

            econstructor; eauto.
            eapply step_release with
                (b:= b2)
                (virtueThread:=virtueThread2)
                (virtueLP:=virtueLP2);
              eauto; try reflexivity;
                try unfold HybridMachineSig.isCoarse,
                HybridMachineSig.HybridCoarseMachine.scheduler.
            rename m2' into MMM.
            rename m2 into MMM2.
            
            * (* bounded_maps.sub_map *)
              
              subst virtueThread2.
              unfold virtueThread_inject.
              destruct virtueThread1 as (virtue11, virtue12).
              cbv iota beta delta[fst] in *.
              destruct Hangel_bound as [Hbounded HboundedLP].
              destruct Hbounded as [Hbound1 Hbound2].
              split.
              -- eapply inject_virtue_sub_map.
                 eapply CMatch.
                 subst angel virtueThread0. assumption.
              -- eapply inject_virtue_sub_map.
                 eapply CMatch.
                 subst angel virtueThread0.
                 eassumption.
                 
            * (* bounded_maps.sub_map *)
              
              destruct Hangel_bound as [Hbounded HboundedLP].
              destruct HboundedLP as (?&?&Hbound).
              move Hbound at bottom.
              rewrite HeqvirtueLP2; simpl.
              
              eapply (proj1 (Logic.and_assoc _ _ _)).
              split.

              (*Easy ones: the default is trivial:
                  bounded_maps.map_empty_def
               *)
              subst virtueLP2.
              unfold virtueLP_inject,
              bounded_maps.map_empty_def, access_map_injected;
                simpl.
              subst angel; auto.

              assert (HboundedLP':
                        bounded_maps.sub_map (snd (fst virtueLP1)) (snd (getMaxPerm m1')) /\
                        bounded_maps.sub_map (snd (snd virtueLP1)) (snd (getMaxPerm m1'))
                     ) by (subst angel; eassumption).
              
              
              subst virtueLP2.
              destruct virtueLP1 as (virtueLP_fst, virtueLP_snd).
              revert HboundedLP'.
              unfold virtueLP_inject, access_map_injected.
              simpl (fst _).
              simpl (snd _) at 3 6 9.
              

              (* eapply self_simulation.minject in matchmem. *)
              intros (Hl & Hr); split;
                eapply inject_virtue_sub_map;
                try eapply CMatch; eauto.

              
            * (*invariant st4 *)
              !goal (invariant _).
              admit.

              
            * (* at_external for code 4. *)
              simpl in *; eassumption.
              
            * (* Mem.range_perm *)
              (* Can read the lock *)
              !goal(Mem.range_perm _ _ _ (intval ofs2 + LKSIZE) Cur Readable).
              admit.

            * (* The load. *)
              !goal ( Mem.load AST.Mint32 _ _ _ = Some _ ).
              admit.
              
            * (* the store *)
              !goal ( Mem.store AST.Mint32 _ _ _ _ = Some _ ).
              admit.

            * (* content of lockres*)
              (* ThreadPool.lockRes st4 (b4', ofs4') *)
              (* NOTE: why is it rmap? It should be an injection of rmap 
                   ANSWER: the 'RMAP' is empty, so its injection is also empty... 
               *)
              !goal (ThreadPool.lockRes _ _ = Some _).
              admit.

            * eapply empty_map_useful; eauto. 
            * (* permissions join FST*)
              simpl.
              !goal(permMapJoin _ _ _ ).
              admit.
              
            * (* permissions join SND *)
              !goal(permMapJoin _ _ _ ).
              admit.
              
            * simpl. 
              subst; repeat f_equal; try eapply Axioms.proof_irr.
              
          Admitted. (* release_step_diagram_compiled *)

          
          exploit release_step_diagram_compiled; eauto;
            try solve reflexivity.
          + destruct angel; subst; auto.
          + subst th_mem1; simpl; eauto.

            (* fail "you can now delete the proof bellow, until you use the lemma!".
            Uncomment until STOPHERE
                     
            fail " HERE time to prove the lemma above. 
            Change the lemma to fit the proof bellow. 
            Also, make sure that it still proves what it needs to prove.  ".
            
            STOPHERE *)
        

            (*
          assert (Hcmpt2: mem_compatible(tpool:=OrdinalThreadPool) st2 m2').
          { inversion CMatch.
            assumption. }
          
          assert (Hcnt2: containsThread st2 hb).
          { eapply contains12; eauto. }

          assert (Hinj2: Mem.inject j m1 m2).
            { clear - Hcomp_match.
              pose proof (Injfsim_match_meminjX compiler_sim _ _ _ _ Hcomp_match).
              destruct code1, code2; auto. }
            remember (virtueThread_inject m2' mu virtueThread1)  as virtueThread2.
            remember (virtueLP_inject m2' mu virtueLP1) as virtueLP2.

            
            simpl in Hat_external1.
            assert (Hat_external1': Smallstep.at_external
                                      (Smallstep.part_sem (Clight.semantics2 C_program))
                                      (Clight.set_mem code1 m1) = Some (UNLOCK, Vptr b1 ofs :: nil)).
            { (* This follows from self simulation:
                   interferences, preserves at_external.
             *)
              (* Things we know *)
              (* th_mem1 =  (m1')|(thread_perms Hcnt1)   *)
              (*
              m1 --lev1--> (m1')|(thread_perms Hcnt1)
             *)
              replace (restrPermMap Hlt1) with th_mem1 in Hinterference1.
              2: { Set Printing Implicit.
                   subst th_mem1.
                   apply restr_proof_irr. } 
            (*The hard part here is to prove the injection of the old memories... 
              but maybe I have that?
             *)
            (* Definition that defines memoryes 
               that are equal in all visible locations.

               Can be define generically or by using mem_interference.
               (using memn_interference is more restrictive, but 
               might be enough.)
             *)

            exploit same_visible_at_external.
            - exact Cself_simulation.
            - apply Hat_external1.
            - simpl; eauto. 
          }
          
          assert (H: exists b2 delt2,
                     mu b1 = Some (b2, delt2) /\
                     j b1 = Some (b2, delt2) /\
                     semantics.at_external CoreAsmSem (code2) m2 =
                     Some (UNLOCK, Vptr b2 (add ofs (repr delt2)) :: nil)
                 ).
          {
            pose proof (Injsim_atxX compiler_sim _ _ _ _ Hcomp_match Hat_external1')
              as Hatx.
            destruct Hatx as (args' & Hat_external2 & list_inj).
            inversion list_inj; subst.
            inversion H2; inversion H4; subst.
            exists b2, delta; repeat (split; auto).
            eapply evolution_inject_incr; eassumption.
          }
          destruct H as (b2&delt2&Hinj_b2&Hinj_b2'&Hat_external2).

          assert (Hat_external2': 
                    semantics.at_external CoreAsmSem code2
                      (restrPermMap (proj1 (Hcmpt2 hb (contains12 CMatch Hcnt1)))) =
                    Some (UNLOCK, Vptr b2 (add ofs (repr delt2)) :: nil)
                         
                 ).

          { (* This follows from self simulation:
                 interferences, preserves at_external.
             *)
            
            exploit same_visible_at_external.
            - exact Aself_simulation.
            - apply Hat_external2.
            - simpl; eauto. 

          }

          
          assert (Hlt_setbBlock2: permMapLt
                           (setPermBlock (Some Writable) b2 (unsigned ofs + delt2)
                                         (snd (getThreadR Hcnt2)) LKSIZE_nat) 
                           (getMaxPerm m2')).
          { move Hinj2 at bottom.
            exploit (@compat_th _ _  _ _ Hcmpt2 hb ltac:((simpl; auto)));
              simpl; intros [? ?].
            
              eapply permMapLt_setPermBlock; eauto.

              intros ??.
              exploit (mem_compatible_lock_writable _ _ Hcmpt2 (b2,unsigned ofs + delt2));
                simpl; eauto.
            - exploit INJ_lock_permissions; eauto.
              intros HH; rewrite <- HH.
              repeat f_equal.
              { (* Make this a lemma? *) 
                symmetry.
                unfold add.
                (* eapply Mem.address_inject; eauto; simpl.
                match goal with
                  |- Mem.perm ?m _ _ _ _ =>
                  replace m with m1 end.
                2: destruct code1; auto.
                instantiate(2:=b1).
                2:instantiate(1:=b2). *)
                
                eapply address_inject_max; try apply Hinj2; eauto.
                match goal with
                  |- Mem.perm ?m _ _ _ _ =>
                  replace m with m1 by (destruct code1; auto)
                end.
                unfold Mem.perm.
                rewrite_getPerm.
                clear - Hwritable_lock1.
                move Hwritable_lock1 at bottom.
                unfold writeable_lock in Hwritable_lock1.
                admit. }
          }

          
          (* build m2' *)
          assert (Hstore2:=Hstore1).
          eapply (Mem.store_mapped_inject mu) in Hstore2; eauto.
          2: {
            (* TODO : Clean this admits here and all useless definitions *)
            instantiate (1:= (restrPermMap Hlt_setbBlock2)).
            (* This goal requires that the injection holds 
                 even after the lock's Cur permission is set 
                 to Writable (in both memories). 
                 This is probably a simple general lemma, about
                 changing Cur memories in two injected memories.
             *)
            subst m_writable_lock_1.
            (*useful? setPermBlock_mem_inject*)
            (* m1|_(lp1 + setPerm) -j->  m2|_(lp2 + setPerm)  *)
            
            (* Construct locks_perm_as_cur*)
            assert (locks_perm_lt1: permMapLt (lock_perms Hcnt1) (getMaxPerm m1')).
            { admit. }
            remember (restrPermMap locks_perm_lt1) as m1'_lock_perms.
            remember (getCurPerm m1'_lock_perms) as locks_perm_as_cur1.
            assert (access_map_equiv locks_perm_as_cur1 (lock_perms Hcnt1)).
            { subst m1'_lock_perms locks_perm_as_cur1; eapply getCur_restr. }

            assert (locks_perm_lt2: permMapLt (lock_perms Hcnt2) (getMaxPerm m2')).
            { admit. }
            remember (restrPermMap locks_perm_lt2) as m2'_lock_perms.
            remember (getCurPerm m2'_lock_perms) as locks_perm_as_cur2.
            assert (access_map_equiv locks_perm_as_cur2 (lock_perms Hcnt2)).
            { subst m2'_lock_perms locks_perm_as_cur2; eapply getCur_restr. }
            
            (* Construct the Hwritable_lock1 using locks_perm_as_cur*)
            assert (Hwritable_lock1':
                      writeable_lock b1 (unsigned ofs) locks_perm_as_cur1 m1').
            { unfold writeable_lock.  rewrite H. assumption. }
            assert (Hlt_setbBlock2':
                      writeable_lock b2 (unsigned ofs+ delt2) locks_perm_as_cur2 m2').
            { unfold writeable_lock.  rewrite H1; assumption. }
                      
            assert (Hwritable_lock1'': writeable_lock b1 (unsigned ofs)
                                                      locks_perm_as_cur1
                                                      m1'_lock_perms).
            { admit. }
            assert (Hwritable_lock2'': writeable_lock b2 (unsigned ofs+ delt2)
                                                      locks_perm_as_cur2
                                                      m2'_lock_perms).
            { admit. }
            
            cut (Mem.inject mu
                            (restrPermMap Hwritable_lock1'')
                            (restrPermMap Hwritable_lock2'')).
            { apply mem_inject_equiv; auto.
              - subst m1'_lock_perms; constructor.
                +
                apply Cur_equiv_restr. auto. rewrite H. reflexivity.
                +
                  
                
                apply Max_equiv_restr. 
                symmetry. apply getMax_restr.
                + do 3 rewrite restr_content_equiv.
                  reflexivity.
                +  reflexivity.
                    
              - subst m2'_lock_perms; constructor.
                + apply Cur_equiv_restr. auto. rewrite H1. reflexivity.
                + apply Max_equiv_restr.
                  symmetry. apply getMax_restr.
                + do 3 rewrite restr_content_equiv.
                  reflexivity.
                + reflexivity.
            }
            
           
            subst locks_perm_as_cur1 locks_perm_as_cur2.
            eapply setPermBlock_mem_inject.
            - admit.
            - do 2 eexists.
              split; eauto. admit.
            - assumption.
            - subst m1'_lock_perms m2'_lock_perms.
              eapply INJ_locks; eauto.
          }

          
          destruct Hstore2 as (m2''& Hstore2 & Hinj2').
          
          remember (add ofs (repr delt2)) as ofs2.
          remember (computeMap (fst (getThreadR Hcnt2)) (fst virtueThread2),
                    computeMap (snd (getThreadR Hcnt2)) (snd virtueThread2)) as new_cur2.
          remember ((updLockSet
                       (updThread Hcnt2 (Kresume (TST code2) Vundef) new_cur2)
                       (b2, unsigned ofs2) virtueLP2)) as st2'.
          
          match goal with
            [|- context[concur_match _ _ ?st1 ?m1 _ _] ] =>
            remember st1 as st1'
          end. 
          
            
          assert (Hcmpt1': mem_compatible(tpool:=OrdinalThreadPool) st1' m1'').
          { 
            eapply mem_compat_Max.
            eapply store_max_equiv.
            eassumption.
            symmetry;
              eapply Mem.nextblock_store; eauto.
            subst m_writable_lock_1.
            eapply (mem_compat_Max _ _ _ m1').
            symmetry. apply restr_Max_equiv.
            reflexivity.
             
            eapply mem_compatible_updLock; eauto.
            - cut (permMapLt_pair virtueLP0  (getMaxPerm m1')).
              { auto. }
              apply (permMapLt_pair_trans211 _ (getThreadR Hcnt1)).
              eapply permMapJoin_lt_pair2. eauto.
              eapply Hcmpt.
            - simpl.
              pose proof (INJ _ _ _ _ _ _ CMatch).
              destruct (mem_lemmas.valid_block_dec m1' b1); auto.
              eapply Mem.mi_freeblocks in n; eauto.
              unify_injection.
            -
              eapply mem_compatible_updthread.
              2: reflexivity.
              fold newThreadPerm1.
              apply (permMapLt_pair_trans211 _ (getThreadR Hcnt1)).
              eapply permMapJoin_lt_pair1. eauto.
              eapply Hcmpt.

            assumption.
            
          }
          assert (H: ThreadPool (Some (S hb)) =
                     @t dryResources (HybridSem (@Some nat (S hb)))).
          { reflexivity. }
          dependent rewrite <- H in st2'. clear H.
          assert (Hcmpt2': mem_compatible st2' m2'').
          {
            admit. (*TODO: from Hcmpt2 *)
          }


          
          eexists.
          exists st2', m2'', (Some i), mu.
          split; [|split].
          
          + eapply Build_concur_match
            ; simpl;
              try assumption;
              try (subst st2' st1'; apply CMatch).
            * !goal (Events.injection_full mu m1'').
              { pose (full_inj _ _ _ _ _ _  CMatch) as Hfull_inj.
                (* Mem.store should preserve Events.injection_full *)
                admit.
              }

            * !context_goal perm_preimage.
              admit.
            * admit. (*inject threads*)
            * admit. (*inject locks*)
            * admit. (*inject lock permission*)
            * admit. (*inject lock content*)
            * admit. (* invariant is preserved! *)
            * admit. (* thread_match source*)
            * admit. (* thread_match target. *)
            * (* thread_match compiled. *)

              intros thread HH Hcnt1_dup Hcnt2_dup.
              subst thread.
              
              subst st1'.
              same_types Hcnt1_dup Hcnt1.
              subst st2'.
              same_types Hcnt2_dup Hcnt2.
              clean_cnt.
              
              intros ? ?.
              
              
              
              match goal with
              | [|- match_thread_compiled _ _ ?X _ ?Y _] =>
                let HH1:= fresh "HH1" in 
                assert (HH1: X = Kresume (SST code1) Vundef)
                  by
                    (simpl; rewrite eqtype.eq_refl; reflexivity);
                  let HH2:= fresh "HH2" in
                  assert (HH2: Y = Kresume (TST code2) Vundef) by
                      (simpl; rewrite eqtype.eq_refl; reflexivity)
                        
              end.
              
              rewrite HH1; clear HH1.
              rewrite HH2; clear HH2.
              
              econstructor.
              intros j'' s1' m1''' m2''' lev1' lev2'.
              intros Hstrict_evolution' (*Hincr'*) Hinterference1' Hinterference2'
                     Hafter_ext.
              assert (Hincr':= evolution_inject_incr _ _ _ _  Hstrict_evolution').
              remember (fst virtueThread1) as dpm1.
              remember (Events.Event_acq_rel lev1 dpm1 lev1' :: nil) as rel_trace.

             
              
              (*
                Prove that this is a CompCert step (en external step).
               *)
              assert (Hstep: Smallstep.step
                               (Clight.part_semantics2 Clight_g)
                               (Clight.set_mem code1 m1)
                               rel_trace
                               (Clight.set_mem s1' m1''')).
              {
                simpl in Hafter_ext. unfold Clight.after_external in Hafter_ext.
                move Hat_external1 at bottom.
                unfold Clight.at_external in Hat_external1.
                destruct code1 eqn:Hcallstate; try discriminate.
                simpl in Hat_external1.
                destruct fd eqn:Hext_func; try discriminate.
                (* inversion Hat_external1; clear Hat_external1; subst. *)
                inversion Hat_external1. subst e args. simpl.
                pose proof (Clight.step_external_function
                              Clight_g (Clight.function_entry2 Clight_g)
                              UNLOCK t0 t1 c (Vptr b1 ofs :: nil) k m1 Vundef
                              rel_trace
                              m1''') as HH.
                assert (Hextcall: Events.external_call
                                    UNLOCK (Clight.genv_genv Clight_g)
                                    (Vptr b1 ofs :: nil) m1
                                    rel_trace
                                    Vundef m1''').
                { simpl.
                  (* This function is given axiomaticall in CompCert. *)
                  
                  rewrite ReleaseExists.
                  subst rel_trace; econstructor.
                  - eassumption.
                  - constructor; auto.
                  - eassumption.
                }
                eapply HH in Hextcall; auto.
                inversion Hafter_ext.
                unfold Clight.step2; auto.
              }

              unfold compiler_match in Hcomp_match.
              eapply (Injsim_simulation_atxX compiler_sim) in Hstep; simpl in *; eauto.
              specialize (Hstep _ _ _ Hcomp_match).
              destruct Hstep as (j2'&Hincr&Hstep_str&Hstep).
              
              fail "Transfer into the lemma until here.".
              
              destruct Hstep_str as
                  (i2_str&s2_str&t_str&Hstep_str&Hmatch_str&Hinj_trace_str).
              remember 
                (Events.Event_acq_rel lev2 (fst virtueThread2) lev2' :: nil)  as rel_trace2.
              assert (Htrace_str : exists lev2_str dpm_str lev2_str',
                         t_str =
                         Events.Event_acq_rel lev2_str
                                              dpm_str
                                              lev2_str' :: nil).
              { subst. inversion Hinj_trace_str; subst.
                inversion H4; subst.
                inversion H2; subst.
                do 3 eexists. f_equal.
              }
              destruct Htrace_str as (lev2_str&dpm_str&lev2_str'&Htrace_str).

              assert (Hconsecutive:
                        consecutive (Mem.nextblock m2) lev2).
              { eapply interference_consecutive; eassumption.
              }

              assert (Hconsecutive': consecutive (Mem.nextblock m2'') lev2').
              { erewrite <- restrPermMap_nextblock.
                eapply interference_consecutive; eassumption.
              }

              (** *Left Diagrams *)
              pose proof (principled_diagram_exists
                            _ _ _ _ _
                            Hstrict_evolution Hconsecutive) as
                  Pdiagram.
              destruct Pdiagram as (lev20&Hprincipled&Hlessdef).
              assert (Hdiagram: diagram (Mem.nextblock m2) j j2' lev1 lev2_str).
              { econstructor.
                - eauto.
                - subst rel_trace t_str;
                    inversion Hinj_trace_str; subst.
                  inversion H3; subst. auto.
                  Lemma list_inject_weaken: 
                    forall j lev1 lev2,
                      Events.list_inject_mem_effect_strong j lev1 lev2 ->
                      Events.list_inject_mem_effect j lev1 lev2.
                  Proof.
                    intros. inversion H; subst; constructor.
                    -
                  Admitted.

                  eapply list_inject_weaken; auto.
                - Lemma Asm_step_consecutive:
                    forall ge st m t st',
                    Asm.step ge (Asm.set_mem st m) t st' ->
                    forall lev dpm lev' t',
                      t = Events.Event_acq_rel lev dpm lev' :: t' ->
                      consecutive (Mem.nextblock m) lev.
                  Admitted.
                  eapply Asm_step_consecutive; eassumption.
              }
              destruct (principled_diagram_correct
                          _ _ _ _ _ _ _ Hprincipled Hdiagram)
                as (Hincr_mu & lessdef_str).

              (** *Right Diagrams*)
              pose proof (principled_diagram_exists
                            _ _ _ _ _
                            Hstrict_evolution' Hconsecutive') as
                  Pdiagram'.
              destruct Pdiagram' as (lev20'&Hprincipled'&Hlessdef').

              
              assert (Hdiagram':
                        diagram (Mem.nextblock m2'') mu j2' lev1' lev2_str').
              { econstructor.
                - eauto.
                - subst rel_trace t_str;
                    inversion Hinj_trace_str; subst.
                  inversion H3; subst. 
                  eapply list_inject_weaken; auto.
                - (* Go back and do that with *)
                  admit. (* follows from the syntax. *)
              }
              destruct (principled_diagram_correct
                          _ _ _ _ _ _ _ Hprincipled' Hdiagram')
                as (Hincr_mu_j2' & lessdef_str').
              
              
              assert (Hinj_trace: Events.inject_trace j2' rel_trace rel_trace2).
              { subst rel_trace rel_trace2.
                econstructor; try solve[constructor].
                econstructor; try eassumption.
                - emonotonicity; eauto.
                  emonotonicity; eauto.
                  eapply evolution_list_inject_mem; eauto.
                - emonotonicity; eauto.
                  subst dpm1. admit. (* proof constructions correct*)
                - emonotonicity; eauto.
                  eapply evolution_list_inject_mem in Hstrict_evolution'; eauto.
              }
              
              destruct  (Hstep _ Hinj_trace)
                as (cd' & s2' & step & comp_match ).


              (* We prove that code2 must do an external step. *)
              (* Note: no need for a { here. 
                 TODO: better formating *)
              { move Hat_external2' at bottom.
                unfold Asm.at_external in Hat_external2'.
                destruct code2 eqn:Code.
                simpl in Hat_external2'.
                destruct (r Asm.PC) eqn:rPC; try discriminate.
                destruct (eq_dec i0 zero) eqn:i0_0; try discriminate.
                unfold Asm_g.
                destruct (Genv.find_funct_ptr the_ge b) eqn:func_lookup; try discriminate.
                destruct f; try discriminate.
                
                
                inversion step; subst; try solve[inversion H5] .
                - rewrite rPC in H2; inversion H2; subst.
                  unfold the_ge in func_lookup.
                  rewrite func_lookup in H3.
                  inversion H3; discriminate.
                (*  - rewrite rPC in H2; inversion H2; subst.
                    unfold the_ge in func_lookup.
                    rewrite func_lookup in H3.
                    inversion H3 discriminate. *)
                - rename m' into m21'''.
                  (* NOTE: 
                       - the s2' (i.e. target state) in comp_match, 
                       results from inverting the step.
                       - the st'2 (i.e. target state) in the goal,
                       results from Asm.after_external. 
                   *)
                  unfold Asm.after_external.
                  unfold Asm.after_external_regset.
                  rewrite rPC, i0_0, func_lookup.
                  (* Show that target program is executing the same function*)
                  assert (FUNeq:e0 = ef ).
                  { assert (BB0: b0 = b)
                      by (rewrite rPC in H2; inversion H2; reflexivity).
                    subst b0. unfold the_ge in func_lookup.
                    rewrite func_lookup in H3; inversion H3.
                    reflexivity.
                  } subst e0.
                  
                  (* Show that the function is UNLOCK*)
                  match type of Hat_external2' with
                  | match ?x with _ => _ end = _ =>
                    destruct x eqn:HH; try discriminate
                  end.

                  inversion Hat_external2'. subst.
                  do 3 eexists; repeat split; eauto.
                  unfold compiler_match.
                  move comp_match at bottom.
                  simpl.
                  
                  instantiate(1:=cd').
                  replace (Clight.set_mem s1' (Clight.get_mem s1')) with s1'
                    by (destruct s1'; reflexivity).
                  simpl in comp_match.
                  
                  (*This should be generalizable*)
                  unfold Asm.loc_external_result,Conventions1.loc_result in comp_match.
                  replace Archi.ptr64 with false in comp_match by reflexivity. 
                  simpl in comp_match.
                  
                  assert (Hres: res = Vundef).
                  { unfold Events.external_call in *.
                    rewrite ReleaseExists in H5.
                    inversion H5. reflexivity.
                  }
                  subst res.
                  (* Here *)
                  replace m2''' with m21'''. auto.
                  
                  (*  m21''' = m2''' *)
                  simpl in H5.
                  rewrite ReleaseExists in H5.
                  inversion H5; subst.
                  rename m' into m21'.
                  rename m'' into m21''.
                  rename H10 into Hinterference21.
                  rename H11 into Hrelease.
                  
                  move Hinterference2' at bottom.

                  (*
                     m1 -lev1-> m1' -dpm-> m1'' -lev1'-> m1'''
                     |          |         |            |
                     |          |         |            |
                     m2 -lev2-> m2' -dpm-> m2'' -lev2'-> m2'''
                     !          !         !            !     
                     m2 -lev2-> m21'-dpm-> m21''-lev2'-> m21'''
                   *)
                  
                  assert (m21' =
                          (restrPermMap (proj1 ((memcompat2 CMatch) hb Hcnt2)))).
                  { move Hinterference2 at bottom.
                    move Hinterference21 at bottom.
                    eapply mem_interference_determ. eassumption.
                    repeat clean_proofs.
                    erewrite restr_proof_irr; eauto.
                  }
                  
                  assert (m21'' = (restrPermMap (proj1 (Hcmpt2' hb Hcnt2)))).
                  { move Hstore2 at bottom.
                    move Hrelease at bottom.
                    admit.
                  (* Sketch: release has to be defined.
                          it should modify content without touching permissions.
                          then show: 
                          m2' -release-> m2''
                          (or their restrictions to the cur)
                          release is deterministic and so the result follows. *)
                  }
                  (*  m21''' = m2''' *)
                  eapply mem_interference_determ; subst; try eassumption.
                  erewrite restr_proof_irr; eauto.
              }
              
          + eapply List.Forall2_app.
            * eauto.
            * econstructor; try solve[constructor].
              simpl.
              econstructor.
              admit.
          (* injection of the event*)
          (* Should be obvious by construction *)
          + (* HybridMachineSig.external_step *)

            econstructor; eauto.
            eapply step_release with
                (b:= b2)
                (virtueThread:=virtueThread2)
                (virtueLP:=virtueLP2);
              eauto; try reflexivity;
                try unfold HybridMachineSig.isCoarse,
                HybridMachineSig.HybridCoarseMachine.scheduler.
            rename m2' into MMM.
            rename m2 into MMM2.
            
            * (* bounded_maps.sub_map *)
              
              subst virtueThread2.
              unfold virtueThread_inject.
              destruct virtueThread1 as (virtue11, virtue12).
              cbv iota beta delta[fst] in *.
              destruct Hangel_bound as [Hbounded HboundedLP].
              destruct Hbounded as [Hbound1 Hbound2].
              split.
              -- eapply inject_virtue_sub_map.
                 eapply CMatch.
                 rewrite <- HeqvirtueThread1 in Hbound1. 
                 eassumption.
              -- eapply inject_virtue_sub_map.
                 eapply CMatch. 
                 rewrite <- HeqvirtueThread1 in Hbound2. 
                 eassumption.
                 
                 
            * (* bounded_maps.sub_map *)
              
              destruct Hangel_bound as [Hbounded HboundedLP].
              destruct HboundedLP as (?&?&Hbound).
              move Hbound at bottom.
              rewrite HeqvirtueLP2; simpl.
              
              eapply (proj1 (Logic.and_assoc _ _ _)).
              split.

              (*Easy ones: the default is trivial:
                  bounded_maps.map_empty_def
               *)
              subst virtueLP2.
              unfold virtueLP_inject,
              bounded_maps.map_empty_def, access_map_injected;
                simpl.
              split; 
              (rewrite HeqvirtueLP1; auto).

              assert (HboundedLP':
                        bounded_maps.sub_map (snd (fst virtueLP1)) (snd (getMaxPerm m1')) /\
                        bounded_maps.sub_map (snd (snd virtueLP1)) (snd (getMaxPerm m1'))
                     ) by (rewrite HeqvirtueLP1; eassumption).
              
              
              subst virtueLP2.
              destruct virtueLP1 as (virtueLP_fst, virtueLP_snd).
              revert HboundedLP'.
              unfold virtueLP_inject, access_map_injected.
              simpl (fst _).
              simpl (snd _) at 3 6 9.
              

              (* eapply self_simulation.minject in matchmem. *)
              intros (Hl & Hr); split;
                eapply inject_virtue_sub_map;
                try eapply CMatch; eauto.

              
            * (*invariant st4 *)
              !goal (invariant _).
              admit.

              
            * (* at_external for code 4. *)
              simpl in *; eassumption.
              
            * (* Mem.range_perm *)
              (* Can read the lock *)
              admit.

            * (* The load. *)
              admit.
              
            * (* the store *)
              admit.

            * (* content of lockres*)
              (* ThreadPool.lockRes st4 (b4', ofs4') *)
              (* NOTE: why is it rmap? It should be an injection of rmap 
                   ANSWER: the 'RMAP' is empty, so its injection is also empty... 
               *)
              
              admit.

            * eapply empty_map_useful; eauto. 
            * (* permissions join FST*)
              admit.
              
            * (* permissions join SND *)
              admit.
              
            * admit. (* Wrong machine state *)   
            
          Qed. (*End of release_step_diagram_compiled  *)
          
          remember (virtueThread_inject m2' mu virtueThread1)  as virtueThread2.
          remember (virtueLP_inject m2' mu virtueLP1) as virtueLP2.
          
          simpl in Hat_external1.
          assert (Hat_external1': Smallstep.at_external
                                    (Smallstep.part_sem (Clight.semantics2 C_program))
                                    (Clight.set_mem code1 m1) = Some (UNLOCK, Vptr b1 ofs :: nil)).
          { (* This follows from self simulation:
                   interferences, preserves at_external.
             *)
            (* Things we know *)
            (* th_mem1 =  (m1')|(thread_perms Hcnt1)   *)
            (*
              m1 --lev1--> (m1')|(thread_perms Hcnt1)
             *)
            replace (restrPermMap Hlt1) with th_mem1 in Hinterference1
              by apply restr_proof_irr.
            (*The hard part here is to prove the injection of the old memories... 
              but maybe I have that?
             *)
            (* Definition that defines memoryes 
               that are equal in all visible locations.

               Can be define generically or by using mem_interference.
               (using memn_interference is more restrictive, but 
               might be enough.)
             *)

            Definition same_visible: mem -> mem -> Prop.
            Admitted.
            Lemma interference_same_visible:
              forall m m' lev, mem_interference m lev m' ->
              same_visible m m'.
            Admitted.

            (* this lemma should be included in the self simulation. *)
            Lemma same_visible_at_external:
              forall C (sem: semantics.CoreSemantics C mem), 
                self_simulation _ sem ->
                forall c m m' f_and_args, 
                  semantics.at_external sem c m = Some f_and_args->
                  semantics.at_external sem c m' = Some f_and_args.
            Admitted.

            exploit same_visible_at_external.
            - exact Cself_simulation.
            - apply Hat_external1.
            - simpl; eauto. 
          }
          assert (H: exists b2 delt2,
                     mu b1 = Some (b2, delt2) /\
                     j b1 = Some (b2, delt2) /\
                     semantics.at_external CoreAsmSem (code2) m2 =
                     Some (UNLOCK, Vptr b2 (add ofs (repr delt2)) :: nil)
                 ).
          {
            pose proof (Injsim_atxX compiler_sim _ _ _ _ Hcomp_match Hat_external1')
              as Hatx.
            destruct Hatx as (args' & Hat_external2 & list_inj).
            inversion list_inj; subst.
            inversion H2; inversion H4; subst.
            exists b2, delta; repeat (split; auto).
            eapply evolution_inject_incr; eassumption.
          }
          destruct H as (b2&delt2&Hinj_b2&Hinj_b2'&Hat_external2).
          assert (Hat_external2': 
                    semantics.at_external CoreAsmSem code2
                      (restrPermMap (proj1 (Hcmpt2 hb (contains12 CMatch Hcnt1)))) =
                    Some (UNLOCK, Vptr b2 (add ofs (repr delt2)) :: nil)
                         
                 ).

          { (* This follows from self simulation:
                 interferences, preserves at_external.
             *)
            
            exploit same_visible_at_external.
            - exact Aself_simulation.
            - apply Hat_external2.
            - simpl; eauto. 

          }

          
          assert (Hlt_setbBlock2: permMapLt
                           (setPermBlock (Some Writable) b2 (unsigned ofs + delt2)
                                         (snd (getThreadR Hcnt2)) LKSIZE_nat) 
                           (getMaxPerm m2')).
          { move Hinj2 at bottom.
            exploit (@compat_th _ _  _ _ Hcmpt2 hb ltac:((simpl; auto)));
              simpl; intros [? ?].

            Definition permMapLt_range (perms:access_map) b lo hi p:=
              forall ofs : Z, lo <= ofs < hi ->
                         Mem.perm_order'' (perms !! b ofs) p.

            (*Lookup : 
                setPermBlock_range_perm  *)
              Lemma permMapLt_setPermBlock:
              forall perm1 perm2 op b ofs sz,
              permMapLt_range perm2 b ofs (ofs + Z.of_nat sz) op  ->
              permMapLt perm1 perm2 ->
              permMapLt (setPermBlock op b ofs perm1 sz) perm2.
              Proof. Admitted.

              eapply permMapLt_setPermBlock; eauto.

              Lemma mem_compatible_lock_writable:
                (* This might need to be included into mem_compatible.
                   That would break many things, but all those things should be
                   easy to fix.
                 *)
                forall {sem TP} tp m,
                  @mem_compatible sem TP tp m ->
                  forall (l : Address.address) (rmap : lock_info),
                    ThreadPool.lockRes tp l = Some rmap ->
                    permMapLt_range (getMaxPerm m) (fst l) (snd l)
                                    ((snd l) + LKSIZE) (Some Writable).
              Proof.
              Admitted.
              intros ??.
              exploit (mem_compatible_lock_writable _ _ Hcmpt2 (b2,unsigned ofs + delt2));
                simpl; eauto.
            - exploit INJ_lock_permissions; eauto.
              intros HH; rewrite <- HH.
              repeat f_equal.
              { (* Make this a lemma? *) 
                symmetry.
                unfold add.
                (* eapply Mem.address_inject; eauto; simpl.
                match goal with
                  |- Mem.perm ?m _ _ _ _ =>
                  replace m with m1 end.
                2: destruct code1; auto.
                instantiate(2:=b1).
                2:instantiate(1:=b2). *)
                Lemma address_inject_max:
                  forall f m1 m2 b1 ofs1 b2 delta p,
                    Mem.inject f m1 m2 ->
                    Mem.perm m1 b1 (Ptrofs.unsigned ofs1) Max p ->
                    f b1 = Some (b2, delta) ->
                    unsigned (add ofs1 (Ptrofs.repr delta)) =
                    unsigned ofs1 + delta.
                Proof.
                  intros.
                  assert (Mem.perm m1 b1 (Ptrofs.unsigned ofs1) Max Nonempty)
                    by eauto with mem.
                  exploit Mem.mi_representable; eauto. intros [A B].
                  assert (0 <= delta <= Ptrofs.max_unsigned).
                  generalize (Ptrofs.unsigned_range ofs1). omega.
                  unfold Ptrofs.add. repeat rewrite Ptrofs.unsigned_repr; omega.
                Qed.
                eapply address_inject_max; try apply Hinj2; eauto.
                match goal with
                  |- Mem.perm ?m _ _ _ _ =>
                  replace m with m1 by (destruct code1; auto)
                end.
                unfold Mem.perm.
                rewrite_getPerm.
                clear - Hwritable_lock1.
                move Hwritable_lock1 at bottom.
                unfold writeable_lock in Hwritable_lock1.
                admit. }
          }
          
          
          (* build m2' *)
          assert (Hstore2:=Hstore1).
          eapply (Mem.store_mapped_inject mu) in Hstore2; eauto.
          2: {
            (* TODO : Clean this admits here and all useless definitions *)
            instantiate (1:= (restrPermMap Hlt_setbBlock2)).
            (* This goal requires that the injection holds 
                 even after the lock's Cur permission is set 
                 to Writable (in both memories). 
                 This is probably a simple general lemma, about
                 changing Cur memories in two injected memories.
             *)
            subst m_writable_lock_1.
            (*useful? setPermBlock_mem_inject*)
            (* m1|_(lp1 + setPerm) -j->  m2|_(lp2 + setPerm)  *)
            
            (* Construct locks_perm_as_cur*)
            assert (locks_perm_lt1: permMapLt (lock_perms Hcnt1) (getMaxPerm m1')).
            { admit. }
            remember (restrPermMap locks_perm_lt1) as m1'_lock_perms.
            remember (getCurPerm m1'_lock_perms) as locks_perm_as_cur1.
            assert (access_map_equiv locks_perm_as_cur1 (lock_perms Hcnt1)).
            { subst m1'_lock_perms locks_perm_as_cur1; eapply getCur_restr. }

            assert (locks_perm_lt2: permMapLt (lock_perms Hcnt2) (getMaxPerm m2')).
            { admit. }
            remember (restrPermMap locks_perm_lt2) as m2'_lock_perms.
            remember (getCurPerm m2'_lock_perms) as locks_perm_as_cur2.
            assert (access_map_equiv locks_perm_as_cur2 (lock_perms Hcnt2)).
            { subst m2'_lock_perms locks_perm_as_cur2; eapply getCur_restr. }
            
            (* Construct the Hwritable_lock1 using locks_perm_as_cur*)
            assert (Hwritable_lock1':
                      writeable_lock b1 (unsigned ofs) locks_perm_as_cur1 m1').
            { unfold writeable_lock.  rewrite H. assumption. }
            assert (Hlt_setbBlock2':
                      writeable_lock b2 (unsigned ofs+ delt2) locks_perm_as_cur2 m2').
            { unfold writeable_lock.  rewrite H1; assumption. }

            assert (Hwritable_lock1'': writeable_lock b1 (unsigned ofs)
                                                      locks_perm_as_cur1
                                                      m1'_lock_perms).
            { admit. }
            assert (Hwritable_lock2'': writeable_lock b2 (unsigned ofs+ delt2)
                                                      locks_perm_as_cur2
                                                      m2'_lock_perms).
            { admit. }
            
            cut (Mem.inject mu
                            (restrPermMap Hwritable_lock1'')
                            (restrPermMap Hwritable_lock2'')).
            { apply mem_inject_equiv; auto.
              - subst m1'_lock_perms; constructor.
                +
                Lemma Cur_equiv_restr:
                  forall p1 p2 m1 m2 Hlt1 Hlt2,
                    access_map_equiv p1 p2 ->
                    Cur_equiv (@restrPermMap p1 m1 Hlt1)
                              (@restrPermMap p2 m2 Hlt2).
                Proof. unfold Cur_equiv; intros.
                       do 2 rewrite getCur_restr; assumption. Qed.
                apply Cur_equiv_restr. auto. rewrite H. reflexivity.
                +
                  
                Lemma Max_equiv_restr:
                  forall p1 p2 m1 m2 Hlt1 Hlt2,
                    Max_equiv m1 m2 ->
                    Max_equiv (@restrPermMap p1 m1 Hlt1)
                              (@restrPermMap p2 m2 Hlt2).
                Proof. unfold Max_equiv; intros.
                       do 2 rewrite getMax_restr; assumption. Qed.
                apply Max_equiv_restr. 
                symmetry. apply getMax_restr.
                + do 3 rewrite restr_content_equiv.
                  reflexivity.
                +  reflexivity.
                    
              - subst m2'_lock_perms; constructor.
                + apply Cur_equiv_restr. auto. rewrite H1. reflexivity.
                + apply Max_equiv_restr.
                  symmetry. apply getMax_restr.
                + do 3 rewrite restr_content_equiv.
                  reflexivity.
                + reflexivity.
            }
            
           
            subst locks_perm_as_cur1 locks_perm_as_cur2.
            eapply setPermBlock_mem_inject.
            - admit.
            - do 2 eexists.
              split; eauto. admit.
            - assumption.
            - subst m1'_lock_perms m2'_lock_perms.
              eapply INJ_locks; eauto.
          }

          
          destruct Hstore2 as (m2''& Hstore2 & Hinj2').
          
          remember (add ofs (repr delt2)) as ofs2.
          remember (computeMap (fst (getThreadR Hcnt2)) (fst virtueThread2),
                    computeMap (snd (getThreadR Hcnt2)) (snd virtueThread2)) as new_cur2.
          remember ((updLockSet
                       (updThread Hcnt2 (Kresume (TST code2) Vundef) new_cur2)
                       (b2, unsigned ofs2) virtueLP2)) as st2'.
          
          match goal with
            [|- context[concur_match _ _ ?st1 ?m1 _ _] ] =>
            remember st1 as st1'
          end. 

          assert (Hcmpt1': mem_compatible(tpool:=OrdinalThreadPool) st1' m1'').
          { 
            Lemma mem_compat_Max:
              forall Sem Tp st m m',
                Max_equiv m m' ->
                Mem.nextblock m = Mem.nextblock m' ->
              @mem_compatible Sem Tp st m ->
              @mem_compatible Sem Tp st m'.
            Proof.
              intros * Hmax Hnb H.
              assert (Hmax':access_map_equiv (getMaxPerm m) (getMaxPerm m'))
                by eapply Hmax.
              constructor; intros;
                repeat rewrite <- Hmax';
                try eapply H; eauto.
              unfold Mem.valid_block; rewrite <- Hnb;
                eapply H; eauto.
            Qed.
            eapply mem_compat_Max.
            Lemma store_max_equiv:
              forall sz m b ofs v m',
                Mem.store sz m b ofs v = Some m' ->
                Max_equiv m m'.
            Proof.
              intros. intros ?.
              extensionality ofs'.
              eapply memory_lemmas.MemoryLemmas.mem_store_max.
              eassumption.
            Qed.
            eapply store_max_equiv.
            eassumption.
            symmetry;
              eapply Mem.nextblock_store; eauto.
            subst m_writable_lock_1.
            eapply (mem_compat_Max _ _ _ m1').
            symmetry. apply restr_Max_equiv.
            reflexivity.
            Lemma mem_compatible_updLock:
              forall Sem Tp m st st' l lock_info,
                permMapLt_pair lock_info (getMaxPerm m) ->
                Mem.valid_block m (fst l) ->
              st' = ThreadPool.updLockSet(resources:=dryResources) st l lock_info ->
              @mem_compatible Sem Tp st m ->
              @mem_compatible Sem Tp st' m.
            Proof.
              intros * Hlt Hvalid HH Hcmpt.
              subst st'; constructor; intros.
              - erewrite ThreadPool.gLockSetRes. apply Hcmpt.
              - (*Two cases, one of which goes by Hlt*)
                admit.
              - (*Two cases, one of which goes by Hvalid*)
                admit.
            Admitted.
            eapply mem_compatible_updLock; eauto.
            - cut (permMapLt_pair virtueLP0  (getMaxPerm m1')).
              { auto. }
              apply (permMapLt_pair_trans211 _ (getThreadR Hcnt1)).
              eapply permMapJoin_lt_pair2. eauto.
              eapply Hcmpt.
            - simpl.
              pose proof (INJ _ _ _ _ _ _ CMatch).
              destruct (mem_lemmas.valid_block_dec m1' b1); auto.
              eapply Mem.mi_freeblocks in n; eauto.
              unify_injection.
            - Lemma mem_compatible_updthread:
              forall Sem Tp m st st' i (cnt:ThreadPool.containsThread st i) c res,
              permMapLt_pair res (getMaxPerm m) ->
              st' = ThreadPool.updThread(resources:=dryResources) cnt c res ->
              @mem_compatible Sem Tp st m ->
              @mem_compatible Sem Tp st' m.
            Proof.
              intros * Hlt HH Hcmpt.
              subst st'; constructor; intros.
              - (*Two cases, one of which goes by Hlt*)
                admit.
              - rewrite ThreadPool.gsoThreadLPool in H.
                eapply Hcmpt; eassumption.
              -  rewrite ThreadPool.gsoThreadLPool in H.
                 eapply Hcmpt; eassumption.
            Admitted.
            eapply mem_compatible_updthread.
            2: reflexivity.
            subst virtueThread0.
            fold newThreadPerm1.
            apply (permMapLt_pair_trans211 _ (getThreadR Hcnt1)).
            eapply permMapJoin_lt_pair1. eauto.
            eapply Hcmpt.

            assumption.
            
          }
          assert (H: ThreadPool (Some (S hb)) =
                     @t dryResources (HybridSem (@Some nat (S hb)))).
          { reflexivity. }
          dependent rewrite <- H in st2'. clear H.
          assert (Hcmpt2': mem_compatible st2' m2'').
          {
            admit. (*TODO: from Hcmpt2 *)
          }


          
          eexists.
          exists st2', m2'', (Some i), mu.
          split; [|split].
          
          + eapply Build_concur_match
            ; simpl;
              try assumption;
              try (subst st2' st1'; apply CMatch).
            * !goal (Events.injection_full mu m1'').
              { pose (full_inj _ _ _ _ _ _  CMatch) as Hfull_inj.
                (* Mem.store should preserve Events.injection_full *)
                admit.
              }

            * !context_goal perm_preimage.
              admit.
            * admit. (*inject threads*)
            * admit. (*inject locks*)
            * admit. (*inject lock permission*)
            * admit. (*inject lock content*)
            * admit. (* invariant is preserved! *)
            * admit. (* thread_match source*)
            * admit. (* thread_match target. *)
            * (* thread_match compiled. *)

              intros thread HH Hcnt1_dup Hcnt2_dup.
              subst thread.
              
              Ltac same_types H1 H2:=
                match type of H1 with
                | ?T1 =>
                  match type of H2 with
                  | ?T2 =>
                    let HH:=fresh "HH" in 
                    assert (HH:T1 = T2) by reflexivity;
                    try (dependent rewrite HH in H1;
                         clear HH)
                  end
                end.
              subst st1'.
              same_types Hcnt1_dup Hcnt1.
              subst st2'.
              same_types Hcnt2_dup Hcnt2.
              clean_cnt.
              
              intros ? ?.

              match goal with
              | [|- match_thread_compiled _ _ ?X _ ?Y _] =>
                let HH1:= fresh "HH1" in 
                assert (HH1: X = Kresume (SST code1) Vundef)
                  by
                    (simpl; rewrite eqtype.eq_refl; reflexivity);
                  let HH2:= fresh "HH2" in
                  assert (HH2: Y = Kresume (TST code2) Vundef) by
                      (simpl; rewrite eqtype.eq_refl; reflexivity)
                        
              end.
              
              rewrite HH1; clear HH1.
              rewrite HH2; clear HH2.
              
              econstructor.
              intros j'' s1' m1''' m2''' lev1' lev2'.
              intros Hstrict_evolution' (*Hincr'*) Hinterference1' Hinterference2'
                     Hafter_ext.
              assert (Hincr':= evolution_inject_incr _ _ _ _  Hstrict_evolution').
              remember (fst virtueThread1) as dpm1.
              remember (Events.Event_acq_rel lev1 dpm1 lev1' :: nil) as rel_trace.
              
              (*
                Prove that this is a CompCert step (en external step).
               *)
              assert (Hstep: Smallstep.step
                               (Clight.part_semantics2 Clight_g)
                               (Clight.set_mem code1 m1)
                               rel_trace
                               (Clight.set_mem s1' m1''')).
              {
                simpl in Hafter_ext. unfold Clight.after_external in Hafter_ext.
                move Hat_external1 at bottom.
                unfold Clight.at_external in Hat_external1.
                destruct code1 eqn:Hcallstate; try discriminate.
                simpl in Hat_external1.
                destruct fd eqn:Hext_func; try discriminate.
                (* inversion Hat_external1; clear Hat_external1; subst. *)
                inversion Hat_external1. subst e args. simpl.
                pose proof (Clight.step_external_function
                              Clight_g (Clight.function_entry2 Clight_g)
                              UNLOCK t0 t1 c (Vptr b1 ofs :: nil) k m1 Vundef
                              rel_trace
                              m1''') as HH.
                assert (Hextcall: Events.external_call
                                    UNLOCK (Clight.genv_genv Clight_g)
                                    (Vptr b1 ofs :: nil) m1
                                    rel_trace
                                    Vundef m1''').
                { simpl.
                  Inductive release: val -> mem -> delta_perm_map ->  mem -> Prop  :=
                  | ReleaseAngel:
                      forall b ofs m dpm m',
                        True ->
                        (* This shall codify, the change in permissions
                       and changing the  lock value to 1.
                         *)
                        release (Vptr b ofs) m dpm m'.

                  Inductive extcall_release: Events.extcall_sem:=
                  | ExtCallRelease:
                      forall ge m m' m'' m''' b ofs e dpm e',
                        mem_interference m e m' ->
                        release (Vptr b ofs) m' dpm m'' ->
                        mem_interference m'' e' m''' ->
                        extcall_release ge (Vptr b ofs :: nil) m
                                        (Events.Event_acq_rel e dpm e' :: nil)
                                        Vundef m'''.
                  Lemma extcall_properties_release:
                    Events.extcall_properties extcall_release UNLOCK_SIG.
                  Proof.
                  (* this is given axiomatically in compcert, 
                     but we must prove it*)
                  Admitted.
                  
                  Axiom ReleaseExists:
                    forall ge args m ev r m',
                      Events.external_functions_sem "release" UNLOCK_SIG
                                                    ge args m ev r m' =
                      extcall_release ge args m ev r m'.
                  (* This function is given axiomaticall in CompCert. *)
                  
                  rewrite ReleaseExists.
                  subst rel_trace; econstructor.
                  - eassumption.
                  - constructor; auto.
                  - eassumption.
                }
                eapply HH in Hextcall; auto.
                inversion Hafter_ext.
                unfold Clight.step2; auto.
              }

              unfold compiler_match in Hcomp_match.
              eapply (Injsim_simulation_atxX compiler_sim) in Hstep; simpl in *; eauto.
              specialize (Hstep _ _ _ Hcomp_match).
              destruct Hstep as (j2'&Hincr&Hstep_str&Hstep).
              destruct Hstep_str as
                  (i2_str&s2_str&t_str&Hstep_str&Hmatch_str&Hinj_trace_str).
              remember 
                (Events.Event_acq_rel lev2 (fst virtueThread2) lev2' :: nil)  as rel_trace2.
              assert (Htrace_str : exists lev2_str dpm_str lev2_str',
                         t_str =
                         Events.Event_acq_rel lev2_str
                                              dpm_str
                                              lev2_str' :: nil).
              { subst. inversion Hinj_trace_str; subst.
                inversion H4; subst.
                inversion H2; subst.
                do 3 eexists. f_equal.
              }
              destruct Htrace_str as (lev2_str&dpm_str&lev2_str'&Htrace_str).

              assert (Hconsecutive:
                        consecutive (Mem.nextblock m2) lev2).
              { Lemma interference_consecutive: forall m lev m',
                  mem_interference m lev m' ->
                  consecutive (Mem.nextblock m) lev.
                Proof.
                  intros. induction lev; try econstructor.
                Admitted.

                eapply interference_consecutive; eassumption.
              }

              assert (Hconsecutive': consecutive (Mem.nextblock m2'') lev2').
              { erewrite <- restrPermMap_nextblock.
                eapply interference_consecutive; eassumption.
              }

              (** *Left Diagrams *)
              pose proof (principled_diagram_exists
                            _ _ _ _ _
                            Hstrict_evolution Hconsecutive) as
                  Pdiagram.
              destruct Pdiagram as (lev20&Hprincipled&Hlessdef).
              assert (Hdiagram: diagram (Mem.nextblock m2) j j2' lev1 lev2_str).
              { econstructor.
                - eauto.
                - subst rel_trace t_str;
                    inversion Hinj_trace_str; subst.
                  inversion H3; subst. auto.
                  Lemma list_inject_weaken: 
                    forall j lev1 lev2,
                      Events.list_inject_mem_effect_strong j lev1 lev2 ->
                      Events.list_inject_mem_effect j lev1 lev2.
                  Proof.
                    intros. inversion H; subst; constructor.
                    -
                  Admitted.

                  eapply list_inject_weaken; auto.
                - Lemma Asm_step_consecutive:
                    forall ge st m t st',
                    Asm.step ge (Asm.set_mem st m) t st' ->
                    forall lev dpm lev' t',
                      t = Events.Event_acq_rel lev dpm lev' :: t' ->
                      consecutive (Mem.nextblock m) lev.
                  Admitted.
                  eapply Asm_step_consecutive; eassumption.
              }
              destruct (principled_diagram_correct
                          _ _ _ _ _ _ _ Hprincipled Hdiagram)
                as (Hincr_mu & lessdef_str).

              (** *Right Diagrams*)
              pose proof (principled_diagram_exists
                            _ _ _ _ _
                            Hstrict_evolution' Hconsecutive') as
                  Pdiagram'.
              destruct Pdiagram' as (lev20'&Hprincipled'&Hlessdef').

              
              assert (Hdiagram':
                        diagram (Mem.nextblock m2'') mu j2' lev1' lev2_str').
              { econstructor.
                - eauto.
                - subst rel_trace t_str;
                    inversion Hinj_trace_str; subst.
                  inversion H3; subst. 
                  eapply list_inject_weaken; auto.
                - (* Go back and do that with *)
                  admit. (* follows from the syntax. *)
              }
              destruct (principled_diagram_correct
                          _ _ _ _ _ _ _ Hprincipled' Hdiagram')
                as (Hincr_mu_j2' & lessdef_str').
              
              
              assert (Hinj_trace: Events.inject_trace j2' rel_trace rel_trace2).
              { subst rel_trace rel_trace2.
                econstructor; try solve[constructor].
                econstructor; try eassumption.
                - emonotonicity; eauto.
                  emonotonicity; eauto.
                  eapply evolution_list_inject_mem; eauto.
                - emonotonicity; eauto.
                  subst dpm1. admit. (* proof constructions correct*)
                - emonotonicity; eauto.
                  eapply evolution_list_inject_mem in Hstrict_evolution'; eauto.
              }
              
              destruct  (Hstep _ Hinj_trace)
                as (cd' & s2' & step & comp_match ).


              (* We prove that code2 must do an external step. *)
              (* Note: no need for a { here. 
                 TODO: better formating *)
              { move Hat_external2' at bottom.
                unfold Asm.at_external in Hat_external2'.
                destruct code2 eqn:Code.
                simpl in Hat_external2'.
                destruct (r Asm.PC) eqn:rPC; try discriminate.
                destruct (eq_dec i0 zero) eqn:i0_0; try discriminate.
                unfold Asm_g.
                destruct (Genv.find_funct_ptr the_ge b) eqn:func_lookup; try discriminate.
                destruct f; try discriminate.
                
                
                inversion step; subst; try solve[inversion H5] .
                - rewrite rPC in H2; inversion H2; subst.
                  unfold the_ge in func_lookup.
                  rewrite func_lookup in H3.
                  inversion H3; discriminate.
                (*  - rewrite rPC in H2; inversion H2; subst.
                    unfold the_ge in func_lookup.
                    rewrite func_lookup in H3.
                    inversion H3 discriminate. *)
                - rename m' into m21'''.
                  (* NOTE: 
                       - the s2' (i.e. target state) in comp_match, 
                       results from inverting the step.
                       - the st'2 (i.e. target state) in the goal,
                       results from Asm.after_external. 
                   *)
                  unfold Asm.after_external.
                  unfold Asm.after_external_regset.
                  rewrite rPC, i0_0, func_lookup.
                  (* Show that target program is executing the same function*)
                  assert (FUNeq:e0 = ef ).
                  { assert (BB0: b0 = b)
                      by (rewrite rPC in H2; inversion H2; reflexivity).
                    subst b0. unfold the_ge in func_lookup.
                    rewrite func_lookup in H3; inversion H3.
                    reflexivity.
                  } subst e0.
                  
                  (* Show that the function is UNLOCK*)
                  match type of Hat_external2' with
                  | match ?x with _ => _ end = _ =>
                    destruct x eqn:HH; try discriminate
                  end.

                  inversion Hat_external2'. subst.
                  do 3 eexists; repeat split; eauto.
                  unfold compiler_match.
                  move comp_match at bottom.
                  simpl.
                  
                  instantiate(1:=cd').
                  replace (Clight.set_mem s1' (Clight.get_mem s1')) with s1'
                    by (destruct s1'; reflexivity).
                  simpl in comp_match.
                  
                  (*This should be generalizable*)
                  unfold Asm.loc_external_result,Conventions1.loc_result in comp_match.
                  replace Archi.ptr64 with false in comp_match by reflexivity. 
                  simpl in comp_match.
                  
                  assert (Hres: res = Vundef).
                  { unfold Events.external_call in *.
                    rewrite ReleaseExists in H5.
                    inversion H5. reflexivity.
                  }
                  subst res.
                  (* Here *)
                  replace m2''' with m21'''. auto.
                  
                  (*  m21''' = m2''' *)
                  simpl in H5.
                  rewrite ReleaseExists in H5.
                  inversion H5; subst.
                  rename m' into m21'.
                  rename m'' into m21''.
                  rename H10 into Hinterference21.
                  rename H11 into Hrelease.
                  
                  move Hinterference2' at bottom.

                  (*
                     m1 -lev1-> m1' -dpm-> m1'' -lev1'-> m1'''
                     |          |         |            |
                     |          |         |            |
                     m2 -lev2-> m2' -dpm-> m2'' -lev2'-> m2'''
                     !          !         !            !     
                     m2 -lev2-> m21'-dpm-> m21''-lev2'-> m21'''
                   *)
                  
                  assert (m21' =
                          (restrPermMap (proj1 ((memcompat2 CMatch) hb Hcnt2)))).
                  { move Hinterference2 at bottom.
                    move Hinterference21 at bottom.
                    eapply mem_interference_determ. eassumption.
                    Definition expl_restrPermMap p m Hlt:=
                      @restrPermMap p m Hlt.
                    Lemma expl_restr:
                      forall p m Hlt,
                        restrPermMap Hlt = expl_restrPermMap p m Hlt.
                    Proof. reflexivity. Qed.


                    Ltac clean_proofs:=
                      match goal with
                      | [A: ?T, B: ?T |- _] =>
                        match type of T with
                        | Prop => assert (A = B) by apply Axioms.proof_irr;
                              subst A
                        end
                      end.

                    repeat clean_proofs.
                    erewrite restr_proof_irr; eauto.
                  }
                  
                  assert (m21'' = (restrPermMap (proj1 (Hcmpt2' hb Hcnt2)))).
                  { move Hstore2 at bottom.
                    move Hrelease at bottom.
                    admit.
                  (* Sketch: release has to be defined.
                          it should modify content without touching permissions.
                          then show: 
                          m2' -release-> m2''
                          (or their restrictions to the cur)
                          release is deterministic and so the result follows. *)
                  }
                  (*  m21''' = m2''' *)
                  eapply mem_interference_determ; subst; try eassumption.
                  erewrite restr_proof_irr; eauto.
              }
              
          + eapply List.Forall2_app.
            * eauto.
            * econstructor; try solve[constructor].
              simpl.
              econstructor.
              admit.
          (* injection of the event*)
          (* Should be obvious by construction *)
          + (* HybridMachineSig.external_step *)

            econstructor; eauto.
            eapply step_release with
                (b:= b2)
                (virtueThread:=virtueThread2)
                (virtueLP:=virtueLP2);
              eauto; try reflexivity;
                try unfold HybridMachineSig.isCoarse,
                HybridMachineSig.HybridCoarseMachine.scheduler.
            rename m2' into MMM.
            rename m2 into MMM2.
            
            * (* bounded_maps.sub_map *)
              
              subst virtueThread2.
              unfold virtueThread_inject.
              destruct virtueThread1 as (virtue11, virtue12).
              cbv iota beta delta[fst] in *.
              destruct Hangel_bound as [Hbounded HboundedLP].
              destruct Hbounded as [Hbound1 Hbound2].
              split.
              -- eapply inject_virtue_sub_map.
                 eapply CMatch.
                 rewrite <- HeqvirtueThread1 in Hbound1. 
                 eassumption.
              -- eapply inject_virtue_sub_map.
                 eapply CMatch. 
                 rewrite <- HeqvirtueThread1 in Hbound2. 
                 eassumption.
                 
                 
            * (* bounded_maps.sub_map *)
              
              destruct Hangel_bound as [Hbounded HboundedLP].
              destruct HboundedLP as (?&?&Hbound).
              move Hbound at bottom.
              rewrite HeqvirtueLP2; simpl.
              
              eapply (proj1 (Logic.and_assoc _ _ _)).
              split.

              (*Easy ones: the default is trivial:
                  bounded_maps.map_empty_def
               *)
              subst virtueLP2.
              unfold virtueLP_inject,
              bounded_maps.map_empty_def, access_map_injected;
                simpl.
              split; 
              (rewrite HeqvirtueLP1; auto).

              assert (HboundedLP':
                        bounded_maps.sub_map (snd (fst virtueLP1)) (snd (getMaxPerm m1')) /\
                        bounded_maps.sub_map (snd (snd virtueLP1)) (snd (getMaxPerm m1'))
                     ) by (rewrite HeqvirtueLP1; eassumption).
              
              
              subst virtueLP2.
              destruct virtueLP1 as (virtueLP_fst, virtueLP_snd).
              revert HboundedLP'.
              unfold virtueLP_inject, access_map_injected.
              simpl (fst _).
              simpl (snd _) at 3 6 9.
              

              (* eapply self_simulation.minject in matchmem. *)
              intros (Hl & Hr); split;
                eapply inject_virtue_sub_map;
                try eapply CMatch; eauto.

              
            * (*invariant st4 *)
              !goal (invariant _).
              admit.

              
            * (* at_external for code 4. *)
              simpl in *; eassumption.
              
            * (* Mem.range_perm *)
              (* Can read the lock *)
              admit.

            * (* The load. *)
              admit.
              
            * (* the store *)
              admit.

            * (* content of lockres*)
              (* ThreadPool.lockRes st4 (b4', ofs4') *)
              (* NOTE: why is it rmap? It should be an injection of rmap 
                   ANSWER: the 'RMAP' is empty, so its injection is also empty... 
               *)
              
              admit.

            * eapply empty_map_useful; eauto. 
            * (* permissions join FST*)
              admit.
              
            * (* permissions join SND *)
              admit.
              
            * admit. (* Wrong machine state *)      
              *)
        - (* hb < tid *)
          pose proof (mtch_source _ _ _ _ _ _ CMatch _ l cnt1 (contains12 CMatch cnt1)) as match_thread.
          simpl in Hcode; exploit_match ltac:(apply CMatch).
          inversion H3.
          
          (*Destruct the values of the self simulation *)
          pose proof (self_simulation.minject _ _ _ matchmem) as Hinj.
          assert (Hinj':=Hinj).
          pose proof (self_simulation.ssim_external _ _ Cself_simulation) as sim_atx.
          eapply sim_atx in Hinj'; eauto.
          2: { clean_cmpt.
               erewrite restr_proof_irr; simpl; eauto.
          }
          clear sim_atx.
          destruct Hinj' as (b' & delt & Hinj_b & Hat_external2); eauto.

          
          (edestruct (release_step_diagram_self CSem) as
              (e' & m2' & Hthread_match & Htrace_inj & external_step);
           first[ eassumption|
                  econstructor; eassumption|
                  solve[econstructor; eauto] |
                  eauto]).

          + (* invariant st2 *) 
            eapply CMatch.
          + (*Mem.inject *)
            eapply CMatch.
          + (*at external *)
            clean_cmpt. unfold thread_mems.
            erewrite restr_proof_irr; simpl; eassumption. 
          + (*match_self*)
            econstructor.
            * eapply H3.
            * simpl; clean_cmpt.
              erewrite <- (restr_proof_irr Hlt1).
              erewrite <- (restr_proof_irr Hlt2).
              assumption.
         + exists e'. eexists. exists m2', cd, mu.
            split ; [|split].
            * (* reestablish concur *)
              admit.
            * eapply List.Forall2_app.
              -- eapply inject_incr_trace; eauto.     
              -- econstructor; try solve[constructor]; eauto.
            * econstructor; eauto.

      
        (** *Shelve *)
        Unshelve.
        all: eauto.
        all: try econstructor; eauto.
        all: try apply CMatch.
              
      Admitted.


      
      Lemma acquire_step_diagram:
        let hybrid_sem:= (semantics.csem (event_semantics.msem semSem)) in
        forall (angel: virtue)
          (U : list nat) (tid : nat) (cd : option compiler_index)
          (Hpeek : HybridMachineSig.schedPeek U = Some tid) 
          (mu : meminj)
          (st1 : ThreadPool (Some hb)) (m1 m1' : mem)
          (tr1 tr2 : HybridMachineSig.event_trace)
          (st2 : ThreadPool.t) (m2 : mem)
          (CMatch : concur_match cd mu st1 m1 st2 m2) (Htr : List.Forall2 (inject_mevent mu) tr1 tr2)
          (cnt1 : ThreadPool.containsThread st1 tid)
          (c : semC) (b : block) (ofs : int)
          (lock_perms : lock_info)
          (Hwritable_lock1 : writeable_lock b (unsigned ofs) (snd (getThreadR cnt1)) m1)
          (Hcmpt: mem_compatible st1 m1)
          (thread_compat1: thread_compat cnt1 m1),
          let m_writable_lock_1:= restrPermMap Hwritable_lock1 in
          let th_mem1 :=  fst (thread_mems thread_compat1) in
          let locks_mem1:= snd (thread_mems thread_compat1) in
          let newThreadPerm1:= (computeMap_pair (getThreadR cnt1) (virtueThread angel)) in
          let virtueThread:= virtueThread angel in
          forall (Hbounded : pair21_prop bounded_maps.sub_map virtueThread (snd (getMaxPerm m1)))
            (Hinv : invariant st1)
            (Hcode: getThreadC cnt1 = Kblocked c)
            (Hat_external: semantics.at_external hybrid_sem c th_mem1 =
                           Some (LOCK, (Vptr b ofs :: nil)%list))
            (Hload: Mem.load AST.Mint32 locks_mem1 b (unsigned ofs) = Some (Vint Int.one))
            (Haccess: Mem.range_perm locks_mem1 b (unsigned ofs) (Z.add (unsigned ofs) LKSIZE)
                           Cur Readable)
            (Hstore: Mem.store AST.Mint32 m_writable_lock_1 b
                               (unsigned ofs) (Vint Int.zero) = Some m1')
            (HisLock: ThreadPool.lockRes st1 (b, unsigned ofs) = Some lock_perms)
            (Hjoin_angel: permMapJoin_pair lock_perms (ThreadPool.getThreadR cnt1) newThreadPerm1),
          exists evnt' (st2' : ThreadPool.t) (m2' : mem) (cd' : option compiler_index) (mu' : meminj),
            let evnt:= (Events.acquire (b, unsigned ofs) (Some (build_delta_content (fst virtueThread) m1'))) in
            concur_match cd' mu'
                         (updLockSet (updThread cnt1 (Kresume c Vundef) newThreadPerm1)
                                     (b, unsigned ofs) (empty_map, empty_map)) m1' st2' m2' /\
            List.Forall2 (inject_mevent mu')
                         (tr1 ++ (Events.external tid evnt :: nil))
                         (tr2 ++ (Events.external tid evnt' :: nil)) /\
            HybridMachineSig.external_step
              (scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler)
              U tr2 st2 m2 (HybridMachineSig.schedSkip U)
              (tr2 ++ (Events.external tid evnt' :: nil)) st2' m2'.
      Proof.
        intros.

        (* destruct {tid < hb} + {tid = hb} + {hb < tid}  *)
        destruct (Compare_dec.lt_eq_lt_dec tid hb) as [[?|?]|?].

        (* tid < hb *)
        -  Lemma acquire_step_diagram_self Sem:
             let CoreSem:= sem_coresem Sem in
             forall (SelfSim: (self_simulation (@semC Sem) CoreSem))
               (st1 : mach_state hb) (st2 : mach_state (S hb))
               (Hinv1: invariant st1) (Hinv2: invariant st2)
               (m1 m1' m2 : mem) (mu : meminj) tid i b b' ofs delt
               (Hinj_b : mu b = Some (b', delt))
               (Hcmpt2: mem_compatible st2 m2)
               (cnt1 : ThreadPool.containsThread st1 tid)
               (cnt2 : ThreadPool.containsThread st2 tid)
               (thread_compat1: thread_compat cnt1 m1)
               (thread_compat2: thread_compat cnt2 m2)
               (CMatch: concur_match i mu st1 m1 st2 m2)
               (* Thread states *)
               (th_state1: @semC Sem) th_state2 sum_state1 sum_state2
               (HState1: coerce_state_type _ sum_state1 th_state1  
                                           (CSem, Clight.state)
                                           (AsmSem,Asm.state)
                                           (Sem,@semC Sem))
               (HState2: coerce_state_type _ sum_state2 th_state2
                                           (CSem, Clight.state)
                                           (AsmSem,Asm.state)
                                           (Sem,@semC Sem))
               (Hget_th_state1: getThreadC cnt1 = Kblocked sum_state1)
               (Hget_th_state2 : getThreadC cnt2 = Kblocked sum_state2)
               (* angel,lock permissions and new thread permissions *)
               (angel: virtue) lock_perms
               (HisLock: lockRes st1 (b, Integers.Ptrofs.unsigned ofs) =
                         Some lock_perms)
               (Hangel_bound: sub_map_virtue angel (getMaxPerm m1))
               (Hwritable_lock1 : writeable_lock b (unsigned ofs) (snd (getThreadR cnt1)) m1),
               let m_writable_lock_1:= restrPermMap Hwritable_lock1 in
               let th_mem1:= fst (thread_mems thread_compat1) in
               let locks_mem1:= snd (thread_mems thread_compat1) in
               let th_mem2:= fst (thread_mems thread_compat2) in
               let locks_mem2:= snd (thread_mems thread_compat2) in
               let newThreadPerm1:= (computeMap_pair (getThreadR cnt1) (virtueThread angel)) in
               forall (Hjoin_angel: permMapJoin_pair lock_perms (ThreadPool.getThreadR cnt1) newThreadPerm1)
                 (Hinj_lock: Mem.inject mu locks_mem1 locks_mem2)
                 (Hat_external: semantics.at_external CoreSem th_state1 th_mem1 =
                                Some (LOCK, (Vptr b ofs :: nil)%list))
                 (Hload: Mem.load AST.Mint32 locks_mem1 b (unsigned ofs) = Some (Vint Int.one))
                 (Haccess: Mem.range_perm locks_mem1 b (unsigned ofs) (Z.add (unsigned ofs) LKSIZE) Cur Readable)
                 (Hstore: Mem.store AST.Mint32 (m_writable_lock_1) b (unsigned ofs) (Vint Int.zero) = 
                          Some m1')
                 (Amatch : match_self (code_inject _ _ SelfSim) mu th_state1 th_mem1 th_state2 th_mem2),
                 let event1 := build_acquire_event (b, unsigned ofs) (fst (virtueThread angel)) m1' in
                 exists event2 (m2' : mem),
                   match_self (code_inject _ _ SelfSim) mu th_state1 th_mem1 th_state2 th_mem2 /\
                   (inject_mevent mu) (Events.external tid event1) (Events.external tid event2) /\
                   let angel2:= inject_virtue m2 mu angel in
                   let newThreadPerm2:= (computeMap_pair (getThreadR cnt2) (virtueThread angel2)) in
                   let st2':= updThread(tp:=st2) cnt2 (Kresume sum_state2 Vundef) newThreadPerm2 in
                   let st2'':=updLockSet st2' (b', unsigned (add ofs (repr delt))) (virtueLP angel2) in
                   syncStep(Sem:=HybridSem (Some (S hb))) true cnt2 Hcmpt2 st2'' m2' event2.
           Proof.
           Admitted. (* END acquire_step_diagram_self *)

           
          pose proof (mtch_target _ _ _ _ _ _ CMatch _ l cnt1 (contains12 CMatch cnt1)) as match_thread.
          simpl in Hcode; exploit_match ltac:(apply CMatch).
          inversion H3. (* Asm_match *)
          
          (*Destruct the values of the self simulation *)
          pose proof (self_simulation.minject _ _ _ matchmem) as Hinj.
          assert (Hinj':=Hinj).
          pose proof (self_simulation.ssim_external _ _ Aself_simulation) as sim_atx.
          eapply sim_atx in Hinj'; eauto.
          2: { (*at_external*)
            clean_cmpt.
            erewrite restr_proof_irr; simpl; eauto.
          }
          clear sim_atx.
          destruct Hinj' as (b' & delt & Hinj_b & Hat_external2); eauto.


           
           edestruct (acquire_step_diagram_self AsmSem) as
              (e' & m2' & Hthread_match & Htrace_inj & external_step);
           first[ eassumption|
                  econstructor; eassumption|
                  solve[econstructor; eauto] |
                  eauto].
           + !goal(invariant(tpool:=OrdinalThreadPool) st2).
             eapply CMatch.
           + !goal ( sub_map_virtue angel (getMaxPerm m1)).
             admit. (* Think about this. c*)
           + (*Mem.inject *)
             !goal(Mem.inject mu _ _).
             eapply CMatch.
           + (*at external *)
             clean_cmpt. unfold thread_mems.
             erewrite restr_proof_irr; simpl; eassumption. 
           + (*match_self*)
             econstructor.
             * eapply H3.
             * simpl; clean_cmpt.
               erewrite <- (restr_proof_irr Hlt1).
               erewrite <- (restr_proof_irr Hlt2).
               assumption.
           + exists e'. eexists. exists m2', cd, mu.
             split ; [|split].
             * (* reestablish concur *)
               admit.
             * eapply List.Forall2_app.
               -- eapply inject_incr_trace; eauto.     
               -- econstructor; try solve[constructor]; eauto.
             * econstructor; eauto.
               
          
        (* tid = hb *)
        - admit.
          
        (* tid > hb *)
          
        - pose proof (mtch_source _ _ _ _ _ _ CMatch _ l cnt1 (contains12 CMatch cnt1)) as match_thread.
          simpl in Hcode; exploit_match ltac:(apply CMatch).
          inversion H3. (* Asm_match *)
          
          (*Destruct the values of the self simulation *)
          pose proof (self_simulation.minject _ _ _ matchmem) as Hinj.
          assert (Hinj':=Hinj).
          pose proof (self_simulation.ssim_external _ _ Cself_simulation) as sim_atx.
          eapply sim_atx in Hinj'; eauto.
          2: { (*at_external*)
            clean_cmpt.
            erewrite restr_proof_irr; simpl; eauto.
          }
          clear sim_atx.
          destruct Hinj' as (b' & delt & Hinj_b & Hat_external2); eauto.


           
           edestruct (acquire_step_diagram_self CSem) as
              (e' & m2' & Hthread_match & Htrace_inj & external_step);
           first[ eassumption|
                  econstructor; eassumption|
                  solve[econstructor; eauto] |
                  eauto].
          (* exploit (release_step_diagram_self CSem); eauto. *)
          + !goal(invariant(tpool:=OrdinalThreadPool) st2).
             eapply CMatch.
          + !goal ( sub_map_virtue angel (getMaxPerm m1)).
             admit. (* Think about this. c*)
           + (*Mem.inject *)
             !goal(Mem.inject mu _ _).
             eapply CMatch.
           + (*at external *)
             clean_cmpt. unfold thread_mems.
             erewrite restr_proof_irr; simpl; eassumption. 
           + (*match_self*)
             econstructor.
             * eapply H3.
             * simpl; clean_cmpt.
               erewrite <- (restr_proof_irr Hlt1).
               erewrite <- (restr_proof_irr Hlt2).
               assumption.
           + exists e'. eexists. exists m2', cd, mu.
             split ; [|split].
             * (* reestablish concur *)
               admit.
             * eapply List.Forall2_app.
               -- eapply inject_incr_trace; eauto.     
               -- econstructor; try solve[constructor]; eauto.
             * econstructor; eauto.
      Admitted.


      (* Remove once we are confident with the new version above. *)
      Lemma acquire_step_diagram':
        forall (cd : option compiler_index) (m1 : mem) (st1 : ThreadPool (Some hb)) (st2 : ThreadPool.t) (mu : meminj) (m2 : mem)
          (tr1 tr2 : HybridMachineSig.event_trace)
          (Hmatch : concur_match cd mu st1 m1 st2 m2) (Htr : List.Forall2 (inject_mevent mu) tr1 tr2)
          (U : list nat)
          (m1' : mem) (tid : nat)
          (Htid : ThreadPool.containsThread st1 tid) (Hpeek : HybridMachineSig.schedPeek U = Some tid) (c : semC) (b : block)
          (ofs : Integers.Ptrofs.int) (virtueThread : delta_map * delta_map)
          (newThreadPerm : access_map * access_map) (pmap : lock_info)
          (Hcmpt: mem_compatible st1 m1)
          (Hlt': permMapLt
                   (setPermBlock (Some Writable) b (Integers.Ptrofs.unsigned ofs)
                                 (snd (ThreadPool.getThreadR Htid)) LKSIZE_nat) (getMaxPerm m1))
          (Hbounded : bounded_maps.sub_map (fst virtueThread) (snd (getMaxPerm m1)) /\
                      bounded_maps.sub_map (snd virtueThread) (snd (getMaxPerm m1)))
          (Hinv : invariant st1),
          semantics.at_external (semantics.csem (event_semantics.msem semSem))
                                c (restrPermMap (fst (ssrfun.pair_of_and (Hcmpt tid Htid)))) =
          Some (LOCK, (Vptr b ofs :: nil)%list) ->
          getThreadC Htid = Kblocked c ->
          Mem.load AST.Mint32 (restrPermMap (snd (ssrfun.pair_of_and (Hcmpt tid Htid)))) b
                   (Integers.Ptrofs.unsigned ofs) = Some (Vint Integers.Int.one) ->
          Mem.range_perm (restrPermMap (snd (ssrfun.pair_of_and (Hcmpt tid Htid)))) b
                         (Integers.Ptrofs.unsigned ofs) (BinInt.Z.add (Integers.Ptrofs.unsigned ofs) LKSIZE)
                         Cur Readable ->
          Mem.store AST.Mint32 (restrPermMap Hlt') b (Integers.Ptrofs.unsigned ofs)
                    (Vint Integers.Int.zero) = Some m1' ->
          ThreadPool.lockRes st1 (b, Integers.Ptrofs.unsigned ofs) = Some pmap ->
          permMapJoin (fst pmap) (fst (ThreadPool.getThreadR Htid)) (fst newThreadPerm) ->
          permMapJoin (snd pmap) (snd (ThreadPool.getThreadR Htid)) (snd newThreadPerm) ->
          exists e' (st2' : ThreadPool.t) (m2' : mem) (cd' : option compiler_index) (mu' : meminj),
            concur_match cd' mu'
                         (ThreadPool.updLockSet (ThreadPool.updThread Htid (Kresume c Vundef) newThreadPerm)
                                                (b, Integers.Ptrofs.unsigned ofs) (empty_map, empty_map)) m1' st2' m2' /\
            List.Forall2 (inject_mevent mu')
                         (seq.cat tr1
                                  (Events.external tid
                                                   (Events.acquire
                                                      (b, Integers.Ptrofs.unsigned ofs)
                                                      (Some (build_delta_content (fst virtueThread) m1'))) :: nil))
                         (seq.cat tr2 (Events.external tid e' :: nil)) /\
            HybridMachineSig.external_step(scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler)
                                          U tr2 st2 m2 (HybridMachineSig.schedSkip U)
                                          (seq.cat tr2
                                                   (Events.external tid e' :: nil)) st2'
                                          m2'.
      Proof.
        
        intros.

        (* destruct {tid < hb} + {tid = hb} + {hb < tid}  *)
        destruct (Compare_dec.lt_eq_lt_dec tid hb) as [[?|?]|?].

        (* tid < hb *)
        - 

      Admitted.
      

      Lemma make_step_diagram:
        forall (U : list nat) (tr1 tr2 : HybridMachineSig.event_trace)
          (st1 : ThreadPool (Some hb)) (m1 m1' : mem) 
          (tid : nat) (cd : option compiler_index)
          (st2 : ThreadPool (Some (S hb))) (mu : meminj) 
          (m2 : mem) (Htid : ThreadPool.containsThread st1 tid)
          (c : semC) (b : block) (ofs : Integers.Ptrofs.int)
          (pmap_tid' : access_map * access_map),
          concur_match cd mu st1 m1 st2 m2 ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          forall Hcmpt : mem_compatible st1 m1,
            HybridMachineSig.schedPeek U = Some tid ->
            invariant st1 ->
            ThreadPool.getThreadC Htid = Kblocked c ->
            semantics.at_external
              (semantics.csem (event_semantics.msem semSem)) c
              (restrPermMap (fst (ssrfun.pair_of_and (Hcmpt tid Htid)))) =
            Some (MKLOCK, (Vptr b ofs :: nil)%list) ->
            Mem.store AST.Mint32
                      (restrPermMap (fst (ssrfun.pair_of_and (Hcmpt tid Htid)))) b
                      (Integers.Ptrofs.unsigned ofs) (Vint Integers.Int.zero) =
            Some m1' ->
            Mem.range_perm
              (restrPermMap (fst (ssrfun.pair_of_and (Hcmpt tid Htid)))) b
              (Integers.Ptrofs.unsigned ofs)
              (BinInt.Z.add (Integers.Ptrofs.unsigned ofs) LKSIZE) Cur Writable ->
            setPermBlock (Some Nonempty) b (Integers.Ptrofs.unsigned ofs)
                         (fst (ThreadPool.getThreadR Htid)) LKSIZE_nat = 
            fst pmap_tid' ->
            setPermBlock (Some Writable) b (Integers.Ptrofs.unsigned ofs)
                         (snd (ThreadPool.getThreadR Htid)) LKSIZE_nat = 
            snd pmap_tid' ->
            ThreadPool.lockRes st1 (b, Integers.Ptrofs.unsigned ofs) = None ->
            exists
              e' (st2' : t) (m2' : mem) (cd' : option compiler_index) 
              (mu' : meminj),
              concur_match cd' mu'
                           (ThreadPool.updLockSet
                              (ThreadPool.updThread Htid (Kresume c Vundef) pmap_tid')
                              (b, Integers.Ptrofs.unsigned ofs) (empty_map, empty_map))
                           m1' st2' m2' /\
              List.Forall2 (inject_mevent mu') (seq.cat tr1 (Events.external tid (Events.mklock (b, Integers.Ptrofs.unsigned ofs)) :: nil))
                           (seq.cat tr2 (Events.external tid e' :: nil)) /\
              HybridMachineSig.external_step
                (scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler)
                U tr2 st2 m2 (HybridMachineSig.schedSkip U)
                (seq.cat tr2
                         (Events.external tid e' :: nil))
                st2' m2'.
      Proof.
      Admitted.

      Lemma free_step_diagram:
        forall (U : list nat) (tr1 tr2 : HybridMachineSig.event_trace)
          (st1 : ThreadPool (Some hb)) (m1' : mem) 
          (tid : nat) (cd : option compiler_index)
          (st2 : ThreadPool (Some (S hb))) (mu : meminj) 
          (m2 : mem) (Htid : ThreadPool.containsThread st1 tid)
          (c : semC) (b : block) (ofs : Integers.Ptrofs.int)
          (pmap_tid' : access_map * access_map)
          (pdata : nat -> option permission) (rmap : lock_info),
          concur_match cd mu st1 m1' st2 m2 ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          forall Hcmpt : mem_compatible st1 m1',
            HybridMachineSig.schedPeek U = Some tid ->
            bounded_maps.bounded_nat_func' pdata LKSIZE_nat ->
            invariant st1 ->
            ThreadPool.getThreadC Htid = Kblocked c ->
            semantics.at_external
              (semantics.csem (event_semantics.msem semSem)) c
              (restrPermMap (fst (ssrfun.pair_of_and (Hcmpt tid Htid)))) =
            Some (FREE_LOCK, (Vptr b ofs :: nil)%list) ->
            ThreadPool.lockRes st1 (b, Integers.Ptrofs.unsigned ofs) =
            Some rmap ->
            (forall (b0 : BinNums.positive) (ofs0 : BinNums.Z),
                (fst rmap) !! b0 ofs0 = None /\ (snd rmap) !! b0 ofs0 = None) ->
            Mem.range_perm
              (restrPermMap (snd (ssrfun.pair_of_and (Hcmpt tid Htid)))) b
              (Integers.Ptrofs.unsigned ofs)
              (BinInt.Z.add (Integers.Ptrofs.unsigned ofs) LKSIZE) Cur Writable ->
            setPermBlock None b (Integers.Ptrofs.unsigned ofs)
                         (snd (ThreadPool.getThreadR Htid)) LKSIZE_nat = 
            snd pmap_tid' ->
            (forall i : nat,
                BinInt.Z.le 0 (BinInt.Z.of_nat i) /\
                BinInt.Z.lt (BinInt.Z.of_nat i) LKSIZE ->
                Mem.perm_order'' (pdata (S i)) (Some Writable)) ->
            setPermBlock_var pdata b (Integers.Ptrofs.unsigned ofs)
                             (fst (ThreadPool.getThreadR Htid)) LKSIZE_nat = 
            fst pmap_tid' ->
            exists
              e' (st2' : t) (m2' : mem) (cd' : option compiler_index) 
              (mu' : meminj),
              concur_match cd' mu'
                           (ThreadPool.remLockSet
                              (ThreadPool.updThread Htid (Kresume c Vundef) pmap_tid')
                              (b, Integers.Ptrofs.unsigned ofs)) m1' st2' m2' /\
              List.Forall2 (inject_mevent mu') (seq.cat tr1 (Events.external tid (Events.freelock (b, Integers.Ptrofs.unsigned ofs)) :: nil))
                           (seq.cat tr2 (Events.external tid e' :: nil)) /\
              HybridMachineSig.external_step
                (scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler)
                U tr2 st2 m2
                (HybridMachineSig.schedSkip U)
                (seq.cat tr2 (Events.external tid e' :: nil)) st2' m2'.
      Proof.
      Admitted.

      Lemma acquire_fail_step_diagram:
        forall (U : list nat) (tr1 tr2 : HybridMachineSig.event_trace)
          (st1' : ThreadPool (Some hb)) (m1' : mem) 
          (tid : nat) (cd : option compiler_index)
          (st2 : ThreadPool (Some (S hb))) (mu : meminj) 
          (m2 : mem) (Htid : ThreadPool.containsThread st1' tid)
          (b : block) (ofs : Integers.Ptrofs.int) 
          (c : semC) (Hcmpt : mem_compatible st1' m1'),
          concur_match cd mu st1' m1' st2 m2 ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          HybridMachineSig.schedPeek U = Some tid ->
          semantics.at_external
            (semantics.csem (event_semantics.msem semSem)) c
            (restrPermMap (fst (ssrfun.pair_of_and (Hcmpt tid Htid)))) =
          Some (LOCK, (Vptr b ofs :: nil)%list) ->
          Mem.load AST.Mint32
                   (restrPermMap (snd (ssrfun.pair_of_and (Hcmpt tid Htid)))) b
                   (Integers.Ptrofs.unsigned ofs) = Some (Vint Integers.Int.zero) ->
          Mem.range_perm
            (restrPermMap (snd (ssrfun.pair_of_and (Hcmpt tid Htid)))) b
            (Integers.Ptrofs.unsigned ofs)
            (BinInt.Z.add (Integers.Ptrofs.unsigned ofs) LKSIZE) Cur Readable ->
          ThreadPool.getThreadC Htid = Kblocked c ->
          invariant st1' ->
          exists
            e' (st2' : t) (m2' : mem) (cd' : option compiler_index) 
            (mu' : meminj),
            concur_match cd' mu' st1' m1' st2' m2' /\
            List.Forall2 (inject_mevent mu') (seq.cat tr1 (Events.external tid (Events.failacq (b, Integers.Ptrofs.unsigned ofs)) :: nil))
                         (seq.cat tr2 (Events.external tid e' :: nil)) /\
            HybridMachineSig.external_step
              (scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler)
              U tr2 st2 m2
              (HybridMachineSig.schedSkip U)
              (seq.cat tr2 (Events.external tid e' :: nil))
              st2' m2'.
      Proof.
      Admitted.
      
      Lemma external_step_diagram:
        forall (U : list nat) (tr1 tr2 : HybridMachineSig.event_trace) (st1 : ThreadPool.t) 
          (m1 : mem) (st1' : ThreadPool.t) (m1' : mem) (tid : nat) (ev : Events.sync_event),
        forall (cd : option compiler_index) (st2 : ThreadPool.t) (mu : meminj) (m2 : mem),
          concur_match cd mu st1 m1 st2 m2 ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          forall (cnt1 : ThreadPool.containsThread st1 tid) (Hcmpt : mem_compatible st1 m1),
            HybridMachineSig.schedPeek U = Some tid ->
            syncStep true cnt1 Hcmpt st1' m1' ev ->
            exists ev' (st2' : t) (m2' : mem) (cd' : option compiler_index) 
              (mu' : meminj),
              concur_match cd' mu' st1' m1' st2' m2' /\
              List.Forall2 (inject_mevent mu') (seq.cat tr1 (Events.external tid ev :: nil)) (seq.cat tr2 (Events.external tid ev' :: nil)) /\
              HybridMachineSig.external_step
                (scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler) U tr2 st2 m2 (HybridMachineSig.schedSkip U)
                (seq.cat tr2 (Events.external tid ev' :: nil)) st2' m2'.
      Proof.
        intros.
        assert (thread_compat1:thread_compat cnt1 m1) by (apply mem_compatible_thread_compat; assumption).
        inversion H2; subst.
        - (*Acquire*)
          remember (Build_virtue virtueThread0 (getThreadR cnt1)) as angel'.
          edestruct (acquire_step_diagram angel') as
              (?&?&?&?&?&?&?&?); subst angel'; simpl in *;
            eauto;
            try rewrite (restr_proof_irr _ (proj1 (Hcmpt tid cnt1)));
            eauto.
          + split; simpl; auto.            
          + do 5 eexists; split; eauto.
        - (*Release*)
          remember (Build_virtue virtueThread0 virtueLP0) as angel'.
          edestruct (release_step_diagram angel') as
              (?&?&?&?&?&?&?&?);
            subst angel'; simpl in *; eauto.
          + constructor; eauto.
          + erewrite restr_proof_irr; eassumption.
          + erewrite restr_proof_irr; eassumption.
          + eapply empty_map_useful; auto.
          + econstructor; eauto.
          + do 5 eexists; split; eauto.
        - (*Create/Spawn*)
          admit.
        - (*Make Lock*)
          eapply make_step_diagram; eauto.
        - (*Free Lock*)
          eapply free_step_diagram; eauto.
        - (*AcquireFail*)
          eapply acquire_fail_step_diagram; eauto.

          Unshelve.
          assumption.
      Admitted.


      
      Lemma start_step_diagram:
        forall (m : option mem) (tge : HybridMachineSig.G) 
          (U : list nat) (st1 : ThreadPool (Some hb)) 
          (m1 : mem) (tr1 tr2 : HybridMachineSig.event_trace)
          (st1' : ThreadPool (Some hb)) (m' : mem)
          (cd : option compiler_index) (st2 : ThreadPool (Some (S hb)))
          (mu : meminj) (m2 : mem) (tid : nat)
          (Htid : ThreadPool.containsThread st1 tid),
          concur_match cd mu st1 m1 st2 m2 ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          HybridMachineSig.schedPeek U = Some tid ->
          HybridMachineSig.start_thread m1 Htid st1' m' ->
          exists
            (st2' : ThreadPool (Some (S hb))) (m2' : mem) 
            (cd' : option compiler_index) (mu' : meminj),
            concur_match cd' mu' st1' (HybridMachineSig.diluteMem m') st2'
                         m2' /\
            List.Forall2 (inject_mevent mu') tr1 tr2 /\
            machine_semantics.machine_step(HybConcSem (Some (S hb)) m) tge
                                          U tr2 st2 m2 (HybridMachineSig.yield
                                                          (Scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler)
                                                          U) tr2 st2' m2'.
      Proof.
      Admitted.

      
      Lemma resume_step_diagram:
        forall (m : option mem) (tge : HybridMachineSig.G) 
               (U : list nat) (st1 : ThreadPool (Some hb))
               (tr1 tr2 : HybridMachineSig.event_trace)
               (st1' : ThreadPool (Some hb)) (m1' : mem)
               (cd : option compiler_index) (st2 : ThreadPool (Some (S hb)))
               (mu : meminj) (m2 : mem) (tid : nat)
               (Htid : ThreadPool.containsThread st1 tid),
          concur_match cd mu st1 m1' st2 m2 ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          HybridMachineSig.schedPeek U = Some tid ->
          HybridMachineSig.resume_thread m1' Htid st1' ->
          exists
            (st2' : ThreadPool (Some (S hb))) (m2' : mem) 
            (cd' : option compiler_index) (mu' : meminj),
            concur_match cd' mu' st1' m1' st2' m2' /\
            List.Forall2 (inject_mevent mu') tr1 tr2 /\
            machine_semantics.machine_step (HybConcSem (Some (S hb)) m) tge
                                           U tr2 st2 m2
                                           (HybridMachineSig.yield(Scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler)
                                                                  U) tr2 st2' m2'.
      Proof.
        intros.

        assert (Hcnt2: containsThread st2 tid).
        { eapply contains12; eauto. }
        
        (* destruct {tid < hb} + {tid = hb} + {hb < tid}  *)
        destruct (Compare_dec.lt_eq_lt_dec tid hb) as [[?|?]|?].
        - (* tid < hb *)
          admit.
          
        - (* tid = hb *)
          subst. inversion H2; subst.
          inversion H. simpl in *.
          clean_cnt.
          assert (m1_restr: permMapLt (thread_perms Htid) (getMaxPerm m1')) by
              eapply memcompat3.
          assert (m2_restr: permMapLt (thread_perms Hcnt2) (getMaxPerm m2)) by
              eapply memcompat4.
          specialize (mtch_compiled0 hb ltac:(reflexivity) Htid Hcnt2
                                                           m1_restr
                                                           m2_restr).
          rewrite Hcode in mtch_compiled0.
          inv mtch_compiled0.
          
          (* TODO: Add the precondition of H10 to the concur match.
             that means: assert all the preconditions for the current state,
             and also have the precondition for all future states that satisfy the hyps.
             
             WAIT: Maybe not, I think you just need to instantiate it with the 
             current values. All the precontidions are refelxive.

           *)
          simpl in H10.
          inv Hafter_external.
          erewrite (restr_proof_irr m1_restr) in H10.
          destruct ((Clight.after_external None code1 m')) eqn:Hafter_x1; inv H4.
          rewrite Hperm in Hafter_x1.
          specialize (H10 mu s (restrPermMap _) (restrPermMap m2_restr) nil nil
                          ltac:(constructor)
                          ltac:(constructor)
                          ltac:(constructor)
                          Hafter_x1
                     ).
          destruct H10 as (cd' & mu' & s2' & Hafter_x2 & INJ1 & Hcompiler_match).
          remember 
            (updThreadC Hcnt2 (Krun (TState Clight.state Asm.state s2'))) as st2'.
          exists st2',m2,(Some cd'), mu'. 
          split; [|split].
          + !goal (concur_match _ mu' _ _ _ _).
            admit.
          + !goal (Forall2 (inject_mevent mu') tr1 tr2).
            admit.
          + (* Step *)
            !goal (HybridMachineSig.external_step _ _ _ _ _ _ _ _).

            
            assert (HH: U = (HybridMachineSig.yield
                               (Scheduler:=HybridMachineSig.HybridCoarseMachine.scheduler) U))
              by reflexivity.
            rewrite HH at 2.
            eapply HybridMachineSig.resume_step'; eauto.
            admit.
        (* econstructor; eauto. *)

        - (* hb < tid *)
          admit.
      Admitted.

      
      
      
      Lemma suspend_step_diagram:
        forall (m : option mem) (tge : HybridMachineSig.G) 
               (U : list nat) (st1 : ThreadPool (Some hb))
               (tr1 tr2 : HybridMachineSig.event_trace)
               (st1' : ThreadPool (Some hb)) (m1' : mem)
               (cd : option compiler_index) (st2 : ThreadPool (Some (S hb)))
               (mu : meminj) (m2 : mem) (tid : nat)
               (Htid : ThreadPool.containsThread st1 tid),
          concur_match cd mu st1 m1' st2 m2 ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          HybridMachineSig.schedPeek U = Some tid ->
          HybridMachineSig.suspend_thread m1' Htid st1' ->
          exists
            (st2' : ThreadPool (Some (S hb))) (m2' : mem) 
            (cd' : option compiler_index) (mu' : meminj),
            concur_match cd' mu' st1' m1' st2' m2' /\
            List.Forall2 (inject_mevent mu') tr1 tr2 /\
            machine_semantics.machine_step (HybConcSem (Some (S hb)) m) tge
                                           U tr2 st2 m2 (HybridMachineSig.schedSkip U) tr2 st2' m2'.
      Proof.
        admit. (* Easy  since there is no changes to memory. *)
      Admitted.

      Lemma schedfail_step_diagram:
        forall (m : option mem) (tge : HybridMachineSig.G) 
               (U : list nat) (tr1 tr2 : HybridMachineSig.event_trace)
               (st1' : ThreadPool (Some hb)) (m1' : mem)
               (st2 : ThreadPool (Some (S hb))) (m2 : mem) 
               (tid : nat) cd mu,
          concur_match cd mu st1' m1' st2 m2 ->
          List.Forall2 (inject_mevent mu) tr1 tr2 ->
          HybridMachineSig.schedPeek U = Some tid ->
          ~ ThreadPool.containsThread st1' tid ->
          HybridMachineSig.invariant st1' ->
          HybridMachineSig.mem_compatible st1' m1' ->
          exists
            (st2' : ThreadPool (Some (S hb))) (m2' : mem) 
            (cd' : option compiler_index) (mu' : meminj),
            concur_match cd' mu' st1' m1' st2' m2' /\
            List.Forall2 (inject_mevent mu') tr1 tr2 /\
            machine_semantics.machine_step (HybConcSem (Some (S hb)) m) tge
                                           U tr2 st2 m2 (HybridMachineSig.schedSkip U) tr2 st2' m2'.
      Proof.
        admit.
        (* Easy  since there is no changes to memory. *)
      Admitted.
      
      Lemma machine_step_diagram:
        forall (m : option mem) (sge tge : HybridMachineSig.G) (U : list nat)
               (tr1 : HybridMachineSig.event_trace) (st1 : ThreadPool (Some hb)) 
               (m1 : mem) (U' : list nat) (tr1' : HybridMachineSig.event_trace)
               (st1' : ThreadPool (Some hb)) (m1' : mem),
          machine_semantics.machine_step (HybConcSem (Some hb) m) sge U tr1 st1 m1 U' tr1' st1' m1' ->
          forall (cd : option compiler_index) tr2 (st2 : ThreadPool (Some (S hb))) 
                 (mu : meminj) (m2 : mem),
            concur_match cd mu st1 m1 st2 m2 ->
            List.Forall2 (inject_mevent mu) tr1 tr2 ->
            exists
              tr2' (st2' : ThreadPool (Some (S hb))) (m2' : mem) (cd' : option compiler_index) 
              (mu' : meminj),
              concur_match cd' mu' st1' m1' st2' m2' /\
              List.Forall2 (inject_mevent mu') tr1' tr2' /\
              machine_semantics.machine_step (HybConcSem (Some (S hb)) m) tge U tr2 st2 m2 U' tr2' st2'
                                             m2'.
      Proof.
        intros.
        simpl in H.
        inversion H; subst.
        - (* Start thread. *)
          exists tr2; eapply start_step_diagram; eauto.
          
        - (* resume thread. *)
          exists tr2; eapply resume_step_diagram; eauto.
          
        - (* suspend thread. *)
          exists tr2; eapply suspend_step_diagram; eauto.
          
        - (* sync step. *)
          edestruct external_step_diagram as (? & ? & ? & ? & ? & ? & ? & ?); eauto 8.

        - (*schedfail. *)
          exists tr2; eapply schedfail_step_diagram; eauto.
      Qed.


      
      Lemma initial_diagram:
        forall (m : option mem) (s_mem s_mem' : mem) (main : val) (main_args : list val)
               (s_mach_state : ThreadPool (Some hb)) (r1 : option res),
          machine_semantics.initial_machine (HybConcSem (Some hb) m) r1 s_mem s_mach_state s_mem'
                                            main main_args ->
          exists
            (j : meminj) (cd : option compiler_index) (t_mach_state : ThreadPool (Some (S hb))) 
            (t_mem t_mem' : mem) (r2 : option res),
            machine_semantics.initial_machine (HybConcSem (Some (S hb)) m) r2 t_mem t_mach_state
                                              t_mem' main main_args /\ concur_match cd j s_mach_state s_mem' t_mach_state t_mem'.
      Proof.
        intros m.
        
        simpl; unfold HybridMachineSig.init_machine''.
        intros ? ? ? ? ? ? (?&?).
        destruct r1; try solve[inversion H0].
        simpl in H0.
        destruct H0 as (init_thread&?&?); simpl in *.
        unfold initial_core_sum in *.
        destruct init_thread; destruct H0 as (LT&H0); simpl in LT.
        + admit. (*identical start!*)
        + admit. (*should follow from compiler simulation*)
      Admitted.
      
      Lemma compile_one_thread:
        forall m,
          HybridMachine_simulation_properties
            (HybConcSem (Some hb) m)
            (HybConcSem (Some (S hb)) m)
            (concur_match).
      Proof.
        intros.
        econstructor.
        - eapply option_wf.
          eapply (Injfsim_order_wfX compiler_sim). (*well_founded order*)

        (*Initial Diagram*)
        - eapply initial_diagram.

        (* Internal Step diagram*)
        - eapply internal_step_diagram.

        (* Machine Step diagram *)
        - eapply machine_step_diagram.

        (* Halted *)
        - simpl; unfold HybridMachineSig.halted_machine; simpl; intros.
          destruct (HybridMachineSig.schedPeek U); inversion H0.
          eexists; reflexivity.

        (*Same running *)
        - eapply concur_match_same_running.
          
      Qed.
      

    End CompileOneThread.

    
    Section CompileNThreads.
      
      Definition nth_index:= list (option compiler_index).
      Definition list_lt: nth_index -> nth_index -> Prop.
      Admitted.
      Lemma list_lt_wf:
        well_founded list_lt.
      Admitted.
      Inductive match_state:
        forall n,
          nth_index ->
          Values.Val.meminj ->
          ThreadPool (Some 0)%nat -> Memory.Mem.mem -> ThreadPool (Some n) -> Memory.Mem.mem -> Prop:=
      | refl_match: forall j tp m,
          match_state 0 nil j tp m tp m
      | step_match_state:
          forall n ocd ils jn jSn tp0 m0 tpn mn tpSn mSn,
            match_state n ils jn tp0 m0 tpn mn ->
            concur_match n ocd jSn tpn mn tpSn mSn ->
            match_state (S n) (cons ocd ils) (compose_meminj jn jSn) tp0 m0 tpSn mSn.

      Lemma trivial_self_injection:
        forall m : option mem,
          HybridMachine_simulation_properties (HybConcSem (Some 0)%nat m)
                                              (HybConcSem (Some 0)%nat m) (match_state 0).
      Proof.
      (* NOTE: If this lemma is not trivial, we can start the induction at 1,
         an the first case follow immediately by lemma
         compile_one_thread
       *)
      Admitted.

      Lemma simulation_inductive_case:
        forall n : nat,
          (forall m : option mem,
              HybridMachine_simulation_properties (HybConcSem (Some 0)%nat m)
                                                  (HybConcSem (Some n) m) (match_state n)) ->
          (forall m : option mem,
              HybridMachine_simulation_properties (HybConcSem (Some n) m)
                                                  (HybConcSem (Some (S n)) m) (concur_match n)) ->
          forall m : option mem,
            HybridMachine_simulation_properties (HybConcSem (Some 0)%nat m)
                                                (HybConcSem (Some (S n)) m) (match_state (S n)).
      Proof.
        intros n.
      Admitted.
      
      Lemma compile_n_threads:
        forall n m,
          HybridMachine_simulation.HybridMachine_simulation_properties
            (HybConcSem (Some 0)%nat m)
            (HybConcSem (Some n) m)
            (match_state n).
      Proof.
        induction n.
        - (*trivial reflexive induction*)
          apply trivial_self_injection.
        - eapply simulation_inductive_case; eauto.
          eapply compile_one_thread.
      Qed.

    End CompileNThreads.

    Section CompileInftyThread.

      Parameter lift_state: forall on, ThreadPool on -> forall on', ThreadPool on' -> Prop.
      
      Inductive infty_match:
        nth_index -> meminj ->
        ThreadPool (Some 0)%nat -> mem ->
        ThreadPool None -> mem -> Prop:=
      | Build_infty_match:
          forall n cd j st0 m0 stn mn st,
            match_state n cd j st0 m0 stn mn ->
            lift_state (Some n) stn None st ->
            infty_match cd j st0 m0 st mn.


      Lemma initial_infty:
        forall (m : option mem) (s_mem s_mem' : mem) 
               (main : val) (main_args : list val)
               (s_mach_state : ThreadPool (Some 0)%nat) (r1 : option res),
          machine_semantics.initial_machine (HybConcSem (Some 0)%nat m) r1
                                            s_mem s_mach_state s_mem' main main_args ->
          exists
            (j : meminj) (cd : nth_index) (t_mach_state : ThreadPool None) 
            (t_mem t_mem' : mem) (r2 : option res),
            machine_semantics.initial_machine (HybConcSem None m) r2 t_mem
                                              t_mach_state t_mem' main main_args /\
            infty_match cd j s_mach_state s_mem' t_mach_state t_mem'.
      Proof.
      (* Follows from any initial diagram and a missing lemma showing that the initial state
        can be "lifted" (lift_state) *)
      Admitted.

      Lemma infinite_step_diagram:
        forall (m : option mem) (sge tge : HybridMachineSig.G)
               (U : list nat) tr1 (st1 : ThreadPool (Some 0)%nat) 
               (m1 : mem) (st1' : ThreadPool (Some 0)%nat) 
               (m1' : mem),
          machine_semantics.thread_step (HybConcSem (Some 0)%nat m) sge U st1
                                        m1 st1' m1' ->
          forall (cd : nth_index) tr2 (st2 : ThreadPool None) 
                 (mu : meminj) (m2 : mem),
            infty_match cd mu st1 m1 st2 m2 ->
            List.Forall2 (inject_mevent mu) tr1 tr2 ->
            exists
              (st2' : ThreadPool None) (m2' : mem) (cd' : nth_index) 
              (mu' : meminj),
              infty_match cd' mu' st1' m1' st2' m2' /\
              List.Forall2 (inject_mevent mu') tr1 tr2 /\
              (machine_semantics_lemmas.thread_step_plus 
                 (HybConcSem None m) tge U st2 m2 st2' m2' \/
               machine_semantics_lemmas.thread_step_star 
                 (HybConcSem None m) tge U st2 m2 st2' m2' /\ 
               list_lt cd' cd).
      Proof.
      (*Proof sketch:
            infty_match defines an intermediate machine Mn at level n, matching the 0 machine.
            All threads of machine Mn are in Asm. A lemma should show that all hier machines 
            (Mk, for k>n) also match the machine at 0. 
            lemma [compile_n_threads] shows that machine M(S n) can step and reestablish 
            [match_states]. Since we increased the hybrid bound (n -> S n) then the new thread 
            is in Asm and [match_states] can be lifted to [infty_match].
       *)
      Admitted.
      Lemma infinite_machine_step_diagram:
        forall (m : option mem) (sge tge : HybridMachineSig.G)
               (U : list nat) (tr1 : HybridMachineSig.event_trace)
               (st1 : ThreadPool (Some 0)%nat) (m1 : mem) (U' : list nat)
               (tr1' : HybridMachineSig.event_trace)
               (st1' : ThreadPool (Some 0)%nat) (m1' : mem),
          machine_semantics.machine_step (HybConcSem (Some 0)%nat m) sge U tr1
                                         st1 m1 U' tr1' st1' m1' ->
          forall (cd : nth_index) tr2 (st2 : ThreadPool None) 
                 (mu : meminj) (m2 : mem),
            infty_match cd mu st1 m1 st2 m2 ->
            List.Forall2 (inject_mevent mu) tr1 tr2 ->
            exists
              tr2' (st2' : ThreadPool None) (m2' : mem) (cd' : nth_index) 
              (mu' : meminj),
              infty_match cd' mu' st1' m1' st2' m2' /\
              List.Forall2 (inject_mevent mu') tr1' tr2' /\
              machine_semantics.machine_step (HybConcSem None m) tge U tr2 st2
                                             m2 U' tr2' st2' m2'.
      Proof.
        (* Same as the other step diagram.*)
      Admitted.

      Lemma infinite_halted:
        forall (m : option mem) (cd : nth_index) (mu : meminj)
               (U : list nat) (c1 : ThreadPool (Some 0)%nat) 
               (m1 : mem) (c2 : ThreadPool None) (m2 : mem) 
               (v1 : val),
          infty_match cd mu c1 m1 c2 m2 ->
          machine_semantics.conc_halted (HybConcSem (Some 0)%nat m) U c1 =
          Some v1 ->
          exists v2 : val,
            machine_semantics.conc_halted (HybConcSem None m) U c2 =
            Some v2.
      Proof.
        intros m.
        (* Should follow easily from the match. *)
      Admitted.

      Lemma infinite_running:
        forall (m : option mem) (cd : nth_index) (mu : meminj)
               (c1 : ThreadPool (Some 0)%nat) (m1 : mem) (c2 : ThreadPool None)
               (m2 : mem),
          infty_match cd mu c1 m1 c2 m2 ->
          forall i : nat,
            machine_semantics.running_thread (HybConcSem (Some 0)%nat m) c1 i <->
            machine_semantics.running_thread (HybConcSem None m) c2 i.
      Proof.
        intros m.
      (* Should follow from the match relation. And there should be a similar lemma 
             for the [match_states]
       *)
      Admitted.
      Lemma compile_all_threads:
        forall m,
          HybridMachine_simulation.HybridMachine_simulation_properties
            (HybConcSem (Some 0)%nat m)
            (HybConcSem None m)
            infty_match.
      Proof.
        intros. 
        (*All the proofs use the following lemma*)
        pose proof compile_n_threads as HH.
        econstructor.
        - eapply list_lt_wf.
        - apply initial_infty.
        - apply infinite_step_diagram.
        - apply infinite_machine_step_diagram.
        - apply infinite_halted.
        - apply infinite_running.

      Qed.

    End CompileInftyThread.
    
  End ThreadedSimulation.
End ThreadedSimulation.