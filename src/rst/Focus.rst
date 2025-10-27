
Focus
-----

It is common practice to use the file I/O features of VHDL for VHDL
testbenches. Typically, each developer creates their own format for
commands in an input stimuli text file, along with a unique file name
and extension. The command set is focused on the tasks currently being
solved.

The general advantage of this technique is that the VHDL code of the
testbench doesn't need to be changed and recompiled for different
stimuli command sets. Different command set files can be presented to
the VHDL testbench, or command files can be interactively changed during
debugging.

While the advantage of not having to recompile the VHDL testbench has
decreased due to increased computer and tool performance, a major part
of the advantage remains valid for reusability and having a first
decoupled level of abstraction for stimuli above the VHDL code.

This is particularly applicable to CPUs attached or integrated into
components under development. For example, an IP such as an
I2C-controller with a HW/SW interface can be tested with the same
stimuli, whether attached to an AXI-bus in a SOC of the latest
generation or to a plain microcontroller bus connected via copper on a
PCB to an FPGA housing the I2C controller IP.

SimStm focuses on this purpose. It delivers a command set that is fixed
and suitable for all needs in this context. The command set is defined
by a domain-specific language that provides and controls all necessary
keywords and object references, called the SimStm language. The commands
are referred to as instructions.

The SimStm language is edited within respective IDE plugins for Eclipse
or Visual Studio Code editors, supplying state-of-the-art coding support
such as syntax highlighting, auto-completion, error detection, and more.

The user starts editing a ``top.stm`` file and as many ``child.stm``
files as needed. The latter are included by ``include`` instructions,
which may be nested. ``Child.stm`` files can be used in a library manner
for reuse.

The SimStm instructions are purposely very close to HW to avoid
debugging through too much overhead. All objects declared, such as
variables, constants, arrays, implicit labels, etc., are global within
one SimStm project. All objects representing values consider the values
to be unsigned integer values. The values are 64-bit wide by default but 
can be customized to be any width by setting the **machine_value_width** 
generic when instanciating the **tb_simstm** top entity, individually 
for each instance.

The SimStm testbench presents a bus and a signal package source file to
the user. These packages can be customized by the user to add busses,
signals, or interrupts to the testbench. All other files shall be used
unchanged. Eccelerator samples for Wishbone, Avalon, and AXI4lite busses
for single read/write accesses are already included.

The primary focus of SimStm is to have a **functional** verification of
all connected IPs via multiple busses with high coverage in a short
time. It is **not** prepared to be used to verify the different
conditions and sequences of accesses to the busses like other
testbenches. However, it could control these testbenches via respective
bus adapters. Eccelerators uses its own HxS tool to design and generate
HW/SW interfaces. The patterns used by the generators are verified to
work with all circumstances happening on the supported busses all the
way to having counterparts in other asynchronous clock domains. The
generated instances do not have to be verified again at this depth.

The SimStm language can be transpiled into Python, C, and other
programming languages to use the code written in SimStm for a first test
of a target HW. Thus, a functional coverage test is achieved very fast
when the real target HW arrives. The transport and isolation of problems
from the real application to the simulation environment and vice versa
are simplified. Interaction between SW and HW developers is simplified
too since SW developers can work with SimStm code rather than VHDL.

