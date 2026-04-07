import os
import re

base = r'c:\git_wsl\SimStm\src\vhdl'

# Short one-line descriptions, keyed by filename
short_desc = {
    'tb_base_pkg.vhd':
        'Base types, constants and helper subprogram declarations used by the SimStm runtime.',
    'tb_base_pkg_body.vhd':
        'Base helper subprogram implementations used by the SimStm runtime.',
    'tb_bus_avalon.vhd':
        'Avalon-MM bus helper package used by SimStm bus access instructions.',
    'tb_bus_axi4lite.vhd':
        'AXI4-Lite bus helper package used by SimStm bus access instructions.',
    'tb_bus_ram.vhd':
        'Simple RAM bus helper package used by SimStm bus access instructions.',
    'tb_bus_wishbone.vhd':
        'Wishbone bus helper package used by SimStm bus access instructions.',
    'tb_instructions_pkg.vhd':
        'Instruction mnemonics and related constants used by the SimStm interpreter.',
    'tb_instructions_pkg_body.vhd':
        'Implementation of helper functions around instruction parsing and handling.',
    'tb_interpreter_pkg.vhd':
        'Public interpreter API for parsing stimulus files and executing SimStm instructions.',
    'tb_interpreter_pkg_body.vhd':
        'Interpreter implementation for parsing stimulus files and executing SimStm instructions.',
    'tb_interpreter_util_pkg.vhd':
        'Interpreter utility types and helper subprogram declarations.',
    'tb_interpreter_util_pkg_body.vhd':
        'Interpreter utility helper subprogram implementations.',
    'tb_simstm.vhd':
        'SimStm testbench top-level entity. It reads SimStm stimulus files (*.stm),\n'
        '--   parses and validates them, builds instruction/variable/procedure tables,\n'
        '--   and executes the stimuli.',
}

SEP = '-' * 79

for filename, desc in short_desc.items():
    path = os.path.join(base, filename)
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    is_new = 'Created by Eccelerators' in content

    # Pattern: optional pre-line (any -- comment before the banner), then the full header block
    if is_new:
        old_pat = (
            r'(?:^--[^\n]*\n)?'          # optional pre-line
            r'(?m)^-{79}\r?\n'
            r'-- SimStm\r?\n'
            r'--\r?\n'
            r'-- SPDX-License-Identifier: Apache-2\.0\r?\n'
            r'--\r?\n'
            r'-- Copyright:\r?\n'
            r'--   - Created by Eccelerators\r?\n'
            r'--\r?\n'
            r'-- Description:\r?\n'
            r'(?:--[^\n]*\n)+'           # one or more description lines
            r'-{79}'
        )
        new_header = (
            SEP + '\n'
            '-- SimStm\n'
            '--\n'
            '-- SPDX-License-Identifier: Apache-2.0\n'
            '--\n'
            '-- Copyright:\n'
            '--   - Created by Eccelerators\n'
            '--\n'
            '-- Description:\n'
            '--   ' + desc + '\n'
            '--\n'
            + SEP
        )
    else:
        # Check if there is an upstream reference line
        has_upstream = 'Upstream reference' in content

        if has_upstream:
            old_pat = (
                r'(?:^--[^\n]*\n)?'      # optional pre-line
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
                r'(?:--[^\n]*\n)+'
                r'-- Upstream reference:\r?\n'
                r'--   https://github\.com/sckoarn/VHDL-Test-Bench\r?\n'
                r'-{79}'
            )
            new_header = (
                SEP + '\n'
                '-- SimStm\n'
                '--\n'
                '-- SPDX-License-Identifier: Apache-2.0\n'
                '--\n'
                '-- Copyright:\n'
                '--   - Original work derived from VHDL-Test-Bench (Ken Campbell)\n'
                '--   - Subsequent modifications: Eccelerators\n'
                '--\n'
                '-- Description:\n'
                '--   ' + desc + '\n'
                '--\n'
                '-- Upstream reference:\n'
                '--   https://github.com/sckoarn/VHDL-Test-Bench\n'
                + SEP
            )
        else:
            # tb_base_pkg_body.vhd had no upstream reference after the verbose edit
            old_pat = (
                r'(?:^--[^\n]*\n)?'
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
                r'(?:--[^\n]*\n)+'
                r'-{79}'
            )
            new_header = (
                SEP + '\n'
                '-- SimStm\n'
                '--\n'
                '-- SPDX-License-Identifier: Apache-2.0\n'
                '--\n'
                '-- Copyright:\n'
                '--   - Original work derived from VHDL-Test-Bench (Ken Campbell)\n'
                '--   - Subsequent modifications: Eccelerators\n'
                '--\n'
                '-- Description:\n'
                '--   ' + desc + '\n'
                '--\n'
                '-- Upstream reference:\n'
                '--   https://github.com/sckoarn/VHDL-Test-Bench\n'
                + SEP
            )

    new_content = re.sub(old_pat, new_header, content, count=1, flags=re.DOTALL | re.MULTILINE)
    if new_content == content:
        print(f'WARNING: no match in {filename}')
    else:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'OK: {filename}')
