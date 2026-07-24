# f-binheap - A functional binary heap implementation

This library is an functional implementation of a binary heap.
You never update the existing heap, but instead each change returns
a new version of the heap that shares some of its structure with
the previous version.

## Installing

There may be better ways to do this with ASDF, but this is how I
installed this locally on my system. First, I went into my lisp
system (SBCL) and did: `asdf:*central-registry*`

Since I am using Quicklsp, it said it was `/home/mark/quicklisp/quicklisp`.

So, I created a symbolic link from binheap.asd to `/home/mark/quicklisp/quicklisp`:

```shell
ln -s /home/mark/lispprogs/f-binheap/f-binheap.asd /home/mark/quicklisp/quicklisp/f-binheap.asd
```

Then from within SBCL I can load it with:

```lisp
(asdf:operate 'asdf:load-op :f-binheap)
```

## Usage

I usually do `(use-package :com.wutka.f-binheap)` to put the binheap
functions into my local namespace.

### make-binheap

To create a new binary heap, use `make-binheap`. For example:

```lisp
(setf myheap (make-binheap))
```

You can also use the `:compare` keyword to specify a comparison function.
The default is `#'<`. The
comparison function should take two items and return true if the
first item should be the parent of the second item. Since `#'<` is the
default comparison function, the heap defaults to having the smallest
item at the top. If you are just storing numbers and want the heap
to have the largest number on the top, you can supply `#'>` as the
comparison func:

```lisp
(setf myheap (make-binheap :compare #'>))
```

Finally, if you have a sequence of objects to store in the heap,
you can specify them with the `:initial-contents` keyword:

```lisp
(setf myheap (make-binheap :initial-contents '(5 1 4 3 2)))
```

### binheap-push

To add a new item to the heap, use `binheap-push` _heap_ _new-item_:

```lisp
(binheap-push myheap 7)
```

If you just do the push and don't save it, though, the push won't really
have done anything. This will push a value and then update the `myheap` variable:

```lisp
(setf myheap (binheap-push myheap 7))
```

### binheap-pop

To pop the item off the top of the heap, use `binheap-pop` _heap_:

```lisp
(binheap-pop myheap)
```

The `binheap-pop` function returns multiple values. The first is the new copy
of the binheap with the popped item removed. Here is one way to view the popped
item and update the `myheap` variable:

```lisp
(multiple-value-bind (new-heap popped-value)
    (binheap-pop myheap)
  (format t "Popped ~a~%" popped-value)
  (setf myheap newheap))
```

If the heap is empty, the function returns `nil` for the value, and returns the heap
unchanged.

### binheap-emptyp

The `binheap-emptyp` function returns true if the heap is empty.

### binheap-top

Returns the top value in the heap (the value that would be popped next).
It returns `nil` if the heap is empty. This function exists in case you
don't want to use the multiple value return of `binheap-pop`. For example:
```lisp
(defun dump-binheap (bh)
	   (when (not (binheap-emptyp bh))
	     (format t "~a~%" (binheap-top bh))
	     (dump-binheap (binheap-pop bh))))
```

### Example

Here is an example that creates an empty heap, populates it, and
then pops off the values:

```lisp
* (asdf:operate 'asdf:load-op :f-binheap)
#<ASDF/LISP-ACTION:LOAD-OP >
#<ASDF/PLAN:SEQUENTIAL-PLAN {1201A14283}>
* (use-package :com.wutka.f-binheap)
T
* (defun dump-binheap (bh)
           (when (not (binheap-emptyp bh))
             (format t "~a~%" (binheap-top bh))
             (dump-binheap (binheap-pop bh))))
DUMP-BINHEAP
* (setf myheap (make-binheap))
#S(COM.WUTKA.F-BINHEAP::BH :ROW 0 :COL 0 :ROOT NIL :COMPARE #<FUNCTION <>)
* (setf myheap (reduce #'binheap-push '(7 3 12 8) :initial-value myheap))
#S(COM.WUTKA.F-BINHEAP::BH
   :ROW 2
   :COL 1
   :ROOT #S(COM.WUTKA.F-BINHEAP::BHNODE
            :V 3
            :LEFT #S(COM.WUTKA.F-BINHEAP::BHNODE
                     :V 7
                     :LEFT #S(COM.WUTKA.F-BINHEAP::BHNODE
                              :V 8
                              :LEFT NIL
                              :RIGHT NIL)
                     :RIGHT NIL)
            :RIGHT #S(COM.WUTKA.F-BINHEAP::BHNODE :V 12 :LEFT NIL :RIGHT NIL))
   :COMPARE #<FUNCTION <>)
* (dump-binheap myheap)
3
7
8
12
NIL
*
```

