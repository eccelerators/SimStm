-- ******************************************************************************
-- 
--                   /------o
--             eccelerators
--          o------/
-- 
--  This file is an Eccelerators GmbH sample project.
-- 
--  MIT License:
--  Copyright (c) 2023 Eccelerators GmbH
-- 
--  Permission is hereby granted, free of charge, to any person obtaining a copy
--  of this software and associated documentation files (the "Software"), to deal
--  in the Software without restriction, including without limitation the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
-- 
--  The above copyright notice and this permission notice shall be included in all
--  copies or substantial portions of the Software.
-- 
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--  SOFTWARE.
-- ******************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package basic is

    type array_of_std_logic_vector is array (natural range <>) of std_logic_vector;

    type array_of_signed is array (natural range <>) of signed;

    type array_of_unsigned is array (natural range <>) of unsigned;
    
    function get_num_bits (arg : natural) return natural;

    function array_element_counter_length(arg : std_logic_vector) return natural;

    function array_element_counter_length(arg : signed) return natural;

    function array_element_counter_length(arg : unsigned) return natural;
    
    function array_element_counter_length(arg : array_of_std_logic_vector) return natural;

    function array_element_counter_length(arg : array_of_signed) return natural;

    function array_element_counter_length(arg : array_of_unsigned) return natural;


end package;


package body basic is

    function get_num_bits (arg : natural) return natural is
        variable nbits : natural;
        variable n : natural;
    begin
        n := arg;
        nbits := 1;
        while n > 1 loop
            nbits := nbits+1;
            n := n / 2;
        end loop;
        return nbits;
    end function;

    function array_element_counter_length(arg : std_logic_vector) return natural is
    begin
        return get_num_bits(arg'length);
    end function;

    function array_element_counter_length(arg : signed) return natural is
    begin
        return get_num_bits(arg'length);
    end function;
    
    function array_element_counter_length(arg : unsigned) return natural is
    begin
        return get_num_bits(arg'length);
    end function;
    
    function array_element_counter_length(arg : array_of_std_logic_vector) return natural is
    begin
        return get_num_bits(arg'length);
    end function;

    function array_element_counter_length(arg : array_of_signed) return natural is
    begin
        return get_num_bits(arg'length);
    end function;
    
    function array_element_counter_length(arg : array_of_unsigned) return natural is
    begin
        return get_num_bits(arg'length);
    end function;


end package body;
