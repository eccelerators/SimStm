
Labels
------

.. code-block:: simstm
	
 label lbl_var a_var
 
The instruction ``label`` declares and defines a label with an ID and an initial value.

A label can act as a placeholder for actual values which are modifiable through ``label equ``, ``label set`` or ``label pointer copy``.

Label Equ
^^^^^^^^^

.. code-block:: simstm
	
 label equ lbl_varA lbl_varB
 
The instruction ``label equ`` sets the value of a label to a different label.

In the example, ``lbl_var`` is set to the value of ``a_var``.

Label Set
^^^^^^^^^

.. code-block:: simstm
	
 label set lbl_var a_var
 


Label Pointer Copy
^^^^^^^^^^^^^^^^^^

.. code-block:: simstm
	
 label pointer copy lbl_var a_var
 
The instruction ``label pointer copy`` creates a label pointer.

In the example, ``lbl_var`` points to ``a_var``.


