Variables
---------

.. code-block:: none

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

Var Verify
^^^^^^^^^^^^^

.. code-block:: none

 var verify a_var e_var m_var
 var verify a_var 0x01 0x0F

The ``var verify`` instruction reads the value of a signal and compares it to an expected
value with a given mask.

The expected value and mask can be variables,
constants, or numeric values. On mismatch, the simulation stops with
severity Failure if the global resume is set to 0.


Var Pointer Copy
^^^^^^^^^^^^^^^^

.. code-block:: none
	
 var pointer copy a_varA a_varB
 
The ``var pointer copy`` instruction copies an variable pointer; for example, the pointer ``a_varA``  
is a copy of the pointer ``a_varB`` after the execution of the instruction.
