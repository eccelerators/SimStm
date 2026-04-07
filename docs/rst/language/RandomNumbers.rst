
Random Numbers
--------------

Random
^^^^^^

.. code-block:: simstm

 random t_var min_var max_var
 random t_var 0 10

The ``random`` instruction generates a random number greater or equal to the min value given and
less than the maximum number given.

Seed
^^^^

.. code-block:: simstm

 seed s_var
 seed 10

The ``seed`` instruction sets the internal start value for the random number generator.
