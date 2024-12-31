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
            {"testsuite-name":"testSuiteFile", "file":"TestSuites/TestSuiteFile.stm", "entry-file":"testMainSuiteFile.stm", "entry-label":"$testMainSuiteFile"},
            {"testsuite-name":"testSuiteArray", "file":"TestSuites/TestSuiteArray.stm", "entry-file":"testMainSuiteArray.stm", "entry-label":"$testMainSuiteArray"},
            {"testsuite-name":"testSuiteSignal", "file":"TestSuites/TestSuiteSignal.stm", "entry-file":"testMainSuiteSignal.stm", "entry-label":"$testMainSuiteSignal"},
            {"testsuite-name":"testSuiteBusWishbone", "file":"TestSuites/TestSuiteBusWishbone.stm", "entry-file":"testMainSuiteBusWishbone.stm", "entry-label":"$testMainSuiteBusWishbone"}
    ],
    "test_labs" : [
            {"testlab-name":"testLabArrayGetOutPos", "file":"TestLabs/TestLabArrayGetOutPos.stm", "entry-file":"testMainLabArrayGetOutPos.stm", "entry-label":"$testMainLabArrayGetOutPos"},
            {"testlab-name":"testLabArrayZeroSize", "file":"TestLabs/TestLabArrayZeroSize.stm", "entry-file":"testMainLabArrayZeroSize.stm", "entry-label":"$testMainLabArrayZeroSize"},
            {"testlab-name":"testLabArraySetOutPos", "file":"TestLabs/TestLabArraySetOutPos.stm", "entry-file":"testMainLabArraySetOutPos.stm", "entry-label":"$testMainLabArraySetOutPos"}
    ],
    "other_data_files" : [(
        "simstm", [
            {"file":"README.md"}
        ])
    ],
    "src_data_files" : [(
        "simstm/src_to_customize", [
            {"file":"src_to_customize/tb_bus_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00070"},
            {"file":"src_to_customize/tb_signals_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00030"}
        ]),(
        "simstm/src/vhdl", [
            {"file":"src/vhdl/tb_bus_avalon_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00060"},
            {"file":"src/vhdl/tb_base_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00080"},
            {"file":"src/vhdl/tb_interpreter_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00100"},
            {"file":"src/vhdl/tb_interpreter_pkg_body.vhd", "file_type":"VHDL 2008", "hdl_order":"00101"},
            {"file":"src/vhdl/tb_bus_axi4lite_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00050"},
            {"file":"src/vhdl/tb_base_pkg_body.vhd", "file_type":"VHDL 2008", "hdl_order":"00081"},
            {"file":"src/vhdl/tb_instructions_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00090"},
            {"file":"src/vhdl/tb_simstm.vhd", "file_type":"VHDL 2008", "hdl_order":"00110"},
            {"file":"src/vhdl/tb_bus_wishbone_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00040"}
        ])
    ],
    "tb_data_files" : [(
        "simstm/tb/hdl", [
            {"file":"tb/hdl/RamWishbone.vhd", "file_type":"VHDL 2008", "hdl_order":"00000", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/tbTop.vhd", "file_type":"VHDL 2008", "hdl_order":"00120", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/RamAvalon.vhd", "file_type":"VHDL 2008", "hdl_order":"00020", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/RamAxi4Lite.vhd", "file_type":"VHDL 2008", "hdl_order":"00010", "ghdl_options":["-frelaxed"]}
        ])
    ],
    "src_tb_simstm_data_files" : [(
        "simstm/tb/simstm/TestLabs", [
            {"file":"tb/simstm/TestLabs/TestLabArrayGetOutPos.stm"},
            {"file":"tb/simstm/TestLabs/TestLabArrayZeroSize.stm"},
            {"file":"tb/simstm/TestLabs/TestLabArraySetOutPos.stm"}
        ]),(
        "simstm/tb/simstm/File", [
            {"file":"tb/simstm/File/file.stm"}
        ]),(
        "simstm/tb/simstm/Signal", [
            {"file":"tb/simstm/Signal/signal.stm"},
            {"file":"tb/simstm/Signal/signal_pointer.stm"}
        ]),(
        "simstm/tb/simstm/Common", [
            {"file":"tb/simstm/Common/Common.stm"},
            {"file":"tb/simstm/Common/CommonLabs.stm"}
        ]),(
        "simstm/tb/simstm/Bus", [
            {"file":"tb/simstm/Bus/bus.stm"}
        ]),(
        "simstm/tb/simstm/TestSuites", [
            {"file":"tb/simstm/TestSuites/TestSuiteFile.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteArray.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteSignal.stm"},
            {"file":"tb/simstm/TestSuites/TestSuiteBusWishbone.stm"}
        ]),(
        "simstm/tb/simstm/Array", [
            {"file":"tb/simstm/Array/array.stm"},
            {"file":"tb/simstm/Array/array_zero_size.stm"},
            {"file":"tb/simstm/Array/array_pointer.stm"},
            {"file":"tb/simstm/Array/array_size.stm"}
        ]),(
        "simstm/tb/simstm/TestCase", [
            {"file":"tb/simstm/TestCase/TestCase.stm"}
        ]),(
        "simstm/tb/simstm/Base", [
            {"file":"tb/simstm/Base/Base.stm"}
        ]),(
        "simstm/tb/simstm", [
            {"file":"tb/simstm/testMainSuiteBusWishbone.stm"},
            {"file":"tb/simstm/testMainLabArraySetOutPos.stm"},
            {"file":"tb/simstm/testMainLabArrayGetOutPos.stm"},
            {"file":"tb/simstm/testMain.stm"},
            {"file":"tb/simstm/testMainLabArrayZeroSize.stm"},
            {"file":"tb/simstm/testMainSuiteSignal.stm"},
            {"file":"tb/simstm/testMainSuiteArray.stm"},
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