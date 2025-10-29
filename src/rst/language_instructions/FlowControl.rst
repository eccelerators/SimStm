Subroutines, Branches, and Loops
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

proc, end proc
^^^^^^^^^^^^^^^^^

.. code-block:: none

 a_proc:
 proc
     --...
     -- subroutine code
     --...
 end proc

Code of a subroutine is placed between  ``proc`` and ``end proc`` instructions.
The name of the subroutine is a label placed a line ahead of the ``proc``
instruction, e.g., ``a_proc``. The label ends with a colon as a label
indicator.

call
^^^^

.. code-block:: none

 call a_proc

The ``call`` instruction branches execution to the subroutine with the given label. Code execution proceeds
in the next line after an ``end proc`` or a ``return`` in the subroutine.

return
^^^^^^

.. code-block:: none

 return

The ``return`` instruction returns to calling code from a subroutine.

interrupt, end interrupt
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: none

 an_interrupt:
 interrupt
     --...
     -- interrupt subroutine code
     --...
 end interrupt

Code of an interrupt subroutine is placed between ``interrupt``
and ``end interrupt`` instructions. The interrupt subroutine name is a label placed
a line ahead of the ``interrupt`` instruction, e.g., ``an_interrupt``. The label
ends with a colon as a label indicator. The label must be given in the
tbsignal package by customization and attached to a signal triggering
the interrupt. If necessary, the handling of nested interrupts must be
resolved there too.

if, elsif, else, end if
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: none

 if a_var = b_var
     -- ... some code
 elsif a_var 0xABC
     -- ... some code
 elsif 0x123} b_var
     -- ... some code
 else
     -- ... some code
 end if



Possible comparison operators are:
``>= <= > < != =``.

The ``if`` or ``elsif`` instructions compares two variables, constants, or numeric values and branches
execution to the next line after the ``end if`` if it resolves to true. Otherwise, it branches
to the next ``elsif`` or ``else`` or ``end if`` instruction.

The ``if`` ``elsif`` or ``else`` instructions can be nested.

loop
^^^^

.. code-block:: none

 loop l_var
     -- ... some code
 end loop

 loop 32
     -- ... some code
 end loop

The ``loop`` instruction executes a loop of the code between the ``loop`` and ``end loop`` instruction.

The number of times the loop should be executed is given after the ``loop``
keyword. It can be a numeric value, a variable, or a constant.

In case of a variable, this number can be changed by code within the loop, e.g.,
to skip loops or end the loop earlier, due to the global nature of all
variables. No break or continue instructions are supported therefore.

The loop can be terminated by a ``return`` instruction too at any time,
which is a good practice.

abort
^^^^^

.. code-block:: none

 abort

The ``abort`` instruction aborts the simulation with severity Failure.

finish
^^^^^^

.. code-block:: none

 finish

The ``finish`` instruction exits the simulation.

stop
^^^^

.. code-block:: none
	
	stop
	
The ``stop`` instruction stops the simulation with the severity Failure. The simulation can be resumed.

Resume
^^^^^^

.. code-block:: none

 resume EXIT_ON_VERIFY_ERROR
 resume 0

| Usual practice is to use the following constants to set verbosity:
| ``const RESUME_ON_VERIFY_ERROR 1``
| ``const EXIT_ON_VERIFY_ERROR 0``


The ``resume`` instruction sets the global resume behavior for verify instructions. On a verify
mismatch, the simulation stops with severity Failure if the global
resume is set to 0; otherwise, it continues and reports an error.
