Bus
^^^

.. code-block:: simstm

 bus a_bus 10
 bus a_bus a_const
 bus a_bus a_global_var

The instruction ``bus`` declares a bus object with ID initialized with a global variable, constant or literal. 

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

The instruction ``bus write`` writes a variable, constant, or numeric value to a bus with a given width and address.

In the example, the value of ``a_var`` is being stored in ``a_bus``.

Bus Read
^^^^^^^^

.. code-block:: simstm

 bus read a_bus a_width an_address a_var

The instruction ``bus read`` reads the value of a bus with a given width and address into a variable.

In the example, the value of ``a_bus`` is stored in ``a_var``.

Bus Verify
^^^^^^^^^^

.. code-block:: simstm

 bus verify a_bus a_width an_address a_var e_var m_var
 bus verify a_bus a_width an_address a_var 0x01 0x0F

The instruction ``bus verify`` reads the value of a bus with a given width and address into a variable 
and compares it to an expected value with a given mask. The expected values and masks can be variables,
constants, or numeric values. On mismatch, the simulation stops with
severity Failure if the global resume is set to 0; otherwise, it continues and reports an error.

In the example, it is verified that the value of ``a_bus``, which is stored in ``a_var``, is the same as the value of ``e_var``,
with the mask ``m_var``.

Bus Pointer Copy
^^^^^^^^^^^^^^^^

.. code-block:: simstm

 bus pointer copy t_bus s_bus

The instruction ``bus pointer copy`` creates a bus pointer; 

In the example, ``t_bus`` points to ``s_bus`` after the execution of the instruction.
Used, for instance, to hand over a bus to a subroutine. Changes to the source
bus are applied to the target bus as well.


Bus Pointer Set
^^^^^^^^^^^^^^^

.. code-block:: simstm

 bus pointer set t_bus 5
 bus pointer set t_bus ptr_var

The instruction ``bus pointer set`` sets a bus pointer to an absolute address.

In the example, the pointer ``t_bus`` is set to 5.

Bus Pointer Get
^^^^^^^^^^^^^^^

.. code-block:: simstm

 bus pointer get s_bus ptr_var

The instruction ``bus pointer get`` gets the value of a bus pointer and stores it in a variable.

In the example, the pointer ``s_bus`` is stored in ``ptr_var``.

Bus Timeout Set
^^^^^^^^^^^^^^^

.. code-block:: simstm

 bus timeout set a_bus s_var
 bus timeout set a_bus 1000

The instruction ``bus timeout`` sets the timeout in nanoseconds to wait for a bus access to end. On
violation, the simulation always stops with severity Failure.


Bus Timeout Get
^^^^^^^^^^^^^^^

.. code-block:: simstm

 bus timeout get s_bus to_var

The instruction ``bus timeout get`` gets a bus timeout and stores it in a variable; 

In the example, the timeout ``s_bus`` is stored in ``to_var``.

