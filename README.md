# trx-control

Software to control amateur radio transceivers.

trx-control consists of trxd(8), a daemon to control the transceivers,
trxctl(1), a command line utility to access trxd(8), and, xqrg(1), a
graphical client to display a transceivers frequency. trxctl(1) and
xqrg(1) are meant as reference clients only.
Software that wants to make use of trxd(8) should implement the protocol
and talk to trxd(8) directly over the network.

trxd(8) listens on port 14285 by default for incoming connections.
It supports both IPv4 and IPv6.

The effective transceiver control is done using Lua modules,
this way new transceivers can easily be supported by supplying
a corresponding Lua driver module for a specific transceiver model.
See https://lua.org and https://lua.msys.ch for more information
on Lua.

## Supported transceivers

Initially, trx-control will support the following transceivers:

* Yaesu FT-710
* Yaesu FT-897
* Yaesu FT-817
* Yaesu FT-991A

A special dummy transceiver driver exists for development and testing
purposes.

## More information

More information can be found the wiki at
https://github.com/hb9ssb/trx-control/wiki

## Signal group

You can join a group on signal to discuss trx-control:
https://signal.group/#CjQKIDkha6NGciRN-eA-qWjMTvtDfLkCeUBR_CDFtkMPJH9wEhAAVKw8SHl3dGIvVU2AT2sR
