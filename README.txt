Baganator Refresh Button v0.1.0 -- WoW Forever
================================================

Purpose
-------
A manual in-place refresh for Baganator Categories view. Clicking the new
header button or activating the keybinding triggers Baganator's confirmed
working RefreshStateChange event with flags 2 and 128. It does not close
or reopen your bags, actually sort items between slots, or refresh on sales.

Installation
------------
1. Exit WoW.
2. Extract this archive to:
   World of Warcraft/_forever_/Interface/AddOns/
3. Make sure you have the folder:
   .../AddOns/BaganatorRefreshButton/
   containing Main.lua, Bindings.xml, Assets/, and the .toc file.
4. Launch the game and enable "Baganator Refresh Button" in AddOns.
5. Open Baganator in Categories view. Look immediately LEFT of Sort.

Keybinding
----------
Open Game Menu > Options > Keybindings and find the "Baganator Refresh
Button" section. Bind "Refresh Baganator Categories" to any free key.

You can also use /bgrrefresh or /bgrr from chat.

Compatibility / limitations
---------------------------
- Intended for Baganator 868 on Forever 1.60.1.
- Built against header/button interfaces documented in older public Baganator
  source; the exact 868 client was NOT available for in-game testing.
- The code uses Baganator's internal callback and skin frame registry, not
  a guaranteed public API. Future Baganator releases may require changes.
- If the button is absent but /bgrrefresh works, Baganator may have changed
  its header structure. Check the companion code against your installed
  Baganator files and send the relevant header files for an exact adjustment.
