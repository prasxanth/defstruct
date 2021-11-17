(defmacro defproperty [attribute &optional docstring &rest body]
  "Generates property to return private attribute (__ attr __).

  Parameters
  ----------
  attribute -- name string
  docstring -- documentation for property (optional)
  body -- statements (typically representing transformations to private attribute)
  "
  `(with-decorator property
     (defn ~(HySymbol attribute) [self]
       ~docstring
       (do ~@body)
       (return (getattr self (+ "__" ~attribute "__"))))))

(defmacro parse-args [&rest args]
  "Extracts argument names and corresponding defaults (if any) from input arguments."
  `(->> (lfor args% '~@args
              (cond [(.startswith (str args%) "&") (continue)]
                 [(or (isinstance args% HyList) 
                      (isinstance args% HySymbol)) args%]))
        (filter None)
        (HyList)))

(defmacro! defstruct [struct-name inherits properties
                        &optional docstring &rest body]
  "Generates boilerplate code for class.

  Parameters
  ----------

  recname -- name of class
  inherits -- list of super classes
  properties -- tuple with variables names, defaults and corresponding type annotations
  docstring -- documentation for generated class (optional)
  body -- custom code for class
  "

  `(do
     (require [defstruct.defs :as defstruct-defs])
     (import [hy [HyList]])
     (import [pydantic [validate-arguments]])
     
     (setv ~g!pargs% (defstruct-defs.parse-args ~properties)
           ~g!pvars% (lfor arg% ~g!pargs% (if (isinstance arg% HyList) (first arg%) arg%)))

     (defclass ~struct-name [~@inherits]

       ~docstring

       #@(validate-arguments
           (defn __init__ [self ~@properties]
             (for [arg% ~g!pargs%]
               (if (isinstance arg% HyList)
                   (setattr self (+ "__" (str (first arg%)) "__")
                            (or (eval (first arg%)) (eval (second arg%))))
                   (setattr self (+ "__" (str arg%) "__") (eval arg%))))

             (self.__post-init__)))

       (defn __post-init__ [self])

        (for [var% ~g!pvars%] (eval `(defstruct-defs.defproperty ~(str var%))))

        (do ~@body)

        (defn __repr__ [self]
         (setv ~g!repr% (+ "(" (. self __class__ __name__)))
         (setv ~g!properties% (lfor (, k% v%) (.items (. self __class__ __dict__))
                               :if (isinstance v% property) k%))
         (for [prop% ~g!properties%]
           (setv ~g!repr% (+ ~g!repr%
                            " :" prop% " "
                            (-> (getattr self prop%) (repr)))))
         (return (+ ~g!repr% ")"))))))
