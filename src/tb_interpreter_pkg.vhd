-------------------------------------------------------------------------------
--             Copyright 2007  Ken Campbell
-------------------------------------------------------------------------------
-- $Author: sckoarn $
--
-- $Date: 2008-02-24 01:34:11 $
--
-- $Name: not supported by cvs2svn $
--
-- $Id: tb_pkg_header.vhd,v 1.4 2008-02-24 01:34:11 sckoarn Exp $
--
-- $Source: /home/marcus/revision_ctrl_test/oc_cvs/cvs/vhld_tb/source/tb_pkg_header.vhd,v $
--
-- Description :  The the testbench package header file.
--                Initial GNU release.
--
------------------------------------------------------------------------------
--This file is part of The VHDL Test Bench.
--
--    The VHDL Test Bench is free software; you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation; either version 2 of the License, or
--    (at your option) any later version.
--
--    The VHDL Test Bench is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with The VHDL Test Bench; if not, write to the Free Software
--    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
-------------------------------------------------------------------------------
-- Revision History:
-- $Log: not supported by cvs2svn $
-- Revision 1.3  2007/09/02 04:04:04  sckoarn
-- Update of version 1.2 tb_pkg
-- See documentation for details
--
-- Revision 1.2  2007/08/21 02:43:14  sckoarn
-- Fix package definition to match with body
--
-- Revision 1.1.1.1  2007/04/06 04:06:48  sckoarn
-- Import of the vhld_tb
--
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

use work.tb_pkg_basics.all;

package tb_interpreter_pkg_body is

    -- define_instruction
    --    inputs     file_name  the file to be read from
    --
    --    output     file_line  a line of text from the file
    procedure define_instruction(variable inst_set : inout inst_def_ptr;
                                 constant inst : in string;
                                 constant args : in integer);

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

    --  index_array
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               array
    --               valid  is 1 if valid 0 if not
    procedure index_array(variable var_list : in var_field_ptr;
                          variable index : in integer;
                          variable array_object_ptr : out t_array_object_ptr;
                          variable valid : out integer);

    --  index_file
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               file record
    --               valid  is 1 if valid 0 if not
    procedure index_file(variable var_list : in var_field_ptr;
                         variable index : in integer;
                         variable file_object : out text_field;
                         variable valid : out integer);
                       
    --  index_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               lines object
    --               valid  is 1 if valid 0 if not
    procedure index_lines(variable var_list : in var_field_ptr;
                         variable index : in integer;
                         variable lines_object_ptr : out t_lines_object_ptr;
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
    procedure update_array(variable var_list : in var_field_ptr;
                           variable index : in integer;
                           variable array_object_ptr : in t_array_object_ptr;
                           variable valid : out integer);
                           
    --  update_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               new lines
    --               valid  is 1 if valid 0 if not
    procedure update_array(variable var_list : in var_field_ptr;
                           variable index : in integer;
                           variable lines_object_ptr : in t_lines_object_ptr;
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

end package;

