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
    "name": "HelloWorld",
    "author": "Heinrich Diebel, Bernd Roeckert, Denis Vasilik",
    "author_email": "heinrich.diebel@eccelerators.com; bernd.roeckert@eccelerators.com; denis.vasilik@eccelerators.com;",
    "url": "https://github.com/eccelerators/HelloWorld/",
    "description": "HelloWorld",
    "long_description_content_type": "text/markdown",
    "classifiers": [
        "Programming Language :: Python :: 3.7",
        "Operating System :: OS Independent"
    ],
    "dependency_links": [],
    "package_data": {},
    "project_name": "HelloWorld",
    "top_entity": "Dut",
    "top_entity_file": "src/vhdl/Dut.vhd",
    "tb_top_entity": "tbTop",
    "tb_top_entity_file": "/tb/hdl/tbTop.vhd",
        "test_suites" : [
    ],
    "test_labs" : [
    ],
    "other_data_files" : [(
        "HelloWorld", [
        ])
    ],
    "src_data_files" : [(
        "HelloWorld/src/vhdl", [
            {"file":"src/vhdl/Dut.vhd", "file_type":"VHDL 2008", "hdl_order":"00170"},
            {"file":"src/vhdl/eccelerators_basic.vhd", "file_type":"VHDL 2008", "hdl_order":"00160"}
        ])
    ],
    "tb_data_files" : [(
        "HelloWorld/tb/hdl/src_to_customize", [
            {"file":"tb/hdl/src_to_customize/tb_signals_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00050", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/src_to_customize/tb_limits_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00000", "ghdl_options":["-frelaxed"]},
            {"file":"tb/hdl/src_to_customize/tb_bus_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00140", "ghdl_options":["-frelaxed"]}
        ]),(
        "HelloWorld/tb/hdl", [
            {"file":"tb/hdl/tbTop.vhd", "file_type":"VHDL 2008", "hdl_order":"00180", "ghdl_options":["-frelaxed"]}
        ]),(
        "HelloWorld/../../src", [
            {"file":"../../src/tb_bus_wishbone_64_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00060", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_bus_wishbone_256_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00080", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_instructions_pkg_body.vhd", "file_type":"VHDL 2008", "hdl_order":"00021", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_simstm.vhd", "file_type":"VHDL 2008", "hdl_order":"00150", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_base_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00010", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_interpreter_pkg_body.vhd", "file_type":"VHDL 2008", "hdl_order":"00041", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_bus_avalon_64_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00120", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_bus_wishbone_32_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00070", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_instructions_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00020", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_interpreter_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00040", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_bus_avalon_32_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00130", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_bus_wishbone_128_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00090", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_interpreter_util_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00030", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_interpreter_util_pkg_body.vhd", "file_type":"VHDL 2008", "hdl_order":"00031", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_bus_axi4lite_32_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00110", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_bus_ram_32_pkg.vhd", "file_type":"VHDL 2008", "hdl_order":"00100", "ghdl_options":["-frelaxed"]},
            {"file":"../../src/tb_base_pkg_body.vhd", "file_type":"VHDL 2008", "hdl_order":"00011", "ghdl_options":["-frelaxed"]}
        ])
    ],
    "src_tb_simstm_data_files" : [(
        "HelloWorld/tb/simstm/hello", [
            {"file":"tb/simstm/hello/hello.stm"}
        ]),(
        "HelloWorld/tb/simstm", [
            {"file":"tb/simstm/testMain.stm"}
        ]),(
        "HelloWorld/../../lib", [
            {"file":"../../lib/util.stm"},
            {"file":"../../lib/arith.stm"},
            {"file":"../../lib/array.stm"},
            {"file":"../../lib/base.stm"}
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