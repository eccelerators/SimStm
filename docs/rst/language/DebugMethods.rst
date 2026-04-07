Debug Methods
~~~~~~~~~~~~~

Trace
^^^^^

.. code-block:: simstm

 trace t_var
 trace 0b111

The ``trace`` instruction enables or disables the output of trace
information when it is set at some point during the SimStm code
execution. Thus, e.g., the flow through complex if, elsif … trees can be
shown.

-  Setting the bit 0 in the given value prints the lines of code with
   some additional information.
-  Setting the bit 1 dumps all(!) objects before a line is executed.
-  Setting the bit 2 dumps all file names currently in use.

Marker
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
