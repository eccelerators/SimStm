Files
-----

.. code-block:: none

 file a_file "filename.stm"
 file a_file "filename{:d}{:d}.stm" index1 index2

The ``file`` instruction declares a file with an ID and a file name.

The latter must be a relative path to the location of the main.stm file.
Text substitution by variables is allowed in file names. Thus, files can
be accessed in an indexed manner. The variables are evaluated every time
a reference to a file is used in another instruction accessing a
file, e.g., ``file read all a_file a_lines``.

File Access
~~~~~~~~~~~

File Writable
^^^^^^^^^^^^^^

.. code-block:: none

 file writable a_file r_var

The ``file writable`` instruction tests if a file is writable. If the file is not present, it is created
without having content. The result for ``STATUSOK`` is 0, ``STATUSERROR`` is 1,
``STATUSNAMEERROR`` is 2, ``STATUSMODEERROR`` is 3 and may, in case of error, depend
on the operating system.

File Readable
^^^^^^^^^^^^^

.. code-block:: none

 file readable a_file r_var

The ``file readable`` instruction tests if a file is readable. The result for ``STATUSOK`` is 0, ``STATUSERROR`` is 1,
``STATUSNAMEERROR`` is  2, ``STATUSMODEERROR`` is 3 and may, in case of error, depend
on the operating system.

File Appendable
^^^^^^^^^^^^^^^

.. code-block:: none

 file appendable a_file r_var

The ``file appendable`` instruction tests if a file is appendable. The result for ``STATUSOK`` is 0, 
``STATUSERROR`` is 1, ``STATUSNAMEERROR`` is 2, ``STATUSMODEERROR`` is 3 and may, in case of error,
depend on the operating system.

File Write
^^^^^^^^^^

.. code-block:: none

 file write a_file a_lines

The ``file write`` instruction writes all lines of a lines object to a file. The file is
overwritten if it exists.

File Append
^^^^^^^^^^^

.. code-block:: none

 file append a_file a_lines

The ``file append`` instruction appends all lines of a lines object to a file. The method will fail
if the file doesn't exist.

File Read All
^^^^^^^^^^^^^

.. code-block:: none

 file read all a_file a_lines

The ``file read all`` instruction reads all lines of a file into a lines object.

File Read
^^^^^^^^^

.. code-block:: none

   file read a_file a_lines n_var
   file read a_file a_lines 10

The ``file read`` instruction reads a number of lines from a file into an lines object.

The first read opens the file for read, following reads start at the line after
the last line which has been read by the previous read. Thus a file can
be read piecewise similar as it can be written piecewise by file append.
The piecewise read process of the file must be terminated by a file read
end instruction always. The number of concurrent file read processes is
limited to 4.

File Read End
^^^^^^^^^^^^^

.. code-block:: none

   file read end a_file

The ``file read end`` instruction ends the piecewise read process of a file.

File Pointer Copy
^^^^^^^^^^^^^^^^^

.. code-block:: none

   file pointer copy t_file s_file

The ``file pointer copy`` instruction creates a file pointer; for example, ``t_file`` points to ``s_file`` after the
execution of the instruction. Used, for
instance, to hand over a file to a subroutine. Changes to the source
file are applied in the target file as well.
