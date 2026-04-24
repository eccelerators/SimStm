Automated Tests
---------------

The test folder contains unit tests for all commands. Thus all commands
are verified for each release by regression tests.

.. code-block:: none
	
    pip3 install click jinja2
    ant _helper-generate-ghdl-ant-build-xml
    ant ghdl-all

.. code-block:: none
	
    pip3 install click jinja2
    ant _helper-generate-modelsim-ant-build-xml
    ant modelsim-all
