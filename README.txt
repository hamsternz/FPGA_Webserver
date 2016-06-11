I'm slowly building a hardware-based web server.

Feel free to look around, but it is not yet anywhere near working

Status
======
* ARP works at Gigabit speeds
* ICMP is working at Gigabit speeds
* UDP RX works

TODO LIST OF MINOR ISSUES THAT I DON'T WANT TO FORGET
=====================================================
General
-------
* A lot of modules are inferring distributed RAM rather than the desired Block RAM.
  Fixing this will save a lot of LUTS (approx 1,500).

Inbound packets
---------------
* Inbound packet reception errors should cause the packet to be dropped.
  Currently this is being done in the individual protocol handlers.

* Inbound packet CRC verification is not being performed - should cause 
  packet to dropped

* Inbound packet MAC filtering not coded - should only accept packets 
  for 'our_mac' or the broadcast MAC. This could be handled the same as 
  CRC or reception errors (where  the FIFO can be rolled back). Doing this
  in one place could save resources.

UDP Support
-----------
* UDP TX in not asserting udp_busy as needed
* UDP TX is not padding packets out to minimum frame size
* UDP TX can not send a packet without any data.

* UDP RX IP Checksum is not being validated
* UDP RX UDP Checksum is not being validated
* UDP RX a packet with no data will not result in anything that the 
  consuming design can see (not a bug, a feature?)

ICMP Support
------------
* ICMP 'echo request' is not validating that the IP checksum is correct
* ICMP 'echo request' is not validating that the ICMP length field is correct.
* ICMP 'echo request' is not validating that the ICMP checksum is correct

Outbound packets
----------------
* Outbound packets are not being sent correctly for 10 & 100Mbps speed. 
  This requies a 4k FIFO, which will block the arbiter when less than 
  1600 entries are free (enough for a packet and some loop latency)
