Flow Control
~~~~~~~~~~~~

abort
^^^^^

.. code-block:: none

 abort

The ``abort`` instruction aborts the simulation with severity failure.

finish
^^^^^^

.. code-block:: none

 finish

The ``finish`` instruction exits the simulation with severity note or error. The latter occurs only
if resume has been set to other values than 0, and there were verify
errors in verify instructions.

stop
^^^^

.. code-block:: none

 stop
 
The ``stop`` instruction halts the simulation with severity failure. The simulation can be resumed.