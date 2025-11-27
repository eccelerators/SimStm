Bus
^^^

.. code-block:: simstm

 bus a_bus

The ``bus`` instruction declares a bus object with ID.

The signal object associates a SimStm bus name with a bus number. This
bus number must be given in the tb_bus package by customization and
attached to a bus.

Bus Access
~~~~~~~~~~

Bus Write
^^^^^^^^^

.. code-block:: simstm

 bus write a_bus a_width an_address a_var
 bus write a_bus 32 0x0004 0x12345678

The ``bus write`` instruction writes a variable, constant, or numeric value to a bus with a given width and address.

Bus Read
^^^^^^^^

.. code-block:: simstm

 bus read a_bus a_width an_address a_var

The ``bus read`` instruction reads the value of a bus with a given width and address into a variable.

Bus Verify
^^^^^^^^^^

.. code-block:: simstm

 bus verify a_bus a_width an_address a_var e_var m_var
 bus verify a_bus a_width an_address a_var 0x01 0x0F

The ``bus verify`` instruction reads the value of a bus with a given width and address into a variable 
and compares it to an expected value with a given mask. The expected values and masks can be variables,
constants, or numeric values. On mismatch, the simulation stops with
severity Failure if the global resume is set to 0; otherwise, it continues and reports an error.

Bus Pointer Copy
^^^^^^^^^^^^^^^^

.. code-block:: simstm

 bus pointer copy t_bus s_bus

The ``bus pointer copy`` instruction creates a bus pointer; for example, ``t_bus`` points to ``s_bus`` after the execution of the instruction.
Used, for instance, to hand over a bus to a subroutine. Changes to the source
bus are applied to the target bus as well.

Bus Pointer Set
^^^^^^^^^^^^^^^

.. code-block:: simstm

 bus pointer set t_bus 5
 bus pointer set t_bus ptr_var

The ``bus pointer set`` instruction sets a bus pointer (for example, the pointer ``t_bus``)
to an absolute address.

Bus Pointer Get
^^^^^^^^^^^^^^^

.. code-block:: simstm

 bus pointer get s_bus ptr_var

The ``bus pointer get`` instruction gets the value of a bus pointer and stores it in a variable.
For example, the pointer ``s_bus`` is stored in ``ptr_var``.

Bus Timeout Set
^^^^^^^^^^^^^^^

.. code-block:: simstm

 bus timeout set a_bus s_var
 bus timeout set a_bus 1000

The ``bus timeout`` instruction sets the timeout in nanoseconds to wait for a bus access to end. On
violation, the simulation stops with severity Failure always.

Bus Timeout Get
^^^^^^^^^^^^^^^

.. code-block:: simstm

 bus timeout get s_bus to_var

The ``bus timeout get`` instruction gets a bus timeout and stores it in a variable; for example, the timeout ``s_bus`` is stored in ``to_var``.