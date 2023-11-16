# SimStm                                                                                                                                                             
SimStm is a VHDL testbench designed to facilitate testing driven by external stimulus files with a ".stm" extension.
This testbench, is provided by Eccelerators and aims to simplify test script creation by introducing the SimStm language.
Eccelerators provides IDE support for Visual Studio Code and Eclipse by SimStm plugins, visit https://eccelerators.com .

The original of the VHDL testbench has been coded by Ken Campbell, visit https://github.com/sckoarn/VHDL-Test-Bench . Therefore the SimStm
repository is forked from this original. The complete VHDL source code of the SimStm VHDL testbench is distributed under the same license as the original.
However the code has been repartioned and changed substantially. The original copyright notice has been kept within all source files having a relation to
an original.

The IDE plugins are available for free at the Eccelerators web page. They may be available for free at the respective IDE marketplaces once they are deployed there.
The source code of the SimStm language plugins is Eccelerators GmbH property and closed source. 
                                                                                                                                                                     
## Focus                                                                                                         
It is a common practice to use the file I/O features of VHDL for VHDL testbenches. Usually each developer creates an own format for commands in an input stimuli text file                                                                              
and its own file name and file extension. The command set is focused on the tasks currently to be solved.                                                            
                                                                                                                                                                     
The general advantage of this technique is that the VHDL-code of the testbench doesn't have to be changed and recompiled for different stimuli command sets          
supplied to the VHDL testbench by presenting different command set files or interactively changed command files when debugging.                                      
                                                                                                                                                                     
The advantage of not to have to recompile the VHDL testbench has decreased in recent day's because of increased computer and tool performance but a major part of    
advantage of this technique remains valid if it is applied for the purpose of reusability and to have a first decoupled level of abstraction for the stimuli         
above the VHDL code.                                                                                                                                                 
                                                                                                                                                                     
The later applies especially for CPUs which are attached or integrated in components to be developed. An IP e.g., I2C-controller with a HW/SW interface can          
be tested with the same stimuli if it is attached to an AXI-bus in a SOC of the latest generation or to a plain microcontroller bus                                  
connected via copper of a PCB to an FPGA housing the I2C controller IP.                                                                                              
                                                                                                                                                                     
SimStm focuses on this purpose. It delivers a command set which is fix and suitable for all needs in this context. The command set is defined by means of            
a domain specific language delivering and controlling all necessary keywords and object references. It is called SimStm language subsequently. The                   
commands are called instructions.                                                                                                                                    
                                                                                                                                                                     
The SimStm language is edited within respective IDE plugins for Eclipse or Visual Studio Code editors supplying state of the art coding support like                 
syntax highlighting, auto completion, error detecton and much more.                                                                                                  
                                                                                                                                                                     
The user starts editing a top.stm file and as many child.stm files as suitable. The later are included by include instructions which may be nested.                  
Child.stm files can of course be used in a library manner for reuse.                                                                                                 
                                                                                                                                                                     
The SimStm instructions are on purpose very near to HW not to have to debug through to much overhead. All objects declared by e.g., variable, constant, array,       
implicit labels, etc. are global within one SimStm project. All objects representing values consider the values to be unsigned 32bit integer values.                 
                                                                                                                                                                     
Next development steps of SimStm may introduce larger unsigned integer values e.g., 64bit, 128bit ... if specified in a new package to be customized by the user.    
There may further parameters opened to the user then e.g. maximum object ID string length and others when their modification has been tested to work as expected.    
Further development steps may introduce namespaces together with the abilities of the IDE plugins.                                                                   
                                                                                                                                                                     
The SimStm testbench presents a bus and a signal package source file to the user. This packages can be customized by the user to add busses, signals or interrupts   
to the testbench. All other files shall be used unchanged. Eccelerator samples for Wishbone, Avalon and AXI4lite busses for single read/write accesses are           
already included.                                                                                                                                                    
                                                                                                                                                                     
The primary focus of the SimStm is to have a **functional** verification of all connected IPs via multiple busses with high coverage in a short time.                
It is **not** prepared to be used to verify the different conditions and sequences of accesses to the busses like other testbenches. However it could control these  
testbenches via respective bus adapters. Eccelerators uses its own HxS-tool to design and generate HW/SW interfaces. The patterns used by the generators are verified
to work with all circumstances happening on the supported busses all the way to having counterparts in other asynchronous clock domains. The generated instances     
do not have to be verified again at this depths again.                                                                                                               
                                                                                                                                                                     
The SimStm language can be transpiled into Python, C and other programming languages to be able to use the code written in SimStm for a first test                   
of a target HW. Thus a functional coverage test is achieved very fast when the real target HW arrives. The transport and isolation of problems                       
from the real application to the simulation environment and vice versa is simplified. Interaction between SW and HW developers is simplified too, since SW           
developers can work with SimStm code rather than VHDL.
## Features and Advantages
SimStm provides the following features and advantages over similar tools:

- Compact and lightweight compared to other solutions like OSSVM.
- Utilizes its own "stm" language and IDE support for rapid test case creation.
- Supports various VHDL simulators due to its nature as a pure VHDL interpreter.
- Simplifies test writing through IDE plugins for Visual Code and Eclipse.

## Installation and Usage of the plugin
Visual Studio Code Plugin
The SimStm Visual Studio Code plugin enhances your testing experience. It provides code highlighting, auto-completion, and other features to expedite test script development. To install the plugin, follow these steps:

### Open Visual Studio Code.
Go to the Extensions Marketplace.  
Search for "SimStm" and install the plugin.  
Create or open a ".stm" test script file.  
Enjoy the IDE support provided by the plugin.  

### Open Eclipse.
Navigate to the eccelerators.com.  
Here you can download the plugin.  
Install this via Eclipse.  
Create or open a ".stm" test script file within your project.  
Leverage the plugin's IDE features to enhance your testing workflow.  


## Test Commands

### Basics

| Command | Parameters | Description | Comment |
|---------|------------|-------------|---------|
| abort | | Abort simulation | |
| break | | Exit a while loop | Future implementation |
| const | [name] [value] | Define a constant | |
| else | | Else statement | |
| elsif | [value] [operation] [value] | Elseif statement | |
| end if | | End statement for if | |
| finish | | Successful end of simulation | |
| if | [value] [operation] [value] | If statement | |
| include | [file] | Include another *.stm file | |
| loop | [num of iterations] | Start a loop | |
| end loop | | End statement for loop | |
| var | [name] [value] | Define a variable | |
| while | [value] [operation] [value] | Start a while loop | Future implementation |
| end while | | End statement for while | |

### Operations

| Command | Parameters | Description | Comment |
|---------|------------|-------------|---------|
| add | [variable] [value] | Add value to variable | |
| and | [variable] [value] | Logical AND | |
| div | [variable] [value] | Divide value | |
| equ | [variable] [value] | Set new value | |
| mul | [variable] [value] | Multiply value | |
| or | [variable] [value] | Logical OR | |
| sub | [variable] [value] | Subtract value | |
| xor | [variable] [value] | Logical XOR | |
| shl | [variable] [value] | Shift left | |
| shr | [variable] [value] | Shift right | |
| ld | [variable] | Logarithmus Dualis | |
| lg | [variable] [value] | Logarithmus | Maybe a future Implementation |
| pwr | [variable] [value] | Variable ** value (power of) | Maybe a future Implementation |
| inv | [variable] | Invert | |

### Signals

| Command | Parameters | Description |
|---------|------------|-------------|
| signal read | [signal number] [store variable] | Read from a signal |
| signal verify | [signal number] [store variable] [match value] [mask] | Verify a signal |
| signal write | [signal number] [value] | Write to a signal |

### Bus

| Command | Parameters | Description |
|---------|------------|-------------|
| bus read | [bus number] [bit width] [address] [store variable] | Read from a bus |
| bus timeout | [bus number] [timeout] | Set a read timeout for a bus |
| bus verify | [bus number] [bit width] [address] [store variable] [match value] [mask] | Verify the read data from a bus |
| bus write | [bus number] [bit width] [address] [value] | Write to a bus |

### File

| Command | Parameters | Description |
|---------|------------|-------------|
| file | [name] [path] | Path to the file |
| line pos | [name] | Get the current line number of a file |
| line read | [name] [variable to store read data] | Read a line from a file and store data in variable |
| line size | [name] | Get the number of lines in a file |
| line seek | [name] [line number] | Seek to a specific line in a file |
| line write | [name] [message] | Write a line to a file |

### Array

| Command | Parameters | Description |
|---------|------------|-------------|
| array | [name] [size] | Define an array, 1 dim with size of [size] |
| array get | [name] [pos] [variable name] | Read a value at the [pos] of the array and store it into a variable |
| array set | [name] [pos] [value] | Write the value at the array [pos] |
| array size | [name] [variable name] | Read the size of the array and store it into a variable |

### Others

| Command | Parameters | Description |
|---------|------------|-------------|
| call | [name] | Call a subroutine |
| return | | Return from a called subroutine or interrupt routine |
| resume | [0 / 1] | Exit simulation on error (default is 1) |
| interrupt | | Define an interrupt subroutine |
| end interrupt | | End statement for interrupt | |
| jump | [label] | Jump to a label |
| label | | Define a new label |
| marker | [marker number] [value] | Set a marker |
| log | [log level] [message] | Print a message |
| verbosity | [number] | Print only messages that are lesser or equal to the log level |
| random | [variable] | Get a random number |
| seed | [seed number A] [seed number B] | Set the seed numbers for the pseudo-random generator |
| proc | | Begin a subroutine |
| end proc | | End statement for proc | |
| trace | [0 / 1] | Enable or disable SimStm trace |
| wait | [ns] | Wait for * ns |


## Example Usage

Here's an example of how SimStm commands can be used in a test script:

### `main.stm`

```stm
equ ReadModifyWriteBus32 0
equ ReadModifyWriteBus16 0
equ ReadModifyWriteBus8 0
equ CmdBus 0
equ SpiFlashBus 0
equ DoubleBufferBus 0

var WaitTimeOut 100000 -- ms

call $SpiControllerIfcInit
call $CellBufferIfcInit

verbosity $INFO_2
trace 0
wait 1000
log $INFO "Main test started"
log $INFO_3 "HwBufferMask: $HwBufferMask"

call $testSpiFlash

log $INFO "Main test finished"
wait 1000
finish

-- includes must be placed at the end of a module
include "DoubleBuffer/StatusReg.stm"
```

### `StatusReg.stm`

```stm
-- global
-- var WaitTimeOut Test.stm
-- var DoubleBufferBus from DoubleBuffer.stm

-- parameter
var StatusRegOperationMVal 0
var StatusRegOperationMValToWaitFor 0
var StatusRegHwBufferMVal 0
var StatusRegHwBufferMValToWaitFor 0

-- intern
var StatusRegTmp0 0

getStatusRegOperationMVal:
proc
	bus read $DoubleBufferBus 32 $StatusRegAddress StatusRegTmp0
	and StatusRegTmp0 $OperationMask
	equ StatusRegOperationMVal $StatusRegTmp0
end proc

getStatusRegHwBufferMVal:
proc
	bus read $DoubleBufferBus 32 $StatusRegAddress StatusRegTmp0
	log $INFO_3 "getStatusRegHwBufferMVal: $StatusRegTmp0"
	and StatusRegTmp0 $HwBufferMask
	log $INFO_3 -- global
-- var WaitTimeOut Test.stm
-- var DoubleBufferBus from DoubleBuffer.stm

-- parameter
var StatusRegOperationMVal 0
var StatusRegOperationMValToWaitFor 0
var StatusRegHwBufferMVal 0
var StatusRegHwBufferMValToWaitFor 0

-- intern
var StatusRegTmp0 0

getStatusRegOperationMVal:
proc
	bus read $DoubleBufferBus 32 $StatusRegAddress StatusRegTmp0
	and StatusRegTmp0 $OperationMask
	equ StatusRegOperationMVal $StatusRegTmp0
end proc

getStatusRegHwBufferMVal:
proc
	bus read $DoubleBufferBus 32 $StatusRegAddress StatusRegTmp0
	log $INFO_3 "getStatusRegHwBufferMVal: $StatusRegTmp0"
	and StatusRegTmp0 $HwBufferMask
	log $INFO_3 "getStatusRegHwBufferMValHwBufferMask: $HwBufferMask"
	log $INFO_3 "getStatusRegHwBufferMValMasked: $StatusRegTmp0"
	equ StatusRegHwBufferMVal $StatusRegTmp0
end proc

waitForStatusRegOperationMVal:
proc
    loop $WaitTimeOut
        wait 1000
        call $getStatusRegOperationMVal
        log $INFO_3 "waitForStatusRegOperationMVal: $StatusRegOperationMVal"
        if $StatusRegOperationMVal = $StatusRegOperationMValToWaitFor
            return
        end if
    end loop
    log $ERROR "waitForStatusRegOperationMVal: $WaitForStatusRegOperationMVal not set within reasonable time"
    abort
end proc

waitForStatusRegHwBufferMVal:
proc
    loop $WaitTimeOut
        wait 1000
        call $getStatusRegHwBufferMVal
        log $INFO_3 "waitForStatusRegHwBufferMVal: $StatusRegHwBufferMVal"
        if $StatusRegHwBufferMVal = $StatusRegHwBufferMValToWaitFor
            return
        end if
    end loop
    log $ERROR "waitForStatusRegHwBufferMVal: $WaitForStatusRegHwBufferMVal not set within reasonable time"
    abort
end proc"getStatusRegHwBufferMValHwBufferMask: $HwBufferMask"
	log $INFO_3 "getStatusRegHwBufferMValMasked: $StatusRegTmp0"
	equ StatusRegHwBufferMVal $StatusRegTmp0
end proc

waitForStatusRegOperationMVal:
proc
    loop $WaitTimeOut
        wait 1000
        call $getStatusRegOperationMVal
        log $INFO_3 "waitForStatusRegOperationMVal: $StatusRegOperationMVal"
        if $StatusRegOperationMVal = $StatusRegOperationMValToWaitFor
            return
        end if
    end loop
    log $ERROR "waitForStatusRegOperationMVal: $WaitForStatusRegOperationMVal not set within reasonable time"
    abort
end proc

waitForStatusRegHwBufferMVal:
proc
    loop $WaitTimeOut
        wait 1000
        call $getStatusRegHwBufferMVal
        log $INFO_3 "waitForStatusRegHwBufferMVal: $StatusRegHwBufferMVal"
        if $StatusRegHwBufferMVal = $StatusRegHwBufferMValToWaitFor
            return
        end if
    end loop
    log $ERROR "waitForStatusRegHwBufferMVal: $WaitForStatusRegHwBufferMVal not set within reasonable time"
    abort
end proc
```

## Prerequisites
To write ".stm" files, we recommend using the provided IDE plugins for Visual Code and Eclipse. For executing the tests, any VHDL simulator like Siemens Questa or GHDL can be used.

## Connecting to the DUT
SimStm offers two ways to interface with the Device Under Test (DUT): dedicated signals and bus systems. The "signal" and "bus" commands are used to interact with these interfaces. Additionally, SimStm provides packages for both signal and bus definitions, allowing easy integration with named objects without requiring extensive modifications to the testbench.

## Licensing
This project is licensed under the Apache License 2.0. You can find a copy of the license in the LICENSE file.
