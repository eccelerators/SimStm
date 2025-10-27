
Subroutines
~~~~~~~~~~~

proc and end proc
^^^^^^^^^^^^^^^^^

.. code-block:: none

 aproc:
 proc
     --...
     -- subroutine code
     --...
 end proc

Code of a subroutine is placed between  ``proc`` and ``end proc`` instructions.
The subroutine name is a label placed on the line before the ``proc``
instruction, e.g., ``aproc``. The label ends with a colon as a label
indicator.

call
^^^^

.. code-block:: none

 call $aproc

The ``call`` instruction branches execution to the subroutine with the label ``aproc`` and continues
execution with the next line when it returns from the subroutine after
it has reached an ``end proc`` or ``return`` instruction there.

return
^^^^^^

.. code-block:: none

 return

The ``return`` instruction returns to calling code from a subroutine.
