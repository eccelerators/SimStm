Arrays
------

.. code-block:: none

 array a_array 16

The ``array`` instruction declares an array with an ID and an unsigned 32-bit integer length.

Only arrays with one dimension are possible; the length is fixed.

Array Access
~~~~~~~~~~~~

Array Set
^^^^^^^^^

.. code-block:: none

 array set a_array p_var a_var
 array set a_array p_var 5
 array set b_array 3 b_var
 array set b_array 3 4

The ``array set`` instruction sets the value of ``a_array`` at position ``p_var`` to 
the value of ``a_var`` or ``5``.

The ``array set`` instruction sets the value of ``b_array`` at position ``3`` to the value of ``b_var`` or
``4``.

Array Get
^^^^^^^^^

.. code-block:: none

 array get b_array p_var t_var
 array get b_array 5  t_var

The ``array get`` instruction gets the value of ``b_array`` at position ``p_var`` or ``5`` into ``t_var``.

Array Verify
^^^^^^^^^^^^^

.. code-block:: none

 array verify b_array p_var e_var m_var
 array verify b_array p_var 0x01 0x0F

The ``array verify`` instruction reads the value of an array at a position and compares it to an expected
value with a given mask.

The expected value and mask can be variables,
constants, or numeric values. On mismatch, the simulation stops with
severity Failure if the global resume is set to 0.

Array Size
^^^^^^^^^^

.. code-block:: none

 array size b_array t_var

The ``array size`` instruction gets the size of an array and stores it in a variable.

Array Pointer Copy
^^^^^^^^^^^^^^^^^^

.. code-block:: none

 array pointer copy t_array s_array

The ``array pointer copy`` instruction copies an array pointer; for example, the pointer ``t_array``  
is a copy of the pointer ``s_array`` after the execution of the instruction. Used, for
instance, to hand over an array to a subroutine. Changes to the source
array also apply to the target array.
