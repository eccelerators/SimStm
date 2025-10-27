
Assignments
~~~~~~~~~~~

equ
^^^

.. code-block:: none

 equ operand1 $operand2
 equ operand1 0xF0

The ``equ`` instruction copies the value of operand2 variable, constant, or numeric value into
variable operand1 value or copy the value 0xF0 into variable operand1
value.

var pointer copy
^^^^^^^^^^^^^^^^

Todo

Array Set
^^^^^^^^^

.. code-block:: none

 array set barray $pvar $avar
 array set barray 3 $avar
 array set barray $pvar 5
 array set barray 3 4

The ``array set`` instruction sets the value of ``barray`` at position ``pvar``to the value of ``avar`` or
``5``.

The ``array set`` instruction the value of ``barray`` at position ``3``to the value of ``avar`` or
``4``.

Array Get
^^^^^^^^^

.. code-block:: none

 array get barray $pvar tvar
 array get barray 5  tvar

The ``array get`` instruction gets the value of ``barray`` at position ``pvar`` or ``5`` into ``tvar``.

Array Size
^^^^^^^^^^

.. code-block:: none

 array size barray tvar

The ``array size`` instruction gets the size of an array.

Array Pointer Copy
^^^^^^^^^^^^^^^^^^

.. code-block:: none

 array pointer copy tarray sarray

The ``array pointer copy`` instruction copies an array pointer; for example, ``tarray`` pointer is a copy of
``sarray`` pointer after the execution of the instruction. Used, for
instance, to hand over an array to a subroutine. Changes to the source
array happen in the target array too.

File Writeable
^^^^^^^^^^^^^^

.. code-block:: none

 file writeable afile rvar

The ``file writeable`` instruction tests if a file is writable. If the file is not present, it is created
without having content. The result is for STATUSOK 0, STATUSERROR 1,
STATUSNAMEERROR 2, STATUSMODEERROR 3 and may, in case of error, depend
on the operating system.

File Readable
^^^^^^^^^^^^^

.. code-block:: none

 file readable afile rvar

The ``file readable`` instruction tests if a file is readable. The result is for STATUSOK 0, STATUSERROR 1,
STATUSNAMEERROR 2, STATUSMODEERROR 3 and may, in case of error, depend
on the operating system.

File Appendable
^^^^^^^^^^^^^^^

.. code-block:: none

 file appendable afile rvar

The ``file appendable`` instruction tests if a file is appendable. The result is for STATUSOK 0, STATUSERROR
1, STATUSNAMEERROR 2, STATUSMODEERROR 3 and may, in case of error,
depend on the operating system.

File Write
^^^^^^^^^^

.. code-block:: none

 file write afile alines

The ``file write`` instruction writes all lines of an ``alines`` object to a file. The file is
overwritten if it exists.

File Append
^^^^^^^^^^^

.. code-block:: none

 file append afile alines

The ``file append`` instruction appends all lines of an ``alines`` object to a file. The method will fail
if the file doesn't exist.

File Read All
^^^^^^^^^^^^^

.. code-block:: none

 file read all afile alines

The ``file read all`` instruction reads all lines of a file into an ``alines`` object.

File Read
^^^^^^^^^

.. code-block:: none

   file read afile alines $nvar
   file read afile alines 10

The ``file read`` instruction reads a number of lines from a file into an ``alines`` object.

The first read opens the file for read, following reads start at the line after
the last line which has been read by the previous read. Thus a file can
be read piecewise similar as it can be written piecewise by file append.
The piecewise read process of the file must be terminated by a file read
end instruction always. The number of concurrent file read processes is
limited to 4.

File Read End
^^^^^^^^^^^^^

.. code-block:: none

   file read end afile

The ``file read end `` instruction ends the piecewise read process of a file.

File Pointer Copy
^^^^^^^^^^^^^^^^^

.. code-block:: none

   file pointer copy tfile sfile

The ``file pointer copy`` instruction copies a file pointer; for example, ``tfile`` pointer is a copy of
``sfile`` pointer after the execution of the instruction. Used, for
instance, to hand over a file to a subroutine. Changes to the source
file happen in the target file too.

Lines Get
^^^^^^^^^

.. code-block:: none

 lines get array alines $pvar tarray rvar
 lines get array alines 9 tarray rvar

The ``lines get array`` instruction gets a line from a lines object at a given position and write its content
into an array.

The line is expected to hold hex numbers (without 0x
prefix) separated by spaces (e.g., A123 BCF11 123 E333 would be 4 hex
numbers). The given array must be able to hold the number of found hex
numbers. It will not be filled completely if fewer than its size are
found. Numbers will be skipped if there are more hex numbers found than
the array can hold. The number of detected hex numbers is reported in a
result variable. Then the user can decide what action should follow a
mismatch.

Lines Set
^^^^^^^^^
.. code-block:: none

 lines set array alines $pvar sarray
 lines set array alines 9 sarray
 lines set message alines $pvar "Some message to be written to a file later"
 lines set message alines $pvar "Value1: {} Value2: {} to be written to a file later" $mvar1 $mvar2

The ``lines get array`` instruction sets a line at a given position of a lines object.

The line currently at this position is overwritten. The line can be derived from an array or a
message. The message string can contain {} placeholders which are filled
by values of variables given after the message string.

Lines Insert
^^^^^^^^^^^^

.. code-block:: none

 lines insert array alines $pvar sarray
 lines insert array alines 9 sarray
 lines insert message alines $pvar "Some message to be written to a file later"
 lines insert message alines $pvar "Value1: {} Value2: {} to be written to a file later" $mvar1 $mvar2

The ``lines insert array`` instruction inserts a line at a given position of a lines object. The line currently
at this position is moved to the next position. The line can be derived
from an array or a message. The message string can contain {}
placeholders which are filled by values of variables given after the
message string.

Lines Append
^^^^^^^^^^^^

.. code-block:: none

 lines append array alines sarray
 lines append message alines "Some message to be written to a file later"
 lines append message alines "Value1: {} Value2: {} to be written to a file later" $mvar1 $mvar2

The ``lines append array`` instruction appends a line at the end of a lines object. The line can be derived from
an array or a message. The message string can contain {} placeholders
which are filled by values of variables given after the message string.

Lines Delete
^^^^^^^^^^^^

.. code-block:: none

 lines delete alines $pvar
 lines delete alines 3

The ``lines delete`` instruction deletes a line at a given position of a lines object. The next line is
moved to the given position if it exists.

Lines Size
^^^^^^^^^^

.. code-block:: none

 lines size alines rvar

The ``lines size`` instruction gets the size of a lines object, which is the number of lines it contains
currently.

Lines Pointer Copy
^^^^^^^^^^^^^^^^^^

.. code-block:: none

 lines pointer copy tlines slines

The ``lines pointer copy`` instruction copies a lines pointer; for example, ``tlines`` pointer is a copy of
``slines``

Signal Write
^^^^^^^^^^^^

.. code-block:: none

 signal write asignal $svar
 signal write asignal 0b11

The ``signal write`` instruction writes variable, constant, or numeric value to a signal.

Signal Read
^^^^^^^^^^^

.. code-block:: none

 signal read asignal tvar

The ``signal read`` instruction reads the value of a signal into a variable.

Signal Pointer Copy
^^^^^^^^^^^^^^^^^^^

.. code-block:: none

 signal pointer copy tsignal ssignal

The ``signal pointer copy`` instruction copies a signal pointer; for example, ``tsignal`` pointer is a copy of
``ssignal``

Signal Pointer Set
^^^^^^^^^^^^^^^^^^

.. code-block:: none

 signal pointer set tsignal 5
 signal pointer set tsignal $ptvar

The ``signal pointer set`` instruction sets a signal pointer; for example, ``tsignal`` pointer absolutely.

Signal Pointer Get
^^^^^^^^^^^^^^^^^^

.. code-block:: none

 signal pointer get ssignal ptvar

The ``signal pointer get`` instruction gets a signal pointer; for example, ``tsignal`` pointer absolutely into e.g. ptvar.

Bus Write
^^^^^^^^^

.. code-block:: none

 bus write abus $width $address $wvar
 bus write abus 32 0x0004 0x12345678

The ``bus write`` instruction writes a variable, constant, or numeric value to a bus with a given width and address.

Bus Read
^^^^^^^^

.. code-block:: none

 bus read abus $width $address tvar

The ``bus read`` instruction reads the value of a bus with a given width and address into a variable.

Bus Pointer Copy
^^^^^^^^^^^^^^^^

.. code-block:: none

 bus pointer copy tsignal ssignal

The ``bus pointer copy`` instruction copies a bus pointer; for example, ``tbus`` pointer is a copy of
``sbus``

Bus Pointer Set
^^^^^^^^^^^^^^^

.. code-block:: none

 bus pointer set tbus 5
 bus pointer set tbus $ptvar

The ``bus pointer set`` instruction sets a bus pointer; for example, ``tbus`` pointer absolutely.

Bus Pointer Get
^^^^^^^^^^^^^^^

.. code-block:: none

 bus pointer get sbus ptvar

The ``bus pointer get`` instruction gets a bus pointer; for example, ``tbus`` pointer absolutely into e.g. ptvar.

Bus Timeout Set
^^^^^^^^^^^^^^^

.. code-block:: none

 bus timeout set abus $svar
 bus timeout set abus 1000

The ``bus timeout`` instruction sets the timeout in nanoseconds to wait for a bus access to end. On
violation, the simulation stops with severity failure always.

Bus Timeout Get
^^^^^^^^^^^^^^^

.. code-block:: none

 bus timeout get sbus tovar

The ``bus timeout get`` instruction gets a bus timeout; for example, ``tbus`` pointer absolutely into e.g. tovar.
