
SimStm
======

Why:

- Control HDL simulation tests from power-on to power-off using simple yet powerful instructions in ``.stm`` files dedicated solely to this purpose.
- Use the same ``.stm`` files to stimulate tests independently of the bus interface used.
- Easily adapt it to the buses and signals your testbench needs.
- Transparently follow the execution of your instructions through the pure VHDL interpreter during simulation.
- Use interrupts to naturally respond to events.
- Instantiate it multiple times to model multi-core systems and verify that your design is hardened against concurrency issues.
- Modify ``.stm`` files on the fly without recompiling HDL when changing stimuli.
- No need to learn another language such as Python, which often leads to opaque, over-engineered software for testbenches. 
  Instead, use a simple, human-readable instruction set that is easy to understand and maintain for HW and SW engineers alike.
- Use it to create a library of reusable test scenarios that can be shared across projects and teams.


How to: `SimStm HTML docs`_

.. _SimStm HTML docs: https://eccelerators.github.io/SimStm/