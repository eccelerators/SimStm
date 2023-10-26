library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_base_pkg.all;

package body tb_interpreter_pkg is

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
        variable valid : out integer) is

        variable l : integer;
        variable var_ptr : var_field_ptr;
        variable temp_field : text_field;
        variable ptr : integer := 0; -- 0 is index, 1 is pointer
        variable is_defined : boolean := false;
    begin

        l := fld_len(var);
        valid := 0;
        -- if the variable is a special
        if (var(1) = '=') then
            value := 0;
            valid := 1;
        elsif (var(1 to 2) = ">=") then
            value := 4;
            valid := 1;
        elsif (var(1 to 2) = "<=") then
            value := 5;
            valid := 1;
        elsif (var(1) = '>') then
            value := 1;
            valid := 1;
        elsif (var(1) = '<') then
            value := 2;
            valid := 1;
        elsif (var(1 to 2) = "!=") then
            value := 3;
            valid := 1;
        else
            if (var(1) = '$') then
                ptr := 1; -- this is a pointer
                for i in 2 to l loop
                    temp_field(i - 1) := var(i);
                end loop;
            else
                temp_field := var;
            end if;

            assert (var_list /= null)
            report lf & "error: no variables are defined." & lf
            severity failure;

            var_ptr := var_list;
            while (var_ptr.next_rec /= null) loop
                -- if we have a match
                if (fld_equal(temp_field, var_ptr.var_name)) then
                    if (ptr = 1) then
                        value := var_ptr.var_value;
                        valid := 1;
                        is_defined := true;
                    else
                        value := var_ptr.var_index;
                        valid := 1;
                        is_defined := true;
                    end if;
                    exit;
                end if;
                var_ptr := var_ptr.next_rec;
            end loop;

            -- if we have a match and was the last record
            if (var_ptr.next_rec = null) then
                if (fld_equal(temp_field, var_ptr.var_name)) then
                    if (ptr = 1) then
                        value := var_ptr.var_value;
                        valid := 1;
                        is_defined := true;
                    else
                        value := var_ptr.var_index;
                        valid := 1;
                        is_defined := true;
                    end if;
                end if;
            end if;

            assert (is_defined)
            report lf & "error: variable is not defined " & temp_field & lf
            severity failure;
        end if;
    end procedure;


    --  index_variable
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               variable value
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable value : out integer;
        variable valid : out integer) is

        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index) then
                value := ptr.var_value;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if (ptr.var_index = index) then
            value := ptr.var_value;
            valid := 1;
        end if;
    end procedure;


    --  index_variable
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               variable stm_text
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable var_stm_text : out stm_text_ptr;
        variable valid : out integer) is

        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index) then
                var_stm_text := ptr.var_stm_text;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if (ptr.var_index = index) then
            var_stm_text := ptr.var_stm_text;
            valid := 1;
        end if;
    end procedure;


    --  index_stm_array
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               stm_array
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable stm_array : out t_stm_array_ptr;
        variable valid : out integer) is

        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index) then
                stm_array := ptr.var_stm_array;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if (ptr.var_index = index) then
            stm_array := ptr.var_stm_array;
            valid := 1;
        end if;
    end procedure;


    --  index_stm_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               stm_lines
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable stm_lines : out t_stm_lines_ptr;
        variable valid : out integer) is

        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index) then
                stm_lines := ptr.var_stm_lines;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if (ptr.var_index = index) then
            stm_lines := ptr.var_stm_lines;
            valid := 1;
        end if;
    end procedure;

    --  update_variable
    --     inputs:
    --               index:  the index of the variable being updated
    --     outputs:
    --               valid is 1, not valid is 0
    procedure update_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable value : in integer;
        variable valid : out integer) is

        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE) then
                ptr.var_value := value;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if (ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE) then
            ptr.var_value := value;
            valid := 1;
        end if;
    end procedure;


    --  update_array
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               new array
    --               valid is 1, not valid is 0
    procedure update_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable stm_array : in t_stm_array_ptr;
        variable valid : out integer) is

        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE) then
                ptr.var_stm_array := stm_array;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if (ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE) then
            ptr.var_stm_array := stm_array;
            valid := 1;
        end if;
    end procedure;


    --  update_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               new lines
    --               valid is 1, not valid is 0
    procedure update_variable(variable var_list : in var_field_ptr;
        variable index : in integer;
        variable stm_lines : in t_stm_lines_ptr;
        variable valid : out integer) is

        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index) then
                ptr.var_stm_lines := stm_lines;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if (ptr.var_index = index) then
            ptr.var_stm_lines := stm_lines;
            valid := 1;
        end if;
    end procedure;


    -- read a line from a file
    --   inputs  :   file of type text
    --   outputs :   the line of type text_line
    procedure file_read_line(file file_name : text;
        variable file_line : out text_line
    ) is
        variable index : integer; -- index into string
        variable rline : line;

    begin

        index := 1; -- set index to begin of string
        file_line := (others => nul);
        if (not endfile(file_name)) then
            readline(file_name, rline);
            while (rline'right /= (index - 1) and rline'length /= 0) loop
                file_line(index) := rline(index);
                index := index + 1;
            end loop;
        end if;
    end procedure;


    -- procedure to break a line down in to text fields
    procedure tokenize_line(variable text_line : in text_line;
        variable otoken1 : out text_field;
        variable otoken2 : out text_field;
        variable otoken3 : out text_field;
        variable otoken4 : out text_field;
        variable otoken5 : out text_field;
        variable otoken6 : out text_field;
        variable otoken7 : out text_field;
        variable txt_ptr : out stm_text_ptr;
        variable ovalid : out integer) is

        variable token_index : integer := 0;
        variable current_token : text_field;
        variable token_number : integer := 0;
        variable c : string(1 to 2);
        variable comment_found : integer := 0;
        variable txt_found : integer := 0;
        variable j : integer;
        variable txt_ptr_tmp : stm_text_ptr;
        variable txt_str : stm_text;
        variable token1 : text_field;
        variable token2 : text_field;
        variable token3 : text_field;
        variable token4 : text_field;
        variable token5 : text_field;
        variable token6 : text_field;
        variable token7 : text_field;
        variable token8 : text_field;
        variable valid : integer := 0;
        variable token_merge : boolean;
    begin
        -- null outputs
        token1 := (others => nul);
        token2 := (others => nul);
        token3 := (others => nul);
        token4 := (others => nul);
        token5 := (others => nul);
        token6 := (others => nul);
        token7 := (others => nul);
        token8 := (others => nul);
        txt_ptr := null;
        txt_ptr_tmp := null;
        valid := 0;
        txt_found := 0;
        j := 1;
        txt_str := (others => nul);
        token_merge := false;

        -- loop for max number of char
        for i in 1 to text_line'high loop
            -- collect for comment test ** assumed no line will be max 256
            c(1) := text_line(i);
            c(2) := text_line(i + 1); -- or this line will blow up
            if (c = "--") then
                comment_found := 1;
                exit;
            end if;
            -- if is begin text char '"'
            if (txt_found = 0 and c(1) = '"') then --"
                txt_found := 1;
                txt_ptr_tmp := new stm_text;
                next;
            end if;

            -- if we have found a txt string
            if (txt_found = 1 and text_line(i) /= nul) then
                -- if string too long, prevent tool hang, truncate and notify
                if (j > c_stm_text_len) then
                    print("tokenize_line: truncated txt line, it was larger than c_stm_text_len");
                    exit;
                end if;
                -- till the very end of text_line
                if (text_line(i) /= nul) then 
                    txt_str(j) := text_line(i);
                    txt_ptr_copy(txt_ptr_tmp, txt_ptr, txt_str);
                    j := j + 1;
                else
                    exit;
                end if;

            -- if is a character store in the right token
            elsif (is_space(text_line(i)) = false and text_line(i) /= nul) then
                token_index := token_index + 1;
                current_token(token_index) := text_line(i);
            -- else is a space, deal with pointers
            elsif (is_space(text_line(i + 1)) = false and text_line(i + 1) /= nul) then
                case token_number is
                    when 0 =>
                        if (token_index /= 0) then
                            token1 := current_token;
                            current_token := (others => nul);
                            token_number := 1;
                            valid := 1;
                            token_index := 0;
                        end if;
                    when 1 =>
                        token2 := current_token;
                        current_token := (others => nul);
                        token_number := 2;
                        valid := 2;
                        token_index := 0;
                    when 2 =>
                        token3 := current_token;
                        current_token := (others => nul);
                        token_number := 3;
                        valid := 3;
                        token_index := 0;
                    when 3 =>
                        token4 := current_token;
                        current_token := (others => nul);
                        token_number := 4;
                        valid := 4;
                        token_index := 0;
                    when 4 =>
                        token5 := current_token;
                        current_token := (others => nul);
                        token_number := 5;
                        valid := 5;
                        token_index := 0;
                    when 5 =>
                        token6 := current_token;
                        current_token := (others => nul);
                        token_number := 6;
                        valid := 6;
                        token_index := 0;
                    when 6 =>
                        token7 := current_token;
                        current_token := (others => nul);
                        token_number := 7;
                        valid := 7;
                        token_index := 0;
                    when 7 =>
                        token8 := current_token;
                        current_token := (others => nul);
                        token_number := 8;
                        valid := 8;
                        token_index := 0;
                    when 8 =>
                    when others =>
                        null;
                end case;
            end if;
            -- break from loop if is null
            if (text_line(i) = nul) then
                if (token_index /= 0) then
                    case token_number is
                        when 0 =>
                            token1 := current_token;
                            valid := 1;
                        when 1 =>
                            token2 := current_token;
                            valid := 2;
                        when 2 =>
                            token3 := current_token;
                            valid := 3;
                        when 3 =>
                            token4 := current_token;
                            valid := 4;
                        when 4 =>
                            token5 := current_token;
                            valid := 5;
                        when 5 =>
                            token6 := current_token;
                            valid := 6;
                        when 6 =>
                            token7 := current_token;
                            valid := 7;
                        when 7 =>
                            token8 := current_token;
                            valid := 8;
                        when others =>
                            null;
                    end case;
                end if;
                exit;
            end if;
        end loop;
        -- did we find a comment and there is a token
        if (comment_found = 1) then
            if (token_index /= 0) then
                case token_number is
                    when 0 =>
                        token1 := current_token;
                        valid := 1;
                    when 1 =>
                        token2 := current_token;
                        valid := 2;
                    when 2 =>
                        token3 := current_token;
                        valid := 3;
                    when 3 =>
                        token4 := current_token;
                        valid := 4;
                    when 4 =>
                        token5 := current_token;
                        valid := 5;
                    when 5 =>
                        token6 := current_token;
                        valid := 6;
                    when 6 =>
                        token7 := current_token;
                        valid := 7;
                    when 7 =>
                        token8 := current_token;
                        valid := 8;
                    when others =>
                        null;
                end case;
            end if;
        end if;
        token_merge_words( token1, token2, token3, token4, token5, token6, token7, token8, valid,
            otoken1,otoken2, otoken3, otoken4, otoken5, otoken6, otoken7, ovalid );

    end procedure;


    --  add_variable
    --    this procedure adds a variable to the variable list.  this is localy
    --    available at this time.
    procedure add_variable(variable var_list : inout var_field_ptr;
        variable p1 : in text_field; -- should be var name
        variable p2 : in text_field; -- should be value
        variable token_num : in integer;
        variable sequ_num : in integer;
        variable line_num : in integer;
        variable name : in text_line;
        variable length : in integer;
        constant var_stm_type : in t_stm_var_type;
        variable str_ptr : in stm_text_ptr
    ) is
        variable temp_var : var_field_ptr;
        variable current_ptr : var_field_ptr;
        variable index : integer := 1;

        procedure init_stm_lines_var is
        begin
            temp_var := new var_field;
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_value := 0;
            temp_var.var_index := index;
            temp_var.var_stm_text := null;
            temp_var.var_stm_array := null;
            temp_var.var_stm_lines := new t_stm_lines;
            temp_var.var_stm_lines.stm_line_list := null;
            temp_var.var_stm_lines.size := 0;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

        procedure init_stm_array_var is
        begin
            assert (stim_to_integer(p2, name, line_num) > 0)
            report lf & "error: array size < 1 is not allowed on line " & (integer'image(line_num)) & " of file " & name
            severity failure;
            temp_var := new var_field;
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := 0;
            temp_var.var_stm_text := null;
            temp_var.var_stm_array := new t_stm_array(0 to stim_to_integer(p2, name, line_num)-1);
            temp_var.var_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;
        
        procedure init_stm_text_var is
        begin
            assert (stim_to_integer(p2, name, line_num) > 0)
            report lf & "error: array size < 1 is not allowed on line " & (integer'image(line_num)) & " of file " & name
            severity failure;
            temp_var := new var_field;
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := 0;
            temp_var.var_stm_text := str_ptr;
            temp_var.var_stm_array := null;
            temp_var.var_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;
        
        procedure init_non_inline_var is
        begin
            temp_var := new var_field;
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := stim_to_integer(p2, name, line_num); -- convert text_field to integer
            temp_var.var_stm_text := null;
            temp_var.var_stm_array := null;
            temp_var.var_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

        procedure init_inline_var is
        begin
            temp_var := new var_field;
            temp_var.var_name(1 to (length - 1)) := p1(1 to (length - 1));
            temp_var.var_index := index;
            temp_var.var_value := sequ_num;
            temp_var.var_stm_text := null;
            temp_var.var_stm_array := null;
            temp_var.var_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

    begin
        -- if this is not the first one
        if (var_list /= null) then
            current_ptr := var_list;
            index := index + 1;
            while (current_ptr.next_rec /= null) loop
                -- if we have defined the current before then die
                assert (current_ptr.var_name /= p1)
                report lf & "error: attemping to add a duplicate variable definition "
                & " on line " & (integer'image(line_num)) & " of file " & text_line_crop(name)
                severity failure;

                current_ptr := current_ptr.next_rec;
                index := index + 1;
            end loop;
            -- if we have defined the current before then die. this checks the last one
            assert (current_ptr.var_name /= p1)
            report lf & "error: attemping to add a duplicate variable definition "
                & " on line " & (integer'image(line_num)) & " of file " & text_line_crop(name)
            severity failure;            
                        
            if (var_stm_type = STM_LINES_TYPE) then 
                init_stm_lines_var;
                current_ptr.next_rec := temp_var;
            elsif (var_stm_type = STM_ARRAY_TYPE) then
                init_stm_array_var;
                current_ptr.next_rec := temp_var;
            elsif (var_stm_type = STM_TEXT_TYPE) then
                init_stm_text_var;
                current_ptr.next_rec := temp_var;
            elsif (var_stm_type = STM_LABEL_TYPE) then
                init_inline_var;
                current_ptr.next_rec := temp_var;
            else 
                init_non_inline_var;
                current_ptr.next_rec := temp_var;
            end if;
        -- this is the first one
        else
            if (var_stm_type = STM_LINES_TYPE) then 
                init_stm_lines_var;
            elsif (var_stm_type = STM_ARRAY_TYPE) then
                init_stm_array_var;
            elsif (var_stm_type = STM_TEXT_TYPE) then
                init_stm_text_var;
            elsif (var_stm_type = STM_LABEL_TYPE) then
                init_inline_var;
            else
                init_non_inline_var;
            end if;
            var_list := temp_var;
        end if;
    end procedure;


    --  add_instruction
    --    this is the procedure that adds the instruction to the linked list of
    --    instructions.  also variable addition are called and or handled.
    --    the instruction sequence link list.
    --     inputs:
    --               stim_line_ptr   is the pointer to the instruction list
    --               inst            is the instruction token
    --               p1              paramitor one, corrisponds to field one of stimulus
    --               p2              paramitor one, corrisponds to field two of stimulus
    --               p3              paramitor one, corrisponds to field three of stimulus
    --               p4              paramitor one, corrisponds to field four of stimulus
    --               p5              paramitor one, corrisponds to field three of stimulus
    --               p6              paramitor one, corrisponds to field four of stimulus
    --               str_ptr         pointer to string for print instruction
    --               token_num       the number of tokens, including instruction
    --               sequ_num        is the stimulus file line referance  ie program line number
    --               line_num        line number in the text file
    --     outputs:
    --               none.  error will terminate sim
    procedure add_instruction(variable inst_list : inout stim_line_ptr;
        variable var_list : inout var_field_ptr;
        variable inst : in text_field;
        variable p1 : in text_field;
        variable p2 : in text_field;
        variable p3 : in text_field;
        variable p4 : in text_field;
        variable p5 : in text_field;
        variable p6 : in text_field;
        variable str_ptr : in stm_text_ptr;
        variable token_num : in integer;
        variable sequ_num : inout integer;
        variable line_num : in integer;
        variable file_name : in text_line;
        variable file_idx : in integer) is
        
        variable temp_stim_line : stim_line_ptr;
        variable temp_current : stim_line_ptr;
        variable valid : integer;
        variable l : integer;
        variable stm_var_type : t_stm_var_type := NO_VAR_TYPE;
    begin
        valid := 1;
        l := fld_len(inst);
        temp_current := inst_list;
        
        -- take care of special cases
        if (inst(1 to l) = INSTR_VAR) then
            stm_var_type := STM_VALUE_TYPE;
        elsif (inst(1 to l) = INSTR_CONST) then
            stm_var_type := STM_CONST_VALUE_TYPE;
        elsif (inst(1 to l) = INSTR_ARRAY) then
            stm_var_type := STM_ARRAY_TYPE;
        elsif (inst(1 to l) = INSTR_LINES) then
            stm_var_type := STM_LINES_TYPE;
        elsif (inst(1 to l) = INSTR_FILE) then
            stm_var_type := STM_TEXT_TYPE;
        elsif (inst(1 to l) = INSTR_BUS) then
            stm_var_type := STM_BUS_TYPE;
        elsif (inst(1 to l) = INSTR_SIGNAL) then
            stm_var_type := STM_SIGNAL_TYPE;
        elsif (inst(l) = ':') then
            stm_var_type := STM_LABEL_TYPE;
        end if;
        
        if stm_var_type /= NO_VAR_TYPE then
            --  add the variable to the variable pool, not considered an instruction
            if stm_var_type /= STM_LABEL_TYPE then
                l := fld_len(p1);
                add_variable(var_list, p1, p2, token_num, sequ_num, line_num, file_name, l, stm_var_type, str_ptr);
            else     
            	add_variable(var_list, inst, p1, token_num, sequ_num, line_num, file_name, l, stm_var_type, str_ptr);
            end if;
            valid := 0; --removes this from the instruction list
        end if;
         
        if (valid = 1) then
            -- prepare the new record
            temp_stim_line := new stim_line;
            temp_stim_line.instruction := inst;
            temp_stim_line.inst_field_1 := p1;
            temp_stim_line.inst_field_2 := p2;
            temp_stim_line.inst_field_3 := p3;
            temp_stim_line.inst_field_4 := p4;
            temp_stim_line.inst_field_5 := p5;
            temp_stim_line.inst_field_6 := p6;
            temp_stim_line.txt := str_ptr;
            temp_stim_line.line_number := sequ_num;
            temp_stim_line.file_idx := file_idx;
            temp_stim_line.file_line := line_num;
            -- if is not the first instruction
            if (inst_list /= null) then
                while (temp_current.next_rec /= null) loop
                    temp_current := temp_current.next_rec;
                end loop;
                temp_current.next_rec := temp_stim_line;
                inst_list.num_of_lines := inst_list.num_of_lines + 1;
            -- other wise is first instruction to be added
            else
                inst_list := temp_stim_line;
                inst_list.num_of_lines := 1;
            end if;
            sequ_num := sequ_num + 1;
            -- print_inst(temp_stim_line);  -- for debug
        end if;
    end procedure;


    -- test_inst_sequ
    --  this procedure accesses the full instruction sequence and checks for valid
    --   variables.  this is prior to the simulation run start.
    procedure test_inst_sequ(variable inst_sequ : in stim_line_ptr;
        variable file_list : in file_def_ptr;
        variable var_list : in var_field_ptr) is
        variable temp_text_field : text_field;
        variable inst_ptr : stim_line_ptr;
        variable valid : integer;
        variable line : integer; -- value of the file_line
        variable file_name : text_line;
        variable v_p : integer;
        variable inst : text_field;
        variable txt : stm_text_ptr;
        variable inst_len : integer;
        variable fname : text_line;
        variable file_line : integer;
        variable temp_fn_prt : file_def_ptr;
        variable tmp_int : integer;
        -- variable value:     integer := 1;
        -- variable temp_str : string(1 to 48);
    begin
        inst_ptr := inst_sequ;
        -- go through all the instructions
        while (inst_ptr.next_rec /= null) loop
            inst := inst_ptr.instruction;
            inst_len := fld_len(inst_ptr.instruction);
            file_line := inst_ptr.file_line;
            line := inst_ptr.file_line;
            -- recover the file name this line came from
            temp_fn_prt := file_list;
            tmp_int := inst_ptr.file_idx;
            while (temp_fn_prt.next_rec /= null) loop
                if (temp_fn_prt.rec_idx = tmp_int) then
                    exit;
                end if;
                temp_fn_prt := temp_fn_prt.next_rec;
            end loop;
            for i in 1 to fname'high loop
                file_name(i) := temp_fn_prt.file_name(i);
            end loop;

            txt := inst_ptr.txt;
            -- load parameter one
            temp_text_field := inst_ptr.inst_field_1;

            if (temp_text_field(1) /= nul) then
                -- if this is a numaric  do nothing
                if ((temp_text_field(1) = '#' and (temp_text_field(2) = 'x' or temp_text_field(2) = 'b'))
                    or is_digit(temp_text_field(1)) = true) then
                    null;
                else -- else is a variable, get the value or halt incase of error
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert (valid = 1)
                    report lf & "error: first variable on stimulus line " & (integer'image(line))
                      & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            -- load parameter two
            temp_text_field := inst_ptr.inst_field_2;
            if (temp_text_field(1) /= nul) then
                -- if this is a numaric do nothing
                if ((temp_text_field(1) = '#' and (temp_text_field(2) = 'x' or temp_text_field(2) = 'b'))
                    or is_digit(temp_text_field(1)) = true) then
                    null;
                else -- else is a variable, get the value or halt incase of error
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert (valid = 1)
                    report lf & "error: second variable on stimulus line " & (integer'image(line))
                      & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            -- load parameter three
            temp_text_field := inst_ptr.inst_field_3;
            if (temp_text_field(1) /= nul) then
                -- if this is a numaric do nothing
                if ((temp_text_field(1) = '#' and (temp_text_field(2) = 'x' or temp_text_field(2) = 'b'))
                    or is_digit(temp_text_field(1)) = true) then
                    null;
                else -- else is a variable, get the value or halt incase of error
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert (valid = 1)
                    report lf & "error: third variable on stimulus line " & (integer'image(line))
                      & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            -- load parameter four
            temp_text_field := inst_ptr.inst_field_4;
            if (temp_text_field(1) /= nul) then
                -- if this is a numaric do nothing
                if ((temp_text_field(1) = '#' and (temp_text_field(2) = 'x' or temp_text_field(2) = 'b'))
                    or is_digit(temp_text_field(1)) = true) then
                    null;
                else -- else is a variable, get the value or halt incase of error
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert (valid = 1)
                    report lf & "error: forth variable on stimulus line " & (integer'image(line))
                      & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            -- load parameter five
            temp_text_field := inst_ptr.inst_field_5;
            if (temp_text_field(1) /= nul) then
                -- if this is a numaric do nothing
                if ((temp_text_field(1) = '#' and (temp_text_field(2) = 'x' or temp_text_field(2) = 'b'))
                    or is_digit(temp_text_field(1)) = true) then
                    null;
                else -- else is a variable, get the value or halt incase of error
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert (valid = 1)
                    report lf & "error: fifth variable on stimulus line " & (integer'image(line))
                      & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            -- load parameter six
            temp_text_field := inst_ptr.inst_field_6;
            if (temp_text_field(1) /= nul) then
                -- if this is a numaric field convert to integer
                if ((temp_text_field(1) = '#' and (temp_text_field(2) = 'x' or temp_text_field(2) = 'b'))
                    or is_digit(temp_text_field(1)) = true) then
                    null;
                else -- else is a variable, get the value or halt incase of error
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert (valid = 1)
                    report lf & "error: sixth variable on stimulus line " & (integer'image(line))
                      & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            -- point to next record
            inst_ptr := inst_ptr.next_rec;
        end loop;
    end procedure;


    --  the read include file procedure
    --    this is the main procedure for reading, parcing, checking and returning
    --    the instruction sequence link list.
    procedure read_include_file(variable name : text_line;
        variable sequ_numb : inout integer;
        variable file_list : inout file_def_ptr;
        variable inst_set : inout inst_def_ptr;
        variable var_list : inout var_field_ptr;
        variable inst_sequ : inout stim_line_ptr;
        variable status : inout integer) is
        variable l : text_line; -- the line
        variable l_num : integer; -- line number file
        variable sequ_line : integer; -- line number program
        variable t1 : text_field;
        variable t2 : text_field;
        variable t3 : text_field;
        variable t4 : text_field;
        variable t5 : text_field;
        variable t6 : text_field;
        variable t7 : text_field;
        variable t_txt : stm_text_ptr;
        variable valid : integer;
        variable v_inst_ptr : inst_def_ptr;
        variable v_var_prt : var_field_ptr;
        variable v_sequ_ptr : stim_line_ptr;
        variable v_len : integer;
        variable v_stat : file_open_status;
        variable idx : integer;
        variable v_tmp : text_line;

        variable v_tmp_fn_ptr : file_def_ptr;
        variable v_new_fn : integer;
        variable v_tmp_fn : file_def_ptr;

    begin
        sequ_line := sequ_numb;
        v_tmp_fn_ptr := file_list;
        -- for linux systems, trailing spaces need to be removed
        --    from file names
        --  copy text string to temp
        for i in 1 to c_stm_text_len loop
            if (name(i) = nul) then
                v_tmp(i) := name(i);
                exit;
            else
                v_tmp(i) := name(i);
            end if;
        end loop;
        --fix up any trailing white space in txt
        idx := 0;
        --    get to the end of the string
        for i in 1 to c_stm_text_len loop
            if (v_tmp(i) /= nul) then
                idx := idx + 1;
            else
                exit;
            end if;
        end loop;
        --  now nul out spaces
        for i in idx downto 1 loop
            if (is_space(v_tmp(i)) = true) then
                v_tmp(i) := nul;
            else
                exit;
            end if;
        end loop;
        --  open include file
        file_open(v_stat, include_file, v_tmp, read_mode);
        if (v_stat /= open_ok) then
            print("error: unable to open include file  " & name);
            status := 1;
            return;
        end if;
        l_num := 1; -- initialize line number

        --  the file is opened, put it on the file name ll
        while (v_tmp_fn_ptr.next_rec /= null) loop
            v_tmp_fn_ptr := v_tmp_fn_ptr.next_rec;
        end loop;
        v_new_fn := v_tmp_fn_ptr.rec_idx + 1;
        v_tmp_fn := new file_def;
        v_tmp_fn_ptr.next_rec := v_tmp_fn;
        v_tmp_fn.rec_idx := v_new_fn;

        --  nul the text line
        v_tmp_fn.file_name := (others => nul);
        for i in 1 to name'high loop
            v_tmp_fn.file_name(i) := name(i);
        end loop;
        v_tmp_fn.next_rec := null;


        v_inst_ptr := inst_set;
        v_var_prt := var_list;
        v_sequ_ptr := inst_sequ;

        -- while not the end of file read it
        while (not endfile(include_file)) loop
            file_read_line(include_file, l);
            --  tokenize the line
            tokenize_line(l, t1, t2, t3, t4, t5, t6, t7, t_txt, valid);
            v_len := fld_len(t1);
            if (t1(1 to v_len) = "include") then
                print("nested include statement found in " & v_tmp & " on line " &
                    (integer'image(l_num)));
                assert (false)
                report lf & "error: nested include statements are not supported at this time."
                severity failure;

            -- if there was valid tokens
            elsif (valid /= 0) then
                check_valid_inst(t1, v_inst_ptr, valid, l_num, name);
                add_instruction(v_sequ_ptr, v_var_prt, t1, t2, t3, t4, t5, t6, t7, t_txt, valid,
                    sequ_line, l_num, name, v_new_fn);
            end if;
            l_num := l_num + 1;
        end loop; -- end loop read file
        file_close(include_file);
        sequ_numb := sequ_line;
        inst_set := v_inst_ptr;
        var_list := v_var_prt;
        inst_sequ := v_sequ_ptr;
    end procedure;


    --  the read instruction file procedure
    --    this is the main procedure for reading, parcing, checking and returning
    --    the instruction sequence link list.
    procedure read_instruction_file(constant path_name : string;
        constant file_name : string;
        variable inst_set : inout inst_def_ptr;
        variable var_list : inout var_field_ptr;
        variable inst_sequ : inout stim_line_ptr;
        variable file_list : inout file_def_ptr) is
        
        variable l : text_line; -- the line
        variable l_num : integer; -- line number file
        variable sequ_line : integer; -- line number program
        variable t1 : text_field;
        variable t2 : text_field;
        variable t3 : text_field;
        variable t4 : text_field;
        variable t5 : text_field;
        variable t6 : text_field;
        variable t7 : text_field;
        variable t_txt : stm_text_ptr;
        variable valid : integer;
        variable v_ostat : integer;
        variable v_inst_ptr : inst_def_ptr;
        variable v_var_prt : var_field_ptr;
        variable v_sequ_ptr : stim_line_ptr;
        variable v_len : integer;
        variable v_stat : file_open_status;
        variable v_name : text_line;
        variable v_iname : text_line;
        variable v_tmp_fn : file_def_ptr;
        variable v_fn_idx : integer;
        variable v_idx : integer;
        variable path_v_iname : text_line;
    begin
        -- open the stimulus_file and check
        file_open(v_stat, stimulus, path_name & file_name, read_mode);
        assert (v_stat = open_ok)
        report lf & "error: unable to open stimulus_file  " & path_name & file_name
        severity failure;
        -- copy file name to type text_line
        for i in 1 to path_name'high loop
            v_name(i) := path_name(i);
        end loop;
        for i in 1 to file_name'high loop
            v_name(i + path_name'high) := file_name(i);
        end loop;
        -- the first item on the file names link list
        file_list := null;
        v_tmp_fn := new file_def;
        v_tmp_fn.rec_idx := 1;
        v_fn_idx := 1;
        v_idx := 1;
        --  nul the text line
        v_tmp_fn.file_name := (others => nul);
        for i in 1 to path_name'high loop
            v_tmp_fn.file_name(i) := path_name(i);
        end loop;
        for i in 1 to file_name'high loop
            v_tmp_fn.file_name(i + path_name'high) := file_name(i);
        end loop;
        v_tmp_fn.next_rec := null;

        l_num := 1;
        sequ_line := 1;
        v_ostat := 0;

        v_inst_ptr := inst_set;
        v_var_prt := var_list;
        v_sequ_ptr := inst_sequ;

        -- while not the end of file read it
        while (not endfile(stimulus)) loop
            file_read_line(stimulus, l);
            --  tokenize the line
            tokenize_line(l, t1, t2, t3, t4, t5, t6, t7, t_txt, valid);

            v_len := fld_len(t1);
            -- if there is an include instruction
            if (t1(1 to v_len) = "include") then
                -- if file name is in par2
                if (valid = 2) then
                    v_iname := (others => nul);
                    for i in 1 to max_field_len loop
                        v_iname(i) := t2(i);
                    end loop;
                -- elsif the text string is not null
                elsif (t_txt /= null) then
                    v_iname := (others => nul);
                    for i in 1 to c_stm_text_len loop
                        v_iname(i) := t_txt(i);
                        if (t_txt(i) = nul) then
                            exit;
                        end if;
                    end loop;
                else
                    assert (false)
                    report lf & "error:  include instruction has not file name included.  found on" & lf &
                        "line " & (integer'image(l_num)) & " in file " & path_name & file_name & lf
                    severity failure;
                end if;
                -- copy include file name to type text_line
                for i in 1 to path_name'high loop

                    path_v_iname(i) := path_name(i);

                end loop;
                for i in 1 to max_str_len - path_name'high loop
                    path_v_iname(i + path_name'high) := v_iname(i);
                end loop;
                print("include found: loading file " & path_v_iname);
                read_include_file(path_v_iname, sequ_line, v_tmp_fn, v_inst_ptr, v_var_prt, v_sequ_ptr, v_ostat);
                -- if include file not found
                if (v_ostat = 1) then
                    exit;
                end if;
            -- if there was valid tokens
            elsif (valid /= 0) then
                check_valid_inst(t1, v_inst_ptr, valid, l_num, v_name);
                add_instruction(v_sequ_ptr, v_var_prt, t1, t2, t3, t4, t5, t6, t7, t_txt, valid,
                    sequ_line, l_num, v_name, v_fn_idx);
            end if;
            l_num := l_num + 1;
        end loop; -- end loop read file

        file_close(stimulus); -- close the file when done

        assert (v_ostat = 0)
        report lf & "include file specified on line " & (integer'image(l_num)) &
                  " in file " & path_name & file_name &
                  " was not found! test terminated" & lf
        severity failure;

        inst_set := v_inst_ptr;
        var_list := v_var_prt;
        inst_sequ := v_sequ_ptr;
        file_list := v_tmp_fn;

        --  now that all the stimulus is loaded, test for invalid variables
        test_inst_sequ(inst_sequ, v_tmp_fn, var_list);
    end procedure;


    -- access_inst_sequ
    --  this procedure accesses the instruction sequence and returns the parameters
    --  as they exsist related to the variables state.
    --  inputs:   inst_sequ  link list of instructions from stimulus
    --            var_list   link list of variables
    --            file_list  link list of file names
    --            sequ_num   the sequence number to recover
    --
    --  outputs:  inst  instruction text
    --            p1    paramiter 1 in integer form
    --            p2    paramiter 2 in integer form
    --            p3    paramiter 3 in integer form
    --            p4    paramiter 4 in integer form
    --            p5    paramiter 5 in integer form
    --            p6    paramiter 6 in integer form
    --            txt   pointer to any text string of this sequence
    --            inst_len  the lenth of inst in characters
    --            fname  file name this sequence came from
    --            file_line  the line number in fname this sequence came from
    --
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
        variable last_ptr : inout stim_line_ptr) is
        
        variable temp_text_field : text_field;
        variable inst_ptr : stim_line_ptr;
        variable valid : integer;
        variable line : integer; -- value of the file_line
        variable file_name : text_line;
        variable tmp_int : integer;
        variable temp_fn_prt : file_def_ptr;
    begin
        -- get to the instruction indicated by sequ_num
        -- check to see if this sequence is before the last
        --    so search from start
        if (last_num > sequ_num) then
            inst_ptr := inst_sequ;
            while (inst_ptr.next_rec /= null) loop
                if (inst_ptr.line_number = sequ_num) then
                    exit;
                else
                    inst_ptr := inst_ptr.next_rec;
                end if;
            end loop;
        -- else is equal or greater, so search forward
        else
            inst_ptr := last_ptr;
            while (inst_ptr.next_rec /= null) loop
                if (inst_ptr.line_number = sequ_num) then
                    exit;
                else
                    inst_ptr := inst_ptr.next_rec;
                end if;
            end loop;
        end if;

        -- update the last sequence number and record pointer
        last_num := sequ_num;
        last_ptr := inst_ptr;

        -- output the instruction and its length
        inst := inst_ptr.instruction;
        inst_len := fld_len(inst_ptr.instruction);
        file_line := inst_ptr.file_line;
        line := inst_ptr.file_line;
        -- recover the file name this line came from
        temp_fn_prt := file_list;
        tmp_int := inst_ptr.file_idx;
        while (temp_fn_prt.next_rec /= null) loop
            if (temp_fn_prt.rec_idx = tmp_int) then
                exit;
            end if;
            temp_fn_prt := temp_fn_prt.next_rec;
        end loop;
        for i in 1 to fname'high loop
            file_name(i) := temp_fn_prt.file_name(i);
            fname(i) := temp_fn_prt.file_name(i);
        end loop;

        --  print ("access_inst_sequ" & file_name);

        txt := inst_ptr.txt;
        -- load parameter one
        temp_text_field := inst_ptr.inst_field_1;
        if (temp_text_field(1) /= nul) then
            -- if this is a numaric field convert to integer
            if (temp_text_field(1) = '#') then
                p1 := stim_to_integer(temp_text_field, file_name, line);
            elsif (is_digit(temp_text_field(1)) = true) then
                p1 := stim_to_integer(temp_text_field, file_name, line);
            else -- else is a variable, get the value or halt incase of error
                access_variable(var_list, temp_text_field, p1, valid);
                assert (valid = 1)
                report lf & "error: first variable on stimulus line " & (integer'image(line))
                    & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        -- load parameter two
        temp_text_field := inst_ptr.inst_field_2;
        if (temp_text_field(1) /= nul) then
            -- if this is a numaric field convert to integer
            if (temp_text_field(1) = '#') then
                p2 := stim_to_integer(temp_text_field, file_name, line);
            elsif (is_digit(temp_text_field(1)) = true) then
                p2 := stim_to_integer(temp_text_field, file_name, line);
            else -- else is a variable, get the value or halt incase of error
                access_variable(var_list, temp_text_field, p2, valid);
                assert (valid = 1)
                report lf & "error: second variable on stimulus line " & (integer'image(line))
                    & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        -- load parameter three
        temp_text_field := inst_ptr.inst_field_3;
        if (temp_text_field(1) /= nul) then
            -- if this is a numaric field convert to integer
            if (temp_text_field(1) = '#') then
                p3 := stim_to_integer(temp_text_field, file_name, line);
            elsif (is_digit(temp_text_field(1)) = true) then
                p3 := stim_to_integer(temp_text_field, file_name, line);
            else -- else is a variable, get the value or halt incase of error
                access_variable(var_list, temp_text_field, p3, valid);
                assert (valid = 1)
                report lf & "error: third variable on stimulus line " & (integer'image(line))
                    & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        -- load parameter four
        temp_text_field := inst_ptr.inst_field_4;
        if (temp_text_field(1) /= nul) then
            -- if this is a numaric field convert to integer
            if (temp_text_field(1) = '#') then
                p4 := stim_to_integer(temp_text_field, file_name, line);
            elsif (is_digit(temp_text_field(1)) = true) then
                p4 := stim_to_integer(temp_text_field, file_name, line);
            else -- else is a variable, get the value or halt incase of error
                access_variable(var_list, temp_text_field, p4, valid);
                assert (valid = 1)
                report lf & "error: forth variable on stimulus line " & (integer'image(line))
                    & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        -- load parameter five
        temp_text_field := inst_ptr.inst_field_5;
        if (temp_text_field(1) /= nul) then
            -- if this is a numaric field convert to integer
            if (temp_text_field(1) = '#') then
                p5 := stim_to_integer(temp_text_field, file_name, line);
            elsif (is_digit(temp_text_field(1)) = true) then
                p5 := stim_to_integer(temp_text_field, file_name, line);
            else -- else is a variable, get the value or halt incase of error
                access_variable(var_list, temp_text_field, p5, valid);
                assert (valid = 1)
                report lf & "error: fifth variable on stimulus line " & (integer'image(line))
                    & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        -- load parameter six
        temp_text_field := inst_ptr.inst_field_6;
        if (temp_text_field(1) /= nul) then
            -- if this is a numaric field convert to integer
            if (temp_text_field(1) = '#') then
                p6 := stim_to_integer(temp_text_field, file_name, line);
            elsif (is_digit(temp_text_field(1)) = true) then
                p6 := stim_to_integer(temp_text_field, file_name, line);
            else -- else is a variable, get the value or halt incase of error
                access_variable(var_list, temp_text_field, p6, valid);
                assert (valid = 1)
                report lf & "error: sixth variable on stimulus line " & (integer'image(line))
                    & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
    end procedure;

    --  procedure to print to the stdout the txt pointer, and
    --  sub any variables found
    procedure txt_print_wvar(variable var_list : in var_field_ptr;
        variable ptr : in stm_text_ptr;
        constant b : in base) is
        
        variable src_i : integer;
        variable src_tail_i : integer;
        variable dest_i : integer;
        variable k : integer;
        variable dest_txt_str : stm_text;
        variable post_i : integer;
        variable post_j : integer;
        variable post_k : integer;
        variable v1 : integer;
        variable valid : integer;
        variable tmp_field : text_field;
        variable tmp_i : integer;
    begin
        if ptr = null then
            return;
        end if;
        
        -- determine variables tail_start in src string
        src_i := 1;
        src_tail_i := 0;
        dest_txt_str := (others => nul);
        while src_i <= c_stm_text_len loop
            if j = 0 then
                if ptr(src_i) = '"' then
                   src_tail_i := src_i + 1; 
                   exit;
                end if;
            else
                src_i := src_i + 1;
            end if;
        end loop;
        
        
        src_i := 1;
        dest_i := 1;
        while src_i < src_tail_i and dest_i <= c_stm_text_len loop
        
      
            -- copy until next '{'
            dest_txt_str := (others => nul);
            while src_i <= c_stm_text_len and dest_i <= c_stm_text_len loop
                if ptr(i) = '{' then
                    i := i + 1;
                    exit;
                else
                    dest_txt_str(dest_i) := ptr(i);
                    i := i + 1;
                    dest_i := dest_i + 1;
                end if;
            end loop;
    
            while i <= c_stm_text_len and dest_j <= c_stm_text_len loop
                if ptr(i) = '}' then
                    i := i + 1;
                    exit;
                else
                    -- skip until next '}'
                    i := i + 1;
                end if;
            end loop;
                    
                
                
    
            i := 1;
            j := 1;
            dest_txt_str := (others => nul);
            while i <= c_stm_text_len and j <= c_stm_text_len loop
                if (ptr(i) /= '}') then
                    dest_txt_str(j) := ptr(i);
                    i := i + 1;
                    j := j + 1;
                else
                    tmp_field := (others => nul);
                    tmp_i := 1;
                    tmp_field(tmp_i) := ptr(i);
                    i := i + 1;
                    tmp_i := tmp_i + 1;
                    -- parse to the next space
                    while ptr(i) /= ' ' and ptr(i) /= nul loop
                        tmp_field(tmp_i) := ptr(i);
                        i := i + 1;
                        tmp_i := tmp_i + 1;
                    end loop;
                    access_variable(var_list, tmp_field, v1, valid);
                    assert (valid = 1)
                    report lf & "invalid variable found in stm_text_ptr: ignoring."
                    severity warning;
    
                    if valid = 1 then
    
                        dest_txt_str := ew_str_cat(dest_txt_str, ew_to_str_len(v1, b));
                        k := 1;
                        while dest_txt_str(k) /= nul loop
                            k := k + 1;
                        end loop;
                        j := k;
                    end if;
                end if;
            end loop;            
        end loop;
        -- print the created string
        print(dest_txt_str);

    end procedure;


end package body;
