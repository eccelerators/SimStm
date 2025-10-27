
Definitions and Declarations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Const
^^^^^

.. code-block:: none

 const aconst 0x03
 const bconst 0b011
 const cconst 3

The ``const`` instruction declares and defines a constant with ID and hex, binary,
decimal unsigned value.

It **isn't possible** to initialize a constant by referencing another
constant.

Var
^^^

.. code-block:: none

 var avar 0x03
 var bvar 0b011
 var cvar 3

The ``var`` instruction declares and defines a variable with ID and initial hex, binary, or
decimal unsigned value.

It **isn't possible** to initialize a variable by referencing another
variable or constant yet. The ``equ``
instruction must be used within a procedure for this purpose.

Array
^^^^^

.. code-block:: none

 barray 16

The ``array`` instruction declares an array with ID and an unsigned 32-bit integer length.

Only arrays with one dimension are possible; the length must be fixed.

File
^^^^

.. code-block:: none

 file afile "filename.stm"
 file afile "filename{:d}{:d}.stm" $index1 $index2

The ``file`` instruction declares a file with ID and file name.

The latter must be a relative path to the location of the main.stm file.
Text substitution by variables is allowed in file names. Thus, files can
be accessed in an indexed manner. The variables are evaluated each time
when a reference to a file is used in another instruction accessing a
file, e.g., ``file read all afile alines``.

Lines
^^^^^

.. code-block:: none

 lines alines

The ``lines`` instruction declares a lines object with ID.

The lines object contains an arbitrary number of line objects. It is
defined to have no content when it is declared by default. It can grow
or shrink dynamically by lines instructions accessing it, e.g.,
``lines insert array alines 9 barray``.

Signal
^^^^^^

.. code-block:: none

 signal asignal

The ``signal`` instruction declares a signal object with ID.

The signal object associates a SimStm signal name with a signal number.
This signal number must be given in the tb_signal package by
customization and attached to a signal.

Bus
^^^

.. code-block:: none

 bus abus

The ``bus`` instruction declares a bus object with ID.

The signal object associates a SimStm bus name with a bus number. This
bus number must be given in the tb_bus package by customization and
attached to a bus.
