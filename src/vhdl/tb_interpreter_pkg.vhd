-------------------------------------------------------------------------------
-- SimStm
--
-- SPDX-License-Identifier: Apache-2.0
--
-- Copyright:
--   - Original work derived from VHDL-Test-Bench (Ken Campbell)
--   - Subsequent modifications: Eccelerators
--
-- Description:
--   Public interpreter API for parsing stimulus files and executing SimStm instructions.
--
-- Upstream reference:
--   https://github.com/sckoarn/VHDL-Test-Bench
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.tb_limits_pkg.all;
use work.tb_base_pkg.all;
use work.tb_instructions_pkg.all;
use work.tb_interpreter_util_pkg.all;

package tb_interpreter_pkg is

    procedure collect_code_files(
        variable slc : src_locator;
        variable code_files : inout file_def_list;
        constant stimulus_path : string;
        variable stimulus_file : string
    );

    procedure parse_constants(
        variable code_files : in file_def_list;
        variable inst_defs : in inst_def_list;
        variable vars : inout var_pool_ordered;
        variable procs : inout proc_pool_ordered;
        constant machine_value_width : integer;
        constant debug : boolean
    );

    procedure parse_variables(
        variable code_files : in file_def_list;
        variable inst_defs : in inst_def_list;
        variable vars : inout var_pool_ordered;
        variable procs : inout proc_pool_ordered;
        constant machine_value_width : in integer;
        constant debug : boolean
    );

    procedure parse_instructions_and_procs(
        variable code_files : in file_def_list;
        variable inst_defs : in inst_def_list;
        variable insts : inout inst_sequence;
        variable vars : inout var_pool_ordered;
        variable procs : inout proc_pool_ordered;
        constant machine_value_width : integer;
        constant debug : boolean
    );

    procedure check_instructions_in_initial_context(
        variable insts : inout inst_sequence;
        variable vars : inout var_pool_ordered;
        variable procs : inout proc_pool_ordered;
        constant machine_value_width : integer
    );

end package;
