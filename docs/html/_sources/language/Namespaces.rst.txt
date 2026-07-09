Namespaces
~~~~~~~~~~

namespace
^^^^^^^^^

.. code-block:: simstm
	
	namespace a_namespace
		var a_var 0
	end a_namespace
	

The ``namespace`` instruction declares the beginning of a namespace with an ID.


Variables, procedures etc. declared in a namespace are only visible inside that namespace, they can however 
be accessed using fully qualified IDs like namespaceID.varID, for example ``a_namespace.a_var`` in other namespaces.
Namespaces are mandatory, wrapping every piece of code (except ``include`` statements) between a namespace declaration 
and ``end namespace`` instruction.

Multiple pieces of code in different files belong to the same namespace if they are wrapped by the same namespace ID.

