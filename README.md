# RouterOS Configurations

## qos.rsc
### 2-Step QoS using using eight priorities and a preconfigured set of classifiers

The queue tree consists of a parent queue for managing the upstream rate of your
Internet connection. Under the parent queue are eight child queues, mapping to
each of the eight priorities defined.

The IP Firewall Mangle commands use a 2-step approach to maximize the efficiency
of your CPU--especially important for single-core MIPS CPUs and high-speed
Internet connections.

Rather than deep-inspecting every packet, we take a more efficient approach:
1. Deep-inspect, and mark as priority 1, every TCP SYN packet <= 123 bytes,
every TCP SYN-ACK packet <= 123 bytes, and every TCP ACK packet.
   * This allows the TCP 3-way handshake (setup) protocol to finish as fast as
     possible, minimizing latency of new connections, and maximizing download
     speed.
1. Deep-inspect only the first packet of new connections, that is, connections
   that are not already tracked in the Connection Tracking table.
   * Note: Connection Tracking must be enabled for the 2-step method to work.
     It is on by default, and must be used for NAT to function, so it is
     typically enabled on nearly all home and small-office networks.
1. Classify the new connection based on a variety of patterns found in the
   packets, including port numbers, DSCP bits, MAC addresses, etc.
1. Mark the connection based on the classification rule match.
1. Mark the packets according to the connection marking in the Connection
   Tracking table, which is much more efficient than deep-inspecting every
   packet.
1. The Queue Tree configuration prioritizes the outbound packet based on its
   packet marking value.
   
The "2-step QoS" approach is generally defined as such:
1. Mark the connection by evaluting only the first packet
1. Mark all packets of the connection by checking the value of the Connection
   marking

**Note:** The script assumes you are using the default `ether1` WAN/Internet interface. If
you are using something else, change this value everywhere in the script.

**Important:** You must perform upload speed tests to your ISP's **own** servers
to determine your exact generally achievable rate. Set the `max-limit=` to
90-95% of your generally achievable rate, or QoS will not function! You can
specify an exact bitrate, or use the "k" and "M" suffixes; decimals are not
allowed (i.e., use 8400k instead of 8.4M). After full configuration of the QoS
rules, test the upload speed again. While testing, watch the Queue Tree counters
to ensure you see Queued bytes. If you do not see some queued bytes, the
`max-limit=` is set too high.
* Do not test to common speed test services such as speedtest.net, Google,
  Netflix (fast.com), speedof.me, etc., unless your ISP does not provide a
  direct speed test service.
* You may need to contact your ISP to find out which address to use for
  conducting a speed test, and you should try to use a wired connection
  directly to your router or modem, if at all possible. The goal is to measure
  your generally available upload speed to your ISP, not through the ISP to the
  Internet.
