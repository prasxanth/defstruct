# defstruct

<font size = "+2"> Simple class declaration with automatic property definitions and type validation </font>

## Installation

Install using `setup.py` (`--user` is optional)

```bash
python3 setup.py install --user
```

or in development mode,

```bash
python3 setup.py develop --user
```

##  API

This package provides the `defstruct` macro for simple class declarations. It aims to reduce boilerplate code by automatically defining properties. It also provides type validation through `pydantic.validate_arguments`. 

### Usage
The typical use of `defstruct` resembles the simplest form of [dataclasses](https://docs.python.org/3/library/dataclasses.html), [attrs](https://github.com/python-attrs/attrs) or [pydantic](https://github.com/samuelcolvin/pydantic),


```hy
(require [defstruct.defs [defstruct]])

(defstruct struct []  (^(of float) data 
                        ^int x 
                        &optional ^(of str) [s None]
                        &kwonly ^float [f 0.5]))
```

```hy
(setv test-struct (struct 0.3 2 "pqr"))
```

```hy
test-struct
```

```hy
(struct :data 0.3 :x 2 :s 'pqr' :f 0.5)
```


As seen above, the `__repr__` method is provided for displaying a nicely formatted string representation of `defstruct` objects.

### `defproperty`

Properties associated with each input are defined automatically. The convention is to represent "internal" (private) class variables by surrounding them with double underscores. So the variable `data` in the struct above would have the following, automatically defined, property 

```
(with-decorator property
  (defn data [self]
    return __self.data__))
```

The objective is to have read-only properties, so setters are not automatically defined.

A `defproperty` macro is provided for defining custom properties, 

```hy
(defmacro defproperty [attribute &optional docstring &rest body]
  `(with-decorator property
     (defn ~(HySymbol attribute) [self]
       ~docstring
       (do ~@body)
       (return (getattr self (+ "__" ~attribute "__"))))))
```

`defproperty` is used to automatically define the properties in `defstruct`.

### Customization

`defstruct` is flexible allowing for definition of custom properties, methods and even changing the automatically defined properties.


```hy
(require [defstruct.defs [defproperty]])

(defstruct struct-custom [] (^(of float) data 
                              ^(of int) x 
                              ^(of str) doc) 
           
    "Documentation for custom struct."

    (defproperty "info"
        (setattr self "__info__" (+ self.data self.x))))
```

```hy
(setv test-struct-custom (struct-custom 2.0 3 "abc"))
```

```hy
test-struct-custom
```

```hy
(struct_custom :data 2.0 :x 3 :doc 'abc' :info 5.0)
```


A `__post-init__` method allows for implementating functionality after `__init__`,

```hy
(defstruct struct-post-init [] (^(of float) data ^(of int) x ^(of str) doc) "some doc"

    (defproperty "info")

    (defn __post-init__ [self]
      (setattr self "__info__" (+ self.data self.x))))
```

```hy
(setv test-struct-post-init (struct-post-init 2.0 3 "abc"))
```


```hy
struct-post-init
```

```hy
(struct_post_init :data 2.0 :x 3 :doc 'abc' :info 5.0)
```

Of course one the `__init__` method can be overwritten if needed.

### Type validation

Basic type validation is provided by `pydantic.validate_arguments`,


```hy
(setv test-struct-type-validate (struct 0.3 ["wrong type"] "pqr"))
```

    [0;31mTraceback (most recent call last):
      File "/home/prashanth/.local/lib/python3.6/site-packages/calysto_hy/kernel.py", line 145, in do_execute_direct
        eval(exec_code, self.locals)
      File "In [28]", line 1, in <module>
      File "/usr/local/lib/python3.6/dist-packages/pydantic/decorator.py", line 39, in wrapper_function
        return vd.call(*args, **kwargs)
      File "/usr/local/lib/python3.6/dist-packages/pydantic/decorator.py", line 132, in call
        m = self.init_model_instance(*args, **kwargs)
      File "/usr/local/lib/python3.6/dist-packages/pydantic/decorator.py", line 129, in init_model_instance
        return self.model(**values)
      File "/usr/local/lib/python3.6/dist-packages/pydantic/main.py", line 406, in __init__
        raise validation_error
    pydantic.error_wrappers.ValidationError: 1 validation error for Init
    x
      value is not a valid integer (type=type_error.integer)
    
    [0m

## Tests
Ensure `hy` is in the executable path. Tests are written using the [hyprovo](https://github.com/prasxanth/hyprovo) library. Run the `tests.hy` command line script from inside the [tests](tests) directory,

```bash
./tests.hy
```

A log file with the start timestamp will be created in the [logs](tests/logs) subdirectory.
