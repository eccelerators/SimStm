Loops
~~~~~

loop
^^^^

.. code-block:: none

 loop $lvar
     -- ... some code
 end loop

 loop 32
     -- ... some code
 end loop

The ``loop`` instruction executes a loop of the code between the ``loop`` and end ``loop`` instruction.

The number of times the loop should be executed is given after the ``loop``
keyword. It can be a numeric value, a variable, or a constant.

In case of a variable, this number can be changed by code within the loop, e.g.,
to skip loops or end the loop earlier, due to the global nature of all
variables. No break or continue instructions are supported therefore.

The loop can be terminated by a ``return`` instruction too at any time,
which is a good practice.
