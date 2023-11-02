library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.tb_base_pkg.all;
use work.tb_instructions_pkg.all;

package tb_interpreter_pkg is

    --  access_variable
    --     inputs:
    --               text field containing variable
    --     outputs:
    --               value  $var  returns value of var
    --               value  var   returns index of var
    --
    --               valid is 1, not valid is 0
    procedure access_variable(variable var_list : in var_field_ptr;
        variable var : in text_field;
        variable value : out integer;
        variable valid : out integer);

    --  index_variable
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               variable value
    --               valid  is 1 if valid 0 if not
    procedure index_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable value : out integer;
        variable valid : out integer);

    --  index_variable
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               variable stm_text
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable var_stm_text : out stm_text_ptr;
        variable valid : out integer);

    --  index_stm_array
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               stm_array
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable stm_array : out t_stm_array_ptr;
        variable valid : out integer);

    --  index_stm_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               stm_lines
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable stm_lines : out t_stm_lines_ptr;
        variable valid : out integer);

    --  update_variable
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               variable value
    --               valid  is 1 if valid 0 if not
    procedure update_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable value : in integer;
        variable valid : out integer);

    --  update_array
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               new array
    --               valid  is 1 if valid 0 if not
    procedure update_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable stm_array : in t_stm_array_ptr;
        variable valid : out integer);

    --  update_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               new lines
    --               valid  is 1 if valid 0 if not
    procedure update_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable stm_lines : in t_stm_lines_ptr;
        variable valid : out integer);

    -- read_instruction_file
    --  this procedure reads the instruction file, name passed throught file_name.
    --  pointers to records are passed in and out.  a table of variables is created
    --  with variable name and value (converted to integer).  the instructions are
    --  parsesed into the inst_sequ list.  instructions are validated against the
    --  inst_set which must have been set up prior to loading the instruction file.
    procedure read_instruction_file(constant path_name : string;
        constant file_name : string;
        variable inst_set : inout inst_def_ptr;
        variable var_list : inout var_field_ptr;
        variable inst_sequ : inout stim_line_ptr;
        variable file_list : inout file_def_ptr);

    -- access_inst_sequ
    --   this procedure retreeves an instruction from the sequence of instructions.
    --   based on the line number you pass to it, it returns the instruction with
    --   any variables substituted as integers.
    procedure access_inst_sequ(variable inst_sequ : in stim_line_ptr;
        variable var_list : in var_field_ptr;
        variable file_list : in file_def_ptr;
        variable sequ_num : in integer;
        variable inst : out text_field;
        variable p1 : out integer;
        variable p2 : out integer;
        variable p3 : out integer;
        variable p4 : out integer;
        variable p5 : out integer;
        variable p6 : out integer;
        variable txt : out stm_text_ptr;
        variable inst_len : out integer;
        variable fname : out text_line;
        variable file_line : out integer;
        variable last_num : inout integer;
        variable last_ptr : inout stim_line_ptr
    );

    --  tokenize_line
    --    this procedure takes a type text_line in and returns up to 6
    --    tokens and the count in integer valid, as well if text string
    --    is found the pointer to that is returned.
    procedure tokenize_line(variable text_line : in text_line;
        variable otoken1 : out text_field;
        variable otoken2 : out text_field;
        variable otoken3 : out text_field;
        variable otoken4 : out text_field;
        variable otoken5 : out text_field;
        variable otoken6 : out text_field;
        variable otoken7 : out text_field;
        variable txt_ptr : out stm_text_ptr;
        variable ovalid : out integer);

    --procedure print stim txt sub variables found
    procedure txt_print_wvar(variable var_list : in var_field_ptr;
        variable ptr : in stm_text_ptr;
        constant b : in base);

    procedure stm_text_substitude_wvar(variable var_list : in var_field_ptr;
        variable ptr : in stm_text_ptr;
        variable stm_text_substituded : out stm_text;
        constant b : in base);

    -- dump inst_sequ
    --  this procedure dumps to the simulation window the current instruction
    --  sequence.  the whole thing will be dumped, which could be big.
    --   ** intended for testbench development debug**
    procedure dump_inst_sequ(variable inst_sequ : in stim_line_ptr; file_list : inout file_def_ptr);

    -- procedure to print instruction records to stdout  *for debug*
    procedure print_inst(variable inst_sequ : in stim_line_ptr; v_line : in integer; file_list : inout file_def_ptr);

     -- dump all variables    
    procedure dump_variables(variable var_list : in var_field_ptr);

    procedure dump_var_field(variable ptr : var_field_ptr);

    procedure dump_file_defs(file_list : inout file_def_ptr);

    procedure print_file_def(file_list : inout file_def_ptr; index : in integer);

end package;
