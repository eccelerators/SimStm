library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tb_signals_pkg is

    procedure define_instructions(variable inst_list : inout inst_def_ptr); 
    
    procedure token_merge( variable token1 : in text_field;
                            variable token2 : in text_field;
                            variable token3 : in text_field;
                            variable token4 : in text_field;
                            variable token5 : in text_field;
                            variable token6 : in text_field;
                            variable token7 : in text_field;
                            variable token8 : in text_field;
                            variable valid : in integer;  
                            variable otoken1 : out text_field;
                            variable otoken2 : out text_field;
                            variable otoken3 : out text_field;
                            variable otoken4 : out text_field;
                            variable otoken5 : out text_field;
                            variable otoken6 : out text_field;
                            variable otoken7 : out text_field;
                            variable ovalid : out integer);

end package;



package body tb_pkg_signals is

    procedure define_instructions(variable inst_list : inout inst_def_ptr) is
    begin

        -- basic
        define_instruction(inst_list, "abort", 0);
        define_instruction(inst_list, "const", 2);
        define_instruction(inst_list, "else", 0);
        define_instruction(inst_list, "elsif", 3);
        define_instruction(inst_list, "end_if", 0);
        define_instruction(inst_list, "end_loop", 0);
        define_instruction(inst_list, "finish", 0);
        define_instruction(inst_list, "if", 3);
        define_instruction(inst_list, "include", 1);
        define_instruction(inst_list, "loop", 1);
        define_instruction(inst_list, "var", 2);

        -- variables
        define_instruction(inst_list, "add", 2);
        define_instruction(inst_list, "and", 2);
        define_instruction(inst_list, "div", 2);
        define_instruction(inst_list, "equ", 2);
        define_instruction(inst_list, "mul", 2);
        define_instruction(inst_list, "shl", 2);
        define_instruction(inst_list, "shr", 2);
        define_instruction(inst_list, "inv", 1);
        define_instruction(inst_list, "or", 2);
        define_instruction(inst_list, "sub", 2);
        define_instruction(inst_list, "xor", 2);
        define_instruction(inst_list, "ld", 1);

        -- signals
        define_instruction(inst_list, "signal_read", 2);
        define_instruction(inst_list, "signal_verify", 4);
        define_instruction(inst_list, "signal_write", 2);

        -- bus
        define_instruction(inst_list, "bus_read", 4);
        define_instruction(inst_list, "bus_verify", 6);
        define_instruction(inst_list, "bus_write", 4);
        define_instruction(inst_list, "bus_timeout", 2);

        -- file
        define_instruction(inst_list, "file_read", 2); 
        define_instruction(inst_list, "file_write", 2); 
        define_instruction(inst_list, "file_append", 2);
        
        -- lines
        define_instruction(inst_list, "lines", 1);
        define_instruction(inst_list, "lines_get", 3);
        define_instruction(inst_list, "lines_set", 3);
        define_instruction(inst_list, "lines_delete", 2);
        define_instruction(inst_list, "lines_insert", 3);
        define_instruction(inst_list, "lines_append", 3);
        define_instruction(inst_list, "lines_size", 2);
        define_instruction(inst_list, "lines_pointer", 2);

        -- array
        define_instruction(inst_list, "array", 2);
        define_instruction(inst_list, "array_get", 3);
        define_instruction(inst_list, "array_set", 3);
        define_instruction(inst_list, "array_size", 2);
        define_instruction(inst_list, "array_pointer", 2);

        -- others
        define_instruction(inst_list, "proc", 0);
        define_instruction(inst_list, "call", 1);
        define_instruction(inst_list, "interrupt", 0);
        define_instruction(inst_list, "end_proc", 0);
        define_instruction(inst_list, "end_interrupt", 0);
        define_instruction(inst_list, "random", 3);
        define_instruction(inst_list, "log", 1);
        define_instruction(inst_list, "return", 0);
        define_instruction(inst_list, "resume", 1);
        define_instruction(inst_list, "marker", 2);
        define_instruction(inst_list, "verbosity", 1);
        define_instruction(inst_list, "seed", 1);
        define_instruction(inst_list, "trace", 1);
        define_instruction(inst_list, "wait", 1);
    end procedure;
    
    
    procedure token_merge( variable token1 : in text_field;
                            variable token2 : in text_field;
                            variable token3 : in text_field;
                            variable token4 : in text_field;
                            variable token5 : in text_field;
                            variable token6 : in text_field;
                            variable token7 : in text_field;
                            variable token8 : in text_field;
                            variable valid : in integer;  
                            variable otoken1 : out text_field;
                            variable otoken2 : out text_field;
                            variable otoken3 : out text_field;
                            variable otoken4 : out text_field;
                            variable otoken5 : out text_field;
                            variable otoken6 : out text_field;
                            variable otoken7 : out text_field;
                            variable ovalid : out integer) is
                            
        variable token_merge : boolean;
        variable token1_len : integer;
        variable token2_len : integer;
        variable token : text_field;
        
    begin
        if valid > 1 then
            if token1(1 to 3) = "end" then
                token1_len := 3;
                if token2(1 to 2) = "if" then
                    token2_len := 2;
                    token_merge := true;
                elsif token2(1 to 4) = "loop" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 4) = "proc" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 9) = "interrupt" then
                    token2_len := 9;
                    token_merge := true;
                end if;
            elsif token1(1 to 4) = "file" then
                token1_len := 4;
                if token2(1 to 4) = "read" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 5) = "write" then
                    token2_len := 5;
                    token_merge := true;
                elsif token2(1 to 6) = "append" then
                    token2_len := 6;
                    token_merge := true;
                end if;
            elsif token1(1 to 5) = "lines" then
                token1_len := 5;
                if token2(1 to 3) = "get" then
                    token2_len := 3;
                    token_merge := true;
                elsif token2(1 to 3) = "set" then
                    token2_len := 3;
                    token_merge := true;
                elsif token2(1 to 6) = "delete" then
                    token2_len := 6;
                    token_merge := true;
                elsif token2(1 to 6) = "insert" then
                    token2_len := 6;
                    token_merge := true;
                elsif token2(1 to 4) = "size" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 7) = "pointer" then
                    token2_len := 7;
                    token_merge := true;
                end if;
            elsif token1(1 to 5) = "array" then
                token1_len := 5;
                if token2(1 to 3) = "set" then
                    token2_len := 3;
                    token_merge := true;
                elsif token2(1 to 3) = "get" then
                    token2_len := 3;
                    token_merge := true;
                elsif token2(1 to 4) = "size" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 7) = "pointer" then
                    token2_len := 7;
                    token_merge := true;
                end if;
            elsif token1(1 to 4) = "else" then
                token1_len := 4;
                if token2(1 to 2) = "if" then
                    token2_len := 2;
                    token_merge := true;
                end if;
            elsif token1(1 to 6) = "signal" then
                token1_len := 6;
                if token2(1 to 6) = "verify" then
                    token2_len := 6;
                    token_merge := true;
                elsif token2(1 to 4) = "read" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 5) = "write" then
                    token2_len := 5;
                    token_merge := true;
                end if;
            elsif token1(1 to 3) = "bus" then
                token1_len := 3;
                if token2(1 to 6) = "verify" then
                    token2_len := 6;
                    token_merge := true;
                elsif token2(1 to 4) = "read" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 5) = "write" then
                    token2_len := 5;
                    token_merge := true;
                elsif token2(1 to 7) = "timeout" then
                    token2_len := 7;
                    token_merge := true;
                end if;
            end if;
        end if;
        if token_merge then
            token(token1_len + 2 to token1_len + token2_len + 1) := token2(1 to token2_len);
            token(token_len + 1) := '_';

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
    
end package body;
