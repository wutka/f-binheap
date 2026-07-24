(defpackage :com.wutka.binheap-system (:use :asdf :cl))
(in-package :com.wutka.binheap-system)

(defsystem f-binheap
  :name "f-binheap"
  :author "Mark Wutka <mark@wutka.com>"
  :version "1.0"
  :license "BSD"
  :description "Funcational Binary heap"
  :long-description ""
  :components
  ((:file "package")
   (:file "f-binheap" :depends-on ("package")))
  :depends-on ())
