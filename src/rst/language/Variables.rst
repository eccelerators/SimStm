Variables
---------

.. code-block:: simstm

 var a_var 0x03
 var b_var 0b011
 var c_var 3

The ``var`` instruction declares and defines a variable with an ID and an initial hex, binary, or
decimal unsigned value.

It **isn't possible** to initialize a variable by referencing another
variable or constant yet. The ``equ``
instruction must be used within a procedure for this purpose.

Var Access
~~~~~~~~~~

Equ
^^^

.. code-block:: simstm

 equ operand1 operand2
 equ operand1 0xF0

The ``equ`` instruction sets the value of a variable or constant to a different variable.

In the example, the value of ``operand1`` is set to ``operand2``.


Var Verify
^^^^^^^^^^^^^

.. code-block:: simstm

 var verify a_var e_var m_var
 var verify a_var 0x01 0x0F

The ``var verify`` instruction reads the value of a signal and compares it to an expected
value with a given mask.

In the example, it is verified that the values of ``a_var`` and ``e_var`` are the same with mask ``m_var``.

The expected value and mask can be variables,
constants, or numeric values. On mismatch, the simulation stops with
severity Failure if the global resume is set to 0.


Var Pointer Copy
^^^^^^^^^^^^^^^^

.. code-block:: simstm
	
 var pointer copy a_var b_var
 
The instruction ``var pointer copy`` creates a variable pointer. 

For example, ``a_var``  points to ``B_var`` after the execution of the instruction.
