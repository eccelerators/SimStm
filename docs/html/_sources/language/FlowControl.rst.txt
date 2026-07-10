Subroutines, Branches, and Loops
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

proc
^^^^

.. code-block:: simstm

 proc a_proc ()
     --...
     --... local variable , array, files, lines, bus, signals, label declarations
     --...
     -- subroutine code
     --...
 end proc
 
 proc p_proc (
    --...
    --... parameter variable , array, file, lines, bus, signal, label declarations
    --...
  )
     --...
     --... local variable , array, file, lines, bus, signal, label declarations
     --...
     -- subroutine code
     --...
 end proc

Code of a subroutine is placed between  ``proc`` and ``end proc`` instructions.

A procedure can have parameters. The parameters are declared as usually with variables, arrays, files, lines, buses, signals, or labels 
between the parentheses after the procedure name. If the parameters are passed by reference or by value is decided by the 
assignments within the parentheses when calling the procedures.

The value given with the parameter declaration is the default value, which is used when the parameter is not assigned when calling the procedure.
The default value can be any global variable, array, file, line, bus, signal, or label. 
It can also be a constant or a numeric value in case of variables, busses, signals.

This mechanism allows to have optional parameters, which can be used when the same procedure is called with different parameters in different places.
In case of suitable default values, the calls can be very lean.

Parameter objects mustn't have the same name as any **local** variable, array, file, line, bus, signal, or label within the same procedure. 
However, they can have the same name as global variables, arrays, files, lines, buses, signals, or labels.


call
^^^^

.. code-block:: simstm

 call a_proc ()
 
 call p_proc (
    --...
    --... parameter variable , array, file, lines, bus, signal, label assignments
    --...
  )

The ``call`` instruction branches execution to the subroutine with the given procedure name. Code execution proceeds
until an ``end proc`` or a ``return`` statement.

- Parameter variable assignments of a source variable to destination parameter variable can be passed by 

 - ``equ d_var s_var`` to pass by value 
 - ``var pointer copy d_var s_var`` to pass by reference

- Parameter label assignments of a source label or direct procedure name to destination parameter label can be passed by 

 - ``label equ d_label s_label`` to pass by value
 - ``var pointer copy a_par a_var`` to pass by reference
 - ``label set d_label proc_name`` to set it to a procedure directly 
 
- Parameter array assignments of a source array to destination parameter array can be passed by  

 - ``array pointer copy d_array s_array`` to pass by reference only
 
- Parameter file assignments of a source file to destination parameter file can be passed by  

 - ``file pointer copy d_file s_file`` to pass by reference only  
 
- Parameter lines assignments of a source lines to destination parameter lines can be passed by  

 - ``lines pointer copy d_lines s_lines`` to pass by reference only
 
 - Parameter bus assignments of a source bus to destination parameter bus can be passed by  

 - ``bus pointer copy d_bus s_bus`` to pass by reference only 
 
 - Parameter signal assignments of a source signal to destination parameter signal can be passed by  

 - ``signal pointer copy d_signal s_signal`` to pass by reference only 
 
 Source variables, labels, arrays, files, lines, buses, or signals are taken with preceedence from 
 the calling subroutine when present as locals there, otherwise from the global scope.
 
call label
^^^^^^^^^^

.. code-block:: simstm

 call label a_label ()
 
 call label p_label (
    --...
    --... parameter variable , array, file, lines, bus, signal, label assignments
    --...
  )
  
The ``call label`` instruction branches execution to the label given after the ``label`` keyword. 

Thus a label must be declared in the same procedure or globally. 
The label can be passed as a parameter to the procedure as well, which allows to call different labels within the same procedure. 

A label declaration especially when used in parameters must always point to a existing procedure, 
at least a dummy procedure in case it is always overridden.

return
^^^^^^

.. code-block:: simstm

 return

The ``return`` instruction returns to calling code from a subroutine.

interrupt
^^^^^^^^^

.. code-block:: simstm


 interrupt an_interrupt ()
     --...
     -- interrupt subroutine code
     --...
 end interrupt

Code of an interrupt subroutine is placed between ``interrupt``
and ``end interrupt`` instructions.  The label ``an_interrupt`` must be given in the
tb_signal package by customization and attached to a signal triggering
the interrupt. If necessary, the handling of nested interrupts must be
resolved there too.

if
^^

.. code-block:: simstm

 if a_var = b_var
     -- ... some code
 elsif a_var 0xABC
     -- ... some code
 elsif 0x123} b_var
     -- ... some code
 else
     -- ... some code
 end if



Possible comparison operators are:
``>= <= > < != =``.

The ``if`` or ``elsif`` instructions compares two variables, constants, or numeric values and branches
execution to the next line after the ``end if`` if it resolves to true. Otherwise, it branches
to the next ``elsif`` or ``else`` or ``end if`` instruction.

The ``if`` ``elsif`` or ``else`` instructions can be nested.

loop
^^^^

.. code-block:: simstm

 loop l_var
     -- ... some code
 end loop

 loop 32
     -- ... some code
 end loop

The ``loop`` instruction executes a loop of the code between the ``loop`` and ``end loop`` instruction.

The number of times the loop should be executed is given after the ``loop``
keyword. It can be a numeric value, a variable, or a constant.

In case of a variable, this number can be changed by code within the loop, e.g.,
to skip loops or end the loop earlier, due to the global nature of all
variables. No break or continue instructions are supported therefore.

The loop can be terminated by a ``return`` instruction too at any time,
which is a good practice.

abort
^^^^^

.. code-block:: simstm

 abort

The ``abort`` instruction aborts the simulation with severity Failure.

finish
^^^^^^

.. code-block:: simstm

 finish

The ``finish`` instruction exits the simulation.

stop
^^^^

.. code-block:: simstm
	
	stop
	
The ``stop`` instruction stops the simulation with the severity Failure. The simulation can be resumed.

resume
^^^^^^

.. code-block:: simstm

 resume EXIT_ON_VERIFY_ERROR
 resume 0

| Usual practice is to use the following constants to set verbosity:
| ``const RESUME_ON_VERIFY_ERROR 1``
| ``const EXIT_ON_VERIFY_ERROR 0``


The ``resume`` instruction sets the global resume behavior for verify instructions. On a verify
mismatch, the simulation stops with severity Failure if the global
resume is set to 0; otherwise, it continues and reports an error.
