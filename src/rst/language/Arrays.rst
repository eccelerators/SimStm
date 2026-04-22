Arrays
------

.. code-block:: simstm

 array a_array 16

The instruction ``array`` declares an array with an ID and an unsigned 32-bit integer length.

Only arrays with one dimension are possible; the length is fixed.

Array Access
~~~~~~~~~~~~

Array Set
^^^^^^^^^

.. code-block:: simstm

 array set a_array p_var a_var
 array set a_array p_var 5
 array set b_array 3 b_var
 array set b_array 3 4

The instruction ``array set`` sets the value of an array at a position to 
a certain value.

For example, the instruction ``array set a_array p_var a_var`` sets the value of ``a_array`` at position ``p_var`` to the 
value of ``a_var``.

Array Get
^^^^^^^^^

.. code-block:: simstm

 array get b_array p_var t_var
 array get b_array 5  t_var

The ``array get`` instruction gets the value of an array at a position and stores it in a variable.

For example, the instruction ``array get b_array p_var t_var`` gets the value of ``b_array`` at position 
``p_var`` and stores it in ``t_var``.

Array Verify
^^^^^^^^^^^^^

.. code-block:: simstm

 array verify b_array p_var e_var m_var
 array verify b_array p_var 0x01 0x0F

The instruction ``array verify`` reads the value of an array at a position and compares it to an expected
value with a given mask.

The expected value and mask can be variables,
constants, or numeric values. On mismatch, the simulation stops with
severity Failure if the global resume is set to 0; otherwise, it continues, reports an simulation error and 
counts up the SimStm testbench internal verify_failure_count variable.

The SimStm testbench internal verify_passes_count variable counts up the number verify instructions happened at all regardless if a 
simulation error occurs or not.

For example, the instruction ``array verify b_array p_var e_var m_var`` verifies that the value of ``b_array`` at position ``p_var``
is the same as the value of ``e_var``, with the mask ``m_var``.

Array Size
^^^^^^^^^^

.. code-block:: simstm

 array size b_array t_var

The ``array size`` instruction gets the size of an array and stores it in a variable.

For example, ``array size b_array t_var`` stores the size of ``b_array`` in ``t_var``.

Array Pointer Copy
^^^^^^^^^^^^^^^^^^

.. code-block:: simstm

 array pointer copy t_array s_array

The instruction ``array pointer copy`` creates an array pointer.

For example, ``t_array`` points to ``s_array`` after the execution of the instruction. 
Used, for instance, to hand over an array to a subroutine. Changes to the source
array also apply to the target array.
