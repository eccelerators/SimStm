
Objects
-------

Const
^^^^^

.. code-block:: simstm

 const a_const 0x03
 const b_const 0b011
 const c_const 3

The ``const`` instruction declares and defines a constant with an ID and a hex, binary,
decimal unsigned value.

It **isn't possible** to initialize a constant by referencing another
constant.


Var
^^^

.. code-block:: simstm

 var a_var 0x03
 var b_var 0b011
 var c_var 3

The ``var`` instruction declares and defines a variable with an ID and an initial hex, binary, or
decimal unsigned value.

It **isn't possible** to initialize a variable by referencing another
variable or constant yet. The ``equ``
instruction must be used within a procedure for this purpose.


Array
^^^^^

.. code-block:: simstm

 a_array 16

The ``array`` instruction declares an array with an ID and an unsigned 32-bit integer length.

Only arrays with one dimension are possible; the length is fixed.


File
^^^^

.. code-block:: simstm

 file a_file "filename.stm"
 file a_file "filename{:d}{:d}.stm" index1 index2

The ``file`` instruction declares a file with an ID and a file name.

The latter must be a relative path to the location of the main.stm file.
Text substitution by variables is allowed in file names. Thus, files can
be accessed in an indexed manner. The variables are evaluated every time
a reference to a file is used in another instruction accessing a
file, e.g., ``file read all a_file a_lines``.


Lines
^^^^^

.. code-block:: simstm

 lines a_lines

The ``lines`` instruction declares a lines object with an ID.

The lines object contains an arbitrary number of line objects. It is
defined to have no content when it is declared by default. It can grow
or shrink dynamically by lines instructions accessing it, e.g.,
``lines insert array a_lines 9 b_array``.


Signal
^^^^^^

.. code-block:: simstm

 signal a_signal

The ``signal`` instruction declares a signal object with an ID.

The signal object associates a SimStm signal name with a signal number.
This signal number must be given in the tb_signal package by
customization and attached to a signal.


Bus
^^^

.. code-block:: simstm

 bus a_bus

The ``bus`` instruction declares a bus object with ID.

The signal object associates a SimStm bus name with a bus number. This
bus number must be given in the tb_bus package by customization and
attached to a bus.


Namespace
^^^^^^^^^

.. code-block:: simstm
	
	namespace a
	var l_var 0
	end namespace
	
The ``namespace`` instruction declares a container-like space, that can hold variables, subroutines etc.
These are defined only inside the namespace and therefore help organizing code and avoiding naming conflicts.
In the given example, the variable ``l_var`` is only defined inside the namespace ``a``.