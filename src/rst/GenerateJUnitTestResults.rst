
SimStm Testbench Build Structure
--------------------------------

The SimStm testbench is structured like a JUnit framework. It consists of the actual test cases, testMains, TestSuites and TestLabs.

TestSuites group related test cases into logical units to run them together. For example, all tests related to testing different
functionalities of files are grouped in TestSuiteFile.

TestMains launch the TestSuites. They can also provide a user interface for better readability.

TestLabs are for experimenting with specific test cases.

