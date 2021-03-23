I/O Expander Polyfill
=====================

The IOX script serves as a polyfill for the Cheapie Systems Digilines I/O
Expander, for use on servers where that node is not available. It should be a
drop-in replacement, so if the actual Digilines I/O Expander is later installed
on the server, the Luacontroller can be replaced with an actual I/O Expander
without affecting the rest of the system.

Note that the actual Cheapie Systems IOX sends extra pin-state messages when
output signals go from high to low. It is unclear whether this is a feature or
a bug, and the information necessary to replicate the behaviour is not
available to a Luacontroller, so this has not been implemented. A system using
unidirectional I/O will not care about this difference; a system using
bidirectional I/O may need to send an extra `GET` request after deactivating an
output in order to determine whether the attached wire contains any other
active drivers (but this is likely the case anyway since an actual IOX would
only report this situation by the absence of a message, not by a message
containing different values).


Configuration
-------------

The `channel` string is the Digiline channel which listens for new output
states and `GET` requests, and where new input states are sent.


Bugs
----

The behaviour of I/O pins connected to wires with multiple drivers is slightly
different between the Cheapie Systems IOX and this IOX. The specific details
are quite complex and may or may not involve bugs on either side. I recommend
treating each I/O pin as unidirectional.
