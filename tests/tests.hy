#!/usr/bin/env hy

(require [hyprovo.framework [check
                             report-combined-results
                             deftest
                             defsuite]])
(import [hyprovo.framework [combine-results ▶]])

(import [hyprovo.logger [console-logger
                         console-and-file-logger]])

(require [defstruct.defs [defproperty
                          parse-args
                          defstruct]])

(import os)
(setv make-path (. os path join))

(import [datetime [datetime]])

(defn now-str []
  "Return current timestamp as string upto precision of seconds."
  (.strftime (.now datetime) "%Y%m%d%H%M%S"))

(deftest test-parsed-args
  (setv parsed-args%
        (parse-args (^(of int) y &optional ^(of str) [x None] &kwonly ^int [a 0])))
  (check (= (HyExpression parsed-args%) `(y [x None] [a 0])
            "Annotations ^(of ...), ^; & parameters: &optional, &kwonly; defaults")))

(deftest test-defstruct-basic
  (defstruct struct [] (^(of float) data ^(of int) x ^(of str) doc))
  (setv test-struct (struct 1.0 3 "abc"))
  (check (= (str test-struct) "(struct :data 1.0 :x 3 :doc 'abc')"
            "Basic case with annotations [^(of ...)] and standard data types")))

(deftest test-defstruct-optional-kwonly
  (defstruct struct []  (^(of float) data ^int x &optional ^(of str) [doc None]
                          &kwonly ^float [f 0.5]))

  (setv test-struct-1 (struct 0.3 2 "pqr")
        test-struct-2 (struct 5.6 -7 :f 0.2)
        test-struct-3 (struct -0.2 10 "abc" :f 0.01)
        test-struct-4 (struct 9.1 3))

  (combine-results
    (check (= (str test-struct-1) "(struct :data 0.3 :x 2 :doc 'pqr' :f 0.5)"
              "Standard data types, mixed annotations [^(of ...) and ^type], &optional value and default &kwonly parameter")
           (= (str test-struct-2) "(struct :data 5.6 :x -7 :doc None :f 0.2)"
              "Standard data types, mixed annotations [^(of ...) and ^type], &kwonly value and default &optional parameter")
           (= (str test-struct-3) "(struct :data -0.2 :x 10 :doc 'abc' :f 0.01)"
              "Standard data types, mixed annotations [^(of ...) and ^type], values for &optional and &kwonly parameters")
           (= (str test-struct-4) "(struct :data 9.1 :x 3 :doc None :f 0.5)"
              "Standard data types, mixed annotations [^(of ...) and ^type], default &optional and &kwonly parameters"))))

(deftest test-defstruct-custom-property
  (defstruct struct [] (^(of float) data ^(of int) x ^(of str) doc) "some doc"

    (defproperty "info")

    (defn __post-init__ [self]
      (setattr self "__info__" (+ self.data self.x))))

  (setv test-struct (struct 2.0 3 "abc"))

  (combine-results
    (check (= (. test-struct info) 5.0
              "Custom property default in __post-init__ method initialized correctly")
           (= (str test-struct) "(struct :data 2.0 :x 3 :doc 'abc' :info 5.0)"
              "Custom property with default in '__post-init__ method"))))

(deftest test-defstruct
  (combine-results
    (▶ (test-defstruct-basic)
       (test-defstruct-optional-kwonly)
       (test-defstruct-custom-property))))

(defsuite test-suite-module
  (-> (combine-results
        (▶ (test-parsed-args) (test-defstruct)))
      (report-combined-results)))

;; the logger outputs to both console and file. The file defaults to the start
;; timestamp of each test run.
(setv log-file% (make-path "logs" (+ (now-str) ".log"))
      test-logger% (console-and-file-logger :log-file log-file%))
(test-suite-module :test-logger test-logger%)
