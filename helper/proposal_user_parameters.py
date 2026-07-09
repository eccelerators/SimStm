from contextlib import redirect_stdout
import io
import os
from pathlib import Path
from pathlib import PurePath

import click
from jinja2 import Environment
from jinja2 import FileSystemLoader
from jinja2 import Template
from vhdeps import run_cli

class UserParameters:
    
    def __init__(self, project_folder_name):
        self.project_folder_name = project_folder_name
              
        self.src_vhdl_folders = []

        self.tb_vhdl_folders = ['src_to_customize',
                                'src',
                                'tb/hdl',
                                ]

        self.tb_simstm_folders = ['tb/simstm',
                             ]
    
        self.other_folders = {
            self.project_folder_name: [{"source_folder": ".", "suffixes": [".md", ".rst"]}]
        }
        
        self.search_folder_for_top_entity = None
        self.search_folder_for_tb_top_entity = 'tb/hdl'
        self.search_folder_for_simstm_test_main_files_for_entry_namespace = 'tb/simstm'
    
        self.search_phrase_in_vhdl_files_for_top_entity = 'dut'
        self.search_phrase_in_vhdl_files_for_tb_top_entity = "tbTop"
        self.search_phrase_in_simstm_test_main_files_for_entry_namespace = "testMain."

        self.extra_src_data_files_entries = [
        ]
        
        self.extra_vhdl_file_dicts = [
            {"file":"src/tb_bus_wishbone.vhd", "file_type":"VHDL 2008", "hdl_order":"00062", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_bus_axi4lite.vhd", "file_type":"VHDL 2008", "hdl_order":"00063", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_bus_ram.vhd", "file_type":"VHDL 2008", "hdl_order":"00064", "ghdl_options":["-frelaxed"]},
            {"file":"src/tb_bus_avalon.vhd", "file_type":"VHDL 2008", "hdl_order":"00065", "ghdl_options":["-frelaxed"]},
        ]
