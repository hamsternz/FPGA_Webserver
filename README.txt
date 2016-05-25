I'm slowly building a hardware-based web server.

Feel free to look around, but it is not yet anywhere near working

Status
======
* ARP works at Gigabit speeds
* Going to start working on ICMP

TODO LIST OF MINOR ISSUES THAT I DON'T WANT TO FORGET
=====================================================
* Inbound packet reception errors should cause the packet to be dropped.
* Inbound packet CRC verification is not being performed - should cause 
  packet to dropped
* Inbound packet MAC filtering not coded - should only accept packets 
  for 'our_mac' or the broadcast MAC. This could be handled the same as 
  CRC or reception errors (where  the FIFO can be rolled back)
* Outbound packets are not being send correctly for 10 & 100Mbps speed. 
  This requies a 4k FIFO, which will block the arbiter when less then 
  1600 entries are free (enough for a packet an some loop latency)