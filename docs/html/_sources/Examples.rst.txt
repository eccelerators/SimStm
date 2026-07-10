Examples
--------

How to run the examples
~~~~~~~~~~~~~~~~~~~~~~~

The examples are found in the ``examples`` folder of the repository. Each example has its own subfolder. Use this folder as current folder to run the examples.
Install java, ant and python set the environment variables JAVA_HOME and ANT_HOME. Then you can run the examples by calling the respective ant target.
Install the simulators you want to use and set the environment variables for the simulators. 
Then you can run the examples by calling the respective ant target.
For example, to run the Hello World example, call the target **modelsim-simulate** or **ghdl-simulate**. 
The target **modelsim-simulate** will run the simulation with modelsim and the target **ghdl-simulate** will run the simulation with ghdl.
Adaptations to different locations of the tools and simulators can be done by changing the build-local-overrides.xml file. 
This is usually not needed if you have the tools and simulators in the system path. 
It is usually not under version control but kept here for the user to adapt it to his needs.

The simulation results are generated as JUnit test result in the file `simulation/SimulationResults/testSuitesSimulation.xml <.simulation/SimulationResults/testSuitesSimulation.xml>`__.

Hello World
~~~~~~~~~~~

The Hello World example is the most basic example to demonstrate the usage of SimStm. 
It uses no JUnit test result features, but only the logging feature of SimStm.

The device under test in file `examples/HelloWorld/tb/src/vhdl/Dut.vhd <.examples/HelloWorld/tb/src/vhdl/Dut.vhd>`__  is very simple;
it has a Clk and a Rst signal as inputs and an Active signal as output. The Active signal 
is high when the Rst signal is low with the next rising edge of the Clk signal. 

The testbench in file `examples/HelloWorld/tb/hdl/tbTop.vhd <.examples/HelloWorld/tb/hdl/tbTop.vhd>`__  instantiates the Dut 
and generates the Clk signal.

The Rst signal is connected to the *out_signal_init_dut* signal of the SimStm testbench. 
This is a special signal which should be used to initialize the DUT.

The Active signal is connected to the *in_signal_Active* signal of the SimStm testbench.  

These signals are defined and declared in file `examples/HelloWorld/tb/simstm/hello/hello.stm <.examples/HelloWorld/tb/simstm/hello/hello.stm>`__

There are 2 standard tests in this file. The testHelloWorld test subroutine is the one which logs the message "Hello World" three times. 
The testActivation test subroutine is the one which waits 20 ns and verifies the Active signal to be high.

The testMain subroutine in file `examples/HelloWorld/tb/simstm/testMain.stm <.examples/HelloWorld/tb/simstm/testMain.stm>`__ calls both test subroutines.

.. code-block:: simstm

 proc testMain ()
     log message stm.INFO "Main test started"
 
     call testHelloWorld ()
     call testActivation ()
     
     log message stm.INFO "Main test finished"
     wait 1000
     lines append message success_lines "SUCCESS"
     log lines stm.INFO success_lines
     file write simulation_success success_lines
     wait 1000
     finish
 end proc
 
 
CounterLab
~~~~~~~~~~~~

The Counter Lab example is the basic example to demonstrate the usage of SimStm to provide 
Labs for different invesitgations at the same time in one project. 

The device under test in file `examples/HelloWorld/tb/src/vhdl/Dut.vhd <.examples/HelloWorld/tb/src/vhdl/Dut.vhd>`__  
is a counter with up and down count capability.
Beneath the signals of the Hello World example, it has a StepUp and a  StepDown signal as input and a Count signal as output.
The signals are connected to the SimStm testbench in the same way as in the Hello World example.

These signals are defined and declared in file
`examples/CounterPlain/tb/simstm/common/common.stm <.examples/CounterPlain/tb/simstm/common/common.stm>`__, 
which is the usual practice. Beneath the signals there are 3 subroutines control the initialization and the counting of the counter. 
The testCountUp and testCountDown standard test subroutines in 
file `examples/CounterPlain/tb/simstm/count/count.stm <.examples/CounterPlain/tb/simstm/count/count.stm>`__ calls these 
subroutines and verifies the count value after each step.

They are called by the testMain subroutine in 
file `examples/CounterPlain/tb/simstm/testMain.stm <.examples/CounterPlain/tb/simstm/testMain.stm>`__ for standard testing.

Beneath the standard test entry point testMain, there is now the 
file `examples/CounterPlain/tb/simstm/testMainLabCount.stm <.examples/CounterLab/tb/simstm/testMainLabCount.stm>`__ 
which is the entry point for a test lab with the name TestLabCount.

Th file `examples/CounterPlain/tb/simstm/TestLabs/TestLabCount.stm <.examples/CounterPlain/tb/simstm/TestLabs/TestLabCount.stm>`__
contains the test suite with the name TestSuiteCount. It calls the same test subroutines as the standard test entry point testMain.
Since one can have an arbitrary number of test labs it is possible to maintain different test labs for different purposes at the same time. 
The test lab TestLabCount is for example used to run the same standard tests as in testMain,

Only the usaul standard test logs are generated, but no JUnit test result is generated for the test lab.

.. code-block:: simstm

 proc testLabCount ()
 
     -- the test lab simply calls the test directly
     call testCountUp ()
     
     call testCountDown ()
     
 end proc



CounterPlain
~~~~~~~~~~~~

The Counter Plain example is the basic example to demonstrate the usage of SimStm with JUnit test result features. 

The device under test in file `examples/HelloWorld/tb/src/vhdl/Dut.vhd <.examples/HelloWorld/tb/src/vhdl/Dut.vhd>`__  
is a counter with up and down count capability.
Beneath the signals of the Hello World example, it has a StepUp and a  StepDown signal as input and a Count signal as output.
The signals are connected to the SimStm testbench in the same way as in the Hello World example.

These signals are defined and declared in file
`examples/CounterPlain/tb/simstm/common/common.stm <.examples/CounterPlain/tb/simstm/common/common.stm>`__, 
which is the usual practice. Beneath the signals there are 3 subroutines control the initialization and the counting of the counter. 
The testCountUp and testCountDown standard test subroutines in 
file `examples/CounterPlain/tb/simstm/count/count.stm <.examples/CounterPlain/tb/simstm/count/count.stm>`__ calls these 
subroutines and verifies the count value after each step.

They are called by the testMain subroutine in 
file `examples/CounterPlain/tb/simstm/testMain.stm <.examples/CounterPlain/tb/simstm/testMain.stm>`__ for standard testing.

Beneath the standard test entry point testMain, there is now the 
file `examples/CounterPlain/tb/simstm/testMainSuiteCount.stm <.examples/CounterPlain/tb/simstm/testMainSuiteCount.stm>`__ 
which is the entry point for a test suite with the name TestSuiteCount.

Th file `examples/CounterPlain/tb/simstm/TestSuites/TestSuiteCount.stm <.examples/CounterPlain/tb/simstm/TestSuites/TestSuiteCount.stm>`__
contains the test suite with the name TestSuiteCount. It calls the same test subroutines as the standard test entry point testMain, 
but it also calls some additional test subroutines by decorating the standard tests which are not called by the standard test entry point.

This provides the JUnit test result showing the 2 tests within a test suite with the name TestSuiteCount.

.. code-block:: simstm

 proc testSuiteCount ()
 
     call stm.testCase (
         label set TestToCall testCountUp
     )
     
     call stm.testCase (
         label set TestToCall testCountDown
     )
 end proc

CounterCaseIndexed
~~~~~~~~~~~~~~~~~~

The Counter Case Indexed example is an advanced example to demonstrate the usage of SimStm with JUnit test result features. 

The device under test and the testbench are similar as in the Counter Plain example. The increment or decrement is now done by a StepValue 
rather than up or down by 1. The test subroutines are also similar, but they are now indexed by the StepValue. Notice the changed decorations of the test subroutines 
in file `examples/CounterCaseIndexed/tb/simstm/count/count.stm <.examples/CounterCaseIndexed/tb/simstm/count/count.stm>`__. 
*Call stm.testCaseWithCaseIndex* is used to call the test subroutines with an index. The index is set by equ stm.TestCaseIndex before the call.

This provides the JUnit test result showing the 8 tests within a test suite with the name TestSuiteCount. 
The test case suffixes will be 0, 1, 2, 3, 4 for the first 5 tests and 10, 20, 30 for the next 3 tests.

.. code-block:: simstm

    proc testSuiteCount ()
    
        -- use stm.TestCaseIndex to run testSampleWithCaseIndexA with different parameters
        -- the individual runs appear automatically as test cases in the generated test suites
        loop 5
            equ stm.TestCaseIndex 0
            call stm.testCaseWithCaseIndex (
                label set TestToCall testCountUp
            )
            add stm.TestCaseIndex 1
        end loop
    
        loop 3
            equ stm.TestCaseIndex 10
            call stm.testCaseWithCaseIndex (
                label set TestToCall testCountDown
            )
            add stm.TestCaseIndex 10
        end loop
        
    end proc


CounterSuitendexed
~~~~~~~~~~~~~~~~~~

The Counter Case Indexed example is another advanced example to demonstrate the usage of SimStm with JUnit test result features. 

Rather than using the test case index to run the same test subroutine with different parameters,
the test suite index is now used to run different test subroutines.
 
The test suite index is set as parameter with the simulator run command by the outer test control ANT script. 
The test suite index is too used in the test suite to call different test subroutines. The outer script can thus run the simulation of different test suites 
in different threads in parallel in contradiction to the test case index which is used to run different test cases within the same test suite in sequence.

The device under test and the testbench are similar as in the Counter Plain example. There is a counter load feature able to set the counter to a LoadValue by a load signal. 
The test subroutines are also similar, but they are now indexed by the test suite index to start the former tests with different start values. 
Notice the changed decorations of the test subroutines 
in file `examples/CounterSuiteIndexed/tb/simstm/count/count.stm <.examples/CounterSuiteIndexed/tb/simstm/count/count.stm>`__. 
*Call stm.testCaseWithSuiteIndex* is used to call the test subroutines with an index. The index is set read by the respective testMainSuiteCount from a signal stm.TestSuiteIndex.

This provides the JUnit test result showing the 4 test suites TestSuiteIndexedCount and suffixes will be 0, 1, 2, 3. Test suite indexes are always incremented by 1, 
internally derived parameters have to calculated based upon the given stm.TestSuiteIndex.
The test case suffixes shown will be 0, 1, 2, 3 too.

.. code-block:: simstm

 proc testSuiteIndexedCount ()
     
     -- the suite index is controlled by the external e.g, ANT script, thus the suite simulations can be run in parallel
     -- the tests take respect to the suite index them self
     -- the individual runs appear automatically as test suites in the generated test junits
     call stm.testCaseWithSuiteIndex (
         label set TestToCall testCountUp
     )
 
     call stm.testCaseWithSuiteIndex (
         label set TestToCall testCountDown
     )
     
 end proc
 
The following file `examples/CounterPlain/tb/simstm/testMainSuiteIndexedCount.stm <.examples/CounterPlain/tb/simstm/testMainSuiteIndexedCount.stm>`__ sets 
the constant testMainSuiteIndexedRangeLengthCount to 4 to run the test suite with the suite index from 0 to 3.
 
.. code-block:: simstm
 
 const testMainSuiteIndexedRangeLengthCount 4

 proc testMainSuiteIndexedCount ()
  
     verbosity stm.INFO_2
     trace stm.TRACE_OFF
     resume stm.RESUME_ON_ALL_FAILURES
     signal write out_signal_init_dut 1
     wait 1000
     signal write out_signal_init_dut 0
     signal read stm.sigInTestSuiteIndex stm.TestSuiteIndex
     log message stm.INFO "Main test main suite indexed Count {:d} started" stm.TestSuiteIndex
 
     call testSuiteIndexedCount ()
 
     log message stm.INFO "Main test main suite indexed Count {:d} ended" stm.TestSuiteIndex
     wait 1000
     finish
 end proc

The test subroutine testCountUp in file `examples/CounterSuiteIndexed/tb/simstm/count/count.stm <.examples/CounterSuiteIndexed/tb/simstm/count/count.stm>`__ is 
an example of a test subroutine which is called by both the standard test entry point and the test suite entry point.
 
.. code-block:: simstm

 proc testCountUp (
    var TestSuiteIndex stm.TestSuiteIndex
 )
     var expextedCount 0
     var loadValue TestSuiteIndex
     mul loadValue 5
     and loadValue 256
     
     equ expextedCount loadValue
     
     call stm.startStandardTestShell ()
     call initDut ()    
     signal write out_signal_LoadValue loadValue
     call countLoad ()
     signal verify in_signal_Count expextedCount stm.MAX
     loop 4
         call countUp ()    
         add expextedCount 1  
         signal verify in_signal_Count expextedCount stm.MAX
         wait 1000
     end loop
     call stm.endStandardTestShell ()
 end procA
 
 
CounterSuiteCaseIndexed
~~~~~~~~~~~~~~~~~~~~~~~

The Counter Case Indexed example is a further advanced example to demonstrate the usage of SimStm with JUnit test result features. 

Both, the test suite and test case index to run the same test subroutine with different parameters.

Thus it isa a combination of the Counter Case Indexed and the Counter Suite Indexed examples. 
The test suite index is set as parameter with the simulator run command by the outer test control ANT script. The test case internally at will.

The device under test and the testbench are similar as in the Counter Suite Indexed example. Now we have the is a counter load and step 
value feature able to set the counter to a LoadValue by a load signal and to step at fifferent sites by the step value. 
The test subroutines are also similar, but they are now indexed by both indexes. 
Notice the changed decorations of the test subroutines 
in file `examples/CounterSuiteIndexed/tb/simstm/count/count.stm <.examples/CounterSuiteIndexed/tb/simstm/count/count.stm>`__. 
*Call stm.testCaseWithSuiteIndex* is used to call the test subroutines with an index. The index is set read by the respective testMainSuiteCount from a signal stm.TestSuiteIndex.

This provides the JUnit test result showing the 4 test suites TestSuiteIndexedCount and suffixes will be 0, 1, 2, 3 with 8 rest cases each. 
The test case suffixes shown will be 0_0, 0_1, 0_2 ... 3_6, 3_7.

.. code-block:: simstm

 proc testSuiteIndexedCount ()
     
     -- the suite index is controlled by the external e.g, ANT script, thus the suite simulations can be run in parallel
     -- the tests take respect to the suite index them self
     -- the individual suite runs appear automatically as test suites in the generated test junits
     -- the individual case runs appear automatically as test cases in the generated test suites
     
     loop 5
         equ stm.TestCaseIndex 0
         call stm.testCaseWithSuiteAndCaseIndex (
             label set TestToCall testCountUp
         )
         add stm.TestCaseIndex 1
     end loop
 
     loop 3
         equ stm.TestCaseIndex 10
         call stm.testCaseWithSuiteAndCaseIndex (
             label set TestToCall testCountDown
         )
         add stm.TestCaseIndex 10
     end loop
     
 end proc


Real-World Examples
~~~~~~~~~~~~~~~~~~~

Complex real-world example are found in the eccelerators group of
repositories on `GitHub <https://github.com/eccelerators>`__.


Example modification workflow
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

For detailed instructions on how to extensively modify the examples e.g. add vhdl or simstm files, see the `Repository Guide <RepositoryGuide.rst>`__.