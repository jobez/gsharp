(defparameter *instructions* '())

(defparameter *ins-del-state* t)

(defparameter *cursors-real* '())

(defparameter *cursors-fake* '())

(defparameter *fc-real* (make-instance 'flexichain:standard-cursorchain))

(defparameter *fc-fake* (make-instance 'stupid:standard-cursorchain))

;; nb-elements fch
;; element* fch pos
;; cursor-pos fcu
;; element< fcu
;; element> fcu

;; insert* fch pos obj
;; delete* fch pos
;; (setf element*)
;; clone-cursor fcu
;; (setf cursor-pos)
;; move> fcu &optional (n 1)
;; move< fcu &optional (n 1)
;; insert fcu obj
;; delete< fcu
;; delete> fcu
;; (setf element<)
;; (setf element>)

;; [flexi-empty-p fch]
;; [push-start fch obj]
;; [push-end fch obj]
;; [pop-start fch obj]
;; [pop-end fch obj]
;; [rotate fch &optional (n 1)]
;; [at-beginning-p fcu]
;; [at-end-p fcu]
;; [insert-sequence fcu sequence]

(defun compare ()
  ;; check that they are the same length
  (assert (= (flexichain:nb-elements *fc-real*)
	     (stupid:nb-elements *fc-fake*)))
  ;; check that they have the same elements in the same places
  (loop for pos from 0 below (flexichain:nb-elements *fc-real*)
	do (assert (= (flexichain:element* *fc-real* pos)
		      (stupid:element* *fc-fake* pos))))
  ;; check all the cursors
  (loop for x in *cursors-real*
	for y in *cursors-fake*
	do (assert (= (flexichain:cursor-pos x)
		      (stupid:cursor-pos y)))
	   (unless (zerop (flexichain:cursor-pos x))
	     (assert (= (flexichain:element< x)
			(stupid:element< y))))
	   (unless (= (flexichain:cursor-pos x)
		      (flexichain:nb-elements *fc-real*))
	     (assert (= (flexichain:element> x)
			(stupid:element> y))))))

(defun add-inst (inst)
  (push inst *instructions*))

(defun i* (&optional
	   (pos (random (1+ (flexichain:nb-elements *fc-real*))))
	   (elem (random 1000000)))   
  (add-inst `(i* ,pos ,elem))
  (flexichain:insert* *fc-real* pos elem)
  (stupid:insert* *fc-fake* pos elem))

(defun d* (&optional (pos (random (flexichain:nb-elements *fc-real*))))
  (add-inst `(d* ,pos))
  (flexichain:delete* *fc-real* pos)
  (stupid:delete* *fc-fake* pos))

(defun se* (&optional pos elem)
  (unless (zerop (stupid:nb-elements *fc-fake*))
    (unless pos
      (setf pos (random (flexichain:nb-elements *fc-real*))
	    elem (random 1000000)))
    (add-inst `(se* ,pos ,elem))
    (setf (flexichain:element* *fc-real* pos) elem)
    (setf (stupid:element* *fc-fake* pos) elem)))

(defun mlc ()
  (add-inst `(mlc))
  (push (make-instance 'flexichain:left-sticky-flexicursor :chain *fc-real*)
	*cursors-real*)
  (push (make-instance 'stupid:left-sticky-flexicursor :chain *fc-fake*)
	*cursors-fake*))
  
(defun mrc ()
  (add-inst `(mrc))
  (push (make-instance 'flexichain:right-sticky-flexicursor :chain *fc-real*)
	*cursors-real*)
  (push (make-instance 'stupid:right-sticky-flexicursor :chain *fc-fake*)
	*cursors-fake*))
  

(defun cc (&optional (elt (random (length *cursors-real*))))
  (add-inst `(cc ,elt))
  (push (flexichain:clone-cursor (elt *cursors-real* elt)) *cursors-real*)
  (push (stupid:clone-cursor (elt *cursors-fake* elt)) *cursors-fake*))

(defun scp (&optional
	    (elt (random (length *cursors-real*)))
	    (pos (random (1+ (flexichain:nb-elements *fc-real*)))))
  (add-inst `(scp ,elt ,pos))
  (setf (flexichain:cursor-pos (elt *cursors-real* elt)) pos)
  (setf (stupid:cursor-pos (elt *cursors-fake* elt)) pos))

(defun m< (&optional (elt (random (length *cursors-real*))))
  (unless (zerop (stupid:cursor-pos (elt *cursors-fake* elt)))
    (add-inst `(m< ,elt))
    (flexichain:move< (elt *cursors-real* elt))
    (stupid:move< (elt *cursors-fake* elt))))
      
(defun m> (&optional (elt (random (length *cursors-fake*))))
  (unless (= (stupid:cursor-pos (elt *cursors-fake* elt))
	     (stupid:nb-elements (stupid:chain (elt *cursors-fake* elt))))
    (add-inst `(m> ,elt))
    (flexichain:move> (elt *cursors-real* elt))
    (stupid:move> (elt *cursors-fake* elt))))

(defun ii (&optional
	   (elt (random (length *cursors-fake*)))
	   (elem (random 1000000)))
  (add-inst `(ii ,elt ,elem))
  (flexichain:insert (elt *cursors-real* elt) elem)
  (stupid:insert (elt *cursors-fake* elt) elem))

(defun d< (&optional (elt (random (length *cursors-real*))))
  (unless (zerop (stupid:cursor-pos (elt *cursors-fake* elt)))
    (add-inst `(d< ,elt))
    (flexichain:delete< (elt *cursors-real* elt))
    (stupid:delete< (elt *cursors-fake* elt))))
      
(defun d> (&optional (elt (random (length *cursors-fake*))))
  (unless (= (stupid:cursor-pos (elt *cursors-fake* elt))
	     (stupid:nb-elements (stupid:chain (elt *cursors-fake* elt))))
    (add-inst `(d> ,elt))
    (flexichain:delete> (elt *cursors-real* elt))
    (stupid:delete> (elt *cursors-fake* elt))))

(defun s< (&optional
	   (elt (random (length *cursors-real*)))
	   (elem (random 1000000)))
  (unless (zerop (stupid:cursor-pos (elt *cursors-fake* elt)))
    (add-inst `(s< ,elt ,elem))
    (setf (flexichain:element< (elt *cursors-real* elt)) elem)
    (setf (stupid:element< (elt *cursors-fake* elt)) elem)))
      
(defun s> (&optional
	   (elt (random (length *cursors-real*)))
	   (elem (random 1000000)))
  (unless (= (stupid:cursor-pos (elt *cursors-fake* elt))
	     (stupid:nb-elements (stupid:chain (elt *cursors-fake* elt))))
    (add-inst `(s> ,elt ,elem))
    (setf (flexichain:element> (elt *cursors-real* elt)) elem)
    (setf (stupid:element> (elt *cursors-fake* elt)) elem)))

(defmacro randomcase (&body clauses)
  `(ecase (random ,(length clauses))
     ,@(loop for clause in clauses
	     for i from 0
	     collect `(,i ,clause))))

(defun i-or-d ()
  (if *ins-del-state*
      (randomcase (i*) (ii))
      (randomcase (d*) (d<) (d>))))

(defun setel ()
  (randomcase (se*) (s<) (s>)))

(defun mc ()
  (randomcase (mlc) (mrc)))

(defun mov ()
  (randomcase  (m<) (m>)))

(defun test-step ()
  (compare)
  (when (zerop (random 200))
    (setf *ins-del-state* (not *ins-del-state*)))
  (randomcase (i-or-d) (setel) (mc) (cc) (scp) (mov)))

(defun reset-all ()
  (setf *instructions* '())
  (setf *ins-del-state* t)
  (setf *cursors-real* '())
  (setf *cursors-fake* '())
  (setf *fc-real* (make-instance 'flexichain:standard-cursorchain))
  (setf *fc-fake* (make-instance 'stupid:standard-cursorchain)))
  
(defun tester ()
  (reset-all)
  (mlc)
  (mrc)
  (loop repeat 100000
	do (test-step)))

(defun replay (instructions)
  (let ((*instructions* '()))
    (reset-all)
    (loop for inst in (reverse instructions)
	  do (apply (car inst) (cdr inst)))))