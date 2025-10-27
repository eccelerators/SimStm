
Interrupts
~~~~~~~~~~

interrupt and end interrupt
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: none

 aninterrupt:
 interrupt
     --...
     -- interrupt subroutine code
     --...
 end interrupt

Code of an interrupt subroutine is placed between ``interrupt``
and ``end interrupt`` instructions. The interrupt subroutine name is a label placed
on the line before the ``interrupt`` instruction, e.g., aninterrupt. The label
ends with a colon as a label indicator. The label must be given in the
tbsignal package by customization and attached to a signal triggering
the interrupt. If necessary, the handling of nested interrupts must be
resolved there too.
