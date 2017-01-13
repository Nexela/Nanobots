Nanobots:

* Early version of ghost building construction bots. Allows researching automated construction earlier (for blueprints etc)
* Equip the Nano Emitter and Some Nano ammo, make it your selected gun and any ghosts/blueprints within 7.5 tiles of you will be automatically built if you have the items in your inventory.
* These early version bots are only capable of building and do not replenish (each Ammo magazine will build 20 items)
* Nanobots do not work inside logistic networks, or personal roboport zones.
* Nanobots can now be shot into an area to do their job.

---
Ammo Details:

* Nano Constructors - These nanobots will revive ghosts in their range
* Nano Termites - These nanobots will kill off trees. Some damage might happen to buildings that are too close to trees.
* Nano Scrappers - These nanobots will destroy anything in their range that is marked for deconstruction that isn't organic. You will not get an item back.
* Nano Deconstructors - These nanobots have more programing and will return deconstructed items to you.

---
Late Game Additions:

* Adds to new equipment pieces for your armor that enhance your personal roboport.
* The Item Programmer will mark all items-on-ground (artifacts, etc) in your robo construction range for deconstruction as long as no enemies are around.
* The Tree Programmer will mark all trees within 10 * (Number of equipped programmers) tiles from you for deconstruction.

---
Future Plans and Known issues:

* All actions are added to a first in, first out queue system. If a lot of items are queued up (I.E. deconstructing a whole forest). It will take some time before it gets around to doing something else, like building or deconstruction a different area.
* More optimizations! Around the tick handler/player loop mostly
* More Personal Roboport Programmers.

Change Log:

* 1.0.0 - Initial Release
* 1.0.1 - Raise event when building entity
* 1.0.2 - Remove Debug line
* 1.0.3 - Better entity-to-item logic
* 1.0.4 - Constructors now do floor tiles, Ghost building is queued, Visual enhancements.  (Scrappers/deconstructors don't do anything yet)
* 1.0.5 - Silly 5 am bobmods typo
* 1.0.6 - Scrappers and Deconstructors added, Small bug fixes/tweaks, Some entites (inserters) are added to the end of the queue.
* 1.0.7 - Hard Crash on invalid ammo
* 1.0.8 - More sanity checks
* 1.0.9 - Remove the shooting event pending more info on crash. Shooting nanobots is now just visual and wastes nanobots. Reverted termite changes,
* 1.2.0 - Many changes, Nanobots are now smarter and harder working!
