Resume
------

.. code-block:: none

 resume EXIT_ON_VERIFY_ERROR
 resume 0

| Usual practice is to use the following constants to set verbosity:
| ``const`` ``RESUME_ON_VERIFY_ERROR 1``
| ``const`` ``EXIT_ON_VERIFY_ERROR 0``

The ``resume`` instruction sets the global resume behavior for verify instructions. On a verify
mismatch, the simulation stops with severity Failure if the global
resume is set to 0; otherwise, it continues and reports an error.