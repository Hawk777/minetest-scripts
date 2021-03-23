Technic Power Network Regulator
===============================

The power network regulator script manages a Technic supply converter to
convert power from one voltage to another without wasting power. The regulator
script monitors the charge level of a set of battery boxes on the output
network and controls a supply converter. The supply converter is turned on when
the battery charge level gets low, to keep the network running, and turned off
when the battery charge level gets high, to avoid wasting power on the input
network by running the supply converter when not needed.


Configuration
-------------

The battery_boxes string is the name of the Digiline channel on which all the
battery boxes are listening.

The supply_converter string is the name of the Digiline channel on which the
supply converter is listening.

The poll_interval integer is the number of seconds between updates. This number
must be greater than 1.

The min_charge integer is the percentage (from 0 to 100) at which the supply
converter should turn on.

The max_charge integer is the percentage (from 0 to 100) at which the supply
converter should turn off.
