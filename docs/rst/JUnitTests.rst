
JUnit Tests
-----------

Test results can be generated in JUnit XML format. This allows for easy integration with CI/CD pipelines 
and test reporting tools that support JUnit format.

To be able to use the helper scripts please follow the naming policies.

The helper scripts generate the ANT scripts to run the TestSuites in the simulator and 
collect the result in a SimulationResult.xml which is a JUnit XML file.

4 types of test suites are supported by the SimStm library and the helper scripts:

- Plain test suites
- Case indexed
- Suite indexed 
- Suite indexed and Case indexed

To obtain SimStm testbench results in JUnit XML format, follow the steps for each type of test suite
as described in the respective sections below.

Plain
~~~~~

1. Create standard test procedures containing assertions for behaviors to test as describe in chapter Standard Tests.

The standard test procedures represent can be placed in arbitrary .stm files and folders. 
They can be called from any testSuite and testMain by including this files.

This has the advantage that they can be used in as standard tests and as test cases in test suites for JUnit tests.
Standard tests can be easily debugged and prepared via the entry point testMain or an individually named test lab.
Once judged to be ready, they can be called from a test suite and thus be part of the JUnit test results.

.. code-block:: simstm

 proc testSampleA ()
     call stm.startStandardTestShell ()
     -- enter your test code here
     -- use verify instructions here as assertions
     -- verify and bus timeouts are monitored between startStandardTestShell and endStandardTestShell
     log message 0 "testSampleA has been run"
     call stm.endStandardTestShell ()
 end proc
 
This snippet is present in `tb/simstm/sample/sample.stm <./tb/simstm/sample/sample.stm>`__. 

2. Write a procedure **testSuite**\ MyName in a **TestSuite**\ MyName.stm file representing the test suite.

The bold parts in the procedure and file name are mandatory by policy.

Test suites may run in parallel threads controlled by the outer e.g., ANT script thus speeding up 
the simulation of a whole project with many suites dramatically. 

This in mind, group related test cases into test suites for better organization and execution.

The standard test chosen for a test suite are wrapped by a *call stm.testCase* instruction each. 
This decorates standard test with the necessary things to be a test case. 
The original standard test is given as a label parameter to the wrapper.
The wrapper accepts the parameter *skipped* to skip the test case if needed. 
This is useful to skip tests that are not ready yet or to skip tests intentionally 
e.g., because they are expected to fail due to a not yet fixed bug.

.. code-block:: simstm

 proc testSuiteSample ()
 
     call stm.testCase (
         label set TestToCall testSampleA
     )
     
     -- this test is skipped to present an example to skip tests
     call stm.testCase (
         label set TestToCall testSampleB
         equ skipped 1
     )
 end proc
 
This snippet is present in `tb/simstm/TestSuites/TestSuiteSample.stm <./tb/simstm/TestSuites/TestSuiteSample.stm>`__. 
 
3. Write a procedure **testMainSuite**\ MyName in a **testMainSuite**\ MyName.stm file as entry point to launch the test suite.

The bold parts in the procedure, file name are mandatory by policy.
 
.. code-block:: simstm

 proc testMainSuiteSample ()
 
     call stm.initBase ()
 
     verbosity stm.INFO_2
     trace stm.TRACE_OFF
     resume stm.RESUME_ON_ALL_ERRORS
     signal write out_signal_init_dut 1
     wait 1000
     signal write out_signal_init_dut 0
     signal read stm.sigInTestSuiteIndex stm.TestSuiteIndex
     log message stm.INFO "Main test main suite Sample started"
 
     call testSuiteSample ()
 
     log message stm.INFO "Main test main suite Sample ended"
     wait 1000
     finish
 end proc
 
This snippet is present in `tb/simstm/testMainSuiteSample.stm <./tb/simstm/testMainSuiteSample.stm>`__. 
 

Case indexed
~~~~~~~~~~~~

1. Same as for plain test suites but with the addition that the test must change its behavior based on 
the value of the variable *stm.TestCaseIndex*.

E.g., the test procedure can use *stm.TestCaseIndex* variable to run a test with different delays. 
The test *stm.TestCaseIndex* variable can have any value but must be unique for each called test
e.g., 20, 40, 60 ... for delays 20ns, 40ns, 60ns ... .

.. code-block:: simstm

 proc testSampleWithCaseIndexA ()
     call stm.startStandardTestShell ()
     -- enter your test code here
     -- use verify instructions here as assertions
     -- verify and bus timeouts are monitored between startStandardTestShell and endStandardTestShell
     -- stm.TestCaseIndex is controlled by the respective TestSuite to iterate over all Case Indexes and run them
     log message 0 "testSampleWithCaseIndexA has been run with case index {}" stm.TestCaseIndex
     call stm.endStandardTestShell ()
 end proc

This snippet is present in `tb/simstm/Sample/Sample.stm <./tb/simstm/Sample/Sample.stm>`__. 

2. Same as for plain test suites but with the difference that the standard test calls are 
wrapped by a *call stm.testCaseWithCaseIndex* instruction.


.. code-block:: simstm

    proc testSuiteSampleCaseOnlyIndex ()
        
        -- use stm.TestCaseIndex to run testSampleWithCaseIndexA with different parameters
        -- the individual runs appear automatically as test cases in the generated test suites
        loop 5
            equ stm.TestCaseIndex 0
            call stm.testCaseWithCaseIndex (
                label set TestToCall testSampleWithCaseIndexA
            )
            add stm.TestCaseIndex 1
        end loop
    
        loop 3
            equ stm.TestCaseIndex 10
            call stm.testCaseWithCaseIndex (
                label set TestToCall testSampleWithCaseIndexB
            )
            add stm.TestCaseIndex 10
        end loop
        
    end proc
    
This snippet is present in `tb/simstm/TestSuites/TestSuiteSampleCaseOnly.stm <./tb/simstm/TestSuites/TestSuiteSampleCaseOnly.stm>`__. 
    
3. Same as for plain test suites.

Plain and indexed test cases can be freely mixed in the same test suite. 
The presence of indexed test cases does not affect the test suite procedure or file name.

A snippet is present in `tb/simstm/testMainSuiteSampleCaseOnly.stm <./tb/simstm/testMainSuiteSampleCaseOnly.stm>`__. 


Suite indexed
~~~~~~~~~~~~~

1. Same as for plain test suites but with the addition that the test must change its behavior 
based on the value of the variable *stm.TestSuiteIndex*.

Test suites and in fact each index may run in parallel threads controlled by the outer e.g., ANT script thus speeding up 
the simulation of a whole project with many suites dramatically. 

This in mind, group related test cases into test suites for better organization and execution.

E.g., the test procedure can use *stm.TestSuiteIndex* variable to run a test on a different bus. 
The test *stm.TestSuiteIndex* variable is given by the outer e.g., ANT script to run the same test suite with different 
parameters. E.g., the test suite is run 3 times with *stm.TestSuiteIndex* values 0, 1, 2 for bus0, bus1, bus2.

The range of *stm.TestSuiteIndex* values is *const testMainSuiteIndexedRangeLengthMyName* defined in the respective testMainSuiteIndexedMyName.stm file.

.. code-block:: simstm

 proc testSampleWithSuiteIndexA ()
     call stm.startStandardTestShell ()
     -- enter your test code here
     -- use verify instructions here as assertions
     -- verify and bus timeouts are monitored between startStandardTestShell and endStandardTestShell
     -- stm.TestSuiteIndex is controlled by the respective TestSuite to iterate over all Suite Indexes and run them
     -- the Suite index is controlled by the external e.g, ANT script, thus the suite simulations can be run in parallel
     log message 0 "testSampleWithCaseIndexA has been run with suite index {}" stm.TestSuiteIndex
     call stm.endStandardTestShell ()
 end proc

This snippet is present in `tb/simstm/Sample/Sample.stm <./tb/simstm/Sample/Sample.stm>`__. 

2. Write a procedure **testSuiteIndexed**\ MyName in a **TestSuiteIndexed**\ MyName.stm file representing the test suite.

The bold parts in the procedure and file name are mandatory by policy.

The standard test are wrapped by a *call stm.testCaseWithSuiteIndex* instruction. 
This allows to set a label for the called standard test and to skip it if needed.

.. code-block:: simstm

 proc testSuiteIndexedSampleSuiteOnlyIndex ()
     
     -- the suite index is controlled by the external e.g, ANT script, thus the suite simulations can be run in parallel
     -- the tests take respect to the suite index them self
     -- the individual runs appear automatically as test suites in the generated test junits
     call stm.testCaseWithSuiteIndex (
         label set TestToCall testSampleWithSuiteIndexA
     )
 
     call stm.testCaseWithSuiteIndex (
         label set TestToCall testSampleWithSuiteIndexB
     )
     
 end proc
        
This snippet is present in `tb/simstm/TestSuites/TestSuiteSampleSuiteOnly.stm <./tb/simstm/TestSuites/TestSuiteSampleSuiteOnly.stm>`__. 
    
3. Write a procedure **testMainSuiteIndexedMyName**\ MyName in a **testMainSuiteIndexedMyName**\ MyName.stm file as entry point to launch the test suite.

Give the suite index range in  const **testMainSuiteIndexedRangeLength**\ MyName (this parsed and read by the helper scripts).  

The bold parts in the procedure, file name and constant are mandatory by policy.

.. code-block:: simstm

 const testMainSuiteIndexedMyNameIndexRangeLength 4


 proc testMainSuiteIndexedSample ()
 
     call stm.initBase ()
 
     verbosity stm.INFO_2
     trace stm.TRACE_OFF
     resume stm.RESUME_ON_ALL_ERRORS
     signal write out_signal_init_dut 1
     wait 1000
     signal write out_signal_init_dut 0
     signal read stm.sigInTestSuiteIndex stm.TestSuiteIndex
     log message stm.INFO "Main test main suite Sample started with suite index {}" stm.TestSuiteIndex
 
     call testSuiteIndexedSampleSuiteOnlyIndex ()
 
     log message stm.INFO "Main test main suite Sample ended with suite index {}" stm.TestSuiteIndex
     wait 1000
     finish
 end proc
 
This snippet is present in `tb/simstm/testMainSuiteSampleSuiteOnly.stm <./tb/simstm/testMainSuiteSampleSuiteOnly.stm>`__. 
 
Suite and Case indexed
~~~~~~~~~~~~~~~~~~~~~~

1. Same as for plain test suites but with the addition that the test must change its behavior 
based on the value of the variable *stm.TestSuiteIndex* and the value of the variable *stm.TestCaseIndex*..

Test suites and in fact each suite index may run in parallel threads controlled by the outer e.g., ANT script thus speeding up 
the simulation of a whole project with many suites dramatically. 

This in mind, group related test cases into test suites for better organization and execution.

E.g., the test procedure can use *stm.TestSuiteIndex* variable to run a test on a different bus. 
The test *stm.TestSuiteIndex* variable is given by the outer e.g., ANT script to run the same test suite with different 
parameters. E.g., the test suite is run 3 times with *stm.TestSuiteIndex* values 0, 1, 2 for bus0, bus1, bus2.

E.g., the test procedure can use *stm.TestCaseIndex* variable to run each suite indexed test with different delays additionally. 
The test *stm.TestCaseIndex* variable can have any value but must be unique for each called test
e.g., 20, 40, 60 ... for delays 20ns, 40ns, 60ns ... .

The range of *stm.TestSuiteIndex* values is *const testMainSuiteIndexedRangeLengthMyName* defined in the respective testMainSuiteIndexedMyName.stm file.

.. code-block:: simstm

 proc testSampleWithSuiteIndexA ()
     call stm.startStandardTestShell ()
     -- enter your test code here
     -- use verify instructions here as assertions
     -- verify and bus timeouts are monitored between startStandardTestShell and endStandardTestShell
     -- stm.TestSuiteIndex is controlled by the respective TestSuite to iterate over all Suite Indexes and run them
     -- the Suite index is controlled by the external e.g, ANT script, thus the suite simulations can be run in parallel
     log message 0 "testSampleWithCaseIndexA has been run with suite index {}" stm.TestSuiteIndex
     call stm.endStandardTestShell ()
 end proc

This snippet is present in `tb/simstm/Sample/Sample.stm <./tb/simstm/Sample/Sample.stm>`__. 

2. Write a procedure **testSuiteIndexed**\ MyName in a **TestSuiteIndexed**\ MyName.stm file representing the test suite.

The bold parts in the procedure and file name are mandatory by policy.

The standard test are wrapped by a *call stm.testCaseWithSuiteIndex* instruction. 
This allows to set a label for the called standard test and to skip it if needed.

.. code-block:: simstm

 proc testSuiteIndexedSampleSuiteAndCaseIndex ()  
     -- the suite index is controlled by the external e.g, ANT script, thus the suite simulations can be run in parallel
     -- the tests take respect to the suite index them self
     -- the individual suite runs appear automatically as test suites in the generated test junits
     -- the individual case runs appear automatically as test cases in the generated test suites
     loop 5
         equ stm.TestCaseIndex 0
         call stm.testCaseWithSuiteAndCaseIndex (
             label set TestToCall testSampleWithSuiteAndCaseIndexA
         )
         add stm.TestCaseIndex 1
     end loop
 
     loop 3
         equ stm.TestCaseIndex 10
         call stm.testCaseWithSuiteAndCaseIndex (
             label set TestToCall testSampleWithSuiteAndCaseIndexB
         )
         add stm.TestCaseIndex 10
     end loop    
 end proc
        
This snippet is present in `tb/simstm/TestSuites/TestSuiteIndexedSampleSuiteAndCaseIndex.stm <./tb/simstm/TestSuites/TestSuiteIndexedSampleSuiteAndCaseIndex.stm>`__. 
    
3. Write a procedure **testMainSuiteIndexedMyName**\ MyName in a **testMainSuiteIndexedMyName**\ MyName.stm file as entry point to launch the test suite.

Give the suite index range in  const **testMainSuiteIndexedRangeLength**\ MyName (this parsed and read by the helper scripts).  

The bold parts in the procedure, file name and constant are mandatory by policy.

.. code-block:: simstm

 const testMainSuiteIndexedSampleSuiteAndCaseIndexMaximumIndex 7

 proc testMainSuiteIndexedSampleSuiteAndCaseIndex ()
 
     call stm.initBase ()
 
     verbosity stm.INFO_2
     trace stm.TRACE_OFF
     resume stm.RESUME_ON_ALL_ERRORS
     signal write out_signal_init_dut 1
     wait 1000
     signal write out_signal_init_dut 0
     signal read stm.sigInTestSuiteIndex stm.TestSuiteIndex
     log message stm.INFO "Main test main suite indexed SampleSuiteSuiteAndCase {:d} started" stm.TestSuiteIndex
 
     call testSuiteIndexedSampleSuiteAndCaseIndex ()
 
     log message stm.INFO "Main test main suite indexed SampleSuiteSuiteAndCase {:d} ended" stm.TestSuiteIndex
     wait 1000
     finish
 end proc
    
This snippet is present in `tb/simstm/testMainSuiteSampleSuiteAndCaseIndex.stm <./tb/simstm/testMainSuiteSampleSuiteSuiteAndCaseIndex.stm>`__. 
