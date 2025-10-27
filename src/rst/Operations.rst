Operations
~~~~~~~~~~

add
^^^

.. code-block:: none

 add operand1 $operand2
 add operand1 0xF0

The ``add`` instruction adds variable or constant operand2 value to variable operand1 value or
add value 0xF0 to variable operand1 value. The resulting value of the
addition is in variable operand1 value after the operation.

sub
^^^

.. code-block:: none

 sub operand1 $operand2
 sub operand1 0xF0`

The ``sub`` instruction subtracts variable or constant operand2 value from variable operand1
value or subtract value 0xF0 from variable operand1 value. The resulting
value of the subtraction is in variable operand1 value after the
operation.

mul
^^^

.. code-block:: none

 mul operand1 $operand2
 mul operand1 0xF0

The ``mul`` instruction multiplies variable or constant operand2 value with variable operand1
value or multiply value 0xF0 with variable operand1 value. The resulting
value of the multiplication is in variable operand1 value after the
operation.

div
^^^

.. code-block:: none

 div operand1 $operand2
 div operand1 0xF0

The ``div`` instruction divides variable operand1 value by variable or constant operand2 value or
divide variable operand1 value by value 0xF0. The resulting value of the
division is in variable operand1 value after the operation.

and
^^^

.. code-block:: none

 and operand1 $operand2
 and operand1 0xF0

The ``and`` instruction does a bitwise and of variable or constant operand2 value with variable operand1
value or bitwise and value 0xF0 with variable operand1 value. The
resulting value of the bitwise and is in variable operand1 value after
the operation.

or
^^

.. code-block:: none

 or operand1 $operand2
 or operand1 0xF0

The ``or`` instruction does a bitwise or of variable or constant operand2 value with variable operand1
value or bitwise or value 0xF0 with variable operand1 value. The
resulting value of the bitwise or is in variable operand1 value after
the operation.

xor
^^^

.. code-block:: none

 xor operand1 $operand2
 xor operand1 0xF0

The ``xor`` instruction does a bitwise xor of variable or constant operand2 value with variable operand1
value or bitwise xor value 0xF0 with variable operand1 value. The
resulting value of the bitwise xor is in variable operand1 value after
the operation.

shl
^^^

.. code-block:: none

 shl operand1 $operand2
 shl operand1 0xF0

The ``shl`` instruction does a bitwise shift left of variable or constant operand2 value with variable
operand1 value or bitwise shift left value 0xF0 with variable operand1
value. The resulting value of the bitwise shift left is in variable
operand1 value after the operation.

shr
^^^

.. code-block:: none

 shr operand1 $operand2
 shr operand1 0xF0

The ``shr`` instruction does a bitwise shift right of variable or constant operand2 value with variable
operand1 value or bitwise shift right value 0xF0 with variable operand1
value. The resulting value of the bitwise shift right is in variable
operand1 value after the operation.

inv
^^^

.. code-block:: none

 inv operand1

The ``or`` instruction does a bitwise invert of variable operand1 value. The resulting value of the
bitwise invert is in variable operand1 value after the operation.

ld
^^

.. code-block:: none

 ld operand1

The ``ld`` instruction does calculates logarithmus dualis of variable operand1 value. The resulting
value is in variable operand1 value after the operation. The function
returns the number of the utmost set bit, e.g., 4 for the input 16. It
returns 0 for the input 0 too since this is the best approximation in a
natural number range. The user should handle this discontinuity if
another result or an error is expected.