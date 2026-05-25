import setuptools

with open("CHANGELOG.md", "r") as fh:
    long_description = fh.read()

__tag__ = ""
__build__ = 0
__commit__ = "0000000"
__version__ = "{}".format(__tag__)

# Section is used to generate an AMD project file
# Dont't use trailing ,
# Only use " but '
# start static_setup_data section
static_setup_data = {
    "name": "SimStm",
    "author": "Heinrich Diebel, Bernd Roeckert, Denis Vasilik",
    "author_email": "heinrich.diebel@eccelerators.com; bernd.roeckert@eccelerators.com; denis.vasilik@eccelerators.com;",
    "url": "https://github.com/eccelerators//simstm/examples/SimStm/",
    "description": "SimStm",
    "long_description_content_type": "text/markdown",
    "classifiers": [
        "Programming Language :: Python :: 3.7",
        "Operating System :: OS Independent"
    ],
    "dependency_links": [],
    "package_data": {},
    "project_name": "SimStm",
    "top_entity": "",
    "top_entity_file": "",
    "tb_top_entity": "tbTop",
    "tb_top_entity_file": "/tb/hdl/tbTop.vhd",
    "tb_simstm_entry_namespace": "SimStmTest",
    "tb_simstm_entry_file": "testMain.stm",
    "test_suites" : [
        {"testsuite-name":"testSuiteVariable", "file":"TestSuites/TestSuiteVariable.stm", "entry-file":"testMainSuiteVariable.stm", "entry-label":"SimStmTest.testMainSuiteVariable"},
        {"testsuite-name":"testSuiteSignal", "file":"TestSuites/TestSuiteSignal.stm", "entry-file":"testMainSuiteSignal.stm", "entry-label":"SimStmTest.testMainSuiteSignal"},
        {"testsuite-name":"testSuiteOther", "file":"TestSuites/TestSuiteOther.stm", "entry-file":"testMainSuiteOther.stm", "entry-label":"SimStmTest.testMainSuiteOther"},
        {"testsuite-name":"testSuiteNamespace", "file":"TestSuites/TestSuiteNamespace.stm", "entry-file":"testMainSuiteNamespace.stm", "entry-label":"SimStmTest.testMainSuiteNamespace"},
        {"testsuite-name":"testSuiteIndexedBus", "file":"TestSuites/TestSuiteIndexedBus.stm", "testsuite-indexes":"32", "entry-file":"testMainSuiteIndexedBus.stm", "entry-label":"SimStmTest.testMainSuiteIndexedBus"},
        {"testsuite-name":"testSuiteInterrupt", "file":"TestSuites/TestSuiteInterrupt.stm", "entry-file":"testMainSuiteInterrupt.stm", "entry-label":"SimStmTest.testMainSuiteInterrupt"},
        {"testsuite-name":"testSuiteArray", "file":"TestSuites/TestSuiteArray.stm", "entry-file":"testMainSuiteArray.stm", "entry-label":"SimStmTest.testMainSuiteArray"},
        {"testsuite-name":"testSuiteFile", "file":"TestSuites/TestSuiteFile.stm", "entry-file":"testMainSuiteFile.stm", "entry-label":"SimStmTest.testMainSuiteFile"},
        {"testsuite-name":"testSuiteConstant", "file":"TestSuites/TestSuiteConstant.stm", "entry-file":"testMainSuiteConstant.stm", "entry-label":"SimStmTest.testMainSuiteConstant"},
        {"testsuite-name":"testSuiteLines", "file":"TestSuites/TestSuiteLines.stm", "entry-file":"testMainSuiteLines.stm", "entry-label":"SimStmTest.testMainSuiteLines"},
        {"testsuite-name":"testSuiteBasic", "file":"TestSuites/TestSuiteBasic.stm", "entry-file":"testMainSuiteBasic.stm", "entry-label":"SimStmTest.testMainSuiteBasic"}
    ],
    "test_labs" : [
            {"testlab-name":"testLabBasicFinish", "file":"TestLabs/TestLabBasicFinish.stm", "entry-file":"testMainLabBasicFinish.stm", "entry-label":"SimStmTest.testMainLabBasicFinish"},
            {"testlab-name":"testLabBasicIncludeNested", "file":"TestLabs/TestLabBasicIncludeNested.stm", "entry-file":"testMainLabBasicIncludeNested.stm", "entry-label":"SimStmTest.testMainLabBasicIncludeNested"},
            {"testlab-name":"testLabArraySetOutPos", "file":"TestLabs/TestLabArraySetOutPos.stm", "entry-file":"testMainLabArraySetOutPos.stm", "entry-label":"SimStmTest.testMainLabArraySetOutPos"},
            {"testlab-name":"testLabConstantAdd", "file":"TestLabs/TestLabConstantAdd.stm", "entry-file":"testMainLabConstantAdd.stm", "entry-label":"SimStmTest.testMainLabConstantAdd"},
            {"testlab-name":"testLabArrayZeroSize", "file":"TestLabs/TestLabArrayZeroSize.stm", "entry-file":"testMainLabArrayZeroSize.stm", "entry-label":"SimStmTest.testMainLabArrayZeroSize"},
            {"testlab-name":"testLabArrayGetOutPos", "file":"TestLabs/TestLabArrayGetOutPos.stm", "entry-file":"testMainLabArrayGetOutPos.stm", "entry-label":"SimStmTest.testMainLabArrayGetOutPos"},
            {"testlab-name":"testLabBasicDoubleConst", "file":"TestLabs/TestLabBasicDoubleConst.stm", "entry-file":"testMainLabBasicDoubleConst.stm", "entry-label":"SimStmTest.testMainLabBasicDoubleConst"},
            {"testlab-name":"testLabBasicIncludeFlat", "file":"TestLabs/TestLabBasicIncludeFlat.stm", "entry-file":"testMainLabBasicIncludeFlat.stm", "entry-label":"SimStmTest.testMainLabBasicIncludeFlat"},
            {"testlab-name":"testLabConstantEqu", "file":"TestLabs/TestLabConstantEqu.stm", "entry-file":"testMainLabConstantEqu.stm", "entry-label":"SimStmTest.testMainLabConstantEqu"},
            {"testlab-name":"testLabBasicAbort", "file":"TestLabs/TestLabBasicAbort.stm", "entry-file":"testMainLabBasicAbort.stm", "entry-label":"SimStmTest.testMainLabBasicAbort"},
            {"testlab-name":"testLabBasicDoubleVar", "file":"TestLabs/TestLabBasicDoubleVar.stm", "entry-file":"testMainLabBasicDoubleVar.stm", "entry-label":"SimStmTest.testMainLabBasicDoubleVar"}
    ],
    "other_data_files" : [(
        "SimStm", [
            {"file":"README.rst"}
        ])
    ],
    "src_data_files" : [
    ],
    "tb_data_files" : [(
        "SimStm/src_to_customize", [
            {"file":"src_to_customize/tb_signals_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00070", "ghdl_options":["-frelaxed"]},
            {"file":"src_to_customize/tb_bus_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00080", "ghdl_options":["-frelaxed"]}
        ]),(
        "SimStm/src", [
            {"file":"src/tb_bus_wishbone.vhd", "file_type":"VHDL 2008", "hdl_order":"00062", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_bus_axi4lite.vhd", "file_type":"VHDL 2008", "hdl_order":"00063", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_bus_ram.vhd", "file_type":"VHDL 2008", "hdl_order":"00064", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_instructions_pkg_body.vhd", "file_type":"VHDL 2008", "hdl_order":"00091", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_simstm.vhd", "file_type":"VHDL 2008", "hdl_order":"00120", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_base_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00060", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_interpreter_pkg_body.vhd", "file_type":"VHDL 2008", "hdl_order":"00111", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_instructions_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00090", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_bus_avalon.vhd", "file_type":"VHDL 2008", "hdl_order":"00065", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_interpreter_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00110", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_interpreter_util_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00100", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_limits_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00050", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_interpreter_util_pkg_body.vhd", "file_type":"VHDL 2008", "hdl_order":"00101", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_base_pkg_body.vhd", "file_type":"VHDL 2008", "hdl_order":"00061", "ghdl_options":["-frelaxed"]}
        ]),(
        "SimStm/tb/hdl", [
            {"file":"tb/hdl/eccelerators_basic.vhd", "file_type":"VHDL 2008", "hdl_order":"00000", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/RamAvalon.vhd", "file_type":"VHDL 2008", "hdl_order":"00030", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/Ram.vhd", "file_type":"VHDL 2008", "hdl_order":"00040", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/tbTop.vhd", "file_type":"VHDL 2008", "hdl_order":"00130", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/RamWishbone.vhd", "file_type":"VHDL 2008", "hdl_order":"00010", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/RamAxi4Lite.vhd", "file_type":"VHDL 2008", "hdl_order":"00020", "ghdl_options":["-frelaxed"]}
        ])
    ],
    "src_tb_simstm_data_files" : [(
        "SimStm/tb/simstm/Array", [
            {"file":"tb/simstm/Array/array_size.stm"},
            {"file":"tb/simstm/Array/array_local_override.stm"},
            {"file":"tb/simstm/Array/array_parameter.stm"},
            {"file":"tb/simstm/Array/array_local.stm"},
            {"file":"tb/simstm/Array/array_labs.stm"},
            {"file":"tb/simstm/Array/array_default_value.stm"},
            {"file":"tb/simstm/Array/array_pointer.stm"},
            {"file":"tb/simstm/Array/array_labs_zero_size.stm"},
            {"file":"tb/simstm/Array/array.stm"}
        ]),(
        "SimStm/tb/simstm/File", [
            {"file":"tb/simstm/File/file_local.stm"},
            {"file":"tb/simstm/File/file_pointer.stm"},
            {"file":"tb/simstm/File/file_parameter.stm"},
            {"file":"tb/simstm/File/file.stm"},
            {"file":"tb/simstm/File/file_local_override.stm"}
        ]),(
        "SimStm/tb/simstm/Namespace", [
            {"file":"tb/simstm/Namespace/namespace.stm"}
        ]),(
        "SimStm/tb/simstm/Signal", [
            {"file":"tb/simstm/Signal/signal_pointer.stm"},
            {"file":"tb/simstm/Signal/signal_extend.stm"},
            {"file":"tb/simstm/Signal/signal_scoping.stm"},
            {"file":"tb/simstm/Signal/signal_local_override.stm"},
            {"file":"tb/simstm/Signal/signal_parameter.stm"},
            {"file":"tb/simstm/Signal/signal_verify_failure.stm"},
            {"file":"tb/simstm/Signal/signal_base.stm"}
        ]),(
        "SimStm/tb/simstm/Units", [
            {"file":"tb/simstm/Units/units_file.stm"},
            {"file":"tb/simstm/Units/units_array.stm"},
            {"file":"tb/simstm/Units/units_namespace.stm"},
            {"file":"tb/simstm/Units/units_bus.stm"},
            {"file":"tb/simstm/Units/units_interrupt.stm"},
            {"file":"tb/simstm/Units/units_other.stm"},
            {"file":"tb/simstm/Units/units_basic.stm"},
            {"file":"tb/simstm/Units/units_constant.stm"},
            {"file":"tb/simstm/Units/units_lines.stm"},
            {"file":"tb/simstm/Units/units_signal.stm"},
            {"file":"tb/simstm/Units/units_variable.stm"}
        ]),(
        "SimStm/tb/simstm/Common", [
            {"file":"tb/simstm/Common/common.stm"},
            {"file":"tb/simstm/Common/interface.stm"}
        ]),(
        "SimStm/tb/simstm/Lines", [
            {"file":"tb/simstm/Lines/lines_local.stm"},
            {"file":"tb/simstm/Lines/lines_pointer.stm"},
            {"file":"tb/simstm/Lines/lines_local_override.stm"},
            {"file":"tb/simstm/Lines/lines_parameter.stm"},
            {"file":"tb/simstm/Lines/lines.stm"}
        ]),(
        "SimStm/tb/simstm/Interrupt", [
            {"file":"tb/simstm/Interrupt/interrupt.stm"}
        ]),(
        "SimStm/tb/simstm/Basic", [
            {"file":"tb/simstm/Basic/lib2.stm"},
            {"file":"tb/simstm/Basic/lib4.stm"},
            {"file":"tb/simstm/Basic/basic_labs_double_const.stm"},
            {"file":"tb/simstm/Basic/lib6.stm"},
            {"file":"tb/simstm/Basic/basic_labs.stm"},
            {"file":"tb/simstm/Basic/basic_labs_double_var.stm"},
            {"file":"tb/simstm/Basic/lib5.stm"},
            {"file":"tb/simstm/Basic/lib1.stm"},
            {"file":"tb/simstm/Basic/lib3.stm"},
            {"file":"tb/simstm/Basic/basic.stm"}
        ]),(
        "SimStm/tb/simstm/TestLabs", [
            {"file":"tb/simstm/TestLabs/TestLabBasicFinish.stm"},
            {"file":"tb/simstm/TestLabs/TestLabBasicIncludeNested.stm"},
            {"file":"tb/simstm/TestLabs/TestLabArraySetOutPos.stm"},
            {"file":"tb/simstm/TestLabs/TestLabConstantAdd.stm"},
            {"file":"tb/simstm/TestLabs/TestLabArrayZeroSize.stm"},
            {"file":"tb/simstm/TestLabs/TestLabArrayGetOutPos.stm"},
            {"file":"tb/simstm/TestLabs/TestLabBasicDoubleConst.stm"},
            {"file":"tb/simstm/TestLabs/TestLabBasicIncludeFlat.stm"},
            {"file":"tb/simstm/TestLabs/TestLabConstantEqu.stm"},
            {"file":"tb/simstm/TestLabs/TestLabBasicAbort.stm"},
            {"file":"tb/simstm/TestLabs/TestLabBasicDoubleVar.stm"}
        ]),(
        "SimStm/tb/simstm/Label", [
            {"file":"tb/simstm/Label/label.stm"}
        ]),(
        "SimStm/tb/simstm/Variable", [
            {"file":"tb/simstm/Variable/variable_local.stm"},
            {"file":"tb/simstm/Variable/variable_local_override.stm"},
            {"file":"tb/simstm/Variable/variable_pointer.stm"},
            {"file":"tb/simstm/Variable/variable.stm"},
            {"file":"tb/simstm/Variable/variable_default_value.stm"},
            {"file":"tb/simstm/Variable/variable_parameter.stm"}
        ]),(
        "SimStm/tb/simstm/Constant", [
            {"file":"tb/simstm/Constant/constant.stm"},
            {"file":"tb/simstm/Constant/constant_labs.stm"}
        ]),(
        "SimStm/tb/simstm/TestSuites", [
            {"file":"tb/simstm/TestSuites/TestSuiteVariable.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteSignal.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteOther.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteNamespace.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteIndexedBus.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteInterrupt.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteArray.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteFile.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteConstant.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteLines.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteBasic.stm"}
        ]),(
        "SimStm/tb/simstm/Other", [
            {"file":"tb/simstm/Other/other.stm"}
        ]),(
        "SimStm/tb/simstm/Bus", [
            {"file":"tb/simstm/Bus/bus32.stm"},
            {"file":"tb/simstm/Bus/bus128.stm"},
            {"file":"tb/simstm/Bus/bus256.stm"},
            {"file":"tb/simstm/Bus/bus64.stm"},
            {"file":"tb/simstm/Bus/bus32_parameter.stm"}
        ]),(
        "SimStm/tb/simstm", [
            {"file":"tb/simstm/testMainSuiteSignal.stm"},
            {"file":"tb/simstm/testMainSuiteArray.stm"},
            {"file":"tb/simstm/testMainLabConstantAdd.stm"},
            {"file":"tb/simstm/testMainLabBasicIncludeFlat.stm"},
            {"file":"tb/simstm/testMainSuiteIndexedBus.stm"},
            {"file":"tb/simstm/testMainLabBasicIncludeNested.stm"},
            {"file":"tb/simstm/testMainSuiteBasic.stm"},
            {"file":"tb/simstm/testMainLabArrayGetOutPos.stm"},
            {"file":"tb/simstm/testMainLabBasicDoubleConst.stm"},
            {"file":"tb/simstm/testMainLabBasicDoubleVar.stm"},
            {"file":"tb/simstm/testMainLabBasicAbort.stm"},
            {"file":"tb/simstm/testMainSuiteNamespace.stm"},
            {"file":"tb/simstm/testMainLabArrayZeroSize.stm"},
            {"file":"tb/simstm/testMainSuiteConstant.stm"},
            {"file":"tb/simstm/testMainSuiteVariable.stm"},
            {"file":"tb/simstm/testMain.stm"},
            {"file":"tb/simstm/testMainLabBasicFinish.stm"},
            {"file":"tb/simstm/testMainLabArraySetOutPos.stm"},
            {"file":"tb/simstm/testMainSuiteInterrupt.stm"},
            {"file":"tb/simstm/testMainSuiteOther.stm"},
            {"file":"tb/simstm/testMainSuiteLines.stm"},
            {"file":"tb/simstm/testMainSuiteFile.stm"},
            {"file":"tb/simstm/testMainLabConstantEqu.stm"}
        ])
    ],

    "setup_requires": []
}
# end static_setup_data section

setup_data_files = []
setup_data_files_sections = ["other_data_files", "src_data_files", "tb_data_files", "src_tb_simstm_data_files"]

for section in setup_data_files_sections:
    for data_folder_file_list_pair in static_setup_data[section]:
        data_folder_file_list = []
        for data_file_dict in data_folder_file_list_pair[1]:
            data_folder_file_list.append(data_file_dict["file"])
        setup_data_files.append((data_folder_file_list_pair[0], data_folder_file_list))

setuptools.setup(
    name=static_setup_data["name"],
    version=__version__,
    author=static_setup_data["author"],
    author_email=static_setup_data["author_email"],
    url=static_setup_data["url"],
    description=static_setup_data["description"],
    long_description=long_description,
    long_description_content_type=static_setup_data["long_description_content_type"],
    packages=setuptools.find_packages(),
    classifiers=static_setup_data["classifiers"],
    dependency_links=static_setup_data["dependency_links"],
    package_data=static_setup_data["package_data"],
    data_files=setup_data_files,
    setup_requires=static_setup_data["setup_requires"]
)