Standard Labs
-------------

The testMain entry point `tb/simstm/testMain.stm <./tb/simstm/testMain.stm>`__ can be used to run 
and debug tests e.g., by a list of calls to standard test procedures. 

During progress of work tests can be enabled or disabled by simply commenting or uncommenting the respective call in the testMain procedure.

At some point of time this practice grows annoying since one has to comment and uncomment the respective 
includes too since unused includes prolong the startup time. 

When working on more than one problem at the same time, it may be a good practice to split the test stimulus files into several 
files and include only those files in the testMain procedure that are relevant for the current work.

The different testMain procedures are called testLabs. Different testLabs can be used to run different sets of tests in different experimental state.

The helper scripts generate similar ANT targets as for testMain to run the simulator.

To obtain a test lab, follow the steps as described below.

1. Create or have standard test procedures containing assertions for behaviors to test as describe in chapter Standard Tests.

2. Write a procedure **testLab**\ MyName in a **TestLab**\ MyName.stm file representing the test lab.

The bold parts in the procedure and file name are mandatory by policy.

     
.. code-block:: simstm

 include "Other/other.stm"
 
 namespace SimStmTest
 
 proc testLabSample ()
 
     call testOtherRandom ()
 end proc
 
 end namespace

This snippet is present in `tb/simstm/TestLabs/TestLabSample.stm <./tb/simstm/TestLabs/TestLabSample.stm>`__. 


3. Write a procedure **testMainLab**\ MyName in a **testMainLab**\ MyName.stm file as entry point to launch the test suite.

The bold parts in the procedure, file name are mandatory by policy.

.. code-block:: simstm

 include "Common/Common.stm"
 
 include "TestLabs/TestlabSample.stm"
 namespace SimStmTest
 proc testMainLabSample ()
 
     call stm.initBase ()
 
     verbosity stm.INFO_2
     trace stm.TRACE_OFF
     resume stm.RESUME_ON_ALL_ERRORS
     signal write out_signal_init_dut 1
     wait 1000
     signal write out_signal_init_dut 0
     signal read stm.sigInTestSuiteIndex stm.TestSuiteIndex
     log message stm.INFO "Main test main lab Sample started"
 
     call testLabSample ()
 
     log message stm.INFO "Main test main lab Sample ended"
     wait 1000
     finish
 end proc
 end namespace
 
This snippet is present in `tb/simstm/testMainLabSample.stm <./tb/simstm/testMainLabSample.stm>`__. 
