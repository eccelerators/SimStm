# SimStm
SimStm is a VHDL testbench designed to facilitate testing driven by external stimulus files with a ".stm" extension.
This testbench, is provided by Eccelerators GmbH and aims to simplify test script creation by introducing the SimStm language.
Eccelerators GmbH provides IDE support for this language byVisual Studio Code and Eclipse by SimStm plugins, visit https://eccelerators.com .

The original of the VHDL testbench has been coded by Ken Campbell, visit https://github.com/sckoarn/VHDL-Test-Bench . Therefore the SimStm
repository is forked from this original. The complete VHDL source code of the SimStm VHDL testbench is distributed under the same license as the original.
However the code has been repartioned and changed by Eccelerators GmbH substantially. The original copyright notice has been kept within all source files
having a relation to an original.

The IDE plugins are available for free at the Eccelerators GmbH web page. They may be available for free at the respective IDE marketplaces once they are deployed there.
The source code of the SimStm language IDE plugins is Eccelerators GmbH property and closed source. 

## Focus
It is a common practice to use the file I/O features of VHDL for VHDL testbenches. Usually each developer creates an own format for commands in an
input stimuli text file and its own file name and file extension. The command set is focused on the tasks currently to be solved.

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


## SimStm language instructions

### Includes, objects and declarations

#### include

${\color{purple}\texttt{include} \space \color{blue}\texttt{"an\\_include.stm"}}$

Include another child *.stm file

Include instructions should be the first instructions of a *.stm file.
An included file can include further *.stm files thus nested includes are possible. The file path 
to be given is relative to the file with the respective include instruction. Nested includes of files 
from the same folder or in child folders are predictable, nested includes to files in parent folders 
would be a bad practice. 


#### const

${\color{purple}\texttt{const} \space \color{black}\texttt{a\\_constA 0x03}}$

${\color{purple}\texttt{const} \space \color{black}\texttt{a\\_constB 0b011}}$

${\color{purple}\texttt{const} \space \color{black}\texttt{a\\_constC 3}}$

Declare and define a constant with ID and hex, binary or decimal unsigned 32 bit integer value.

It isn't possible to initialize a constant by referencing another constant or variable.


#### var

${\color{purple}\texttt{var} \space \color{black}\texttt{a\\_varA 0x03}}$

${\color{purple}\texttt{var} \space \color{black}\texttt{a\\_varB 0b011}}$

${\color{purple}\texttt{var} \space \color{black}\texttt{a\\_varC 3}}$

Declare and define a variable with ID and initial hex, binary or decimal unsigned 32 bit integer value.

It isn't possible to initialize a variable by referencing another variable or constant yet.
The ${\color{purple}\texttt{equ}}$ instruction must be used within a procedure for this purpose.



#### array

${\color{purple}\texttt{var} \space \color{black}\texttt{an\\_array 16}}$

Declare an array with ID and an unsigned 32 bit integer length.

Only arrays with one dimension are possible, the length must be fix.


#### file

${\color{purple}\texttt{file} \space \color{black}\texttt{a\\_fileA} \space \color{blue}\texttt{"file\\_name.stm"}}$

${\color{purple}\texttt{file} \space \color{black}\texttt{a\\_fileB} \space \color{blue}\texttt{"file\\_name\\{\\}\\{\\}.stm"} \space \color{grey}\texttt{\\$} \color{black}\texttt{file\\_user\\_index1} \space \color{grey}\texttt{\\$} \color{black}\texttt{file\\_user\\_index2}}$

Declare a file with ID and file name. 

The later must be a relative path to the location of the main.stm file. Text substitution by variables is allowed in file names.
Thus files can be accessed in an indexed manner. The variables are evaluated each time when a reference to a file is used in another 
instruction accessing a file e.g., ${\color{purple}\texttt{file read all} \space \color{black}\texttt{a\\_file} \space \color{black}\texttt{a\\_lines} }$


#### lines

${\color{purple}\texttt{a\\_lines}}$

Declare a lines object with ID.

The lines object contains an arbitrary number of line objects. It is defined to have null content when it is declared by default.
It can grow or shrink dynamically by lines instructions accessing it e.g., ${\color{purple}\texttt{lines insert array} \space \color{black}\texttt{a\\_lines} \space \color{black}\texttt{9} \space \color{black}\texttt{an\\_array}}$



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
