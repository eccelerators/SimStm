library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package body tb_base_pkg_body is

    procedure file_read(variable lines_object_ptr : inout t_lines_object_ptr;
                          variable file_path : in stm_text_ptr;
                          variable valid : out integer) is
        file user_file : text;
        variable std_line : line;
        variable line_append_valid : integer := 0;
    begin
        file_open(v_stat, user_file, file_path, read_mode);
        if v_stat /= open_ok then
            return;
        end if;      
        while not endfile(user_file) loop
            readline(user_file, std_line);           
            lines_line_append(lines_object_ptr, std_line, line_append_valid);
            valid := line_append_valid;                         
        end loop;
        file_close(user_file);                      
    end procedure;
                          
    procedure file_write(variable lines_object_ptr : out t_lines_object_ptr;
                          variable file_path : in stm_text_ptr;
                          variable valid : out integer) is
        file user_file : text;
        variable std_line : line;
        variable line_get_valid : integer := 0;
    begin
        file_open(v_stat, user_file, file_path, write_mode);
        if v_stat /= open_ok then
            return;
        end if;   
        for i in 0 to lines_object_ptr.size - 1 loop                            
            lines_line_get(lines_object_ptr, i, std_line, line_get_valid);  
            writeline(user_file, std_line);
            valid := line_get_valid;                                          
        end loop;
        file_close(user_file);
    end procedure;
                                           
    procedure file_append(variable lines_object_ptr : in t_lines_object;
                          variable file_path : in stm_text_ptr;
                          variable valid : out integer) is
        file user_file : text;
        variable std_line : line;
        variable line_get_valid : integer := 0;
    begin
        file_open(v_stat, user_file, file_path, append_mode);
        if v_stat /= open_ok then
            return;
        end if;   
        for i in 0 to lines_object_ptr.size - 1 loop                            
            lines_line_get(lines_object_ptr, i, std_line, line_get_valid);  
            writeline(user_file, std_line);
            valid := line_get_valid;                                          
        end loop;
        file_close(user_file);
    end procedure;                           


    procedure lines_line_get(variable lines_object_ptr : in t_lines_object_ptr;
                           variable position : in integer;
                           variable array_object_ptr : inout t_array_object_ptr;
                           variable valid : out integer) is
        variable line_ptr : t_lines_object_ptr;
        variable value : integer;
        variable value_found : boolean;
        variable array_index : integer := 0;
    begin
        line_ptr := lines_object_ptr;
        for i in 0 to lines_object_ptr.size - 1 loop     
            if line_ptr.line_number = position then
                hread(line_ptr.line_number.content, value, value_found);
                if value_found then
                    array_object(array_index) := value;
                end if; 
            end if;                        
            valid := 0;                                              
        end loop;
    end procedure;
    
    procedure lines_line_get(variable lines_object_ptr : in t_lines_object_ptr;
                           variable position : in integer;
                           variable std_line : out line;
                           variable valid : out integer) is
        variable line_ptr : t_lines_object_ptr;
    begin
        line_ptr := lines_object_ptr;
        for i in 0 to lines_object_ptr.size - 1 loop     
            if line_ptr.line_number = position then  
                return line_ptr.line_number.content;
            end if;                        
            valid := 0;                                              
        end loop;
    end procedure; 


    procedure lines_line_set(variable lines_object_ptr : inout t_lines_object_ptr;
                           variable position : in integer;
                           variable array_object_ptr : in t_array_object_ptr;
                           variable valid : out integer) is
    variable line_ptr : t_lines_object_ptr;
    variable std_line : line;
    begin
        line_ptr := lines_object_ptr;
        for i in 0 to lines_object_ptr.size - 1 loop     
            if line_ptr.line_number = position then  
                for j in 0 to array_object_ptr.size - 1 loop
                    hwrite(std_line, array_object_ptr(j));
                end loop;          
            end if;                       
            valid := 0;                                              
        end loop;    
    end procedure;
                                                       
    procedure lines_line_set(variable lines_object_ptr : inout t_lines_object_ptr;
                           variable position : in integer;
                           variable text_ptr : out stm_text_ptr;
                           variable valid : out integer) is
    begin
    end procedure; 

                           
    procedure lines_line_append(variable lines_object_ptr : inout t_lines_object_ptr;
                           variable array_object : in t_array_object;
                           variable valid : out integer) is
    begin
    end procedure;

                                                       
    procedure lines_line_append(variable lines_object_ptr : inout t_lines_object_ptr;
                           variable text_ptr : out stm_text_ptr;
                           variable valid : out integer) is
    begin
    end procedure;     
    
    procedure lines_line_append(variable lines_object_ptr : inout t_lines_object_ptr;
                           variable line_object : out line_object_ptr;
                           variable valid : out integer) is
    begin
    end procedure;     

                           
    procedure lines_line_insert(variable lines_object_ptr : inout t_lines_object_ptr;
                           variable position : in integer;
                           variable array_object : in t_array_object;
                           variable valid : out integer) is
    begin
    end procedure;
                                                       
    procedure lines_line_insert(variable lines_object_ptr : inout t_lines_object_ptr;
                           variable position : in integer;
                           variable text_ptr : out stm_text_ptr;
                           variable valid : out integer) is
    begin
    end procedure;                                                   

                                                                                                           
    procedure lines_line_delete(variable lines_object_ptr : inout t_lines_object_ptr;
                           variable position : in integer;
                           variable valid : out integer) is
    begin
    end procedure;  

                           
    procedure lines_pointer(variable lines_object_ptr : inout t_lines_object_ptr;
                           variable lines_object : in t_line_object;
                           variable valid : out integer) is
    begin
    end procedure;  
 
                           
    procedure lines_size(variable lines_object_ptr : in t_lines_object_ptr;
                           variable line_size : out integer;
                           variable valid : out integer) is
    begin
    end procedure; 


    --  is_digit
    function is_digit(constant c : in character) return boolean is
        variable rtn : boolean;
    begin
        if (c >= '0' and c <= '9') then
            rtn := true;
        else
            rtn := false;
        end if;
        return rtn;
    end function;


    -- is_space
    function is_space(constant c : in character) return boolean is
        variable rtn : boolean;
    begin
        if (c = ' ' or c = ht) then
            rtn := true;
        else
            rtn := false;
        end if;
        return rtn;
    end function;


    --  to_char
    function ew_to_char(int : integer) return character is
        variable c : character;
    begin
        c := nul;
        case int is
            when 0 => c := '0';
            when 1 => c := '1';
            when 2 => c := '2';
            when 3 => c := '3';
            when 4 => c := '4';
            when 5 => c := '5';
            when 6 => c := '6';
            when 7 => c := '7';
            when 8 => c := '8';
            when 9 => c := '9';
            when 10 => c := 'A';
            when 11 => c := 'B';
            when 12 => c := 'C';
            when 13 => c := 'D';
            when 14 => c := 'E';
            when 15 => c := 'F';
            when others =>
                assert (false)
                report lf & "error: ew_to_char was given a non number didgit."
                severity failure;
        end case;

        return c;
    end function;


    --  to_string function  integer
    function to_str(int : integer) return string is
    begin
        return ew_to_str(int, dec);
    end function;


    --  ew_str_cat
    function ew_str_cat(s1 : stm_text;
                        s2 : text_field) return stm_text is
        variable i : integer;
        variable j : integer;
        variable sc : stm_text;
    begin
        sc := s1;
        i := 1;
        while (sc(i) /= nul) loop
            i := i + 1;
        end loop;
        j := 1;
        while (s2(j) /= nul) loop
            sc(i) := s2(j);
            i := i + 1;
            j := j + 1;
        end loop;

        return sc;
    end function;


    -- fld_len    field length
    --          inputs :  string of type text_field
    --          return :  integer number of non 'nul' chars
    function fld_len(s : in text_field) return integer is
        variable i : integer := 1;
    begin
        while (s(i) /= nul and i /= max_field_len) loop
            i := i + 1;
        end loop;
        return (i - 1);
    end function;


    -- line_len    textline length
    --          inputs :  string of type text_field
    --          return :  integer number of non 'nul' chars
    function line_len(s : in text_line) return integer is
        variable i : integer := 1;
    begin
        while (s(i) /= nul and i /= max_str_len) loop
            i := i + 1;
        end loop;
        return (i - 1);
    end function;


    -- fld_equal  check text field for equality
    --          inputs :  text field s1 and s2
    --          return :  true if text fields are equal; false otherwise.
    function fld_equal(s1 : in text_field;
                       s2 : in text_field) return boolean is
        variable i : integer := 0;
        variable s1_length : integer := 0;
        variable s2_length : integer := 0;
    begin
        s1_length := fld_len(s1);
        s2_length := fld_len(s2);

        if (s1_length /= s2_length) then
            return false;
        end if;

        while (i /= s1_length) loop
            i := i + 1;
            if s1(i) /= s2(i) then
                return false;
            end if;
        end loop;
        return true;
    end function;


    -- c2int   convert character to integer
    function c2int(c : in character) return integer is
        variable i : integer;
    begin
        i := -1;
        case c is
            when '0' => i := 0;
            when '1' => i := 1;
            when '2' => i := 2;
            when '3' => i := 3;
            when '4' => i := 4;
            when '5' => i := 5;
            when '6' => i := 6;
            when '7' => i := 7;
            when '8' => i := 8;
            when '9' => i := 9;
            when others =>
                assert (false)
                report lf & "error: c2int was given a non number didgit."
                severity failure;
        end case;
        return i;
    end function;


    -- str2integer   convert a string to integer number.
    --   inputs  :  string
    --   output  :  int value
    function str2integer(str : in string) return integer is
        variable l : integer;
        variable j : integer := 1;
        variable rtn : integer := 0;
    begin

        l := fld_len(str);

        for i in l downto 1 loop
            rtn := rtn + (c2int(str(j)) * (10 ** (i - 1)));
            j := j + 1;
        end loop;

        return rtn;
    end function;


    -- hex2integer    convert hex stimulus field to integer
    --          inputs :  string of type text_field containing only hex numbers
    --          return :  integer value
    function hex2integer(hex_number : in text_field;
                         file_name : in text_line;
                         line : in integer) return integer is
        variable len : integer;
        variable temp_int : integer;
        variable power : integer;
        variable int_number : integer;
    begin
        len := fld_len(hex_number);
        power := 0;
        temp_int := 0;
        for i in len downto 1 loop
            case hex_number(i) is
                when '0' =>
                    int_number := 0;
                when '1' =>
                    int_number := 1;
                when '2' =>
                    int_number := 2;
                when '3' =>
                    int_number := 3;
                when '4' =>
                    int_number := 4;
                when '5' =>
                    int_number := 5;
                when '6' =>
                    int_number := 6;
                when '7' =>
                    int_number := 7;
                when '8' =>
                    int_number := 8;
                when '9' =>
                    int_number := 9;
                when 'a' | 'A' =>
                    int_number := 10;
                when 'b' | 'B' =>
                    int_number := 11;
                when 'c' | 'C' =>
                    int_number := 12;
                when 'd' | 'D' =>
                    int_number := 13;
                when 'e' | 'E' =>
                    int_number := 14;
                when 'f' | 'F' =>
                    int_number := 15;
                when others =>
                    assert (false)
                    report lf & "error: hex2integer found non hex didgit on line "
                     & (integer'image(line)) & " of file " & file_name
                    severity failure;
            end case;
            temp_int := temp_int + (int_number * (16 ** power));
            power := power + 1;
        end loop;
        return temp_int;
    end function;


    -- convert character to 4 bit vector
    --   input    character
    --   output   std_logic_vector  4 bits
    function c2std_vec(c : in character) return std_logic_vector is
    begin
        case c is
            when '0' => return "0000";
            when '1' => return "0001";
            when '2' => return "0010";
            when '3' => return "0011";
            when '4' => return "0100";
            when '5' => return "0101";
            when '6' => return "0110";
            when '7' => return "0111";
            when '8' => return "1000";
            when '9' => return "1001";
            when 'a' | 'A' => return "1010";
            when 'b' | 'B' => return "1011";
            when 'c' | 'C' => return "1100";
            when 'd' | 'D' => return "1101";
            when 'e' | 'E' => return "1110";
            when 'f' | 'F' => return "1111";
            when others =>
                assert (false)
                report lf & "error: c2std_vec found non hex didgit on file line "
                severity failure;
                return "XXXX";
        end case;
    end function;


    --  std_vec2c  convert 4 bit std_vector to a character
    --     input  std_logic_vector 4 bits
    --     output  character
    function std_vec2c(vec : in std_logic_vector(3 downto 0)) return character is
    begin
        case vec is
            when "0000" => return '0';
            when "0001" => return '1';
            when "0010" => return '2';
            when "0011" => return '3';
            when "0100" => return '4';
            when "0101" => return '5';
            when "0110" => return '6';
            when "0111" => return '7';
            when "1000" => return '8';
            when "1001" => return '9';
            when "1010" => return 'A';
            when "1011" => return 'B';
            when "1100" => return 'C';
            when "1101" => return 'D';
            when "1110" => return 'E';
            when "1111" => return 'F';
            when others =>
                assert (false)
                report lf & "error: std_vec2c found non-binary didgit in vec "
                severity failure;
                return 'X';
        end case;
    end function;


    -- bin2integer    convert bin stimulus field to integer
    --          inputs :  string of type text_field containing only binary numbers
    --          return :  integer value
    function bin2integer(bin_number : in text_field;
                         file_name : in text_line;
                         line : in integer) return integer is
        variable len : integer;
        variable temp_int : integer;
        variable power : integer;
        variable int_number : integer;
    begin
        len := fld_len(bin_number);
        power := 0;
        temp_int := 0;
        for i in len downto 1 loop
            case bin_number(i) is
                when '0' =>
                    int_number := 0;
                when '1' =>
                    int_number := 1;
                when others =>
                    assert (false)
                    report lf & "error: bin2integer found non binary didgit on line "
                     & (integer'image(line)) & " of file " & file_name
                    severity failure;
            end case;

            temp_int := temp_int + (int_number * (2 ** power));
            power := power + 1;
        end loop;

        return temp_int;
    end function;


    -- stim_to_integer    convert stimulus field to integer
    --          inputs :  string of type text_field "stimulus format of number"
    --          return :  integer value
    function stim_to_integer(field : in text_field;
                             file_name : in text_line;
                             line : in integer) return integer is
        variable len : integer;
        variable value : integer := 1;
        variable temp_str : text_field;
    begin
        len := fld_len(field);

        if (field(1) = '#') then
            case field(2) is
                when 'x' =>
                    value := 3;
                    while (field(value) /= nul) loop
                        temp_str(value - 2) := field(value);
                        value := value + 1;
                    end loop;
                    -- assert(false)
                    -- report lf & "hex2integer: " & temp_str
                    -- severity warning;
                    value := hex2integer(temp_str, file_name, line);
                when 'b' =>
                    value := 3;
                    while (field(value) /= nul) loop
                        temp_str(value - 2) := field(value);
                        value := value + 1;
                    end loop;
                    value := bin2integer(temp_str, file_name, line);
                when 'd' =>
                    value := 3;
                    while (field(value) /= nul) loop
                        temp_str(value - 2) := field(value);
                        value := value + 1;
                    end loop;
                    value := str2integer(temp_str);
                when others =>
                    assert (false)
                    report lf & "error: strange # found ! "
                     & (integer'image(line)) & " of file " & file_name
                    severity failure;
            end case;
        else
            value := str2integer(field);
        end if;
        return value;
    end function;


    --  to_str function  with base parameter
    --     convert integer to number base
    function ew_to_str(int : integer;
                       b : base) return text_field is
        variable temp : text_field;
        variable temp1 : text_field;
        variable radix : integer := 0;
        variable num : integer := 0;
        variable power : integer := 1;
        variable len : integer := 1;
        variable pre : string(1 to 2);
        variable i : integer;
        variable j : integer;
        variable vec : std_logic_vector(31 downto 0);
    begin
        num := int;
        temp := (others => nul);
        case b is
            when bin =>
                radix := 2; -- depending on what
                pre := "0b";
            when oct =>
                radix := 8; -- base the number is
                pre := "0o";
            when hex =>
                radix := 16; -- to be displayed as
                pre := "0x";
            when dec =>
                radix := 10; -- choose a radix range
                pre := (others => nul);
        end case;
        -- now jump through hoops because of sign
        if (num < 0 and b = hex) then
            vec := std_logic_vector(to_unsigned(int, 32));
            temp(1) := std_vec2c(vec(31 downto 28));
            temp(2) := std_vec2c(vec(27 downto 24));
            temp(3) := std_vec2c(vec(23 downto 20));
            temp(4) := std_vec2c(vec(19 downto 16));
            temp(5) := std_vec2c(vec(15 downto 12));
            temp(6) := std_vec2c(vec(11 downto 8));
            temp(7) := std_vec2c(vec(7 downto 4));
            temp(8) := std_vec2c(vec(3 downto 0));
        else
            while num >= radix loop -- determine how many
                len := len + 1; -- characters required
                num := num / radix; -- to represent the
            end loop; -- number.
            for i in len downto 1 loop -- convert the number to
                temp(i) := ew_to_char(int / power mod radix); -- a string starting
                power := power * radix; -- with the right hand
            end loop; -- side.
        end if;
        -- add prefix if is one
        if (pre(1) /= nul) then
            temp1 := temp;
            i := 1;
            j := 3;
            temp(1 to 2) := pre;
            while (temp1(i) /= nul) loop
                temp(j) := temp1(i);
                i := i + 1;
                j := j + 1;
            end loop;
        end if;
        return temp;
    end function;


    --  to_str function  with base parameter
    --     convert integer to number base
    function ew_to_str_len(int : integer;
                           b : base) return text_field is
        variable temp : text_field;
        variable temp1 : text_field;
        variable radix : integer := 0;
        variable num : integer := 0;
        variable power : integer := 1;
        variable len : integer := 1; -- adjusted min. length to 2 for bytes
        variable pre : string(1 to 2);
        variable i : integer;
        variable j : integer;
        variable vec : std_logic_vector(31 downto 0);
    begin
        num := int;
        temp := (others => nul);
        case b is
            when bin =>
                radix := 2; -- depending on what
                pre := "0b";
            when oct =>
                radix := 8; -- base the number is
                pre := "0o";
            when hex =>
                radix := 16; -- to be displayed as
                pre := "0x";
            when dec =>
                radix := 10; -- choose a radix range
                pre := (others => nul);
        end case;
        -- now jump through hoops because of sign
        if (num < 0 and b = hex) then
            vec := std_logic_vector(to_signed(int, 32));
            temp(1) := std_vec2c(vec(31 downto 28));
            temp(2) := std_vec2c(vec(27 downto 24));
            temp(3) := std_vec2c(vec(23 downto 20));
            temp(4) := std_vec2c(vec(19 downto 16));
            temp(5) := std_vec2c(vec(15 downto 12));
            temp(6) := std_vec2c(vec(11 downto 8));
            temp(7) := std_vec2c(vec(7 downto 4));
            temp(8) := std_vec2c(vec(3 downto 0));
        else
            while num >= radix loop -- determine how many
                len := len + 1; -- characters required
                num := num / radix; -- to represent the
            end loop; -- number.
            if (len mod 2 > 0) then -- is odd number, add one
                len := len + 1;
            end if;
            for i in len downto 1 loop -- convert the number to
                temp(i) := ew_to_char(int / power mod radix); -- a string starting
                power := power * radix; -- with the right hand
            end loop; -- side.
        end if;
        -- add prefix if is one
        if (pre(1) /= nul) then
            temp1 := temp;
            i := 1;
            j := 3;
            temp(1 to 2) := pre;
            while (temp1(i) /= nul) loop
                temp(j) := temp1(i);
                i := i + 1;
                j := j + 1;
            end loop;
        end if;
        return temp;
    end function;


    --  function short text_line (remove 'nul')
    function txt_shorter(txt : in text_line) return string is
        variable l : integer;
    begin
        l := line_len(txt);
        return txt(1 to l);
    end function;


    -- procedure to print instruction records to stdout  *for debug*
    procedure print_inst(variable inst : in stim_line_ptr) is
        variable l : text_line;
        variable l_i : integer := 1;
        variable j : integer := 1;
    begin
        while (inst.instruction(j) /= nul) loop
            l(l_i) := inst.instruction(j);
            j := j + 1;
            l_i := l_i + 1;
        end loop;

        l(l_i) := ' ';
        l_i := l_i + 1;
        j := 1;
        -- field one
        if (inst.inst_field_1(1) /= nul) then
            while (inst.inst_field_1(j) /= nul) loop
                l(l_i) := inst.inst_field_1(j);
                j := j + 1;
                l_i := l_i + 1;
            end loop;
            l(l_i) := ' ';
            l_i := l_i + 1;
            j := 1;
            -- field two
            if (inst.inst_field_2(1) /= nul) then
                while (inst.inst_field_2(j) /= nul) loop
                    l(l_i) := inst.inst_field_2(j);
                    j := j + 1;
                    l_i := l_i + 1;
                end loop;
                l(l_i) := ' ';
                l_i := l_i + 1;
                j := 1;
                -- field three
                if (inst.inst_field_3(1) /= nul) then
                    while (inst.inst_field_3(j) /= nul) loop
                        l(l_i) := inst.inst_field_3(j);
                        j := j + 1;
                        l_i := l_i + 1;
                    end loop;
                    l(l_i) := ' ';
                    l_i := l_i + 1;
                    j := 1;
                    -- field four
                    if (inst.inst_field_4(1) /= nul) then
                        while (inst.inst_field_4(j) /= nul) loop
                            l(l_i) := inst.inst_field_4(j);
                            j := j + 1;
                            l_i := l_i + 1;
                        end loop;
                    end if;
                end if;
            end if;
        end if;
        print(l);
        print("   sequence number: " & to_str(inst.line_number) &
          "  file line number: " & to_str(inst.file_line));
        if (inst.num_of_lines > 0) then
            print("   number of lines: " & to_str(inst.num_of_lines));
        end if;
    end procedure;
    
    -------------------------------------------------------------------------
    -- dump inst_sequ
    --  this procedure dumps to the simulation window the current instruction
    --  sequence.  the whole thing will be dumped, which could be big.
    --   ** intended for testbench development debug **
    procedure dump_inst_sequ(variable inst_sequ  :  in  stim_line_ptr) is
      variable v_sequ  :  stim_line_ptr;
    begin
      v_sequ  :=  inst_sequ;
      while(v_sequ.next_rec /= null) loop
        print("-----------------------------------------------------------------");
        print("instruction is " & v_sequ.instruction &
        "     par1: "   & v_sequ.inst_field_1 &
        "     par2: "   & v_sequ.inst_field_2 &
        "     par3: "   & v_sequ.inst_field_3 &
        "     par4: "   & v_sequ.inst_field_4);
        print("line number: " & to_str(v_sequ.line_number) & "     file line number: " & to_str(v_sequ.file_line) &
        "     file name: " & v_sequ.file_name);
    
        v_sequ  :=  v_sequ.next_rec;
      end loop;
      -- get the last one
      print("-----------------------------------------------------------------");
      print("instruction is " & v_sequ.instruction & "     par1: "   & v_sequ.inst_field_1 &
      "     par2: "   & v_sequ.inst_field_2 & "     par3: "   & v_sequ.inst_field_3 &
      "     par4: "   & v_sequ.inst_field_4);
      print("line number: " & to_str(v_sequ.line_number) & "     file line number: " & to_str(v_sequ.file_line) &
      "     file name: " & v_sequ.file_name);
    end procedure;

    

    -- procedure to print loggings to stdout
    procedure print(s : in string) is
        variable l : line;
    begin
        for i in 1 to s'length loop
            if (s(i) /= nul) then
                write(l, s(i));
            end if;
        end loop;
        writeline(output, l);
    end procedure;


    --  procedure to print to the stdout the txt pointer
    procedure txt_print(variable ptr : in stm_text_ptr) is
        variable txt_str : stm_text;
    begin

        if (ptr /= null) then
            txt_str := (others => nul);
            for i in 1 to c_stm_text_len loop
                if (ptr(i) = nul) then
                    exit;
                end if;
                txt_str(i) := ptr(i);
            end loop;
            print(txt_str);
        end if;
    end procedure;


    --  procedure copy text into an existing pointer
    procedure txt_ptr_copy(variable ptr : in stm_text_ptr;
                           variable ptr_o : out stm_text_ptr;
                           variable txt_str : in stm_text) is
        variable ptr_temp : stm_text_ptr;
    begin
        ptr_temp := ptr;
        if (ptr_temp /= null) then
            for i in 1 to c_stm_text_len loop
                if (txt_str(i) = nul) then
                    exit;
                end if;
                ptr_temp(i) := txt_str(i);
            end loop;
        end if;
        ptr_o := ptr_temp;
    end procedure;


    --  procedure to print to the stdout the txt pointer, and
    --  sub any variables found
    procedure txt_print_wvar(variable var_list : in var_field_ptr;
                             variable ptr : in stm_text_ptr;
                             constant b : in base) is
        variable i : integer;
        variable j : integer;
        variable k : integer;
        variable txt_str : stm_text;
        variable v1 : integer;
        variable valid : integer;
        variable tmp_field : text_field;
        variable tmp_i : integer;
    begin
        if (ptr /= null) then
            i := 1;
            j := 1;
            txt_str := (others => nul);
            while (i <= c_stm_text_len and j <= c_stm_text_len) loop
                if (ptr(i) /= '$') then
                    txt_str(j) := ptr(i);
                    i := i + 1;
                    j := j + 1;
                else
                    tmp_field := (others => nul);
                    tmp_i := 1;
                    tmp_field(tmp_i) := ptr(i);
                    i := i + 1;
                    tmp_i := tmp_i + 1;
                    -- parse to the next space
                    while (ptr(i) /= ' ' and ptr(i) /= nul) loop
                        tmp_field(tmp_i) := ptr(i);
                        i := i + 1;
                        tmp_i := tmp_i + 1;
                    end loop;
                    access_variable(var_list, tmp_field, v1, valid);
                    assert (valid = 1)
                    report lf & "invalid variable found in stm_text_ptr: ignoring."
                    severity warning;

                    if (valid = 1) then

                        txt_str := ew_str_cat(txt_str, ew_to_str_len(v1, b));
                        k := 1;
                        while (txt_str(k) /= nul) loop
                            k := k + 1;
                        end loop;
                        j := k;
                    end if;
                end if;
            end loop;
            -- print the created string
            print(txt_str);
        end if;
    end procedure;
     
    
    procedure init_text_field(variable sourcestr : in string;
                              variable destfield : out text_field) is
        variable tempfield : text_field;
    begin
        for i in 1 to sourcestr'length loop
            tempfield(i) := sourcestr(i);
        end loop;

        for i in 1 to text_field'length loop
            destfield(i) := tempfield(i);
        end loop;
    end procedure;


    --  get a random intetger number
    procedure getrandint(variable seed1 : inout positive;
                         variable seed2 : inout positive;
                         variable lowestvalue : in integer;
                         variable utmostvalue : in integer;
                         variable randint : out integer) is
        variable randreal : real;
        variable intdelta : integer;
    begin
        intdelta := utmostvalue - lowestvalue;
        uniform(seed1, seed2, randreal); -- generate random number
        randint := integer(trunc(randreal * (real(intdelta) + 1.0))) + lowestvalue; -- rescale to delta, find integer part, adjust
    end procedure;
        

end package body;
