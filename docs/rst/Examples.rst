Examples
--------

Hello World
~~~~~~~~~~~

.. code-block:: simstm

 const YEAR 2023
 var month 11
 var day 22

 testMain:
 proc
     loop 3
       log message 0 "Hello World {:d}-{:d}-{:d}" YEAR month day
     end loop`
     finish
 end proc

This example is a unit test too and can be found in the repository
folder `tb/simstm/others <./tb/simstm/others>`__. 
The file others.stm contains the testOtherHelloWorld test subroutine.

An demonstration of all commands is in the file
`command_list.stm <./command_list.stm>`__ in the repository root
folder..

Real-World Examples
~~~~~~~~~~~~~~~~~~~

Complex real-world example are found in the eccelerators group of
repositories on `GitHub <https://github.com/eccelerators>`__.
