Documentation
=============

General Structure
-----------------

This documentation only gives a broad overview of how SimStm files are supposed to be written.
More detailed information can be found in src/rst/language.

At the beginning of a file, you declare any imports you might need, using ``include``.
You include a file using its file path (respective to the current file) and with double quotes.
An import declaration cannot be inside a namespace.

A namespace is similar to a class, and every piece of code (except imports) inside a file needs to be written inside a namespace.
Namespaces ensure capsulation. A namespace needs to be closed, using ``end namespace``.

What you can do
---------------

Inside your namespace, you can start working. You can declare any kind of object, like a variable or an array,
as well as procedures.

Objects declarations are of the form ``obj an_obj x`` with ``obj`` being the type, ``an_obj`` the ID and ``x``
the value. The type of value depends on the object.

Procedures are declared using ``proc a_proc ()`` and closed using ``end proc``.
Parameters are given inside the brackets, and with a default value in case a procedure call doesnt give one.
As usual, an object declared inside a procedure is only visible and accessible inside that procedure.

You can output messages using ``log message a_var "string"`` to print a given string
or ``log lines a_var a_lines`` to print a lines object. ``a_var`` indicates the verbosity level.

Using ``an_obj pointer copy x y``, you can also work with pointers. Here, ``x`` points to ``y``.

To verify the value of an object, you can call ``an_obj verify a b M``. This verifies, that ``an_obj``
that ``a``, which is of type ``an_obj``, has the value ``b``.


These are the most important instructions SimStm contains. You can find detailed descriptions to all of them
as well as even more instructions in src/rst/language.



