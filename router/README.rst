Remote Controlled Item Router
=============================

The router script runs on a Lua Controlled Sorting Tube and allows another node
on a Digiline network to remotely control routing of items.


Configuration
-------------

``unroutable``
    This string is the colour where items should be sent if they cannot be
    routed properly according to the instructions received so far from the
    Digiline network. Sending items to this destination indicates an error.

``channel``
    This string is the Digiline channel on which routing instructions are
    received and to which notifications and replies are sent.


Operational Overview
--------------------

The router maintains an internal routing table, keyed by item name (in
Minetest-internal form, e.g. ``default:cobble``). Unlike routing tables in, for
example, IP networks, the routing table in a remote controlled item router
contains entries that only apply to a certain number of items—for example, a
routing table entry might specify “please send seven ``default:cobble`` in the
red direction”. In a typical system, a controller will determine that a
particular number of a particular item needs to reach a particular destination,
then add routing table entries to the routers along the path to ensure the
items reach their destination. If the same item is needed in two places,
entries can be added simultaneously for both destinations; as items pass
through the system, they will go to one destination or the other, up to the
specified count in each direction, eventually delivering the proper number of
items to both destinations.

If a stack of more than one item arrives at the router, it will be sent to some
destination that has routing table entries adding up to at least the stack
size. The router will never send more items to a destination than the total
requested, though if the table has multiple entries for the same destination, a
single stack may contribute to more than one entry; for example, if there are
two three-item requests for the same item to the same colour, a single six-item
stack could be routed to that colour, but a seven-item stack would not. Because
stacks cannot be split, an overly large stack may generate an error; for
example, if there are two three-item requests for the same item to two
different directions, a single six-item stack would generate an error and be
sent to the unroutable colour because it cannot be split into two smaller
stacks. The system injecting item stacks into the routing network is expected
to act accordingly.


Digiline Message Structure
--------------------------

All messages sent to or from the router must be table-typed messages. Messages
are divided into commands and responses: commands are sent to the router while
responses are returned from the router. All command messages contain a key
named ``command`` with a string value identifying the nature of the command.
All response messages contain a key named ``response`` with a string value
identifying the nature of the response. Other keys contain additional
information whose meaning depends on the command or response.


``clear`` Command
-----------------

This command removes all routing table entries. No parameters are needed nor is
a reply generated. `Done response`_ messages are *not* sent for the removed
entries.


``query`` Command
-----------------

This command causes a `query_reply response`_ to be returned. No parameters are
needed.


``route`` Command
-----------------

This command adds one or more entries to the routing table. In addition to
having a ``command`` key, the message must also be an array—in other words, a
table with consecutive integer keys starting from 1. These array entries are
interpreted in order, with each entry being a routing table entry to add.

Routing Table Entry
^^^^^^^^^^^^^^^^^^^

An individual routing table entry in the ``route`` command is formatted as a
table. Within the table, the following keys are understood:

``name``
    This string is the Minetest-internal name of the item to route (e.g.
    ``default:cobble``). This key is required.

``count``
    This number is how many items the entry applies to. Once this many of the
    specified item have been routed according to this entry, the entry expires
    and is removed from the table. This key is required.

``direction``
    This string is the colour indicating which direction to send the items.
    This key is required.

``id``
    This value (of any type) is returned in a `done response`_ when the entry
    expires and can be used by the controller to distinguish entries. The value
    is not interpreted in any way, so the controller may supply any value. This
    key is optional; if not provided, the entry expires silently without a
    `done response`_ being returned.


``done`` Response
-----------------

This response informs the user that a routing table entry has expired. In
addition to the ``response`` key, the message also contains an ``id`` key,
which is set to the ``id`` value provided when the routing table entry was
initially added.


``query_reply`` Response
------------------------

This response reports a summary of all entries in the routing table and is only
sent in response to a `query command`_. In addition to the ``response`` key,
the message also contains an ``items`` key, whose value is a table keyed by
item name. Each item name maps to another table whose keys are the six
directional colours (all six are always present). Each colour maps to a
positive integer which is the number of items remaining to be sent in that
direction.


``error`` Response
------------------

This response reports an item stack that could not be routed properly. In
addition to the ``reponse`` key, the message contains ``name`` string and
``count`` integer keys describing the item stack as well as a ``reason`` string
key which is one of the following values:

``unknown``
    This reason is returned if there are no routing table entries for the item
    type.

``toomany``
    This reason is returned if the item stack is larger than the sum of all the
    routing table entries for the item type.

``unsplittable``
    This reason is returned if the item stack is within the sum of all routing
    table entries for the item type but larger than the sum of all routing
    table entries for any single colour.

In all cases the entire item stack is sent to the unroutable destination.
