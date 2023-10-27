library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_base_pkg.all;

package tb_instructions_pkg is

        -- basic
        constant INSTR_ABORT : string := "abort";
        constant INSTR_CONST : string := "const";
        constant INSTR_ELSE : string := "else";
        constant INSTR_ELSIF : string := "elsif";
        constant INSTR_END_IF : string := "end_if";
        constant INSTR_END_LOOP : string := "end_loop";
        constant INSTR_FINISH : string := "finish";
        constant INSTR_IF : string := "if";
        constant INSTR_INCLUDE : string := "include";
        constant INSTR_LOOP : string := "loop";
        constant INSTR_VAR : string := "var";

        -- variables
        constant INSTR_ADD : string := "add";
        constant INSTR_AND : string := "and";
        constant INSTR_DIV : string := "div";
        constant INSTR_EQU : string := "equ";
        constant INSTR_MUL : string := "mul";
        constant INSTR_SHL : string := "shl";
        constant INSTR_SHR : string := "shr";
        constant INSTR_INV : string := "inv";
        constant INSTR_OR : string := "or";
        constant INSTR_SUB : string := "sub";
        constant INSTR_XOR : string := "xor";
        constant INSTR_LD : string := "ld";

        -- signals
        constant INSTR_SIGNAL : string := "signal";
        constant INSTR_SIGNAL_READ : string := "signal_read";
        constant INSTR_SIGNAL_VERIFY : string := "signal_verify";
        constant INSTR_SIGNAL_WRITE : string := "signal_write";

        -- bus
        constant INSTR_BUS : string := "bus";
        constant INSTR_BUS_READ : string := "bus_read";
        constant INSTR_BUS_VERIFY : string := "bus_verify";
        constant INSTR_BUS_WRITE : string := "bus_write";
        constant INSTR_BUS_TIMEOUT : string := "bus_timeout";

        -- file
        constant INSTR_FILE : string := "file";
        constant INSTR_FILE_READ : string := "file_read";
        constant INSTR_FILE_WRITE : string := "file_write";
        constant INSTR_FILE_APPEND : string := "file_append";

        -- lines
        constant INSTR_LINES : string := "lines";
        constant INSTR_LINES_GET_ARRAY : string := "lines_get_array";
        constant INSTR_LINES_SET_ARRAY : string := "lines_set_array";
        constant INSTR_LINES_SET_MESSAGE : string := "lines_set_array_message";
        constant INSTR_LINES_DELETE : string := "lines_delete";
        constant INSTR_LINES_INSERT_ARRAY : string := "lines_insert_array";
        constant INSTR_LINES_INSERT_MESSAGE : string := "lines_insert_message";
        constant INSTR_LINES_APPEND_ARRAY : string := "lines_append_array";
        constant INSTR_LINES_APPEND_MESSAGE : string := "lines_append_message";
        constant INSTR_LINES_SIZE : string := "lines_size";
        constant INSTR_LINES_POINTER_COPY : string := "lines_pointer_copy";

        -- array
        constant INSTR_ARRAY : string := "array";
        constant INSTR_ARRAY_GET : string := "array_get";
        constant INSTR_ARRAY_SET : string := "array_set";
        constant INSTR_ARRAY_SIZE : string := "array_size";
        constant INSTR_ARRAY_POINTER_COPY : string := "array_pointer_copy";

        -- others
        constant INSTR_PROC : string := "proc";
        constant INSTR_CALL : string := "call";
        constant INSTR_INTERRUPT : string := "interrupt";
        constant INSTR_END_PROC : string := "end_proc";
        constant INSTR_END_INTERRUPT : string := "end_interrupt";
        constant INSTR_RANDOM : string := "random";
        constant INSTR_LOG_MESSAGE : string := "log_message";
        constant INSTR_LOG_LINES : string := "log_lines";
        constant INSTR_RETURN : string := "return";
        constant INSTR_RESUME : string := "resume";
        constant INSTR_MARKER : string := "marker";
        constant INSTR_VERBOSITY : string := "verbosity";
        constant INSTR_SEED : string := "seed";
        constant INSTR_TRACE : string := "trace";
        constant INSTR_WAIT : string := "wait";



    procedure define_instructions(variable inst_list : inout inst_def_ptr);

    procedure token_merge_words( variable token1 : in text_field;
        variable token2 : in text_field;
        variable token3 : in text_field;
        variable token4 : in text_field;
        variable token5 : in text_field;
        variable token6 : in text_field;
        variable token7 : in text_field;
        variable token8 : in text_field;
        variable token9 : in text_field;
        variable valid : in integer;
        variable otoken1 : out text_field;
        variable otoken2 : out text_field;
        variable otoken3 : out text_field;
        variable otoken4 : out text_field;
        variable otoken5 : out text_field;
        variable otoken6 : out text_field;
        variable otoken7 : out text_field;
        variable ovalid : out integer);

    -- define_instruction
    --    inputs     file_name  the file to be read from
    --
    --    output     file_line  a line of text from the file
    procedure define_instruction(variable inst_set : inout inst_def_ptr;
        constant inst : in string;
        constant args : in integer);

    --  check for valid instruction in the list of instructions
    procedure check_valid_inst(variable inst : in text_field;
        variable inst_set : in inst_def_ptr;
        variable token_num : in integer;
        variable line_num : in integer;
        variable name : in text_line);

end package;



package body tb_instructions_pkg is

    procedure define_instructions(variable inst_list : inout inst_def_ptr) is
    begin
        -- basic
        define_instruction(inst_list, INSTR_ABORT, 0);
        define_instruction(inst_list, INSTR_CONST, 2);
        define_instruction(inst_list, INSTR_ELSE, 0);
        define_instruction(inst_list, INSTR_ELSIF, 3);
        define_instruction(inst_list, INSTR_END_IF, 0);
        define_instruction(inst_list, INSTR_END_LOOP, 0);
        define_instruction(inst_list, INSTR_FINISH, 0);
        define_instruction(inst_list, INSTR_IF, 3);
        define_instruction(inst_list, INSTR_INCLUDE, 1);
        define_instruction(inst_list, INSTR_LOOP, 1);
        define_instruction(inst_list, INSTR_VAR, 2);
        -- variable
        define_instruction(inst_list, INSTR_ADD, 2);
        define_instruction(inst_list, INSTR_AND, 2);
        define_instruction(inst_list, INSTR_DIV, 2);
        define_instruction(inst_list, INSTR_EQU, 2);
        define_instruction(inst_list, INSTR_MUL, 2);
        define_instruction(inst_list, INSTR_SHL, 2);
        define_instruction(inst_list, INSTR_SHR, 2);
        define_instruction(inst_list, INSTR_INV, 1);
        define_instruction(inst_list, INSTR_OR, 2);
        define_instruction(inst_list, INSTR_SUB, 2);
        define_instruction(inst_list, INSTR_XOR, 2);
        define_instruction(inst_list, INSTR_LD, 1);
        -- signal
        define_instruction(inst_list, INSTR_SIGNAL, 2);
        define_instruction(inst_list, INSTR_SIGNAL_READ, 2);
        define_instruction(inst_list, INSTR_SIGNAL_VERIFY, 4);
        define_instruction(inst_list, INSTR_SIGNAL_WRITE, 2);
        -- bus
        define_instruction(inst_list, INSTR_BUS, 2);
        define_instruction(inst_list, INSTR_BUS_READ, 4);
        define_instruction(inst_list, INSTR_BUS_VERIFY, 6);
        define_instruction(inst_list, INSTR_BUS_WRITE, 4);
        define_instruction(inst_list, INSTR_BUS_TIMEOUT, 2);
        -- file
        define_instruction(inst_list, INSTR_FILE, 1);
        define_instruction(inst_list, INSTR_FILE_READ, 2);
        define_instruction(inst_list, INSTR_FILE_WRITE, 2);
        define_instruction(inst_list, INSTR_FILE_APPEND, 2);
        -- lines
        define_instruction(inst_list, INSTR_LINES, 1);
        define_instruction(inst_list, INSTR_LINES_GET_ARRAY, 3);
        define_instruction(inst_list, INSTR_LINES_SET_ARRAY, 3);
        define_instruction(inst_list, INSTR_LINES_SET_MESSAGE, 2);
        define_instruction(inst_list, INSTR_LINES_DELETE, 2);
        define_instruction(inst_list, INSTR_LINES_INSERT_ARRAY, 3);
        define_instruction(inst_list, INSTR_LINES_INSERT_MESSAGE, 2);
        define_instruction(inst_list, INSTR_LINES_APPEND_ARRAY, 2);
        define_instruction(inst_list, INSTR_LINES_APPEND_MESSAGE, 1);
        define_instruction(inst_list, INSTR_LINES_SIZE, 2);
        define_instruction(inst_list, INSTR_LINES_POINTER_COPY, 2);
        -- array
        define_instruction(inst_list, INSTR_ARRAY, 2);
        define_instruction(inst_list, INSTR_ARRAY_GET, 3);
        define_instruction(inst_list, INSTR_ARRAY_SET, 3);
        define_instruction(inst_list, INSTR_ARRAY_SIZE, 2);
        define_instruction(inst_list, INSTR_ARRAY_POINTER_COPY, 2);
        -- others
        define_instruction(inst_list, INSTR_PROC, 0);
        define_instruction(inst_list, INSTR_CALL, 1);
        define_instruction(inst_list, INSTR_INTERRUPT, 0);
        define_instruction(inst_list, INSTR_END_PROC, 0);
        define_instruction(inst_list, INSTR_END_INTERRUPT, 0);
        define_instruction(inst_list, INSTR_RANDOM, 3);
        define_instruction(inst_list, INSTR_LOG_MESSAGE, 1);
        define_instruction(inst_list, INSTR_LOG_LINES, 2);
        define_instruction(inst_list, INSTR_RETURN, 0);
        define_instruction(inst_list, INSTR_RESUME, 1);
        define_instruction(inst_list, INSTR_MARKER, 2);
        define_instruction(inst_list, INSTR_VERBOSITY, 1);
        define_instruction(inst_list, INSTR_SEED, 1);
        define_instruction(inst_list, INSTR_TRACE, 1);
        define_instruction(inst_list, INSTR_WAIT, 1);
    end procedure;


    procedure token_merge_words( variable token1 : in text_field;
        variable token2 : in text_field;
        variable token3 : in text_field;
        variable token4 : in text_field;
        variable token5 : in text_field;
        variable token6 : in text_field;
        variable token7 : in text_field;
        variable token8 : in text_field;
        variable token9 : in text_field;
        variable valid : in integer;
        variable otoken1 : out text_field;
        variable otoken2 : out text_field;
        variable otoken3 : out text_field;
        variable otoken4 : out text_field;
        variable otoken5 : out text_field;
        variable otoken6 : out text_field;
        variable otoken7 : out text_field;
        variable ovalid : out integer) is

        variable token_merge : integer;
        variable token1_len : integer;
        variable token2_len : integer;
        variable token3_len : integer;
        variable token : text_field := token1;

    begin
        if valid > 1 then
            if token1(1 to 3) = "end" then
                token1_len := 3;
                if token2(1 to 2) = "if" then
                    token2_len := 2;
                    token_merge := 2;
                elsif token2(1 to 4) = "loop" then
                    token2_len := 4;
                    token_merge := 2;
                elsif token2(1 to 4) = "proc" then
                    token2_len := 4;
                    token_merge := 2;
                elsif token2(1 to 9) = "interrupt" then
                    token2_len := 9;
                    token_merge := 2;
                end if;
            elsif token1(1 to 3) = "log" then
                token1_len := 3;
                if token2(1 to 7) = "message" then
                    token2_len := 7;
                    token_merge := 2;
                elsif token2(1 to 5) = "lines" then
                    token2_len := 5;
                    token_merge := 2;
                end if;
            elsif token1(1 to 4) = "file" then
                token1_len := 4;
                if token2(1 to 4) = "read" then
                    token2_len := 4;
                    token_merge := 2;
                elsif token2(1 to 5) = "write" then
                    token2_len := 5;
                    token_merge := 2;
                elsif token2(1 to 6) = "append" then
                    token2_len := 6;
                    token_merge := 2;
                end if;
            elsif token1(1 to 5) = "lines" then
                token1_len := 5;
                if token2(1 to 3) = "get" then
                    token2_len := 3;
                    token_merge := 2;
                    if token3(1 to 5) = "array" then
                        token3_len := 5;
                        token_merge := 3;                         
                    end if;
                elsif token2(1 to 3) = "set" then
                    token2_len := 3;
                    token_merge := 2;
                    if token3(1 to 5) = "array" then
                        token3_len := 5;
                        token_merge := 3;    
                    elsif token3(1 to 7) = "message" then              
                        token3_len := 7;
                        token_merge := 3;                      
                    end if;
                elsif token2(1 to 6) = "delete" then
                    token2_len := 6;
                    token_merge := 2;
                elsif token2(1 to 6) = "insert" then
                    token2_len := 6;
                    token_merge := 2;
                    if token3(1 to 5) = "array" then
                        token3_len := 5;
                        token_merge := 3;    
                    elsif token3(1 to 7) = "message" then              
                        token3_len := 7;
                        token_merge := 3;                      
                    end if;
                elsif token2(1 to 6) = "append" then
                    token2_len := 6;
                    token_merge := 2;
                    if token3(1 to 5) = "array" then
                        token3_len := 5;
                        token_merge := 3;    
                    elsif token3(1 to 7) = "message" then              
                        token3_len := 7;
                        token_merge := 3;                      
                    end if;
                elsif token2(1 to 4) = "size" then
                    token2_len := 4;
                    token_merge := 2;
                elsif token2(1 to 7) = "pointer" then
                    token2_len := 7;
                    token_merge := 2;
                    if token3(1 to 4) = "copy" then
                        token3_len := 4;
                        token_merge := 3;                         
                    end if;
                end if;
            elsif token1(1 to 5) = "array" then
                token1_len := 5;
                if token2(1 to 3) = "set" then
                    token2_len := 3;
                    token_merge := 2;
                elsif token2(1 to 3) = "get" then
                    token2_len := 3;
                    token_merge := 2;
                elsif token2(1 to 4) = "size" then
                    token2_len := 4;
                    token_merge := 2;
                elsif token2(1 to 7) = "pointer" then
                    token2_len := 7;
                    token_merge := 2;
                    if token3(1 to 4) = "copy" then
                        token3_len := 4;
                        token_merge := 3;                         
                    end if;
                end if;
            elsif token1(1 to 4) = "else" then
                token1_len := 4;
                if token2(1 to 2) = "if" then
                    token2_len := 2;
                    token_merge := 2;
                end if;
            elsif token1(1 to 6) = "signal" then
                token1_len := 6;
                if token2(1 to 6) = "verify" then
                    token2_len := 6;
                    token_merge := 2;
                elsif token2(1 to 4) = "read" then
                    token2_len := 4;
                    token_merge := 2;
                elsif token2(1 to 5) = "write" then
                    token2_len := 5;
                    token_merge := 2;
                end if;
            elsif token1(1 to 3) = "bus" then
                token1_len := 3;
                if token2(1 to 6) = "verify" then
                    token2_len := 6;
                    token_merge := 2;
                elsif token2(1 to 4) = "read" then
                    token2_len := 4;
                    token_merge := 2;
                elsif token2(1 to 5) = "write" then
                    token2_len := 5;
                    token_merge := 2;
                elsif token2(1 to 7) = "timeout" then
                    token2_len := 7;
                    token_merge := 2;
                end if;
            end if;
        end if;
        if token_merge = 3 then
            token(token1_len + 2 to token1_len + token2_len + 1) := token2(1 to token2_len);
            token(token1_len + 1) := '_';
            token(token1_len + token2_len + 3 to token1_len + token2_len + token3_len + 2) := token3(1 to token3_len);
            token(token1_len + 1 + token2_len + 1) := '_';
            otoken1 := token;
            otoken2 := token4;
            otoken3 := token5;
            otoken4 := token6;
            otoken5 := token7;
            otoken6 := token8;
            otoken7 := token9;
            ovalid := valid - 2;        
        elsif token_merge = 2 then
            token(token1_len + 2 to token1_len + token2_len + 1) := token2(1 to token2_len);
            token(token1_len + 1) := '_';
            otoken1 := token;
            otoken2 := token3;
            otoken3 := token4;
            otoken4 := token5;
            otoken5 := token6;
            otoken6 := token7;
            otoken7 := token8;
            ovalid := valid - 1;
        else
            otoken1 := token1;
            otoken2 := token2;
            otoken3 := token3;
            otoken4 := token4;
            otoken5 := token5;
            otoken6 := token6;
            otoken7 := token7;
            ovalid := valid;
        end if;

    end procedure;


    -- add a new instruction to the instruction list
    --   inputs  :   the linked list of instructions
    --               the instruction
    --               the number of args
    --   outputs :   updated instruction set linked list
    procedure define_instruction(variable inst_set : inout inst_def_ptr;
        constant inst : in string;
        constant args : in integer) is

        variable v_inst_ptr : inst_def_ptr;
        variable v_prev_ptr : inst_def_ptr;
        variable v_new_ptr : inst_def_ptr;
        variable v_temp_inst : inst_def_ptr;
        variable v_list_size : integer;
        variable v_dup_error : boolean;
    begin
        assert (inst'high <= max_field_len)
        report lf & "error: creation of instruction of length greater than max_field_len attemped!!" &
             lf & "this max is currently set to " & (integer'image(max_field_len))
        severity failure;
        -- get to the last element and test is not exsiting
        v_temp_inst := inst_set;
        v_inst_ptr := inst_set;
        -- zero the size
        v_list_size := 0;
        while v_inst_ptr /= null loop
            -- if there is a chance of a duplicate command
            if v_inst_ptr.instruction_l = inst'high then
                v_dup_error := true;
                for i in 1 to inst'high loop
                    if v_inst_ptr.instruction(i) /= inst(i) then
                        v_dup_error := false;
                    end if;
                end loop;
                -- if we find a duplicate, die
                assert v_dup_error = false
                report lf & "error: duplicate instruction definition attempted!"
                severity failure;
            end if;
            v_prev_ptr := v_inst_ptr; -- store for pointer updates
            v_inst_ptr := v_inst_ptr.next_rec;
            v_list_size := v_list_size + 1;
        end loop;
        -- add the new instruction
        v_new_ptr := new inst_def;
        -- if this is the first command return new pointer
        if v_list_size = 0 then
            v_temp_inst := v_new_ptr;
        -- else write new pointer to next_rec
        else
            v_prev_ptr.next_rec := v_new_ptr;
        end if;
        v_new_ptr.instruction_l := inst'high;
        v_new_ptr.params := args;
        -- copy the instruction text into field
        for i in 1 to v_new_ptr.instruction_l loop
            v_new_ptr.instruction(i) := inst(i);
        end loop;
        -- return the pointer
        inst_set := v_temp_inst;
    end procedure;


    --  check for valid instruction in the list of instructions
    procedure check_valid_inst(variable inst : in text_field;
        variable inst_set : in inst_def_ptr;
        variable token_num : in integer;
        variable line_num : in integer;
        variable name : in text_line) is

        variable l : integer := 0;
        variable seti : inst_def_ptr;
        variable match : integer := 0;
        variable ilv : integer := 0; -- inline variable
    begin
        -- create useable pointer
        seti := inst_set;
        -- count up the characters in inst
        l := fld_len(inst);
        -- if this is a referance variable -- handle in add variable proc
        if inst(l) = ':' then
            match := 1;
            ilv := 1;
        else
            -- process list till null next
            while seti.next_rec /= null loop
                if seti.instruction_l = l then
                    match := 1;
                    for j in 1 to l loop
                        if seti.instruction(j) /= inst(j) then
                            match := 0;
                        end if;
                    end loop;
                end if;
                if match = 0 then
                    seti := seti.next_rec;
                else
                    exit;
                end if;
            end loop;
            -- check current one
            if seti.instruction_l = l and match = 0 then
                match := 1;
                for j in 1 to l loop
                    if seti.instruction(j) /= inst(j) then
                        match := 0;
                    end if;
                end loop;
            end if;
        end if;
        -- if we had a match, check the number of paramiters
        if match = 1 and ilv = 0 then
            assert seti.params = (token_num - 1)
            report lf & "error: undefined instruction was found, incorrect number of fields passed!" & lf &
                    "this is found on line " & (integer'image(line_num)) & " in file " & name & lf
            severity failure;
        end if;
        -- if we find a duplicate, die
        assert match = 1
        report lf & "error: undefined instruction on line " & (integer'image(line_num)) &
                  " found in input file " & name & lf
        severity failure;
    end procedure;

end package body;
