Includes
~~~~~~~~

include
^^^^^^^

.. code-block:: simstm

 include "aninclude.stm"

Include another child ``\*.stm file``.

The ``include`` instructions should be the first instructions of a ``\*.stm file``
as they are not allowed inside a namespace.
An included file can include further ``\*.stm files``, thus nested includes
are possible. The file path to be given either is prefixed with the generic stimulus_path given via the tb_simstm entity or 
is relative to the file with the respective include instruction if it contains ``./`` or ``../`` elements. 
Later nested relative includes of files from the same folder or into child folders are predictable; nested includes to files in
parent folders may not be a good practice.
