Namespace
---------

.. code-block:: simstm
	
	namespace a_namespace
		var a_var 0
	end a_namespace
	

The ``namespace`` instruction declares the beginning of a namespace with an ID.

A namespace is comparable to a class. Variables etc. declared in a namespace are only visible
inside that namespace, they can however be accessed using namespaceID.*, for example ``a_namespace.a_var``.
Namespaces are necessary, meaning every piece of code (except ``include`` statements)
needs to be inside a namespace.

A namespace must be closed with the instruction ``end namespace``.




