Labels
~~~~~~

label
^^^^^

.. code-block:: simstm
	
 label lbl_var a_var
 
The instruction ``label`` declares and defines a label with an ID and an initial value.

A label can act as a placeholder for actual values which are modifiable through ``label equ``, ``label set`` or ``label pointer copy``.

label equ
^^^^^^^^^

.. code-block:: simstm
	
 label equ lbl_varA lbl_varB
 
The instruction ``label equ`` sets the value of a label to a different label.

In the example, ``lbl_var`` is set to the value of ``a_var``.

label set
^^^^^^^^^

.. code-block:: simstm
	
 label set lbl_var a_var
 

label pointer copy
^^^^^^^^^^^^^^^^^^

.. code-block:: simstm
	
 label pointer copy lbl_var a_var
 
The instruction ``label pointer copy`` creates a label pointer.

In the example, ``lbl_var`` points to ``a_var``.


Powerful Usage Patterns
^^^^^^^^^^^^^^^^^^^^^^^

Labels become most powerful when used to decouple generic behaviour from concrete implementations.
The following patterns demonstrate how labels enable dynamic dispatch, reusable templates, and
shared configuration — all without recompiling HDL.

**Pattern 1: Dynamic Dispatch — one generic poller, thousands of concrete bits**

A single ``waitForBit`` wrapper can poll any status bit in the design.
The concrete procedure to call is injected at the call site via ``label set``.
This avoids duplicating the polling logic for every single bit.

.. code-block:: simstm

 -- Generic poller: calls whatever procedure is injected via ToCall
 proc waitForBit (
     label ToCall waitForBit_ToCall_template
     var IsExpectedValue 0
     var TimeoutCycles 1000
 )
     var cycles 0
     loop
         call label ToCall (
             var pointer copy IsExpectedValue IsExpectedValue
         )
         if IsExpectedValue = 1 then
             return
         end if
         equ cycles cycles + 1
         if cycles >= TimeoutCycles then
             log message stm.ALWAYS "waitForBit: timeout waiting for bit"
             return
         end if
         wait 1
     end loop
 end proc

 -- Concrete bit reader for DMA done flag
 proc isDmaDone (
     var IsExpectedValue 0
 )
     bus read 32 0x4000_0010 IsExpectedValue
     and IsExpectedValue 0x1
 end proc

 -- Concrete bit reader for FIFO not full flag
 proc isFifoNotFull (
     var IsExpectedValue 0
 )
     bus read 32 0x4000_0020 IsExpectedValue
     shr IsExpectedValue 3
     and IsExpectedValue 0x1
 end proc

 -- Test: wait for DMA, then wait for FIFO ready
 proc testDmaAndFifo ()
     var result 0
     call waitForBit (
         label set ToCall isDmaDone
         var pointer copy IsExpectedValue result
     )
     call waitForBit (
         label set ToCall isFifoNotFull
         var pointer copy IsExpectedValue result
     )
 end proc

**Pattern 2: Policy Injection — swap error-handling strategy at the call site**

Use a label to inject a different error-handling procedure without modifying the
generic test procedure. This is the equivalent of a strategy or policy pattern.

.. code-block:: simstm

 -- Generic register write with injected error policy
 proc writeRegChecked (
     label OnError errorPolicy_template
     var Address 0
     var Value 0
 )
     var readback 0
     bus write 32 Address Value
     bus read 32 Address readback
     if readback <> Value then
         call label OnError (
             var pointer copy Address Address
             var pointer copy Value Value
             var pointer copy readback readback
         )
     end if
 end proc

 -- Policy: log and continue
 proc errorPolicy_logOnly (
     var Address 0
     var Value 0
     var readback 0
 )
     log message stm.ALWAYS "Write verify failed at address"
     log var stm.ALWAYS Address
 end proc

 -- Policy: log and stop the simulation
 proc errorPolicy_fatal (
     var Address 0
     var Value 0
     var readback 0
 )
     log message stm.ALWAYS "Fatal: Write verify failed — stopping"
     stop
 end proc

 -- Smoke test uses soft policy; production test uses fatal policy
 proc smokeTest ()
     call writeRegChecked (
         label set OnError errorPolicy_logOnly
         var set Address 0x4000_0000
         var set Value 0xDEAD
     )
 end proc

 proc productionTest ()
     call writeRegChecked (
         label set OnError errorPolicy_fatal
         var set Address 0x4000_0000
         var set Value 0xDEAD
     )
 end proc

**Pattern 3: Shared Configuration Label — one place to change, everywhere updated**

Declare a single label for a base address or constant once and reference it everywhere.
Changing the one declaration updates every use without touching the rest of the test.

.. code-block:: simstm

 -- Declare the DMA controller base address once
 label DMA_BASE 0x4000_0000

 proc startDma ()
     var ctrl 0
     label equ ctrl DMA_BASE
     add ctrl 0x00
     bus write 32 ctrl 0x1
 end proc

 proc resetDma ()
     var rst 0
     label equ rst DMA_BASE
     add rst 0x04
     bus write 32 rst 0xFF
 end proc

 -- Moving the peripheral to a new address only requires changing DMA_BASE above
