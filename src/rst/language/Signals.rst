Signals
~~~~~~~

signal
^^^^^^

.. code-block:: simstm
	
 signal a_signal 10
 signal a_signal a_const
 signal a_signal a_global_var

The instruction ``signal`` declares a signal object with an ID.

The signal object associates a SimStm signal name with a signal number.
This signal number must be given in the tb_signal package by
customization and be attached to a signal.


signal write
^^^^^^^^^^^^

.. code-block:: simstm

 signal write a_signal s_var
 signal write a_signal 0b11

The instruction ``signal write`` writes a variable, constant, or numeric value to a signal.

In the example, ``s_var`` is stored in ``a_signal``.

signal read
^^^^^^^^^^^

.. code-block:: simstm

 signal read a_signal t_var

The instruction ``signal read`` reads the value of a signal into a variable.

In the example, the value of ``a_signal`` is stored in ``t_var``.

signal verify
^^^^^^^^^^^^^

.. code-block:: simstm

 signal verify a_signal e_var m_var
 signal verify a_signal 0x01 0x0F

The instruction ``signal verify`` reads the value of a signal and compares it to an expected
value with a given mask.

In the example, it is verified that the value of ``a_signal``is the same as ``e_var``, with the mask
``m_var``.

The expected value and mask can be variables,
constants, or numeric values. On mismatch, the simulation stops with
severity failure if the global resume is set to 0; otherwise, it continues, reports an simulation error and 
counts up the SimStm testbench internal verify_failure_count variable.

The SimStm testbench internal verify_passes_count variable counts up the number of verify instructions happened at all regardless if a 
simulation error occurs or not.

signal pointer copy
^^^^^^^^^^^^^^^^^^^

.. code-block:: simstm

 signal pointer copy t_signal s_signal

The instruction ``signal pointer copy`` creates a signal pointer; 

In the example, ``t_signal`` points to ``s_signal`` after the instruction of the execution. 

Used, for instance, to hand over a signal to a subroutine. Changes to the source
object are applied to the target object as well.

signal pointer set
^^^^^^^^^^^^^^^^^^

.. code-block:: simstm

 signal pointer set t_signal 5
 signal pointer set t_signal ptr_var

The instruction ``signal pointer set`` sets a signal pointer to an absolute address.

In the example, the pointer ``t_signal`` is set to 5.

signal pointer get
^^^^^^^^^^^^^^^^^^

.. code-block:: simstm

 signal pointer get s_signal ptr_var

The instruction ``signal pointer get`` gets the value of a signal pointer and stores it in a variable.

In the example, the pointer ``s_signal`` is stored in ``ptr_var``.