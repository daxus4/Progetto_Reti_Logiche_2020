# Progetto_Reti_Logiche_2020
Prova Finale di Reti Logiche - Polimi Ingegneria Informatica - a.a. 2019/2020

A large part of chip energy consumption is due to transmission of signals through its pins. When encoding an external address bus, programs usually tend to work with a limited number of working zones (WZ). Once that these zones are identified, a chip can use the WZ encoding, for reducing the energy consumption [1]. Particularly, with this method an address is composed of two parts: the first part contains a number that identifies the WZ that contains the address, and the second part contains the offset of the address from the start of the WZ, using the one-hot encoding. This one-hot encoding, since it has a unique bit set to 1, allows to reduce energy consumption when transmitting information.

During this project, in collaboration with a classmate of mine, we developed an algorithm in VHDL that takes in input a 7-bit address and a set of WZ and encodes the address with WZ encoding if it is within one of them and transmits it, otherwise the address will be transmitted without encoding.
We tested the algorithm, selecting borderline and random cases, and it worked with each test.

[1] E. Musoll, T. Lang and J. Cortadella, "Working-zone encoding for reducing the energy in microprocessor address buses", in IEEE Transactions on Very Large Scale Integration (VLSI) Systems, vol. 6, no. 4, pp. 568-572, Dec. 1998
