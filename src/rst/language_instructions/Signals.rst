Signals
-------

.. code-block:: none
	
 signal a_signal 10
 signal a_signal a_const
 signal a_signal a_global_var

The ``signal`` instruction declares a signal object with an ID.

The signal object associates a SimStm signal name with a signal number.
This signal number must be given in the tb_signal package by
customization and be attached to a signal.

Signal Access
~~~~~~~~~~~~~

Signal Write
^^^^^^^^^^^^

.. code-block:: none

 signal write a_signal s_var
 signal write a_signal 0b11

The ``signal write`` instruction writes a variable, constant, or numeric value to a signal.

Signal Read
^^^^^^^^^^^

.. code-block:: none

 signal read a_signal t_var

The ``signal read`` instruction reads the value of a signal into a variable.

Signal Verify
^^^^^^^^^^^^^

.. code-block:: none

 signal verify a_signal t_var e_var m_var
 signal verify a_signal t_var 0x01 0x0F

The ``signal verify`` instruction reads the value of a signal into a variable and compares it to an expected
value with a given mask.

The expected value and mask can be variables,
constants, or numeric values. On mismatch, the simulation stops with
severity failure if the global resume is set to 0.

Signal Pointer Copy
^^^^^^^^^^^^^^^^^^^

.. code-block:: none

 signal pointer copy t_signal s_signal

The ``signal pointer copy`` instruction copies a signal pointer; for example, ``t_signal``
points to ``s_signal`` after the instruction of the execution. Used, for
instance, to hand over a signal to a subroutine. Changes to the source
object are applied to the target object as well.

Signal Pointer Set
^^^^^^^^^^^^^^^^^^

.. code-block:: none

 signal pointer set t_signal 5
 signal pointer set t_signal ptr_var

The ``signal pointer set`` instruction sets a signal pointer (for example, the pointer ``t_signal``)
to an absolute address.

Signal Pointer Get
^^^^^^^^^^^^^^^^^^

.. code-block:: none

 signal pointer get s_signal ptr_var

The ``signal pointer get`` instruction gets the value of a signal pointer and stores it in a variable.
For example, the pointer ``s_signal`` is stored in ``ptr_var``.