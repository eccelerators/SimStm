Log
---

Log Message
^^^^^^^^^^^

.. code-block:: simstm

 log message v_var "A message to the console"
 log message v_var "A message to the console{}{}" m_var1 m_var2

The ``log message`` instruction prints a message at a given verbosity level to the console.

The message string can contain {} placeholders which are filled by values of
variables given after the message string.

Log Lines
^^^^^^^^^

.. code-block:: simstm

 log lines v_var s_lines

The ``log lines`` instruction dumps a lines object at a given verbosity level to the console.

Verbosity
^^^^^^^^^

.. code-block:: simstm

 verbosity v_var
 verbosity 20

Usual practice is to use the following constants to set verbosity:

.. code-block:: simstm

 const FAILURE 0
 const WARNING 10
 const INFO 20

The ``verbosity`` instruction sets the global verbosity for log messages. Log messages with a
verbosity level greater than the globally set verbosity are not printed
to the console. Of course, the global verbosity can be changed at any
point in the execution flow.