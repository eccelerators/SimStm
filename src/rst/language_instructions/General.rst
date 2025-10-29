SimStm Language Instructions
----------------------------

General
~~~~~~~

In SimStm instructions a line is a instruction, except empty lines or
comment only lines. Subroutine labels are considered as instruction in
this manner too.

The colon postfix of a subroutine label must end with a colon. No space
is allowed between the label ID and the colon. Otherwise the
SimStm language is not white space sensitive.

The SimStm language is case sensitive.

All constants, variables and label IDs are global within a SimStm project.
The IDs must be unique.

There are no subroutine parameters or local variables. Values must be
passed by unique global objects. This is an accommodation to having a
simple SimStm interpreter and develops its own charm when using and
debugging it.

The subroutine with the label ``testMain:``\ is the entry point into the
SimStm code for the simulator.

Comments
~~~~~~~~

.. code-block:: none

 -- This is a full line comment
 const aconst 0x03 -- This is an appended line comment

| Comments in a line start with two hyphens.
| There are only line comments, no block comments.

Includes, Language Objects, and Declarations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Include
^^^^^^^

.. code-block:: none

 include "aninclude.stm"

Include another child ``\*.stm file``.

The ``include`` instructions should be the first instructions of a ``\*.stm file``.
An included file can include further ``\*.stm files``, thus nested includes
are possible. The file path to be given is relative to the file with the
respective include instruction. Nested includes of files from the same
folder or in child folders are predictable; nested includes to files in
parent folders would be bad practice.
