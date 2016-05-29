I'm slowly building a hardware-based web server.

Feel free to look around, but it is not yet anywhere near working

Status
======
* ARP works at Gigabit speeds
* ICMP is working about 50% of the time (packet appears to not 
  matching the input filters)

TODO LIST OF MINOR ISSUES THAT I DON'T WANT TO FORGET
=====================================================
* Inbound packet reception errors should cause the packet to be dropped.
  Currently this is being done in the individual protocol handlers.

* Inbound packet CRC verification is not being performed - should cause 
  packet to dropped

* Inbound packet MAC filtering not coded - should only accept packets 
  for 'our_mac' or the broadcast MAC. This could be handled the same as 
  CRC or reception errors (where  the FIFO can be rolled back)

* Outbound packets are not being sent correctly for 10 & 100Mbps speed. 
  This requies a 4k FIFO, which will block the arbiter when less than 
  1600 entries are free (enough for a packet and some loop latency)

* ICMP 'echo request' is not validating the ICMP length fields correctly.

* ICMP 'echo request' is not validating the IP checksums
* ICMP 'echo request' is not validating the ICMP checksums

* ICMP 'echo request' processing is not yet using the outbound arbitor 
  correctly
