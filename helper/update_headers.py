import os
import re

base = r'c:\git_wsl\SimStm\src\vhdl'

updates = {
    'tb_base_pkg.vhd': {
        'pre': '-- SimStm base package \u2014 core types, constants and helper subprogram declarations.',
        'desc': (
            'This package is the type and subprogram foundation that the entire SimStm\n'
            '--   runtime builds upon. It declares the fundamental data types (text_field,\n'
            '--   text_line, stm_text, stm_text_ptr, src_locator, base, stm_var_type,\n'
            '--   stm_inst_initial_context, stm_runtime_context, inst_element and the\n'
            '--   various pool/sequence/list record types), the global constants (max field\n'
            '--   and string widths, pool capacities), and the full set of helper subprogram\n'
            '--   prototypes whose bodies live in tb_base_pkg_body.vhd.\n'
            '--\n'
            '--   All other SimStm packages depend on tb_base_pkg. End users should not\n'
            '--   modify this file; user-visible customization lives in src_to_customize/.'
        ),
    },
    'tb_bus_avalon.vhd': {
        'pre': '-- SimStm Avalon-MM bus package \u2014 signal types and bus-cycle helper procedures.',
        'desc': (
            'This package declares the Avalon Memory-Mapped (Avalon-MM) signal record\n'
            '--   types and the bus-cycle helper procedures (read, write, wait-for-idle)\n'
            '--   used by the SimStm bus access instructions when the target bus is\n'
            '--   configured as Avalon-MM.\n'
            '--\n'
            '--   The package is generic over address width (G_ADDR_W) and data width\n'
            '--   (G_DATA_W) so it can be instantiated for any word size. It exposes the\n'
            '--   full Avalon-MM handshake signals (address, byteenable, read, readdata,\n'
            '--   readdatavalid, write, writedata, waitrequest) as a record so they can\n'
            '--   be passed as a single port aggregate into the DUT interface.'
        ),
    },
    'tb_bus_axi4lite.vhd': {
        'pre': '-- SimStm AXI4-Lite bus package \u2014 signal types and bus-cycle helper procedures.',
        'desc': (
            'This package declares the AXI4-Lite signal record types and the bus-cycle\n'
            '--   helper procedures (read, write, wait-for-completion) used by the SimStm\n'
            '--   bus access instructions when the target bus is configured as AXI4-Lite.\n'
            '--\n'
            '--   The package is generic over address width (G_ADDR_W) and data width\n'
            '--   (G_DATA_W). It models the five AXI4-Lite channels (AW, W, B, AR, R) as\n'
            '--   separate master- and slave-side signal records, keeping the interface\n'
            '--   aligned with the ARM AMBA AXI4-Lite specification. The helper procedures\n'
            '--   drive the channels through the standard valid/ready handshake and handle\n'
            '--   the address, data and response phases in sequence.'
        ),
    },
    'tb_bus_ram.vhd': {
        'pre': '-- SimStm simple RAM bus package \u2014 signal types and bus-cycle helper procedures.',
        'desc': (
            'This package declares signal record types and bus-cycle helper procedures\n'
            '--   for a simple synchronous SRAM-style interface (address, data, write-\n'
            '--   enable, chip-select, output-enable). It is used by the SimStm bus access\n'
            '--   instructions when the target memory is a plain RAM without a full\n'
            '--   interconnect protocol.\n'
            '--\n'
            '--   The package is generic over address width (G_ADDR_W) and data width\n'
            '--   (G_DATA_W). The byte-enable width C_WE_W is derived automatically as\n'
            '--   G_DATA_W / 8. Helper procedures implement single-cycle read and write\n'
            '--   transactions that drive the RAM control signals and sample the read-data\n'
            '--   path.'
        ),
    },
    'tb_bus_wishbone.vhd': {
        'pre': '-- SimStm Wishbone bus package \u2014 signal types and bus-cycle helper procedures.',
        'desc': (
            'This package declares the Wishbone B4 signal record types and the bus-cycle\n'
            '--   helper procedures (read, write, wait-for-ack) used by the SimStm bus\n'
            '--   access instructions when the target bus is configured as Wishbone.\n'
            '--\n'
            '--   The package is generic over address width (G_ADDR_W) and data width\n'
            '--   (G_DATA_W). The strobe width C_SEL_W is derived as G_DATA_W / 8. The\n'
            '--   helper procedures implement the classic Wishbone handshake: CYC and STB\n'
            '--   are asserted together at the start of a cycle; the transaction completes\n'
            '--   on ACK; WE distinguishes write from read cycles. STALL-based pipelined\n'
            '--   transfers are also supported.'
        ),
    },
    'tb_instructions_pkg.vhd': {
        'pre': '-- SimStm instructions package \u2014 mnemonic constants and instruction-set declarations.',
        'desc': (
            'This package defines the complete SimStm instruction set as a set of\n'
            '--   string constants (one per mnemonic, e.g. "inst_if", "inst_call",\n'
            '--   "inst_bus_write") together with the inst_def_list initialisation data\n'
            '--   that maps each mnemonic to its expected argument count.\n'
            '--\n'
            '--   The interpreter (tb_interpreter_pkg_body.vhd) uses these constants both\n'
            '--   at parse time, to recognise tokens as instruction names, and at execution\n'
            '--   time, to dispatch to the appropriate handler. Adding a new instruction\n'
            '--   requires entries in this package as well as a handler in the interpreter\n'
            '--   body. End users should not modify this file.'
        ),
    },
    'tb_instructions_pkg_body.vhd': {
        'pre': '-- SimStm instructions package body \u2014 instruction-set initialisation implementation.',
        'desc': (
            'This file provides the package body for tb_instructions_pkg. Its primary\n'
            '--   responsibility is to implement init_inst_def_list, which populates the\n'
            '--   inst_def_list structure with a record for every supported mnemonic:\n'
            '--   the mnemonic string itself, the minimum and maximum number of arguments\n'
            '--   it accepts, and the instruction code used internally by the interpreter.\n'
            '--\n'
            '--   The list is built once during the elaboration-time first pass and then\n'
            '--   consulted by the parser on every stimulus-file line to validate the\n'
            '--   mnemonic and argument count before an inst_element is appended to the\n'
            '--   instruction sequence.'
        ),
    },
    'tb_interpreter_pkg.vhd': {
        'pre': '-- SimStm interpreter package \u2014 public API for stimulus-file parsing and execution.',
        'desc': (
            'This package exposes the top-level procedures that tb_simstm calls to\n'
            '--   drive the simulation: load_stm_file (first-pass parser that reads the\n'
            '--   stimulus script and builds the instruction sequence, variable pool,\n'
            '--   procedure pool and file-definition list) and execute_instruction (the\n'
            '--   main dispatch loop that walks the instruction sequence and calls the\n'
            '--   appropriate handler for each mnemonic).\n'
            '--\n'
            '--   Both procedures are generic so they can be instantiated with the\n'
            '--   user-supplied bus and signal packages without requiring access to their\n'
            '--   internals. The full implementation lives in tb_interpreter_pkg_body.vhd.'
        ),
    },
    'tb_interpreter_pkg_body.vhd': {
        'pre': '-- SimStm interpreter package body \u2014 stimulus-file parser and instruction executor.',
        'desc': (
            'This file is the largest and most complex in the SimStm framework. It\n'
            '--   implements the two procedures declared in tb_interpreter_pkg:\n'
            '--\n'
            '--   load_stm_file performs the elaboration-time first pass over the stimulus\n'
            '--   script. It tokenises each line, resolves include directives recursively,\n'
            '--   builds the variable and procedure pools, records jump-label positions,\n'
            '--   and appends every parsed statement to the instruction sequence.\n'
            '--\n'
            '--   execute_instruction is the simulation-time main loop. It walks the\n'
            '--   instruction sequence from index 0 and dispatches each instruction to its\n'
            '--   handler: arithmetic and comparison operations update the variable pool;\n'
            '--   control-flow instructions (if/else/end_if, for/end_for, while/end_while,\n'
            '--   call/return, jump) alter the program counter; bus-access instructions\n'
            '--   delegate to the user bus package; file and print instructions invoke the\n'
            '--   stm_lines helpers; and assert/verify instructions report pass/fail via\n'
            '--   the tb_limits_pkg thresholds. Simulation terminates via std.env.finish\n'
            '--   when the end of the script is reached or a fatal assertion fires.'
        ),
    },
    'tb_interpreter_util_pkg.vhd': {
        'pre': '-- SimStm interpreter utility package \u2014 shared types and utility subprogram declarations.',
        'desc': (
            'This package provides the auxiliary types and subprogram declarations that\n'
            '--   are shared between the interpreter and its helpers but do not belong in\n'
            '--   the base package. It declares the token-array type\n'
            '--   (token_text_field_array), the parameter-extraction helper\n'
            '--   (extract_parameters), and the set of line-parsing procedures used by the\n'
            '--   first-pass parser and the runtime executor (e.g. parse_line,\n'
            '--   get_next_token, skip_white_space, stm_text_substition_of_vars).\n'
            '--\n'
            '--   The bodies of all declared subprograms live in\n'
            '--   tb_interpreter_util_pkg_body.vhd.'
        ),
    },
    'tb_interpreter_util_pkg_body.vhd': {
        'pre': '-- SimStm interpreter utility package body \u2014 line-parsing and token-handling implementations.',
        'desc': (
            'This file provides the package body for tb_interpreter_util_pkg. It\n'
            '--   implements the line-level parsing utilities used by both the first-pass\n'
            '--   loader and the runtime executor:\n'
            '--\n'
            '--   parse_line tokenises a single stimulus-file line into up to seven\n'
            '--   text_field tokens, stripping comments and handling quoted strings.\n'
            '--   get_next_token advances a character-level cursor through a line buffer.\n'
            '--   skip_white_space consumes leading spaces and tabs.\n'
            '--   stm_text_substition_of_vars scans a stm_text string and replaces every\n'
            '--   $variable reference with the current value from the variable pool.\n'
            '--\n'
            '--   These utilities are kept separate from the main interpreter body to\n'
            '--   reduce compilation-order coupling and to make the parsing logic easier\n'
            '--   to review and test in isolation.'
        ),
    },
}

SEP = '-' * 79

for filename, info in updates.items():
    path = os.path.join(base, filename)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    is_new = 'Created by Eccelerators' in content

    if is_new:
        new_header = (
            info['pre'] + '\n'
            + SEP + '\n'
            '-- SimStm\n'
            '--\n'
            '-- SPDX-License-Identifier: Apache-2.0\n'
            '--\n'
            '-- Copyright:\n'
            '--   - Created by Eccelerators\n'
            '--\n'
            '-- Description:\n'
            '--   ' + info['desc'] + '\n'
            '--\n'
            + SEP
        )
        old_pat = (
            r'(?m)^-{79}\r?\n'
            r'-- SimStm\r?\n'
            r'--\r?\n'
            r'-- SPDX-License-Identifier: Apache-2\.0\r?\n'
            r'--\r?\n'
            r'-- Copyright:\r?\n'
            r'--   - Created by Eccelerators\r?\n'
            r'--\r?\n'
            r'-- Description:\r?\n'
            r'--   .*?\r?\n'
            r'--\r?\n'
            r'-{79}'
        )
    else:
        new_header = (
            info['pre'] + '\n'
            + SEP + '\n'
            '-- SimStm\n'
            '--\n'
            '-- SPDX-License-Identifier: Apache-2.0\n'
            '--\n'
            '-- Copyright:\n'
            '--   - Original work derived from VHDL-Test-Bench (Ken Campbell)\n'
            '--   - Subsequent modifications: Eccelerators\n'
            '--\n'
            '-- Description:\n'
            '--   ' + info['desc'] + '\n'
            '--\n'
            '-- Upstream reference:\n'
            '--   https://github.com/sckoarn/VHDL-Test-Bench\n'
            + SEP
        )
        old_pat = (
            r'(?m)^-{79}\r?\n'
            r'-- SimStm\r?\n'
            r'--\r?\n'
            r'-- SPDX-License-Identifier: Apache-2\.0\r?\n'
            r'--\r?\n'
            r'-- Copyright:\r?\n'
            r'--   - Original work derived from VHDL-Test-Bench \(Ken Campbell\)\r?\n'
            r'--   - Subsequent modifications: Eccelerators\r?\n'
            r'--\r?\n'
            r'-- Description:\r?\n'
            r'(?:--   .*?\r?\n)+'
            r'(?:--\r?\n)?'
            r'-- Upstream reference:\r?\n'
            r'--   https://github\.com/sckoarn/VHDL-Test-Bench\r?\n'
            r'-{79}'
        )

    new_content = re.sub(old_pat, new_header, content, count=1, flags=re.DOTALL)
    if new_content == content:
        print(f'WARNING: no match in {filename}')
    else:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'OK: {filename}')
