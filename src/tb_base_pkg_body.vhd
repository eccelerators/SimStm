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
--   Base helper subprogram implementations used by the SimStm runtime.
--
-- Upstream reference:
--   https://github.com/sckoarn/VHDL-Test-Bench
-------------------------------------------------------------------------------

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_textio.all;

use work.tb_limits_pkg.all;

package body tb_base_pkg is

    procedure init_inst_def_list(
        variable inst_defs : inout inst_def_list
    ) is
    begin
        inst_defs.last_element_num := -1;
    end procedure;

    procedure init_file_def_list(
        variable files : inout file_def_list
    ) is
    begin
        files.last_element_num := -1;
    end procedure;

    procedure init_inst_sequence(
        variable insts : inout inst_sequence
    ) is
    begin
        insts.last_element_num := -1;
    end procedure;

    procedure init_var_pool_ordered(
        variable vars : inout var_pool_ordered
    ) is
    begin
        vars.last_element_num := -1;
    end procedure;

    procedure init_proc_pool_ordered(
        variable procs : inout proc_pool_ordered
    ) is
    begin
        procs.last_element_num := -1;
    end procedure;

    procedure init_inst_initial_context(
        variable iic : inout stm_inst_initial_context
    ) is
    begin
        iic.is_var_declaration := false;
        iic.code_section := NONE;
        iic.namespace_name := (others => nul);
        iic.proc_name := (others => nul);
        iic.called_proc_name := (others => nul);
    end procedure;

    procedure init_runtime_context(
        variable rc : inout stm_runtime_context
    ) is
        variable no_scope : text_field;
    begin
        init_const_text_field(".", no_scope);
        rc.call_process_state := IN_NONE;
        rc.ien_of_call := -1;
        rc.ien_of_proc_params_end := -1;
        rc.ien_of_called_proc := -1;
        rc.loop_num := 0;
        rc.loop_if_enter_level := 0;
        rc.curr_loop_count := (others => 0);
        rc.term_loop_count := (others => 0);
        rc.loop_line := (others => 0);
    end procedure;

    function var_type_to_string(
        vt : stm_var_type
    ) return string is
        variable vts : string(1 to 5);
    begin
        case vt is
            when T_LINES =>
                vts := "lines";
            when T_ARRAY =>
                vts := "array";
            when T_TEXT =>
                vts := "text ";
            when T_LABEL =>
                vts := "label";
            when T_CONST =>
                vts := "const";
            when others =>
                vts := "value";
        end case;
        return vts;
    end function;

    procedure append_inst(
        variable insts : inout inst_sequence;
        variable ie : inst_element_ptr;
        constant debug : boolean
    ) is
        variable nen : integer;
        variable ne_ptr : inst_element_ptr;
    begin
        nen := insts.last_element_num + 1;
        ne_ptr := new inst_element;
        ne_ptr.slc := ie.slc;
        ne_ptr.inst := ie.inst;
        ne_ptr.inst_len := fld_len(ie.inst);
        ne_ptr.inst_namespace := ie.inst_namespace;
        ne_ptr.inst_args := ie.inst_args;
        insts.element_ptrs(nen) := ne_ptr;
        insts.last_element_num := nen;
        if debug then
            print("append instruction " & ie.inst & ", element number " & integer'image(insts.last_element_num));
        end if;
    end procedure;
    
    function get_path_stem( 
        p : text_line
    ) return text_line is
        variable po : text_line;
        variable lastPosOfSlash : integer;
        variable pl : integer;
    begin
        lastPosOfSlash := 0;
        pl := text_line_len(p);
        for i in 1 to pl loop
            if p(i) = '/' then
                lastPosOfSlash := i;
            end if;
        end loop;
        for i in 1 to lastPosOfSlash loop        
            po(i) := p(i);
        end loop; 
        return po;
    end function;
    
    function get_path_file_name( 
        p : text_line
    ) return text_line is
        variable po : text_line;
        variable lastPosOfSlash : integer;
        variable pl : integer;
    begin
        lastPosOfSlash := 0;
        pl := text_line_len(p);
        for i in 1 to pl loop
            if p(i) = '/' then
                lastPosOfSlash := i;
            end if;
        end loop;
        for i in lastPosOfSlash + 1 to pl loop        
            po(i - lastPosOfSlash) := p(i);
        end loop; 
        return po;
    end function;
    
    procedure print_path_segments_as_path(
        constant prefix : in string;
        variable path_segments : in text_line_array;
        constant postfix : in string
    ) is
        variable path : text_line;
        variable j : integer;
        variable n : integer;
        variable l : integer;
    begin
        n := 0;
        j := 1;
        while path_segments(n)(1) /= nul loop
            l := text_line_len(path_segments(n));
            for i in 1 to l loop
                path(j) := path_segments(n)(i); 
                j := j + 1;    
            end loop;
            path(j) := '/';
            j := j + 1;
            n := n + 1;
        end loop;
        path(j - 1) := nul;
        print(prefix & path & postfix);
    end procedure;
    
    procedure reduce_next_relative_folder_path_segment(
        variable path_segments : in text_line_array;
        variable reduced_path_segments : out text_line_array ;
        variable reduced : out boolean;
        constant debug : boolean
    ) is
        variable tmp_path_segments : text_line_array;
        variable i : integer;
        variable j : integer;
        variable f : boolean;
    begin
        if debug then
            print("reduce_next_relative_folder_path_segment");
            print_path_segments_as_path("path ", path_segments, "");
        end if;
        i := 0;
        j := 0;
        f := false;
        while path_segments(i)(1) /= nul loop
            if path_segments(i + 1)(1 to 2) = ".." and f = false then
                i := i + 2;
                f := true;
            elsif path_segments(i)(1 to 1) = "."  and f = false then
                i := i + 1;
                f := true;
            else
                tmp_path_segments(j) := path_segments(i);
                i := i + 1;
                j := j + 1;
            end if;     
        end loop;
        if f then
            reduce_next_relative_folder_path_segment(tmp_path_segments, reduced_path_segments, reduced, debug);
        else
            reduced_path_segments := tmp_path_segments;
            reduced := false;
        end if;
        if debug then
            print_path_segments_as_path("reduced_path ", reduced_path_segments, "");
        end if;
    end procedure;    
    
    function to_forward_slash_separator (
        s : string
    ) return string is
        variable so : string(1 to s'length);
    begin
      for i in 1 to s'length loop
        if s(i) = '\' then
            so(i) := '/';
        else
            so(i) := s(i);
        end if;
      end loop;
      return so;
    end function;
  
    procedure normalize_relative_file_path(
        variable root_to_to_current_dir_path : in text_line; 
        variable relative_file_path : in text_line;
        variable normalized_file_path : out text_line;
        constant debug : boolean 
    ) is
        variable l : integer;
        variable n : integer;
        variable j : integer;
        variable f : boolean;
        variable si : integer;
        variable path_segments : text_line_array := (others => (others => nul));
        variable reduced_path_segments : text_line_array;
        variable reduced : boolean;
        variable resolved_file_path : text_line; 
    begin
        assert relative_file_path(1) /= '/'
        report "normalize_code_file_path: relative file pathes mustn't start with /"
        severity failure;
        if debug then 
            print("root_to_to_current_dir_path " & root_to_to_current_dir_path);
        end if; 
        l := text_line_len(root_to_to_current_dir_path);
        n := 0;
        j := 1;
        si := 1;
        if root_to_to_current_dir_path(1) = '/' then
            si := 2;
        end if;
        for i in si to l loop
            if root_to_to_current_dir_path(i) = '/' then
                n := n + 1;
                j := 1;
            else
                path_segments(n)(j) := root_to_to_current_dir_path(i); 
                j := j + 1; 
            end if;     
        end loop; 
        if debug then 
            print("relative_file_path " & relative_file_path);
        end if;              
        l := text_line_len(relative_file_path);
        j := 1;
        for i in 1 to l loop
            if relative_file_path(i) = '/' then
                n := n + 1;
                j := 1;                              
            else  
                path_segments(n)(j) := relative_file_path(i);
                j := j + 1;
            end if;     
        end loop;
        n := n + 1;
        
        reduce_next_relative_folder_path_segment(path_segments, reduced_path_segments, reduced, debug);
        
        n := 0;
        j := 1;
        f := true;
        while reduced_path_segments(n)(1) /= nul loop
            if f = true then     
                if root_to_to_current_dir_path(1) = '/' then
                    resolved_file_path(j) := '/';
                    j := j + 1;              
                end if;
            else
                resolved_file_path(j) := '/';
                j := j + 1;
            end if;
            f := false;
            l := text_line_len(reduced_path_segments(n));
            for i in 1 to l loop
                resolved_file_path(j) := reduced_path_segments(n)(i); 
                j := j + 1;    
            end loop;
            n := n + 1;
        end loop;
        normalized_file_path := resolved_file_path;
        if debug then 
            print("normalized_file_path " & normalized_file_path);
        end if;   
    end procedure;

    procedure append_code_file(
        variable slc : src_locator;
        variable code_files : inout file_def_list;
        variable acfn : text_line
    ) is
        variable nen : integer;
        variable ne_ptr : file_def_element_ptr;
    begin
        nen := code_files.last_element_num + 1;
        ne_ptr := new file_def_element;
        ne_ptr.slc := slc;
        ne_ptr.absolute_file_name := acfn;
        ne_ptr.file_name := get_path_file_name(acfn);
        code_files.element_ptrs(nen) := ne_ptr;
        code_files.last_element_num := nen;
    end procedure;

    procedure extract_parameters(
        variable slc : in src_locator;
        variable ts : in token_text_field_array;
        variable ptfs : out parameter_text_field_array;
        variable ptps : out parameter_type_array;
        variable plit_vals : out parameter_value_array_ptr;
        constant machine_value_width : integer
    ) is
    begin
        plit_vals := new parameter_value_array(1 to 6)(machine_value_width - 1 downto 0);
        for i in 1 to 6 loop
            ptps(i) := PAR_NM;
            ptfs(i) := ts(i + 1);
            if is_digit(ptfs(i)(1)) then
                ptps(i) := PAR_LIT;
                plit_vals(i) := stim_to_stm_value(slc, ptfs(i), machine_value_width);
            elsif contains_dot(ptfs(i)) then
                ptps(i) := PAR_FQN;
                plit_vals(i) := to_unsigned(0, machine_value_width);
            else
                ptps(i) := PAR_NM;
                plit_vals(i) := to_unsigned(0, machine_value_width);
            end if;
        end loop;
    end procedure;

    function contains_dot(
        s : text_field
    ) return boolean is
        variable i : integer;
        variable r : boolean;
    begin
        r := false;
        i := 1;
        while s(i) /= nul loop
            if s(i) = '.' then
                r := true;
                exit;
            end if;
            i := i + 1;
        end loop;
        return r;
    end function;

    function bin2integer(
        slc : src_locator;
        bin_number : in text_field
    ) return integer is
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
                    assert false
                    report "bin2integer found non binary digit on line " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
                    severity failure;
            end case;
            temp_int := temp_int + (int_number * (2 ** power));
            power := power + 1;
        end loop;
        return temp_int;
    end function;

    function bin2stm_value(
        slc : src_locator;
        bin_number : text_field;
        machine_value_width : integer
    ) return unsigned is
        variable len : integer;
        variable temp_stm_value : unsigned(machine_value_width - 1 downto 0);
        variable vec_number : std_logic;
    begin
        len := fld_len(bin_number);
        temp_stm_value := to_unsigned(0, machine_value_width);
        for i in 1 to len loop
            case bin_number(i) is
                when '0' =>
                    vec_number := '0';
                when '1' =>
                    vec_number := '1';
                when others =>
                    assert false
                    report "bin2stm_value found non binary digit on line " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
                    severity failure;
            end case;
            temp_stm_value := temp_stm_value(machine_value_width - 2 downto 0) & vec_number;
        end loop;
        return temp_stm_value;
    end function;

    function c2int(
        c : character
    ) return integer is
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
                report "c2int was given a non number digit"
                severity failure;
        end case;
        return i;
    end function;

    function c2std_vec(
        c : character
    ) return std_logic_vector is
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
                report "c2std_vec found non hex digit on file line "
                severity failure;
                return "XXXX";
        end case;
    end function;

    function ew_str_cat(
        s1 : stm_text;
        s2 : text_field
    ) return stm_text is
        variable i : integer;
        variable j : integer;
        variable sr : stm_text;
    begin
        sr := s1;
        i := 1;
        while sr(i) /= nul loop
            i := i + 1;
        end loop;
        j := 1;
        while s2(j) /= nul loop
            sr(i) := s2(j);
            i := i + 1;
            j := j + 1;
        end loop;
        return sr;
    end function;
    
    function ew_str_cat_text_line(
        s1 : stm_text;
        s2 : text_line
    ) return stm_text is
        variable i : integer;
        variable j : integer;
        variable sr : stm_text;
    begin
        sr := s1;
        i := 1;
        while sr(i) /= nul loop
            i := i + 1;
        end loop;
        j := 1;
        while s2(j) /= nul and j < stm_text'length loop
            sr(i) := s2(j);
            i := i + 1;
            j := j + 1;
        end loop;
        return sr;
    end function;

    procedure ew_str_cat_ptr(
        variable s1 : in stm_text;
        variable s2_ptr : in text_field_ptr;
        variable so : out stm_text
    ) is
        variable i : integer;
        variable j : integer;
        variable sr : stm_text;
    begin
        sr := s1;
        i := 1;
        while sr(i) /= nul loop
            i := i + 1;
        end loop;
        j := 1;
        if s2_ptr /= null then
            while s2_ptr(j) /= nul loop
                sr(i) := s2_ptr(j);
                i := i + 1;
                j := j + 1;
            end loop;
        end if;
        so := sr;
    end procedure;

    function textfield_cat(
        s1 : text_field;
        s2 : text_field
    ) return text_field is
        variable i : integer;
        variable j : integer;
        variable sr : text_field;
    begin
        sr := s1;
        i := 1;
        while sr(i) /= nul loop
            i := i + 1;
        end loop;
        while s2(j) /= nul loop
            sr(i) := s2(j);
            i := i + 1;
            j := j + 1;
        end loop;
        return sr;
    end function;

    -- s  naaa.pbbb
    -- srn naaa
    -- srp pbbb
    procedure split_namespace_proc(
        s : in text_field;
        srn : out text_field;
        srp : out text_field    
    )  is
        variable i : integer;
        variable p : integer;
        variable in_namespace : boolean;
    begin
        i := 1;
        p := 1;
        in_namespace := true;
        while s(i) /= nul loop
            if in_namespace then
                if s(i) /= '.' then
                    srn(i) := s(i);
                else
                    in_namespace := false;
                end if;
            else
                srp(p) := s(i);
                p := p + 1;
            end if;
            i := i + 1;
        end loop;
    end procedure;

    function prepend_namespace(
        s : text_field;
        sp : text_field
    ) return text_field is
        variable i : integer;
        variable j : integer;
        variable sr : text_field;
    begin
        sr := sp;
        i := 1;
        while sr(i) /= nul loop
            i := i + 1;
        end loop;
        if i > 1 then
            sr(i) := '.';
            i := i + 1;
        end if;
        j := 1;
        while s(j) /= nul loop
            sr(i) := s(j);
            i := i + 1;
            j := j + 1;
        end loop;
        return sr;
    end function;

    function append_scope(
        s1 : text_field;
        s2 : text_field
    ) return text_field is
        variable i : integer;
        variable j : integer;
        variable sr : text_field;
    begin
        sr := s1;
        i := 1;
        while sr(i) /= nul loop
            i := i + 1;
        end loop;
        sr(i) := '.';
        i := i + 1;
        j := 1;
        while s2(j) /= nul loop
            sr(i) := s2(j);
            i := i + 1;
            j := j + 1;
        end loop;
        return sr;
    end function;

    function append_dot(
        s1 : text_field
    ) return text_field is
        variable i : integer;
        variable sr : text_field;
    begin
        sr := s1;
        i := 1;
        while sr(i) /= nul loop
            i := i + 1;
        end loop;
        sr(i) := '.';
        return sr;
    end function;

    function ew_str_cat(
        s1 : stm_text;
        s2 : text_field;
        s3 : integer
    ) return stm_text is
        variable i : integer;
        variable j : integer;
        variable sr : stm_text;
    begin
        sr := s1;
        i := 1;
        while sr(i) /= nul loop
            i := i + 1;
        end loop;
        j := s3;
        while s2(j) /= nul loop
            sr(i) := s2(j);
            i := i + 1;
            j := j + 1;
        end loop;
        return sr;
    end function;

    function ew_str_cat(
        s1 : stm_text;
        s2 : text_field;
        s3 : integer;
        s4 : character
    ) return stm_text is
        variable i : integer;
        variable j : integer;
        variable sr : stm_text;
    begin
        sr := s1;
        i := 1;
        while sr(i) /= nul loop
            i := i + 1;
        end loop;
        j := s3;
        while s2(j) /= nul loop
            sr(i) := s2(j);
            i := i + 1;
            j := j + 1;
        end loop;
        sr(i) := s4;
        return sr;
    end function;

    function ew_to_char(
        int : integer
    ) return character is
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
                assert false
                report "ew_to_char was given a non number digit"
                severity failure;
        end case;
        return c;
    end function;

    function ew_to_text_field(
        int : integer;
        b : base
    ) return text_field is
        variable temp : text_field;
        variable temp1 : text_field;
        variable radix : integer := 0;
        variable num : integer := 0;
        variable power : integer := 1;
        variable len : integer := 1;
        variable pre : string(1 to 2);
        variable ix : integer;
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
        if num < 0 and b = hex then
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
            for i in len downto 1 loop -- convert the number to
                temp(i) := ew_to_char(int / power mod radix); -- a string starting
                power := power * radix; -- with the right hand
            end loop; -- side.
        end if;
        -- add prefix if is one
        if pre(1) /= nul then
            temp1 := temp;
            ix := 1;
            j := 3;
            temp(1 to 2) := pre;
            while temp1(ix) /= nul loop
                temp(j) := temp1(ix);
                ix := ix + 1;
                j := j + 1;
            end loop;
        end if;
        return temp;
    end function;

    function ew_to_text_field(
        stmvalue : unsigned;
        b : base
    ) return text_field is
        variable temp : text_field;
        variable temp1 : text_field;
        variable radix : unsigned(stmvalue'length - 1 downto 0) := to_unsigned(1, stmvalue'length);
        variable num : unsigned(stmvalue'length - 1 downto 0) := to_unsigned(0, stmvalue'length);
        variable power : unsigned(stmvalue'length - 1 downto 0) := to_unsigned(1, stmvalue'length);
        variable len : integer := 1;
        variable pre : string(1 to 2);
        variable ix : integer;
        variable j : integer;
        variable cpval : unsigned(stmvalue'length - 1 downto 0) := to_unsigned(0, stmvalue'length);
    begin
        num := stmvalue;
        temp := (others => nul);
        case b is
            when bin =>
                radix := to_unsigned(2, stmvalue'length); -- depending on what
                pre := "0b";
            when oct =>
                radix := to_unsigned(8, stmvalue'length); -- base the number is
                pre := "0o";
            when hex =>
                radix := to_unsigned(16, stmvalue'length); -- to be displayed as
                pre := "0x";
            when dec =>
                radix := to_unsigned(10, stmvalue'length); -- choose a radix range
                pre := (others => nul);
        end case;
        while num >= radix loop -- determine how many
            len := len + 1; -- characters required
            num := num / radix; -- to represent the
        end loop; -- number.
        for i in len downto 1 loop -- convert the number to
            cpval := stmvalue / power mod radix;
            temp(i) := ew_to_char(to_integer(cpval(3 downto 0))); -- a string starting
            power := resize(power * radix, stmvalue'length); -- with the right hand
        end loop; -- side.

        -- add prefix if is one
        if pre(1) /= nul then
            temp1 := temp;
            ix := 1;
            j := 3;
            temp(1 to 2) := pre;
            while temp1(ix) /= nul loop
                temp(j) := temp1(ix);
                ix := ix + 1;
                j := j + 1;
            end loop;
        end if;
        return temp;
    end function;

    function fld_equal(
        s1 : string;
        s2 : string
    ) return boolean is
        variable i : integer := 0;
        variable s1_length : integer := 0;
        variable s2_length : integer := 0;
    begin
        s1_length := fld_len(s1);
        s2_length := fld_len(s2);

        if s1_length /= s2_length then
            return false;
        end if;
        while i /= s1_length loop
            i := i + 1;
            if s1(i) /= s2(i) then
                return false;
            end if;
        end loop;
        return true;
    end function;

    procedure fld_order(
        s1 : in text_field;
        s2 : in text_field;
        is_equ : out boolean;
        is_less : out boolean
    ) is
    begin
        is_equ := true;
        is_less := false;
        for i in 1 to text_field'length loop
            if s1(i) /= nul and s2(i) /= nul then
                if s1(i) < s2(i) then
                    is_less := true;
                    is_equ := false;
                    exit;
                elsif s1(i) > s2(i) then
                    is_less := false;
                    is_equ := false;
                    exit;
                end if;
            elsif s1(i) = nul and s2(i) /= nul then
                is_less := true;
                is_equ := false;
                exit;
            elsif s1(i) /= nul and s2(i) = nul then
                is_less := false;
                is_equ := false;
                exit;
            else
                exit;
            end if;
        end loop;
    end procedure;

    function order_is_less_than_failure_on_equal(
        slc : src_locator;
        s1 : text_field;
        s2 : text_field
    ) return boolean is
        variable is_equ : boolean;
        variable is_less : boolean;
    begin
        fld_order(s1, s2, is_equ, is_less);
        assert not is_equ
        report "attemping to add a duplicate var or proc definition " & " object name " & s1 & " file name " & crop(slc.file_name) & " file line " & integer'image(slc.file_line)
        severity failure;
        return is_less;
    end function;

    function fld_len(
        s : string
    ) return integer is
        variable i : integer := 1;
    begin
        while s(i) /= nul and i /= max_field_len loop
            i := i + 1;
        end loop;
        return (i - 1);
    end function;

    procedure get_line_from_str(
        variable s : in string;
        variable std_line : inout line
    ) is
    begin
        for i in 1 to s'length loop
            if s(i) /= nul then
                write(std_line, s(i));
            end if;
        end loop;
    end procedure;

    procedure get_stm_text_ptr_from_line(
        variable std_line : inout line;
        variable var_stm_text_ptr : inout stm_text_ptr
    ) is
        variable var_stm_text : stm_text;
        variable chr : character;
        variable good : boolean;
        variable tmp_std_line : line;
    begin
        tmp_std_line := new string'(std_line.all);
        for i in 1 to var_stm_text'length loop
            read(tmp_std_line, chr, good);
            if good then
                var_stm_text(i) := chr;
            else
                var_stm_text(i) := nul;
                exit;
            end if;
        end loop;
        stm_text_copy_to_ptr(var_stm_text_ptr, var_stm_text);
    end procedure;

    procedure random(
        variable seed1 : inout positive;
        variable seed2 : inout positive;
        variable rand : out real
    ) is
    begin
        uniform(seed1, seed2, rand);
    end procedure;

    procedure random(
        variable seed1 : inout positive;
        variable seed2 : inout positive;
        variable lowestvalue : in integer;
        variable utmostvalue : in integer;
        variable rand : out integer
    ) is
        variable randreal : real := 0.0;
        variable intdelta : integer := 0;
    begin
        intdelta := utmostvalue - lowestvalue;
        uniform(seed1, seed2, randreal); -- generate random number
        rand := integer(trunc(randreal * (real(intdelta) + 1.0))) + lowestvalue; -- rescale to delta, find integer part, adjust
    end procedure;

    procedure random(
        variable seed1 : inout positive;
        variable seed2 : inout positive;
        variable rand : out unsigned
    ) is
        constant size : integer := rand'length;
        -- Populate vector in 30-bit chunks to avoid exceeding the
        -- range of integer
        constant seg_size : natural := 30;
        constant segments : natural := size / seg_size;
        constant remainder : natural := size - segments * seg_size;
        variable lowestvalue : integer := 0;
        variable utmostvalue : integer := 0;
        variable rand_of_segment : integer := 0;
        variable result : unsigned(rand'range) := (others => '0');
    begin
        if segments > 0 then
            for s in 0 to segments - 1 loop
                lowestvalue := 0;
                utmostvalue := 2 ** seg_size - 1;
                random(seed1, seed2, lowestvalue, utmostvalue, rand_of_segment);
                result((s + 1) * seg_size - 1 downto s * seg_size) := to_unsigned(rand_of_segment, seg_size);
            end loop;
        end if;
        if remainder > 0 then
            lowestvalue := 0;
            utmostvalue := 2 ** remainder - 1;
            random(seed1, seed2, lowestvalue, utmostvalue, rand_of_segment);
            result(size - 1 downto size - remainder) := to_unsigned(rand_of_segment, remainder);
        end if;
        rand := result;
    end procedure;

    procedure random(
        variable seed1 : inout positive;
        variable seed2 : inout positive;
        variable lowestvalue : in unsigned;
        variable utmostvalue : in unsigned;
        variable rand : out unsigned
    ) is
        variable rand_full_range : unsigned(rand'range) := to_unsigned(0, rand'length);
        variable rand_delta_range : unsigned(rand'length * 2 - 1 downto 0) := to_unsigned(0, rand'length * 2);
        variable delta : unsigned(rand'range) := to_unsigned(0, rand'length);
        variable product : unsigned(rand'length * 2 - 1 downto 0) := to_unsigned(0, rand'length * 2);

    begin
        random(seed1, seed2, rand_full_range);
        delta := utmostvalue - lowestvalue;
        product := rand_full_range * delta;
        rand_delta_range := shift_right(product, rand'length);
        rand := lowestvalue + resize(rand_delta_range, rand'length);
    end procedure;

    function hex2integer(
        slc : src_locator;
        hex_number : text_field
    ) return integer is
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
                    assert false
                    report "hex2integer found non hex digit " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
                    severity failure;
            end case;
            temp_int := temp_int + (int_number * (16 ** power));
            power := power + 1;
        end loop;
        return temp_int;
    end function;

    function hex2stm_value(
        slc : src_locator;
        hex_number : text_field;
        machine_value_width : integer
    ) return unsigned is
        variable len : integer;
        variable temp_stm_value : unsigned(machine_value_width - 1 downto 0);
        variable vec_number : unsigned(3 downto 0);
    begin
        len := fld_len(hex_number);
        temp_stm_value := to_unsigned(0, machine_value_width);
        for i in 1 to len loop
            case hex_number(i) is
                when '0' =>
                    vec_number := x"0";
                when '1' =>
                    vec_number := x"1";
                when '2' =>
                    vec_number := x"2";
                when '3' =>
                    vec_number := x"3";
                when '4' =>
                    vec_number := x"4";
                when '5' =>
                    vec_number := x"5";
                when '6' =>
                    vec_number := x"6";
                when '7' =>
                    vec_number := x"7";
                when '8' =>
                    vec_number := x"8";
                when '9' =>
                    vec_number := x"9";
                when 'a' | 'A' =>
                    vec_number := x"A";
                when 'b' | 'B' =>
                    vec_number := x"B";
                when 'c' | 'C' =>
                    vec_number := x"C";
                when 'd' | 'D' =>
                    vec_number := x"D";
                when 'e' | 'E' =>
                    vec_number := x"E";
                when 'f' | 'F' =>
                    vec_number := x"F";
                when others =>
                    assert false
                    report "hex2stm_value found non hex digit " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
                    severity failure;
            end case;
            temp_stm_value := temp_stm_value(machine_value_width - 5 downto 0) & vec_number;

        end loop;
        return temp_stm_value;
    end function;

    function is_digit(
        constant c : character
    ) return boolean is
        variable rtn : boolean;
    begin
        if c >= '0' and c <= '9' then
            rtn := true;
        else
            rtn := false;
        end if;
        return rtn;
    end function;

    function is_txt_var_first_character(
        constant c : character
    ) return boolean is
        variable rtn : boolean;
    begin
        if c >= '0' and c <= '9' then
            rtn := true;
        elsif c >= 'A' and c <= 'Z' then
            rtn := true;
        elsif c >= 'a' and c <= 'z' then
            rtn := true;
        else
            rtn := false;
        end if;
        return rtn;
    end function;

    function is_space(
        constant c : character
    ) return boolean is
        variable rtn : boolean;
    begin
        if c = ' ' or c = ht then
            rtn := true;
        else
            rtn := false;
        end if;
        return rtn;
    end function;

    procedure init_text_field(
        variable sourcestr : in string;
        variable destfield : out text_field
    ) is
        variable tempfield : text_field;
    begin
        for i in 1 to sourcestr'length loop
            tempfield(i) := sourcestr(i);
        end loop;
        for i in 1 to text_field'length loop
            destfield(i) := tempfield(i);
        end loop;
    end procedure;

    procedure init_const_text_field(
        constant sourcestr : in string;
        variable destfield : out text_field
    ) is
        variable tempfield : text_field;
    begin
        for i in 1 to sourcestr'length loop
            tempfield(i) := sourcestr(i);
        end loop;
        for i in 1 to text_field'length loop
            destfield(i) := tempfield(i);
        end loop;
    end procedure;
    
    procedure init_text_line(
        variable sourcestr : in string;
        variable destfield : out text_line
    ) is
        variable tempfield : text_line;
    begin
        for i in 1 to sourcestr'length loop
            tempfield(i) := sourcestr(i);
        end loop;
        for i in 1 to text_line'length loop
            destfield(i) := tempfield(i);
        end loop;
    end procedure;

    procedure init_const_text_line(
        constant sourcestr : in string;
        variable destfield : out text_line
    ) is
        variable tempfield : text_line;
    begin
        for i in 1 to sourcestr'length loop
            tempfield(i) := sourcestr(i);
        end loop;
        for i in 1 to text_line'length loop
            destfield(i) := tempfield(i);
        end loop;
    end procedure;

    procedure print(
        s : in string
    ) is
        variable l : line;
    begin
        for i in 1 to s'length loop
            if s(i) /= nul then
                write(l, s(i));
            end if;
        end loop;
        writeline(output, l);
    end procedure;

    function std_vec2c(
        vec : std_logic_vector(3 downto 0)
    ) return character is
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
                report "std_vec2c found non-binary digit in vec "
                severity failure;
                return 'X';
        end case;
    end function;

    function stim_to_integer(
        slc : src_locator;
        field : text_field
    ) return integer is
        variable value : integer := 1;
        variable temp_str : text_field;
    begin
        if field(1) = '0' and (field(2) = 'x' or field(2) = 'b') then
            case field(2) is
                when 'x' =>
                    value := 3;
                    while field(value) /= nul loop
                        temp_str(value - 2) := field(value);
                        value := value + 1;
                    end loop;
                    -- assert(false)
                    -- report  "hex2integer " & temp_str
                    -- severity warning;
                    value := hex2integer(slc, temp_str);
                when 'b' =>
                    value := 3;
                    while field(value) /= nul loop
                        temp_str(value - 2) := field(value);
                        value := value + 1;
                    end loop;
                    value := bin2integer(slc, temp_str);
                when others =>
                    assert false
                    report "stim_to_integer strange number found, non hex digit " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
                    severity failure;
            end case;
        else
            value := str2integer(field);
        end if;
        return value;
    end function;

    function stim_to_stm_value(
        slc : src_locator;
        field : text_field;
        machine_value_width : integer
    ) return unsigned is
        variable stmvalue : unsigned(machine_value_width - 1 downto 0) := to_unsigned(1, machine_value_width);
        variable ci : integer := 1;
        variable temp_str : text_field;
    begin
        if field(1) = '0' and (field(2) = 'x' or field(2) = 'b') then
            case field(2) is
                when 'x' =>
                    ci := 3;
                    while field(ci) /= nul loop
                        temp_str(ci - 2) := field(ci);
                        ci := ci + 1;
                    end loop;
                    -- assert(false)
                    -- report  "hex2integer " & temp_str
                    -- severity warning;
                    stmvalue := hex2stm_value(slc, temp_str, machine_value_width);
                when 'b' =>
                    ci := 3;
                    while field(ci) /= nul loop
                        temp_str(ci - 2) := field(ci);
                        ci := ci + 1;
                    end loop;
                    stmvalue := bin2stm_value(slc, temp_str, machine_value_width);
                when others =>
                    assert false
                    report "stim_to_stm_value strange number found, non hex digit " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
                    severity failure;
            end case;
        else
            stmvalue := str2stm_value(field, machine_value_width);
        end if;
        return stmvalue;
    end function;

    procedure stm_user_file_open(
        variable slc : in src_locator;
        file file_handle : text;
        variable user_file_path_string : in stm_text;
        open_kind : in file_open_kind
    ) is
        variable v_stat : file_open_status;
        variable file_path_string : stm_text;
    begin
        file_path_string := stm_text_crop(user_file_path_string);
        file_open(v_stat, file_handle, file_path_string, open_kind);
        assert v_stat = open_ok
        report " file object not found " & " file name " & crop(slc.file_name) & " file line " & integer'image(slc.file_line)
        severity failure;
    end procedure;

    procedure stm_file_append(
        variable slc : src_locator;
        variable stm_lines : in stm_lines_ptr;
        variable file_path : in stm_text_ptr
    ) is
        variable v_stat : file_open_status;
        file user_file : text;
        variable std_line : line;
        variable position : integer;
        variable file_path_string : stm_text;
    begin
        txt_to_string(file_path, file_path_string);
        file_open(v_stat, user_file, stm_text_crop(file_path_string), append_mode);
        if v_stat /= open_ok then
            return;
        end if;
        for i in 0 to stm_lines.size - 1 loop
            position := i;
            stm_lines_get(slc, stm_lines, position, std_line);
            writeline(user_file, std_line);
        end loop;
        file_close(user_file);
    end procedure;

    procedure stm_file_appendable(
        variable file_path : in stm_text_ptr;
        variable status : out integer
    ) is
        variable v_stat : file_open_status;
        file user_file : text;
        variable file_path_string : stm_text;
    begin
        txt_to_string(file_path, file_path_string);
        file_open(v_stat, user_file, stm_text_crop(file_path_string), read_mode);
        if v_stat = open_ok then
            file_close(user_file);
        end if;
        status := stm_file_status(v_stat);
    end procedure;

    procedure stm_file_read_all(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable file_path : in stm_text_ptr
    ) is
        variable v_stat : file_open_status;
        file user_file : text;
        variable std_line : line;
        variable tmp_std_line : line;
        variable file_path_string : stm_text;
    begin
        txt_to_string(file_path, file_path_string);
        file_open(v_stat, user_file, stm_text_crop(file_path_string), read_mode);
        if v_stat /= open_ok then
            return;
        end if;
        while not endfile(user_file) loop
            readline(user_file, std_line);
            tmp_std_line := new string'(std_line.all);
            stm_lines_append(slc, stm_lines, tmp_std_line);
        end loop;
        file_close(user_file);
    end procedure;

    procedure stm_file_readable(
        variable file_path : in stm_text_ptr;
        variable status : out integer
    ) is
        variable v_stat : file_open_status;
        file user_file : text;
        variable file_path_string : stm_text;
    begin
        txt_to_string(file_path, file_path_string);
        file_open(v_stat, user_file, stm_text_crop(file_path_string), read_mode);
        if v_stat = open_ok then
            file_close(user_file);
        end if;
        status := stm_file_status(v_stat);
    end procedure;

    function stm_file_status(
        v_stat : file_open_status
    ) return integer is
    begin
        if v_stat = open_ok then
            return 0;
        elsif v_stat = status_error then
            return 1;
        elsif v_stat = name_error then
            return 2;
        elsif v_stat = mode_error then
            return 3;
        else
            return 4;
        end if;
    end function;

    procedure stm_file_write(
        variable slc : src_locator;
        variable stm_lines : in stm_lines_ptr;
        variable file_path : in stm_text_ptr
    ) is
        variable v_stat : file_open_status;
        file user_file : text;
        variable std_line : line;
        variable position : integer;
        variable file_path_string : stm_text;
    begin
        txt_to_string(file_path, file_path_string);
        file_open(v_stat, user_file, stm_text_crop(file_path_string), write_mode);
        if v_stat /= open_ok then
            return;
        end if;
        for i in 0 to stm_lines.size - 1 loop
            position := i;
            stm_lines_get(slc, stm_lines, position, std_line);
            writeline(user_file, std_line);
        end loop;
        file_close(user_file);
    end procedure;

    procedure stm_file_writeable(
        variable file_path : in stm_text_ptr;
        variable status : out integer
    ) is
        variable v_stat : file_open_status;
        file user_file : text;
        variable file_path_string : stm_text;
    begin
        txt_to_string(file_path, file_path_string);
        file_open(v_stat, user_file, stm_text_crop(file_path_string), write_mode);
        if v_stat = open_ok then
            file_close(user_file);
        end if;
        status := stm_file_status(v_stat);
    end procedure;

    procedure stm_lines_append(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable std_line : in line
    ) is
        variable lp : stm_line_ptr;
        variable nlp : stm_line_ptr;
        variable debug : boolean := false;
    begin
        if debug then
            print("stm_lines_append " & " file name " & crop(slc.file_name) & " file line " & integer'image(slc.file_line));
        end if;
        if stm_lines.size = 0 then
            lp := new stm_line;
            lp.line_number := 0;
            lp.line_content := std_line;
            lp.line_type := T_LINE_TEXT;
            lp.array_size := 0;
            lp.next_line_ptr := null;
            stm_lines.line_list := lp;
            stm_lines.size := 1;
        else
            lp := stm_lines.line_list;
            while lp.next_line_ptr /= null loop
                lp := lp.next_line_ptr;
            end loop;
            nlp := new stm_line;
            nlp.line_number := lp.line_number + 1;
            nlp.line_content := std_line;
            nlp.line_type := T_LINE_TEXT;
            nlp.array_size := 0;
            nlp.next_line_ptr := null;
            lp.next_line_ptr := nlp;
            stm_lines.size := stm_lines.size + 1;
        end if;
    end procedure;

    procedure stm_lines_append(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable stm_array : in stm_array_ptr;
        constant machine_value_width : in integer
    ) is
        variable lp : stm_line_ptr;
        variable std_line : line;
        variable nlp : stm_line_ptr;
        variable value_std_logic_vector : std_logic_vector(machine_value_width - 1 downto 0);
        variable debug : boolean := false;
    begin
        if debug then
            print("stm_lines_append " & " file name " & crop(slc.file_name) & " file line " & integer'image(slc.file_line));
        end if;
        for j in 0 to stm_array'length - 1 loop
            value_std_logic_vector := std_logic_vector(stm_array(j));
            hwrite(std_line, value_std_logic_vector, left, machine_value_width / 4 + 1);
        end loop;
        if stm_lines.size = 0 then
            lp := new stm_line;
            lp.line_number := 0;
            lp.line_content := std_line;
            lp.line_type := T_LINE_ARRAY;
            lp.array_size := stm_array'length;
            lp.next_line_ptr := null;
            stm_lines.line_list := lp;
            stm_lines.size := 1;
        else
            lp := stm_lines.line_list;
            while lp.next_line_ptr /= null loop
                lp := lp.next_line_ptr;
            end loop;
            nlp := new stm_line;
            nlp.line_number := lp.line_number + 1;
            nlp.line_content := std_line;
            nlp.line_type := T_LINE_ARRAY;
            nlp.array_size := stm_array'length;
            nlp.next_line_ptr := null;
            lp.next_line_ptr := nlp;
            stm_lines.size := stm_lines.size + 1;
        end if;
    end procedure;

    procedure stm_lines_append(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable var_stm_text : in stm_text_ptr
    ) is
        variable lp : stm_line_ptr;
        variable nlp : stm_line_ptr;
        variable std_line : line;
        variable debug : boolean := false;
    begin
        if debug then
            print("stm_lines_append " & " file name " & crop(slc.file_name) & " file line " & integer'image(slc.file_line));
        end if;
        stm_text_ptr_to_line(var_stm_text, std_line);
        if stm_lines.size = 0 then
            lp := new stm_line;
            lp.line_number := 0;
            lp.line_content := std_line;
            lp.line_type := T_LINE_TEXT;
            lp.array_size := 0;
            lp.next_line_ptr := null;
            stm_lines.line_list := lp;
            stm_lines.size := 1;
        else
            lp := stm_lines.line_list;
            while lp.next_line_ptr /= null loop
                lp := lp.next_line_ptr;
            end loop;
            nlp := new stm_line;
            nlp.line_number := lp.line_number + 1;
            nlp.line_content := std_line;
            nlp.line_type := T_LINE_TEXT;
            nlp.array_size := 0;
            nlp.next_line_ptr := null;
            lp.next_line_ptr := nlp;
            stm_lines.size := stm_lines.size + 1;
        end if;
    end procedure;

    procedure stm_lines_delete(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable position : in integer
    ) is
        variable lp : stm_line_ptr;
        variable lpb : stm_line_ptr := null;
        variable lpa : stm_line_ptr := null;
        variable valid : integer;
    begin
        valid := 0;
        lp := stm_lines.line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                lpa := lp.next_line_ptr;
                if lpb /= null and lpa /= null then
                    lpb.next_line_ptr := lpa;
                elsif lpb = null and lpa /= null then
                    stm_lines.line_list := lpa;
                elsif lpb /= null and lpa = null then
                    lpb.next_line_ptr := null;
                else
                    stm_lines.line_list := null;
                end if;
                deallocate(lp);
                stm_lines.size := stm_lines.size - 1;
                valid := 1;
                exit;
            end if;
            lpb := lp;
            lp := lp.next_line_ptr;
        end loop;
        assert valid = 1;
        report "stm_lines_delete at position not possible " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
        severity failure;
        lp := stm_lines.line_list;
        for i in 0 to stm_lines.size - 1 loop
            lp.line_number := i;
            lp := lp.next_line_ptr;
        end loop;
    end procedure;

    procedure stm_lines_get(
        variable slc : src_locator;
        variable stm_lines : in stm_lines_ptr;
        variable position : in integer;
        variable std_line : out line
    ) is
        variable lp : stm_line_ptr;
    begin
        lp := stm_lines.line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                std_line := new string'(lp.line_content.all);
                return;
            end if;
            lp := lp.next_line_ptr;
        end loop;
        assert false
        report "stm_lines_get line at position not possible " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
        severity failure;
    end procedure;

    procedure stm_lines_get(
        variable slc : src_locator;
        variable stm_lines : in stm_lines_ptr;
        variable position : in integer;
        variable stm_array : inout stm_array_ptr;
        variable number_found : out integer;
        constant machine_value_width : in integer
    ) is
        variable lp : stm_line_ptr;
        variable value_std_logic_vector : std_logic_vector(machine_value_width - 1 downto 0);
        variable success : boolean := true;
        variable array_index : integer := 0;
        variable tmp_std_line : line;
    begin
        lp := stm_lines.line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                tmp_std_line := new string'(lp.line_content.all);
                while success loop
                    hread(tmp_std_line, value_std_logic_vector, success);
                    if success then
                        stm_array(array_index) := unsigned(value_std_logic_vector);
                        array_index := array_index + 1;
                    end if;
                end loop;
                number_found := array_index;
                return;
            end if;
            lp := lp.next_line_ptr;
        end loop;
        assert false
        report "stm_lines_get array at position not possible " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
        severity failure;
    end procedure;

    procedure stm_lines_insert(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable position : in integer;
        variable var_stm_text : in stm_text_ptr
    ) is
        variable lp : stm_line_ptr;
        variable tmp_std_line : line;
        variable stm_line_new : stm_line_ptr := new stm_line;
        variable valid : integer;
    begin
        valid := 0;
        lp := stm_lines.line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                for j in 1 to var_stm_text'length loop
                    if var_stm_text(j) /= nul then
                        write(tmp_std_line, var_stm_text(j), left, 1);
                    else
                        exit;
                    end if;
                end loop;
                -- copy current stm_line to new stmline object
                stm_line_new.line_content := lp.line_content;
                stm_line_new.line_type := lp.line_type;
                stm_line_new.array_size := lp.array_size;
                stm_line_new.next_line_ptr := lp.next_line_ptr;
                -- set current stm_line to new content
                lp.line_content := tmp_std_line;
                lp.line_type := T_LINE_TEXT;
                lp.array_size := 0;
                lp.next_line_ptr := stm_line_new;
                stm_lines.size := stm_lines.size + 1;
                valid := 1;
                exit;
            end if;
            lp := lp.next_line_ptr;
        end loop;
        assert valid = 1
        report "stm_lines_insert text at position not possible " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
        severity failure;
        lp := stm_lines.line_list;
        for i in 0 to stm_lines.size - 1 loop
            lp.line_number := i;
            lp := lp.next_line_ptr;
        end loop;
    end procedure;

    procedure stm_lines_insert(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable position : integer;
        variable stm_array : in stm_array_ptr;
        constant machine_value_width : in integer
    ) is
        variable lp : stm_line_ptr;
        variable tmp_std_line : line;
        variable stm_line_new : stm_line_ptr := new stm_line;
        variable value_std_logic_vector : std_logic_vector(machine_value_width - 1 downto 0);
        variable valid : integer;
    begin
        valid := 0;
        lp := stm_lines.line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                for j in 0 to stm_array'length - 1 loop
                    value_std_logic_vector := std_logic_vector(stm_array(j));
                    hwrite(tmp_std_line, value_std_logic_vector, left, machine_value_width / 4 + 1);
                end loop;
                -- copy current stm_line to new stmline object
                stm_line_new.line_content := lp.line_content;
                stm_line_new.line_type := lp.line_type;
                stm_line_new.array_size := lp.array_size;
                stm_line_new.next_line_ptr := lp.next_line_ptr;
                -- set current stm_line to new content
                lp.line_content := tmp_std_line;
                lp.line_type := T_LINE_ARRAY;
                lp.array_size := stm_array'length;
                lp.next_line_ptr := stm_line_new;
                stm_lines.size := stm_lines.size + 1;
                valid := 1;
                exit;
            end if;
            lp := lp.next_line_ptr;
        end loop;
        assert valid = 1
        report "stm_lines_insert array at position not possible " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
        severity failure;
        lp := stm_lines.line_list;
        for i in 0 to stm_lines.size - 1 loop
            lp.line_number := i;
            lp := lp.next_line_ptr;
        end loop;
    end procedure;

    procedure stm_lines_print(
        variable stm_lines : in stm_lines_ptr
    ) is
        variable std_line : line;
        variable tmp_str_ptr : stm_text_ptr;
        variable lp : stm_line_ptr;
        variable tmp_std_line_print : line;
    begin
        lp := stm_lines.line_list;
        while lp /= null loop
            if lp.line_type = T_LINE_TEXT then
                std_line := lp.line_content;
                tmp_str_ptr := new stm_text;
                get_stm_text_ptr_from_line(std_line, tmp_str_ptr);
                stm_text_ptr_to_line(tmp_str_ptr, std_line);
                lp.line_content := std_line;
                txt_print(tmp_str_ptr);
            elsif lp.line_type = T_LINE_ARRAY then
                tmp_std_line_print := new string'(lp.line_content.all);
                writeline(output, tmp_std_line_print);
            end if;
            lp := lp.next_line_ptr;
        end loop;
    end procedure;

    procedure stm_lines_set(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable position : in integer;
        variable var_stm_text : in stm_text_ptr
    ) is
        variable lp : stm_line_ptr;
        variable std_line : line;
    begin
        lp := stm_lines.line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                for j in 1 to var_stm_text'length loop
                    if var_stm_text(j) /= nul then
                        write(std_line, var_stm_text(j), left, 1);
                    else
                        exit;
                    end if;
                end loop;
                lp.line_content := std_line;
                lp.line_type := T_LINE_TEXT;
                lp.array_size := 0;
                return;
            end if;
            lp := lp.next_line_ptr;
        end loop;
        assert false
        report "stm_lines_set text at position not possible " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
        severity failure;
    end procedure;

    procedure stm_lines_set(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable position : integer;
        variable stm_array : in stm_array_ptr;
        constant machine_value_width : in integer
    ) is
        variable lp : stm_line_ptr;
        variable std_line : line;
        variable value_std_logic_vector : std_logic_vector(machine_value_width - 1 downto 0);
    begin
        lp := stm_lines.line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                for j in 0 to stm_array'length - 1 loop
                    value_std_logic_vector := std_logic_vector(stm_array(j));
                    hwrite(std_line, value_std_logic_vector, left, machine_value_width / 4 + 1);
                end loop;
                lp.line_content := std_line;
                return;
            end if;
            lp := lp.next_line_ptr;
        end loop;
        assert false
        report "stm_lines_set array at position not possible " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
        severity failure;
    end procedure;

    function stm_text_crop(
        txt : stm_text
    ) return string is
        variable l : integer;
    begin
        l := stm_text_len(txt);
        return txt(1 to l);
    end function;

    function stm_text_len(
        s : stm_text
    ) return integer is
        variable i : integer := 1;
    begin
        while s(i) /= nul and i /= c_stm_text_len loop
            i := i + 1;
        end loop;
        return (i - 1);
    end function;

    procedure stm_text_ptr_to_line(
        variable var_stm_text : in stm_text_ptr;
        variable line_out : out line
    ) is
        variable std_line : line;
    begin
        for j in 1 to var_stm_text'length loop
            if var_stm_text(j) /= nul then
                write(std_line, var_stm_text(j), left, 1);
            else
                exit;
            end if;
        end loop;
        line_out := std_line;
    end procedure;

    procedure stm_text_ptr_truncate_trailing_quote(
        variable si : stm_text_ptr;
        variable so : inout stm_text_ptr
    ) is
        variable i : integer := 1;
        variable o : integer := 1;
    begin
        while si(i) /= nul and i /= max_str_len loop
            if i + 1 /= max_str_len then
                if si(i + 1) /= nul then
                    if si(i) = '\' and si(i + 1) = '"' then -- "
                        -- skip '/' before '"'    "
                        i := i + 1;
                        so(o) := si(i);
                        i := i + 1;
                        o := o + 1;
                    else
                        -- don't skip '/' before others but '"'    "
                        if si(i) = '"' then -- this is the trailing '"'    "
                            exit;
                        end if;
                        so(o) := si(i);
                        i := i + 1;
                        o := o + 1;
                    end if;
                else
                    if si(i) = '"' then -- this is the trailing '"'    "
                        exit;
                    end if;
                    so(o) := si(i);
                    i := i + 1;
                    o := o + 1;
                end if;
            else
                if si(i) = '"' then -- this is the trailing '"'    "
                    exit;
                end if;
                so(o) := si(i);
                i := i + 1;
                o := o + 1;
            end if;
        end loop;
    end procedure;

    function str2integer(
        str : string
    ) return integer is
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

    function str2stm_value(
        str : string;
        machine_value_width : integer
    ) return unsigned is
        variable l : integer;
        variable rtn : unsigned(machine_value_width - 1 downto 0) := to_unsigned(0, machine_value_width);
    begin
        l := fld_len(str);
        for i in 1 to l loop
            rtn := resize(rtn * 10 + c2int(str(i)), machine_value_width);
        end loop;
        return rtn;
    end function;

    function text_line_crop(
        txt : text_line
    ) return string is
        variable l : integer;
    begin
        l := text_line_len(txt);
        return txt(1 to l);
    end function;

    function crop(
        s : string
    ) return string is
        variable i : integer := 1;
    begin
        while s(i) /= nul and i /= max_str_len loop
            i := i + 1;
        end loop;
        return s(1 to i - 1);
    end function;

    function text_line_len(
        s : text_line
    ) return integer is
        variable i : integer := 1;
    begin
        while s(i) /= nul and i /= max_str_len loop
            i := i + 1;
        end loop;
        return (i - 1);
    end function;

    procedure txt_print(
        variable ptr : in stm_text_ptr
    ) is
        variable txt_str : stm_text;
    begin
        if ptr /= null then
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

    procedure txt_ptr_copy(
        variable ptr : in stm_text_ptr;
        variable ptr_o : out stm_text_ptr;
        variable txt_str : in stm_text
    ) is
        variable ptr_temp : stm_text_ptr;
    begin
        ptr_temp := ptr;
        if ptr_temp /= null then
            for i in 1 to c_stm_text_len loop
                if txt_str(i) = nul then
                    exit;
                end if;
                ptr_temp(i) := txt_str(i);
            end loop;
        end if;
        ptr_o := ptr_temp;
    end procedure;

    procedure txt_to_string(
        variable ptr : in stm_text_ptr;
        variable str : out stm_text
    ) is
        variable txt_str : stm_text;
    begin
        txt_str := (others => nul);
        if ptr /= null then
            for i in 1 to c_stm_text_len loop
                if (ptr(i) = nul) then
                    exit;
                end if;
                txt_str(i) := ptr(i);
            end loop;
            str := txt_str;
        end if;
    end procedure;

    procedure text_field_ptr_to_text_field(
        variable ptr : in text_field_ptr;
        variable field : out text_field
    ) is
        variable tmp_field : text_field;
    begin
        tmp_field := (others => nul);
        if ptr /= null then
            for i in 1 to field'length loop
                if (ptr(i) = nul) then
                    exit;
                end if;
                tmp_field(i) := ptr(i);
            end loop;
            field := tmp_field;
        end if;
    end procedure;

    procedure text_field_to_text_field_ptr(
        variable field : in text_field;
        variable ptr : inout text_field_ptr
    ) is
    begin
        for i in 1 to field'length loop
            ptr(i) := field(i);
        end loop;
    end procedure;

    function text_field_to_string(
        tf : text_field
    ) return string is
        variable os : string(1 to fld_len(tf));
    begin
        for i in 1 to fld_len(tf) loop
            os(i) := tf(i);
        end loop;
        return os;
    end function;

    function string_to_text_field(
        s : string
    ) return text_field is
        variable otf : text_field;
    begin
        for i in 1 to s'length loop
            otf(i) := s(i);
        end loop;
        return otf;
    end function;
    
    function string_to_text_line(
        s : string
    ) return text_line is
        variable otl : text_line;
    begin
        for i in 1 to s'length loop
            otl(i) := s(i);
        end loop;
        return otl;
    end function;

    procedure stm_text_copy_to_ptr(
        variable ptr : inout stm_text_ptr;
        variable txt_str : in stm_text
    ) is
    begin
        if ptr /= null then
            for i in 1 to c_stm_text_len loop
                if txt_str(i) = nul then
                    exit;
                end if;
                ptr(i) := txt_str(i);
            end loop;
        end if;
    end procedure;

    function to_text_field_hex(
        int : integer
    ) return text_field is
    begin
        return ew_to_text_field(int, hex);
    end function;

    function to_text_field(
        int : integer
    ) return text_field is
    begin
        return ew_to_text_field(int, dec);
    end function;

    function to_text_field_hex(
        stmvalue : unsigned
    ) return text_field is
    begin
        return ew_to_text_field(stmvalue, hex);
    end function;

    function to_text_field(
        stmvalue : unsigned
    ) return text_field is
    begin
        return ew_to_text_field(stmvalue, dec);
    end function;

    procedure dump_text_line(
        variable tl : in text_line;
        constant prefix : in string
    ) is
        constant chunk_size : integer := 64;
        variable l : integer;
        variable row_str : line;
    begin
        l := text_line_len(tl);
        print(prefix & tl(1 to l));
        for i in 0 to l / chunk_size loop
            if tl(i * chunk_size + 1) /= nul then
                row_str := null;
                for j in 1 to chunk_size loop
                    exit when (i * chunk_size + j) > l;
                    if j > 1 then
                        write(row_str, string'(" "));
                    end if;
                    write(row_str, integer'image(character'pos(tl(i * chunk_size + j))));
                end loop;
                print(row_str.all);
                deallocate(row_str);
            end if;
        end loop;
    end procedure;

end package body;
