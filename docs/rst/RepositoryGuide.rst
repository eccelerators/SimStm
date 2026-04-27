Repository Guide
----------------
The repository content needed by the user:

- ``src``: The main folder containing the VHDL code of the testbench not to be modified by the user.
- ``src/vhdl/tb_simstm``: The testbench top entity and architecture to be instanciated in the the user testbench.
- ``src_to_customize``: The folder containing the packages to be customized by the user.

All Eccelerators IP repositories are aimed to be presented as Python Packages in future. 
SimStm though not a synthesizable IP, is presented in the same manner. 
SimStm tests itself by its own means.

- ``helper``: The helper folder containing helper scripts only needed for the SimStm selftest.
- ``helper/proposal_for_setup_py.py``: Generating ``setup.py`` based on Eccelerators conventions.
- ``helper/generate-ghdl-ant-build-xml.py``: Generating ``simulation/ghdl/build-ghdl.xml`` based on ``setup.py``.
- ``helper/generate-modelsim-ant-build-xml.py``: Generating ``simulation/modelsim/build-modelsim.xml`` based on ``setup.py``.
- ``helper/collect-simulation-results.py``: Generating JUnit test result ``simulation/SimulationResults/testSuitesSimulation.xml`` 
  called by ant controlled test flow.
  
All Eccelerators IP repositories are build by **ant**. The ant build scripts are organized hierarchically. 
The top build script is build.xml in the repository root. It imports ``helper/build-helper.xml``. 
This presents the initial workflow target **_helper-generate-proposal-for-setup-py** to generate ``setup.py``.
User adaptions have to be done in **proposal_user_parameters.py** beforehand.

As a next step the target **_helper-generate-ghdl-ant-build-xml** is called to generate the ghdl build script.
Once you refresh the list of shown ant targets in your IDE, you will see the new ghdl targets.
The target **ghdl-all** is the one to be called to run the simulation. It would be similar if you decide for modelsim.

- ``simulation``: The simulation folder containing the generated preparations and the simulation results.
- ``tb/hdl``: The (self)test bench hdl sources and tbTop.vhd with the top entity and architecture.
- ``tb/simstm``: The (self)test bench simstm sources following Eccelerators conventions to produce a selftest result as JUnit test result.

Beneath the simstm selfttest sources in tb/simstm subfolders which of course test every simstm instruction, the ``command_list.stm`` 
in the repository root  can be used as a comprehensive list for instruction examples. 

The main purpose of this repository is to provide and test SimStm. 
Complex real-world examples of how it is used are found in the Eccelerators group of
repositories on `GitHub <https://github.com/eccelerators>`__.