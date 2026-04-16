Include
-------

.. code-block:: simstm

 include "aninclude.stm"

Include another child ``\*.stm file``.

The ``include`` instructions should be the first instructions of a ``\*.stm file``
as they are not allowed inside a namespace.
An included file can include further ``\*.stm files``, thus nested includes
are possible. The file path to be given is relative to the file with the
respective include instruction. Nested includes of files from the same
folder or in child folders are predictable; nested includes to files in
parent folders would be bad practice.
