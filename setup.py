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
    "name" : "simstm", 
    "author": "Heinrich Diebel, Bernd Roeckert, Denis Vasilik",
    "author_email" : "heinrich.diebel@eccelerators.com; bernd.roeckert@eccelerators.com; denis.vasilik@eccelerators.com;",
    "url" : "https://github.com/eccelerators/simstm/",
    "description" : "Simstm",
    "long_description_content_type" : "text/markdown",                   
    "classifiers" : [
        "Programming Language :: Python :: 3.7",
        "Operating System :: OS Independent"
    ],
    "dependency_links" : [],
    "package_data" : {}, 
    "project_name" : "Simstm",
    "top_entity" : "tb_simstm",
    "top_entity_file" : "src/vhdl/tb_simstm.vhd",
    "tb_top_entity" : "tbTop",
    "tb_top_entity_file" : "/tb/hdl/tbTop.vhd",
    "test_suites" : [
            {"testsuite-name":"testSuiteConstant", "file":"TestSuites/TestSuiteConstant.stm", "entry-file":"testMainSuiteConstant.stm", "entry-label":"$testMainSuiteConstant"},
            {"testsuite-name":"testSuiteVariable", "file":"TestSuites/TestSuiteVariable.stm", "entry-file":"testMainSuiteVariable.stm", "entry-label":"$testMainSuiteVariable"},
            {"testsuite-name":"testSuiteLines", "file":"TestSuites/TestSuiteLines.stm", "entry-file":"testMainSuiteLines.stm", "entry-label":"$testMainSuiteLines"},
            {"testsuite-name":"testSuiteInterrupt", "file":"TestSuites/TestSuiteInterrupt.stm", "entry-file":"testMainSuiteInterrupt.stm", "entry-label":"$testMainSuiteInterrupt"},
            {"testsuite-name":"testSuiteBusAvalon", "file":"TestSuites/TestSuiteBusAvalon.stm", "entry-file":"testMainSuiteBusAvalon.stm", "entry-label":"$testMainSuiteBusAvalon"},
            {"testsuite-name":"testSuiteOther", "file":"TestSuites/TestSuiteOther.stm", "entry-file":"testMainSuiteOther.stm", "entry-label":"$testMainSuiteOther"},
            {"testsuite-name":"testSuiteFile", "file":"TestSuites/TestSuiteFile.stm", "entry-file":"testMainSuiteFile.stm", "entry-label":"$testMainSuiteFile"},
            {"testsuite-name":"testSuiteBasic", "file":"TestSuites/TestSuiteBasic.stm", "entry-file":"testMainSuiteBasic.stm", "entry-label":"$testMainSuiteBasic"},
            {"testsuite-name":"testSuiteArray", "file":"TestSuites/TestSuiteArray.stm", "entry-file":"testMainSuiteArray.stm", "entry-label":"$testMainSuiteArray"},
            {"testsuite-name":"testSuiteBusAxi4Lite", "file":"TestSuites/TestSuiteBusAxi4Lite.stm", "entry-file":"testMainSuiteBusAxi4Lite.stm", "entry-label":"$testMainSuiteBusAxi4Lite"},
            {"testsuite-name":"testSuiteSignal", "file":"TestSuites/TestSuiteSignal.stm", "entry-file":"testMainSuiteSignal.stm", "entry-label":"$testMainSuiteSignal"},
            {"testsuite-name":"testSuiteBusWishbone", "file":"TestSuites/TestSuiteBusWishbone.stm", "entry-file":"testMainSuiteBusWishbone.stm", "entry-label":"$testMainSuiteBusWishbone"}
    ],
    "test_labs" : [
            {"testlab-name":"testLabConstantEqu", "file":"TestLabs/TestLabConstantEqu.stm", "entry-file":"testMainLabConstantEqu.stm", "entry-label":"$testMainLabConstantEqu"},
            {"testlab-name":"testLabBasicDoubleVar", "file":"TestLabs/TestLabBasicDoubleVar.stm", "entry-file":"testMainLabBasicDoubleVar.stm", "entry-label":"$testMainLabBasicDoubleVar"},
            {"testlab-name":"testLabArrayGetOutPos", "file":"TestLabs/TestLabArrayGetOutPos.stm", "entry-file":"testMainLabArrayGetOutPos.stm", "entry-label":"$testMainLabArrayGetOutPos"},
            {"testlab-name":"testLabBasicIncludeNested", "file":"TestLabs/TestLabBasicIncludeNested.stm", "entry-file":"testMainLabBasicIncludeNested.stm", "entry-label":"$testMainLabBasicIncludeNested"},
            {"testlab-name":"testLabBasicIncludeFlat", "file":"TestLabs/TestLabBasicIncludeFlat.stm", "entry-file":"testMainLabBasicIncludeFlat.stm", "entry-label":"$testMainLabBasicIncludeFlat"},
            {"testlab-name":"testLabArrayZeroSize", "file":"TestLabs/TestLabArrayZeroSize.stm", "entry-file":"testMainLabArrayZeroSize.stm", "entry-label":"$testMainLabArrayZeroSize"},
            {"testlab-name":"testLabArraySetOutPos", "file":"TestLabs/TestLabArraySetOutPos.stm", "entry-file":"testMainLabArraySetOutPos.stm", "entry-label":"$testMainLabArraySetOutPos"},
            {"testlab-name":"testLabConstantAdd", "file":"TestLabs/TestLabConstantAdd.stm", "entry-file":"testMainLabConstantAdd.stm", "entry-label":"$testMainLabConstantAdd"},
            {"testlab-name":"testLabBasicAbort", "file":"TestLabs/TestLabBasicAbort.stm", "entry-file":"testMainLabBasicAbort.stm", "entry-label":"$testMainLabBasicAbort"},
            {"testlab-name":"testLabBasicDoubleConst", "file":"TestLabs/TestLabBasicDoubleConst.stm", "entry-file":"testMainLabBasicDoubleConst.stm", "entry-label":"$testMainLabBasicDoubleConst"},
            {"testlab-name":"testLabBasicFinish", "file":"TestLabs/TestLabBasicFinish.stm", "entry-file":"testMainLabBasicFinish.stm", "entry-label":"$testMainLabBasicFinish"}
    ],
    "other_data_files" : [(
        "simstm", [
            {"file":"README.md"}
        ])
    ],
    "src_data_files" : [(
        "simstm/src_to_customize", [
            {"file":"src_to_customize/tb_bus_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00090"},
            {"file":"src_to_customize/tb_signals_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00040"},
            {"file":"src_to_customize/tb_bus_axi4lite_32_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00070"},
            {"file":"src_to_customize/tb_bus_avalon_32_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00080"},
            {"file":"src_to_customize/tb_bus_wishbone_64_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00050"},
            {"file":"src_to_customize/tb_bus_wishbone_32_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00060"}
        ]),(
        "simstm/src/vhdl", [
            {"file":"src/vhdl/tb_base_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00030"},
            {"file":"src/vhdl/tb_interpreter_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00110"},
            {"file":"src/vhdl/tb_interpreter_pkg_body.vhd", "file_type":"VHDL 2008", "hdl_order":"00111"},
            {"file":"src/vhdl/tb_base_pkg_body.vhd", "file_type":"VHDL 2008", "hdl_order":"00031"},
            {"file":"src/vhdl/tb_instructions_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00100"},
            {"file":"src/vhdl/tb_simstm.vhd", "file_type":"VHDL 2008", "hdl_order":"00120"}
        ])
    ],
    "tb_data_files" : [(
        "simstm/tb/hdl", [
            {"file":"tb/hdl/RamWishbone.vhd", "file_type":"VHDL 2008", "hdl_order":"00000", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/tbTop.vhd", "file_type":"VHDL 2008", "hdl_order":"00130", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/RamAvalon.vhd", "file_type":"VHDL 2008", "hdl_order":"00020", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/RamAxi4Lite.vhd", "file_type":"VHDL 2008", "hdl_order":"00010", "ghdl_options":["-frelaxed"]}
        ])
    ],
    "src_tb_simstm_data_files" : [(
        "simstm/tb/simstm/TestLabs", [
            {"file":"tb/simstm/TestLabs/TestLabConstantEqu.stm"},
            {"file":"tb/simstm/TestLabs/TestLabBasicDoubleVar.stm"},
            {"file":"tb/simstm/TestLabs/TestLabArrayGetOutPos.stm"},
            {"file":"tb/simstm/TestLabs/TestLabBasicIncludeNested.stm"},
            {"file":"tb/simstm/TestLabs/TestLabBasicIncludeFlat.stm"},
            {"file":"tb/simstm/TestLabs/TestLabArrayZeroSize.stm"},
            {"file":"tb/simstm/TestLabs/TestLabArraySetOutPos.stm"},
            {"file":"tb/simstm/TestLabs/TestLabConstantAdd.stm"},
            {"file":"tb/simstm/TestLabs/TestLabBasicAbort.stm"},
            {"file":"tb/simstm/TestLabs/TestLabBasicDoubleConst.stm"},
            {"file":"tb/simstm/TestLabs/TestLabBasicFinish.stm"}
        ]),(
        "simstm/tb/simstm/Interrupt", [
            {"file":"tb/simstm/Interrupt/interrupt.stm"}
        ]),(
        "simstm/tb/simstm/File", [
            {"file":"tb/simstm/File/file.stm"}
        ]),(
        "simstm/tb/simstm/Signal", [
            {"file":"tb/simstm/Signal/signal.stm"},
            {"file":"tb/simstm/Signal/signal_pointer.stm"}
        ]),(
        "simstm/tb/simstm/Constant", [
            {"file":"tb/simstm/Constant/constant_labs.stm"},
            {"file":"tb/simstm/Constant/constant.stm"}
        ]),(
        "simstm/tb/simstm/Common", [
            {"file":"tb/simstm/Common/Common.stm"},
            {"file":"tb/simstm/Common/CommonLabs.stm"}
        ]),(
        "simstm/tb/simstm/Bus", [
            {"file":"tb/simstm/Bus/bus.stm"}
        ]),(
        "simstm/tb/simstm/TestSuites", [
            {"file":"tb/simstm/TestSuites/TestSuiteConstant.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteVariable.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteLines.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteInterrupt.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteBusAvalon.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteOther.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteFile.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteBasic.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteArray.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteBusAxi4Lite.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteSignal.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteBusWishbone.stm"}
        ]),(
        "simstm/tb/simstm/Other", [
            {"file":"tb/simstm/Other/other.stm"}
        ]),(
        "simstm/tb/simstm/Variable", [
            {"file":"tb/simstm/Variable/variable.stm"}
        ]),(
        "simstm/tb/simstm/Array", [
            {"file":"tb/simstm/Array/array.stm"},
            {"file":"tb/simstm/Array/array_labs_zero_size.stm"},
            {"file":"tb/simstm/Array/array_labs.stm"},
            {"file":"tb/simstm/Array/array_pointer.stm"},
            {"file":"tb/simstm/Array/array_size.stm"}
        ]),(
        "simstm/tb/simstm/TestCase", [
            {"file":"tb/simstm/TestCase/TestCase.stm"}
        ]),(
        "simstm/tb/simstm/Basic", [
            {"file":"tb/simstm/Basic/lib3.stm"},
            {"file":"tb/simstm/Basic/basic_labs_double_var.stm"},
            {"file":"tb/simstm/Basic/lib1.stm"},
            {"file":"tb/simstm/Basic/lib2.stm"},
            {"file":"tb/simstm/Basic/lib5.stm"},
            {"file":"tb/simstm/Basic/basic_labs_double_const.stm"},
            {"file":"tb/simstm/Basic/basic.stm"},
            {"file":"tb/simstm/Basic/lib4.stm"},
            {"file":"tb/simstm/Basic/lib6.stm"},
            {"file":"tb/simstm/Basic/basic_labs.stm"}
        ]),(
        "simstm/tb/simstm/Lines", [
            {"file":"tb/simstm/Lines/lines.stm"}
        ]),(
        "simstm/tb/simstm/Base", [
            {"file":"tb/simstm/Base/Array.stm"},
            {"file":"tb/simstm/Base/Base.stm"},
            {"file":"tb/simstm/Base/ReadModifyWrite.stm"}
        ]),(
        "simstm/tb/simstm", [
            {"file":"tb/simstm/testMainSuiteBusWishbone.stm"},
            {"file":"tb/simstm/testMainLabBasicDoubleConst.stm"},
            {"file":"tb/simstm/testMainSuiteOther.stm"},
            {"file":"tb/simstm/testMainSuiteInterrupt.stm"},
            {"file":"tb/simstm/testMainLabArraySetOutPos.stm"},
            {"file":"tb/simstm/testMainSuiteLines.stm"},
            {"file":"tb/simstm/testMainLabArrayGetOutPos.stm"},
            {"file":"tb/simstm/testMainLabBasicIncludeFlat.stm"},
            {"file":"tb/simstm/testMainSuiteBusAxi4Lite.stm"},
            {"file":"tb/simstm/testMainLabBasicAbort.stm"},
            {"file":"tb/simstm/testMainSuiteConstant.stm"},
            {"file":"tb/simstm/testMainSuiteBusAvalon.stm"},
            {"file":"tb/simstm/testMainLabBasicDoubleVar.stm"},
            {"file":"tb/simstm/testMainLabConstantEqu.stm"},
            {"file":"tb/simstm/testMain.stm"},
            {"file":"tb/simstm/testMainSuiteVariable.stm"},
            {"file":"tb/simstm/testMainLabArrayZeroSize.stm"},
            {"file":"tb/simstm/testMainSuiteSignal.stm"},
            {"file":"tb/simstm/testMainLabBasicIncludeNested.stm"},
            {"file":"tb/simstm/testMainSuiteArray.stm"},
            {"file":"tb/simstm/testMainLabBasicFinish.stm"},
            {"file":"tb/simstm/testMainSuiteBasic.stm"},
            {"file":"tb/simstm/testMainLabConstantAdd.stm"},
            {"file":"tb/simstm/testMainSuiteFile.stm"}
        ])
    ],
      
    "setup_requires" : []
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
    name = static_setup_data["name"],
    version = __version__,
    author = static_setup_data["author"],
    author_email = static_setup_data["author_email"],
    url = static_setup_data["url"],
    description = static_setup_data["description"],
    long_description = long_description,
    long_description_content_type = static_setup_data["long_description_content_type"],
    packages = setuptools.find_packages(),
    classifiers= static_setup_data["classifiers"],
    dependency_links = static_setup_data["dependency_links"],
    package_data = static_setup_data["package_data"],
    data_files = setup_data_files,
    setup_requires = static_setup_data["setup_requires"]
)