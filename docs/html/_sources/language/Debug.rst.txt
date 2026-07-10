Debug
~~~~~

trace
^^^^^

.. code-block:: simstm

 trace t_var
 trace 0b111

The ``trace`` instruction enables or disables the output of trace
information when it is set at some point during the SimStm code
execution. Thus, e.g., the flow through complex if, elsif … trees can be
shown.

Predifined constants can be used to set the trace variable. The following bits are defined:

.. code-block:: simstm

 const TRACE_OFF 0
 const TRACE_EXECUTED_LINES 0x1
 const TRACE_INSTRUCTIONS 0x2
 const TRACE_VARIABLES 0x4
 const TRACE_FILES 0x8
 const TRACE_IF_TREES 0x10
 const TRACE_CALLS 0x20
 const TRACE_ALL 0xFFFF


marker
^^^^^^

.. code-block:: simstm

 marker n_var m_var
 marker 0xF 0b1

The ``marker`` instruction sets a marker at a given number used to mark
interesting points of time in the simulation wavefrom.

The ``tb_simstm`` entity has an output signal marker which is a
``std_logic_vector(15 downto 0)``. Thus there are 16 markers which can
be set ``0b1`` or ``0b0``. This should be used to mark occurrences
during the execution of the SimStm code so they can be found easily in
the waveform display. Beneath this, the intern variables ``Executing_Line`` and
``Executing_File`` in the ``tb_simstm.vhd`` module are always present and
show the currently executed line of code.

stop
^^^^

.. code-block:: simstm
    
    stop
    
The ``stop`` instruction stops the simulation with the severity error. The simulation can be continued by pressing continue in the simulator.