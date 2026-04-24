
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tb_limits_pkg is
    constant max_str_len : integer := 512;
    constant max_field_len : integer := 128;
    constant c_stm_text_len : integer := 500;
    constant max_num_of_inst_def_elements : integer := 500;
    constant max_num_of_inst_elements : integer := 1000;
    constant max_num_of_var_elements : integer := 300;
    constant max_num_of_proc_elements : integer := 100;
    constant max_num_of_file_def_elements : integer := 100;
    constant max_num_of_stack_elements : integer := 31;
end package;
