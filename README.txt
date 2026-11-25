Baganator Refresh Button v0.2.0 -- WoW Forever
==============================================

CHANGES FROM 0.1.0
------------------
* Fixed keybindings declaration: Bindings.xml is automatically loaded by WoW.
  It should NOT be listed in the .toc file; binding placed under AddOns.
* Locate Baganator's real Sort button via the supported Skins IconButton
  "sort" tag instead of assuming bagFrame.SortButton exists on version 868.
* Keep existing working refresh logic exactly as before.
* A troubleshooting command /bgrdebug reports detected Sort controls and
  successfully attached Refresh buttons.

INSTALL
-------
Replace the entire BaganatorRefreshButton addon folder with the included one:
World of Warcraft/_forever_/Interface/AddOns/BaganatorRefreshButton/

Exit WoW fully and restart it (not merely /reload) to pick up Bindings.xml.
Look to the LEFT of Sort in your bag header, in Categories view.

KEYBINDING
----------
Esc > Options > Keybindings > AddOns > Baganator Refresh Button.
Assign any free key to "Refresh Baganator Categories".

COMMANDS
--------
/bgrrefresh    Manually refresh Categories layout (bag remains open)
/bgrr          Short alias of the same command
/bgrdebug      Show skin registration and button-detection counts

IF THE BUTTON IS STILL ABSENT
-----------------------------
Run /bgrdebug in chat and report the three values. This reveals whether
Baganator's current skin registry is supplying the Sort button to us.

NOTE
----
The refresh callback is verified by the user on Baganator 868 / WoW Forever.
Button and keybinding code has been revised using Baganator's documented
skin-listener pattern, but cannot be tested in-game here. Future updates to
Baganator's private button construction could require further changes.
