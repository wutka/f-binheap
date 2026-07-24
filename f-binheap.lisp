(in-package :com.wutka.f-binheap)

(defstruct bhnode
	   (v nil)
	   (left nil)
	   (right nil))

(defstruct bh
	   (row 0)
	   (col 0)
	   (root nil)
	   (comp #'<))

(defun make-binheap (&key (initial-contents nil) (comp #'<))
  (let ((bh (make-bh :comp comp)))
    (if initial-contents
	(reduce #'binheap-push initial-contents :initial-value bh)
	bh)))


(defun binheap-push (bh item)
  ;; insert the item in the tree
  (let ((new-root
	  (binheap-insert bh item (bh-root bh) (bh-row bh))))
    (multiple-value-bind (next-row next-col)
	(increment-size bh)
      ;; return a new tree with the updated last position
      (make-bh :row next-row :col next-col :root new-root
	       :comp (bh-comp bh)))))

(defun binheap-emptyp (bh)
  (not (bh-root bh)))

(defun binheap-pop (bh)
  (if (not (bh-root bh)) (values nil bh)
      (if (and (= (bh-row bh) 1) (= (bh-col bh) 0))
	  ;; If there is only one item in the the heap,
	  ;; return it and an empty heap
	  (values (make-bh :row 0 :col 0 :root nil
			   :comp (bh-comp bh))
		  (bhnode-v (bh-root bh)))
	  ;; Otherwise, remove the top element and rebalance
	  (values (binheap-rebalance-down
		   (binheap-last-to-top bh))
		  (bhnode-v (bh-root bh))))))

(defun binheap-top (bh)
  (if (not (bh-root bh)) nil
      (bhnode-v (bh-root bh))))

;;; Compute the next row and col after the current one
(defun increment-size (bh)
  (let ((next-col (1+ (bh-col bh))))
    ;; If the next-col is larger that the row size, increment the row
    (if (= next-col (ash 1 (bh-row bh)))
	(values (1+ (bh-row bh)) 0)
	(values (bh-row bh) next-col))))

;;; Compute the prev row and col before the current one
(defun decrement-size (bh)
  (if (= 0 (bh-col bh))
      (if (<= (bh-row bh) 1)
	  ;; If the row is 1 or 0, the prev is 0 0
	  (values 0 0)
	  ;; Otherwise, if col is currently 0, then back up
	  ;; one row and set col to the far right
	  (values (1- (bh-row bh)) (1- (ash 1 (1- (bh-row bh))))))
      (values (bh-row bh) (1- (bh-col bh)))))

;;; Insert a new value in the tree
;;; The algorithm for an array-based tree has you putting the
;;; new item at the last open spot, and then rebalancing upward
;;; moving that item up in the tree.
;;; Since we know the path from the root to the final place,
;;; we instead just build the tree on the way down, comparing
;;; the new value with the current node, and when it is "less"
;;; than the current node, we set it as the value of the current
;;; node and then continue down the tree inserting the old value
;;; of the current node
(defun binheap-insert (bh item curr-node row)
  (if (= row 0) (make-bhnode :v item :left nil :right nil)
      (let ((curr-val (bhnode-v curr-node)))
	;;; Figure out which value belongs in the current node
	;;; and which needs to be inserted in the child
	(multiple-value-bind (parent-val child-val)
	    (if (funcall (bh-comp bh) item curr-val)
		(values item curr-val)
		(values curr-val item))
	  (if (= 0 (logand (bh-col bh) (ash 1 (1- row))))
	      ;;; If the bit for this row is 0, modify the left child
	      (make-bhnode :v parent-val
			   :left (binheap-insert bh child-val
						 (bhnode-left curr-node)
						 (1- row))
			   :right (bhnode-right curr-node))
	      ;;; If the bit for this row is 1, modify the right child
	      (make-bhnode :v parent-val
			   :left (bhnode-left curr-node)
			   :right (binheap-insert bh child-val
						  (bhnode-right curr-node)
						  (1- row))))))))

;;; Remove the last item from the heap
(defun binheap-remove-last-item (curr-node row col)
  (if (= row 1)
      ;;; if this is the next-to-last row, one of the children
      ;;; of this node needs to be removed
      (if (= 0 (logand col (ash 1 (1- row))))
	  ;;; If the last bit is 0, remove the left child
	  (values (bhnode-v (bhnode-left curr-node))
		  (make-bhnode :v (bhnode-v curr-node)
			       :left nil :right nil))
	  ;;; otherwise remove the right child
	  (values (bhnode-v (bhnode-right curr-node))
		  (make-bhnode :v (bhnode-v curr-node)
			       :left (bhnode-left curr-node)
			       :right nil)))
      ;;; See whether we need to traverse the left or right
      (if (= 0 (logand col (ash 1 (1- row))))
	  ;;; If the bit for this row is 0, go left
	  (multiple-value-bind (last-value new-left)
	      (binheap-remove-last-item (bhnode-left curr-node)
					(1- row) col)
	    (values last-value
		    (make-bhnode :v (bhnode-v curr-node)
				 :left new-left
				 :right (bhnode-right curr-node))))
	  ;;; Otherwise go right
	  (multiple-value-bind (last-value new-right)
	      (binheap-remove-last-item (bhnode-right curr-node)
					(1- row) col)
	    (values last-value
		    (make-bhnode :v (bhnode-v curr-node)
				 :left (bhnode-left curr-node)
				 :right new-right))))))

;;; Remove the last item from the heap and store it in
;;; root node (the heap must be rebalanced after this)
(defun binheap-last-to-top (bh)
  (multiple-value-bind (new-row new-col)
      (decrement-size bh)
    ;;; Get the last item and a copy of the heap with
    ;;; that last item removed
    (multiple-value-bind (last-item new-root)
	(binheap-remove-last-item (bh-root bh) new-row new-col)

      ;;; Return a new heap with the last item replacing the
      ;;; item at the root
      (make-bh :row new-row :col new-col
	       :root (make-bhnode :v last-item
				  :left (bhnode-left new-root)
				  :right (bhnode-right new-root))
	       :comp (bh-comp bh)))))

(defun binheap-rebalance-down-1 (bh curr-node)
  (if (not (bhnode-left curr-node)) curr-node
      ;; If there is a right node..
      (if (bhnode-right curr-node)
	  (let* ((left (bhnode-left curr-node))
		 (right (bhnode-right curr-node))
		 (v (bhnode-v curr-node))
		 (left-v (bhnode-v left))
		 (right-v (bhnode-v right)))
	    (cond
	      ;; If the left value is less than the current value and left is less than right
	      ;; swap the values of curr node and left, and rebalance the left
	      ((and (funcall (bh-comp bh) left-v v)
		    (funcall (bh-comp bh) left-v right-v))
	       (make-bhnode :v left-v
			    :left (binheap-rebalance-down-1 bh
							    (make-bhnode :v v
									 :left (bhnode-left left)
									 :right (bhnode-right left)))
			    :right right))
	      ;; Otherwise, if the right value is less than the current value,
	      ;; swap the values of curr node and right, and rebalance the right
	      ((funcall (bh-comp bh) right-v v)
	       (make-bhnode :v right-v
			    :left left
			    :right (binheap-rebalance-down-1 bh
							     (make-bhnode :v v
									  :left (bhnode-left right)
									  :right (bhnode-right right)))))
	      ;; If we get here, no further rebalancing is necessary
	      (t curr-node)))
	  
	  ;; If there was no right node, but there is a left, see if
	  ;; the values need to swap
	  (let* ((left (bhnode-left curr-node))
		 (left-v (bhnode-v left))
		 (v (bhnode-v curr-node)))
	    (if (funcall (bh-comp bh) left-v v)
		(make-bhnode :v left-v
			     :left (binheap-rebalance-down-1 bh (make-bhnode :v v
									     :left (bhnode-left left)
									     :right (bhnode-right left))))
		;; Otherwise, no more rebalancing is necessary
		curr-node)))))

(defun binheap-rebalance-down (bh)
  (make-bh :row (bh-row bh) :col (bh-col bh)
	   :root (binheap-rebalance-down-1 bh (bh-root bh))
	   :comp (bh-comp bh)))
