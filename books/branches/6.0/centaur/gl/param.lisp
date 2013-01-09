

(in-package "GL")

(include-book "shape-spec")


(local (include-book "gtype-thms"))
(local (include-book "data-structures/no-duplicates" :dir :system))
(local (include-book "tools/mv-nth" :dir :system))
(local (include-book "ihs/ihs-lemmas" :dir :system))

(include-book "centaur/ubdds/param" :dir :system)
(include-book "centaur/ubdds/lite" :dir :system)
(include-book "../aig/misc")
(local (include-book "../aig/eval-restrict"))

(defun bfr-to-param-space (p x)
  (declare (xargs :guard (and (bfr-p p) (bfr-p x)))
           (ignorable p))
  (bfr-case :bdd (acl2::to-param-space p x)
            :aig (acl2::aig-restrict
                  x (acl2::aig-extract-iterated-assigns-alist p 10))))

(defun bfr-list-to-param-space (p x)
  (declare (xargs :guard (and (bfr-p p) (bfr-listp x)))
           (ignorable p))
  (bfr-case :bdd (acl2::to-param-space-list p x)
            :aig (acl2::aig-restrict-list
                  x (acl2::aig-extract-iterated-assigns-alist p 10))))

(local
 (defthm bfr-p-to-param-space
   (implies (bfr-p x)
            (bfr-p (bfr-to-param-space p x)))
   :hints(("Goal" :in-theory (enable bfr-p)))))

(local
 (defthm bfr-listp-to-param-space-list
   (implies (bfr-listp lst)
            (bfr-listp (bfr-list-to-param-space p lst)))
   :hints(("Goal" :in-theory (enable bfr-listp bfr-p)))))

(in-theory (disable bfr-to-param-space bfr-list-to-param-space))

(defund gnumber-to-param-space (n p)
  (declare (xargs :guard (and (bfr-p p) (wf-g-numberp n))
                  :guard-hints
                  (("goal" :in-theory (enable wf-g-numberp)))))
  (cons (bfr-list-to-param-space p (car n))
        (and (consp (cdr n))
             (cons (bfr-list-to-param-space p (cadr n))
                   (and (consp (cddr n))
                        (cons (bfr-list-to-param-space p (caddr n))
                              (and (consp (cdddr n))
                                   (list (bfr-list-to-param-space
                                          p (cadddr n))))))))))

(local
 (defthm wf-g-numberp-gnumber-to-param-space
   (implies (wf-g-numberp n)
            (wf-g-numberp (gnumber-to-param-space n p)))
   :hints(("Goal" :in-theory (enable wf-g-numberp gnumber-to-param-space)))))


(defund gobj-to-param-space (x p)
  (declare (xargs :guard (and (bfr-p p) (gobjectp x))
                  :verify-guards nil))
  (if (atom x)
      x
    (pattern-match x
      ((g-concrete &) x)
      ((g-boolean b) (mk-g-boolean (bfr-to-param-space p b)))
      ((g-number n) (g-number (gnumber-to-param-space n p)))
      ((g-ite if then else)
       (mk-g-ite (gobj-to-param-space if p)
                 (gobj-to-param-space then p)
                 (gobj-to-param-space else p)))
      ((g-apply fn args) (g-apply fn (gobj-to-param-space args p)))
      ((g-var &) x)
      (& (cons (gobj-to-param-space (car x) p)
               (gobj-to-param-space (cdr x) p))))))

(local (in-theory (enable tag-when-g-var-p
                          tag-when-g-ite-p
                          tag-when-g-apply-p
                          tag-when-g-number-p
                          tag-when-g-boolean-p
                          tag-when-g-concrete-p)))

(defthm gobjectp-gobj-to-param-space
  (implies (gobjectp x)
           (gobjectp (gobj-to-param-space x p)))
  :hints(("Goal" :in-theory (e/d (gobjectp-def gobj-to-param-space)
                                 ((force))))))

(verify-guards gobj-to-param-space
               :hints(("Goal" :in-theory (e/d (gobjectp) ((force))))))

(defun bfr-param-env (p env)
  (declare (xargs :guard t)
           (ignorable p))
  (bfr-case :bdd (acl2::param-env p env)
            :aig env))

(defund genv-param (p env)
  (declare (xargs :guard (consp env))
           (ignorable p))
  (cons (bfr-param-env p (car env))
        (cdr env)))

(local
 (defthmd gobjectp-g-number-2
   (implies (and (wf-g-numberp (g-number->num x))
                 (g-number-p x))
            (gobjectp x))
   :hints(("Goal" :in-theory (enable g-number-p g-number->num tag gobjectp-def)))
   :rule-classes ((:rewrite :backchain-limit-lst (nil 0)))))

(local
 (defthm gobjectp-g-number-list1
   (implies (bfr-listp x)
            (gobjectp (g-number (list x))))
   :hints(("Goal" :in-theory (enable gobjectp-def tag g-number-p
                                     wf-g-numberp-simpler-def)))))

(local
 (defthm gobjectp-g-number-list2
   (implies (and (bfr-listp x)
                 (bfr-listp y))
            (gobjectp (g-number (list x y))))
   :hints(("Goal" :in-theory (enable gobjectp-def tag g-number-p
                                     wf-g-numberp-simpler-def)))))

(local
 (defthm gobjectp-g-number-list3
   (implies (and (bfr-listp x)
                 (bfr-listp y)
                 (bfr-listp z))
            (gobjectp (g-number (list x y z))))
   :hints(("Goal" :in-theory (enable gobjectp-def tag g-number-p
                                     wf-g-numberp-simpler-def)))))

(local
 (defthm gobjectp-g-number-list4
   (implies (and (bfr-listp x)
                 (bfr-listp y)
                 (bfr-listp z)
                 (bfr-listp w))
            (gobjectp (g-number (list x y z w))))
   :hints(("Goal" :in-theory (enable gobjectp-def tag g-number-p
                                     wf-g-numberp-simpler-def)))))

(local
 (defthm wf-g-numberp-implies-bfr-listps
   (implies (wf-g-numberp (g-number->num x))
            (and (bfr-listp (car (g-number->num x)))
                 (bfr-listp (cadr (g-number->num x)))
                 (bfr-listp (caddr (g-number->num x)))
                 (bfr-listp (cadddr (g-number->num x)))))
   :hints(("Goal" :in-theory (enable wf-g-numberp)))))

(local
 (defthmd gobjectp-g-boolean-2
   (implies (and (bfr-p (g-boolean->bool x))
                 (g-boolean-p x))
            (gobjectp x))
   :hints(("Goal" :in-theory (enable gobjectp-def g-boolean-p g-boolean->bool
                                     tag)))
   :rule-classes ((:rewrite :backchain-limit-lst (nil 0)))))

(local
 (defthm gobjectp-g-ite-p
   (implies (and (g-ite-p x)
                 (gobjectp (g-ite->test x))
                 (gobjectp (g-ite->then x))
                 (gobjectp (g-ite->else x)))
            (equal (gobj-fix x) x))
   :hints(("Goal" :in-theory (enable gobjectp-def g-ite-p g-ite->test
                                     g-ite->then g-ite->else tag)))))


(local
 (defthm bfr-eval-to-param-space
   (implies (bfr-eval p env)
            (equal (bfr-eval (bfr-to-param-space p x)
                             (bfr-param-env p env))
                   (bfr-eval x env)))
   :hints(("Goal" :in-theory (e/d* (bfr-eval
                                    bfr-to-param-space
                                    acl2::param-env-to-param-space))))))

(local
 (defthm bfr-eval-list-to-param-space-list
   (implies (bfr-eval p env)
            (equal (bfr-eval-list (bfr-list-to-param-space p x)
                                  (bfr-param-env p env))
                   (bfr-eval-list x env)))
   :hints(("Goal" :in-theory (enable bfr-eval-list
                                     bfr-eval
                                     bfr-list-to-param-space)))))

(local
 (defthm nth-open-const-idx
   (implies (syntaxp (quotep n))
            (equal (nth n lst)
                   (if (zp n)
                       (car lst)
                     (nth (1- n) (cdr lst)))))
   :hints(("Goal" :in-theory (enable nth)))))

(local
 (defthm bfr-eval-list-nil
   (Equal (bfr-eval-list nil env)
          nil)
   :hints (("goal" :in-theory (enable bfr-eval-list)))))

(local
 (defthm bfr-eval-list-t
   (Equal (bfr-eval-list '(t) env)
          '(t))
   :hints (("goal" :in-theory (enable bfr-eval-list)))))

(defthm gobj-to-param-space-correct
  (implies (and (gobjectp x)
                (bfr-eval p (car env)))
           (equal (generic-geval (gobj-to-param-space x p)
                               (genv-param p env))
                  (generic-geval x env)))
  :hints(("Goal" :in-theory
          (e/d* ((:induction gobj-to-param-space)
                 genv-param
                 gobjectp-g-boolean-2
                 gobjectp-g-number-2
                 gnumber-to-param-space
                 break-g-number default-car default-cdr)
                ((force) bfr-eval-list
                 generic-geval-non-gobjectp
                 bfr-p
                 eval-concrete-gobjectp
                 components-to-number-alt-def
                 boolean-listp bfr-eval
                 gobjectp-g-boolean-2
                 gobjectp-g-number-2
                 gobj-fix-when-not-gobjectp
                 gobjectp-def
                 (:rules-of-class :type-prescription :here)
                 ; generic-geval-when-g-var-tag
                 
;                 bfr-eval-of-non-consp-cheap
;                 bfr-eval-when-not-consp
                 bfr-to-param-space
                 bfr-list-to-param-space
                 bfr-param-env
                 hons-assoc-equal
                 (:ruleset gl-tag-rewrites)
                 (:ruleset gl-wrong-tag-rewrites))
                ((:type-prescription len)))
          :induct (gobj-to-param-space x p)
          :expand ((gobj-to-param-space x p)))
         (and stable-under-simplificationp
              (flag::expand-calls-computed-hint
               acl2::clause '(generic-geval)))))



(defun shape-spec-to-gobj-param (spec p)
  (declare (xargs :guard (and (shape-specp spec)
                              (bfr-p p))))
  (gobj-to-param-space (shape-spec-to-gobj spec) p))

(defun shape-spec-to-env-param (x obj p)
  (declare (xargs :guard (shape-specp x)))
  (genv-param p (shape-spec-to-env x obj)))


(defthm eval-bfr-to-param-space-self
  (implies (bfr-eval x (car env))
           (bfr-eval (bfr-to-param-space x x) (car (genv-param x env))))
  :hints(("Goal" :in-theory (enable bfr-eval bfr-to-param-space genv-param
                                    bfr-param-env
                                    default-car))))