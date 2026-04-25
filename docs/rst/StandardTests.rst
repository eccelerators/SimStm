Standard Tests
--------------

SimStm provides standard methods to report test results in the simulator console. 
They can be called in the standard testMain entry point `tb/simstm/testMain.stm <./tb/simstm/testMain.stm>`__ directly or 
in any other procedure called from the testMain entry point.

This is useful for quick feedback during test development and debugging. 
However, for more formal test reporting, SimStm can generate test results in JUnit XML format, refer to chapter JUnit Tests.

To use the standard test result reporting in the simulator console, simply follow these steps:

Write pieces of SimStm code in your test stimulus files (.stm) that represent a test. 
An example is shown in `tb/simstm/sample/sample.stm <./tb/simstm/sample/sample.stm>`__. 
       
.. code-block:: simstm

 proc testSampleA ()
     call stm.startStandardTestShell ()
     -- enter your test code here
     -- use verify instructions here as assertions
     -- verify and bus timeouts are monitored between startStandardTestShell and endStandardTestShell
     log message 0 "testSampleA has been run"
     call stm.endStandardTestShell ()
 end proc

It may be a good practice to name procedures representing a test with a common prefix e.g. *test* as done in the previous example.

Call *stm.startStandardTestShell ()* SimStm library procedure at the beginning of the test procedure. This will start a test shell that monitors 
for any verify instruction or bus timeout.

Call *stm.endStandardTestShell ()* SimStm library procedure at the end of the test procedure. This will end the test shell and report the 
test result in the simulator console.

The total number of executed assertions verify instructions or bus timeouts will be counted and reported separately.
The number of failed assertions verify instructions or bus timeouts will be counted and reported separately.

Sometimes verify instructions or bus timeouts shall fail intentionally. For this purpose SimStm allows to 
set *stm.ExpectedStandardTestVerifyFailureCount* variable or *stm.ExpectedStandardTestBusTimeoutFailureCount* 
variable to the expected number of failed respective assertions.

To modify these variables the respective SimStm library procedure e.g., *stm.setExpectedStandardTestVerifyFailureCount (count)* or *stm.addExpectedStandardTestVerifyFailureCount (count)* **MUST** be used.

The expected values are reported beneath the actually got ones. Of course, the expected values shall be set before 
calling *stm.endStandardTestShell ()* procedure. They are reset to zero within *stm.endStandardTestShell ()* procedure after the report has been printed.

If the number of failed assertions or bus timeouts is greater than the expected number, the test will be report **Failures** at 
the end of the report, otherwise **Success**.

The standard testMain procedure is an example of how to use the standard test result reporting in the simulator console.
An example is shown in `tb/simstm/testMain.stm <./tb/simstm/testMain.stm>`__. 