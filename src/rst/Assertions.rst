
Assertions
~~~~~~~~~~~

Resume
^^^^^^

.. code-block:: none

 resume $EXIT_ON_VERIFY_ERROR
 resume 0

| Usual practice is to use the following constants to set verbosity:
| ``const`` ``RESUME_ON_VERIFY_ERROR 1``
| ``const`` ``EXIT_ON_VERIFY_ERROR 0``

The ``resume`` instruction sets the global resume behavior for verify instructions. On a verify
mismatch, the simulation stops with severity failure if the global
resume is set to 0; otherwise, it continues and reports an error.

Var Verify
^^^^^^^^^^^^^

.. code-block:: none

 var verify a_var $evar $mvar
 var verify a_var 0x01 0x0F

The ``var verify`` instruction reads the value of a signal and compares it to an expected
value with a given mask.

The expected value and mask can be variables,
constants, or numeric values. On mismatch, the simulation stops with
severity failure if the global resume is set to 0.

Array Verify
^^^^^^^^^^^^^

.. code-block:: none

 array verify barray $pvar $evar $mvar
 array verify barray $pvar 0x01 0x0F

The ``array verify`` instruction reads the value of an array at a position and compares it to an expected
value with a given mask.

The expected value and mask can be variables,
constants, or numeric values. On mismatch, the simulation stops with
severity failure if the global resume is set to 0.

Signal Verify
^^^^^^^^^^^^^

.. code-block:: none

 signal verify asignal tvar $evar $mvar
 signal verify asignal tvar 0x01 0x0F

The ``signal verify`` instruction reads the value of a signal into a variable and compares it to an expected
value with a given mask.

The expected value and mask can be variables,
constants, or numeric values. On mismatch, the simulation stops with
severity failure if the global resume is set to 0.

Bus Verify
^^^^^^^^^^

.. code-block:: none

 bus verify abus $width $address tvar $evar $mvar
 bus verify abus $width $address tvar 0x01 0x0F

The ``bus verify`` instruction reads the value of a bus with a given width and address into a variable and compare it to an expected
value with a given mask. The expected value and mask can be variables,
constants, or numeric values. On mismatch, the simulation stops with
severity failure if the global resume is set to 0; otherwise, it
continues and reports an error.
