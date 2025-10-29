
Equations and Arithmetic Operations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

equ
^^^

.. code-block:: none

 equ operand1 operand2
 equ operand1 0xF0

The ``equ`` instruction copies the value of operand2 (variable or constant) into
operand1 (variable) or copies the value 0xF0 into operand1.

add
^^^

.. code-block:: none

 add operand1 operand2
 add operand1 0xF0

The ``add`` instruction adds the value of operand2 (variable or constant) to the value of operand1 (variable) or
adds the value 0xF0 to the value of operand1. The resulting value of the
addition is stored in operand1 after the operation.

sub
^^^

.. code-block:: none

 sub operand1 operand2
 sub operand1 0xF0`

The ``sub`` instruction subtracts the value of operand2 (variable or constant) from the value of operand1
(variable) or subtracts the value 0xF0 from the value operand1. The resulting
value of the subtraction is stored in operand1 after the operation.

mul
^^^

.. code-block:: none

 mul operand1 operand2
 mul operand1 0xF0

The ``mul`` instruction multiplies the value of operand2 (variable or constant) with the value of operand1
(variable) or multiplies the value 0xF0 with the value operand1. The resulting
value of the multiplication is stored in operand1 after the operation.

div
^^^

.. code-block:: none

 div operand1 operand2
 div operand1 0xF0

The ``div`` instruction divides the value of operand1 (variable) by the value of operand2 (variable or constant) or
divides the value of operand1 by the value 0xF0. The resulting value of the
division is stored in operand1  after the operation.

and
^^^

.. code-block:: none

 and operand1 operand2
 and operand1 0xF0

The ``and`` instruction does a bitwise ``and`` of the value of operand2 (variable or constant) with 
the value of operand1 (variable) or a bitwise ``and`` of value 0xF0 with the value of operand1. The
resulting value of the bitwise ``and`` is stored in operand1 after the operation.

or
^^

.. code-block:: none

 or operand1 operand2
 or operand1 0xF0

The ``or`` instruction does a bitwise ``or`` of the value of operand2 (variable or constant) with 
the value of operand1 (variable) or a bitwise ``or`` of value 0xF0 with the value of operand1. The
resulting value of the bitwise ``or`` is stored in operand1 after the operation.

xor
^^^

.. code-block:: none

 xor operand1 operand2
 xor operand1 0xF0

The ``xor`` instruction does a bitwise ``xor`` of the value of operand2 (variable or constant) with
the value of operand1 (variable) or a bitwise ``xor`` of value 0xF0 with the value of operand1. The
resulting value of the bitwise ``xor`` is stored in operand1 after the operation.

shl
^^^

.. code-block:: none

 shl operand1 operand2
 shl operand1 0xF0

The ``shl`` instruction does a bitwise left shift of the value of operand2 (variable or constant) with
the value of operand1 (variable) or a bitwise left shift of value 0xF0 with the value of operand1. 
The resulting value of the bitwise left shift is stored in operand1 after the operation.

shr
^^^

.. code-block:: none

 shr operand1 operand2
 shr operand1 0xF0

The ``shr`` instruction does a bitwise right shift of the value of operand2 (variable or constant) with 
the value ofoperand1 (variable) or a bitwise variable shift of value 0xF0 with the value of operand1.
The resulting value of the bitwise right shift is stored in operand1 after the operation.

inv
^^^

.. code-block:: none

 inv operand1

The ``or`` instruction does a bitwise inversion of the value of operand1 (variable). The resulting value 
of the bitwise inversion is stored in operand1 after the operation.

ld
^^

.. code-block:: none

 ld operand1

The ``ld`` instruction calculates the logarithmus dualis of the value operand1 (variable). The resulting
value is stored in operand1 after the operation. The function returns the index of the highest set bit, 
e.g., 4 for the input 16. It returns 0 for the input 0 too since this is the best approximation in a
natural number range. The user should handle this discontinuity if
another result or an error is expected.
