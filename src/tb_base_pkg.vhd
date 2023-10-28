library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tb_base_pkg is

    -- constants
    constant max_str_len : integer := 256;
    constant max_field_len : integer := 128;
    constant c_stm_text_len : integer := 200;

    -- file handles
    file stimulus : text; -- file main file
    file include_file : text; -- file declaration for includes

    -- type def's
    type base is (bin, oct, hex, dec);
    --  subtype stack_element is integer range 0 to 8192;
    type stack_register is array (31 downto 0) of integer;
    type state_register is array (7 downto 0) of boolean;
    type int_array is array (1 to 128) of integer;
    type int_array_array is array (1 to 16) of int_array;
    type boolean_array is array (0 to 127) of boolean;

    subtype text_field is string(1 to max_field_len);
    subtype text_line is string(1 to max_str_len);
    subtype stm_text is string(1 to c_stm_text_len);
    type stm_text_ptr is access stm_text;

    -- define the stimulus line record and access
    type stim_line;
    type stim_line_ptr is access stim_line; -- pointer to stim_line record
    type stim_line is record
        instruction : text_field;
        inst_field_1 : text_field;
        inst_field_2 : text_field;
        inst_field_3 : text_field;
        inst_field_4 : text_field;
        inst_field_5 : text_field;
        inst_field_6 : text_field;
        txt : stm_text_ptr;
        line_number : integer; -- sequence line
        num_of_lines : integer; -- total number of lines
        file_line : integer; -- file line number
        file_idx : integer;
        next_rec : stim_line_ptr;
    end record;

    -- define the instruction structure
    type inst_def;
    type inst_def_ptr is access inst_def;
    type inst_def is record
        instruction : text_field;
        instruction_l : integer;
        params : integer;
        next_rec : inst_def_ptr;
    end record;

    -- define the file handle record
    type file_def;
    type file_def_ptr is access file_def;
    type file_def is record
        rec_idx : integer;
        file_name : text_line;
        next_rec : file_def_ptr;
    end record;
    
    type t_stm_array is array (natural range <>) of integer;
    type t_stm_array_ptr is access t_stm_array;

    type t_stm_line;
    type t_stm_line_ptr is access t_stm_line;
    type t_stm_line is record
        line_content : line;
        next_stm_line : t_stm_line_ptr;
    end record;

    type t_stm_lines;
    type t_stm_lines_ptr is access t_stm_lines;
    type t_stm_lines is record
        stm_line_list : t_stm_line_ptr;
        size : integer;
        next_stm_lines : t_stm_lines_ptr;
    end record;


    type t_stm_var_type is (STM_VALUE_TYPE, STM_CONST_VALUE_TYPE, STM_TEXT_TYPE, STM_ARRAY_TYPE, STM_LINES_TYPE, STM_BUS_TYPE, STM_SIGNAL_TYPE, STM_LABEL_TYPE, NO_VAR_TYPE);

    -- define the variables field and pointer
    type var_field;
    type var_field_ptr is access var_field; -- pointer to var_field
    type var_field is record
        var_name : text_field;
        var_index : integer;
        var_value : integer;
        var_stm_type : t_stm_var_type;
        var_stm_text : stm_text_ptr;
        var_stm_array : t_stm_array_ptr;
        var_stm_lines : t_stm_lines_ptr;   
        next_rec : var_field_ptr;
    end record;

    function stm_file_status(v_stat : file_open_status) return integer;
    
    procedure stm_file_readable(variable file_path : in stm_text_ptr;
        variable status : out integer);    
    
    procedure stm_file_writeable(variable file_path : in stm_text_ptr;
        variable status : out integer);

    procedure stm_file_appendable(variable file_path : in stm_text_ptr;
        variable status : out integer);
        
    procedure stm_file_read_all(variable stm_lines : inout t_stm_lines_ptr;
        variable file_path : in stm_text_ptr;
        variable valid : out integer);
        
    procedure stm_file_write(variable stm_lines : out t_stm_lines_ptr;
        variable file_path : in stm_text_ptr;
        variable valid : out integer);

    procedure stm_file_append(variable stm_lines : in t_stm_lines_ptr;
        variable file_path : in stm_text_ptr;
        variable valid : out integer);

    procedure stm_lines_get(variable stm_lines : in t_stm_lines_ptr;
        variable position : in integer;
        variable stm_array : inout t_stm_array_ptr;
        variable valid : out integer);

    procedure stm_lines_get(variable stm_lines : in t_stm_lines_ptr;
        variable position : in integer;
        variable std_line : out line;
        variable valid : out integer);

    procedure stm_lines_set(variable stm_lines : inout t_stm_lines_ptr;
        variable position : integer;
        variable stm_array : in t_stm_array_ptr;
        variable valid : out integer);

    procedure stm_lines_set(variable stm_lines : inout t_stm_lines_ptr;
        variable position : in integer;
        variable var_stm_text : in stm_text_ptr;
        variable valid : out integer);

    procedure stm_lines_append(variable stm_lines : inout t_stm_lines_ptr;
        variable stm_array : in t_stm_array_ptr;
        variable valid : out integer);

    procedure stm_lines_append (variable stm_lines : inout t_stm_lines_ptr;
        variable var_stm_text : in stm_text_ptr;
        variable valid : out integer);
        
    procedure stm_lines_append (variable stm_lines : inout t_stm_lines_ptr;
        variable std_line : in line;
        variable valid : out integer);

    procedure stm_lines_insert(variable stm_lines : inout t_stm_lines_ptr;
        variable position : integer;
        variable stm_array : in t_stm_array_ptr;
        variable valid : out integer);

    procedure stm_lines_insert(variable stm_lines : inout t_stm_lines_ptr;
        variable position : in integer;
        variable var_stm_text : out stm_text_ptr;
        variable valid : out integer);

    procedure stm_lines_delete(variable stm_lines : inout t_stm_lines_ptr;
        variable position : in integer;
        variable valid : out integer);
        
    procedure stm_lines_print(variable stm_lines : in t_stm_lines_ptr;
        variable valid : out integer);

    function is_digit(constant c : in character) return boolean;

    function is_space(constant c : in character) return boolean;

    function ew_to_char(int : integer) return character;

    function to_str(int : integer) return string;

    function ew_str_cat(s1 : stm_text;
        s2 : text_field) return stm_text;

    -- function str_len(line: text_line) return text_field;
    function fld_len(s : in text_field) return integer;

    function text_line_len(s : in text_line) return integer;

    function fld_equal(s1 : in text_field;
        s2 : in text_field) return boolean;

    function c2int(c : in character) return integer;

    function str2integer(str : in string) return integer;

    function hex2integer(hex_number : in text_field;
        file_name : in text_line;
        line : in integer) return integer;

    function c2std_vec(c : in character) return std_logic_vector;

    function std_vec2c(vec : in std_logic_vector(3 downto 0)) return character;

    function bin2integer(bin_number : in text_field;
        file_name : in text_line;
        line : in integer) return integer;

    function stim_to_integer(field : in text_field;
        file_name : in text_line;
        line : in integer) return integer;

    function ew_to_str(int : integer;
        b : base) return text_field;

    function ew_to_str_len(int : integer;
        b : base) return text_field;

    --  function short text_line (remove 'nul')
    function text_line_crop(txt : in text_line) return string;
    function stm_text_crop(txt : in stm_text) return string;

    procedure txt_to_string(variable ptr : in stm_text_ptr; variable str : out stm_text);


    procedure print_inst(variable inst : in stim_line_ptr);

    -- dump inst_sequ
    --  this procedure dumps to the simulation window the current instruction
    --  sequence.  the whole thing will be dumped, which could be big.
    --   ** intended for testbench development debug**
    procedure dump_inst_sequ(variable inst_sequ  :  in  stim_line_ptr);

    -- print to stdout  string
    procedure print(s : in string);

    -- procedure print stim txt
    procedure txt_print(variable ptr : in stm_text_ptr);

    -- procedure copy text into an existing pointer
    procedure txt_ptr_copy(variable ptr : in stm_text_ptr;
        variable ptr_o : out stm_text_ptr;
        variable txt_str : in stm_text);

    -- takes a source string of type string and initializes a field of type
    -- text_field that is primarly used by the open corse test bench.
    procedure init_text_field(variable sourcestr : in string;
        variable destfield : out text_field);

    --  get a random intetger number
    procedure getrandint(variable seed1 : inout positive;
        variable seed2 : inout positive;
        variable lowestvalue : in integer;
        variable utmostvalue : in integer;
        variable randint : out integer);

end package;
