
Branches
~~~~~~~~

if, elsif, else, and end if
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: none

 if $avar = $bvar
     -- ... some code
 elsif $avar 0xABC
     -- ... some code
 elsif 0x123} $bvar
     -- ... some code
 else
     -- ... some code
 end if



Possible comparison operators are:
``>= <= > < != =``.

The ``if`` or ``elsif`` instructions compares 2 variables, constants, or numeric values and branches
execution to the next line if resolving to true. Otherwise, it branches
to the next ``elsif`` or ``else`` or ``end if`` instruction.

The ``if`` ``elsif`` or ``else`` instructions can be nested.
