Pipeworks Lua Tube Scanner
==========================

The scanner script serves as a polyfill for the modern Digiline Detecting
Pneumatic Tube Segment for use on servers running older versions of Pipeworks.
It should be a drop-in replacement, so if the server is upgraded, the Lua
Controlled Sorting Tube can be replaced with an actual Digiline Detecting
Pneumatic Tube Segment without affecting the rest of the system.

In the current version of Pipeworks, the Digiline Detecting Pneumatic Tube
Segment sends a Digiline message in table format with details of the itemstack
passing through the segment. In older versions of Pipeworks, however, the
segment instead sent a string representation of the itemstack. When playing on
server running an older version of Pipeworks, this scanner script installed on
a Lua Controlled Sorting Tube can fill in for the detecting tube, as it sends
the itemstack information in table format.


Configuration
-------------

The `output_direction` string is the colour of output direction where all items
should be sent.

The `channel` string is the Digiline channel to which item-passing messages
will be sent.
