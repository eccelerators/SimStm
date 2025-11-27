Lines
-----

.. code-block:: simstm

 lines a_lines

The ``lines`` instruction declares a lines object with an ID.

The lines object contains an arbitrary number of line objects. It is
defined to have no content when it is declared by default. It can grow
or shrink dynamically by lines instructions accessing it, e.g.,
``lines insert array a_lines 9 b_array``.

Lines Access
~~~~~~~~~~~~

Lines Get
^^^^^^^^^

.. code-block:: simstm

 lines get array a_lines p_var t_array r_var
 lines get array a_lines 9 t_array r_var

The ``lines get array`` instruction gets a line from a lines object at a given position and write its content
into an array.

The line is expected to hold hex numbers (without 0x
prefix) separated by spaces (e.g., A123 BCF11 123 E333 would be 4 hex
numbers). The given array must be able to hold the number of found hex
numbers. It will not be filled completely if fewer than its size are
found. Numbers will be skipped if there are more hex numbers found than
the array can hold. The number of detected hex numbers is reported in a
result variable. Then the user can decide what action should follow a
mismatch.

Lines Set
^^^^^^^^^
.. code-block:: simstm

 lines set array a_lines p_var s_array
 lines set array a_lines 9 s_array
 lines set message a_lines p_var "Some message to be written to a file later"
 lines set message a_lines p_var "Value1: {} Value2: {} to be written to a file later" m_var1 m_var2

The ``lines set`` instruction sets a line at a given position of a lines object.

The line currently at this position is overwritten. The line can be derived from an array or a
message. The message string can contain {} placeholders which are filled
by values of variables given after the message string.

Lines Insert
^^^^^^^^^^^^

.. code-block:: simstm

 lines insert array a_lines p_var s_array
 lines insert array a_lines 9 s_array
 lines insert message a_lines p_var "Some message to be written to a file later"
 lines insert message a_lines p_var "Value1: {} Value2: {} to be written to a file later" mvar1 mvar2

The ``lines insert`` instruction inserts a line at a given position of a lines object. The line currently
at this position is moved to the next position. The line can be derived
from an array or a message. The message string can contain {}
placeholders which are filled by values of variables given after the
message string.

Lines Append
^^^^^^^^^^^^

.. code-block:: simstm

 lines append array a_lines s_array
 lines append message a_lines "Some message to be written to a file later"
 lines append message a_lines "Value1: {} Value2: {} to be written to a file later" m_var1 m_var2

The ``lines append`` instruction appends a line at the end of a lines object. The line can be derived from
an array or a message. The message string can contain {} placeholders
which are filled by values of variables given after the message string.

Lines Delete
^^^^^^^^^^^^

.. code-block:: simstm

 lines delete a_lines p_var
 lines delete a_lines 3

The ``lines delete`` instruction deletes a line at a given position of a lines object. The next line is
moved to the given position if it exists.

Lines Size
^^^^^^^^^^

.. code-block:: simstm

 lines size a_lines r_var

The ``lines size`` instruction gets the size of a lines object, which is the number of lines it contains
at that point.

Lines Pointer Copy
^^^^^^^^^^^^^^^^^^

.. code-block:: simstm

 lines pointer copy t_lines s_lines

The ``lines pointer copy`` instruction copies a lines pointer; for example, ``t_lines``
points to ``s_lines`` after the execution of the instruction. Used, for
instance, to hand over a file to a subroutine. Changes to the source
object are applied to the target object as well.