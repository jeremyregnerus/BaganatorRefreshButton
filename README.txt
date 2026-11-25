Baganator Refresh Button v0.5.0 — WoW Forever
============================================

Changes from v0.4.0
- Keeps the working in-place Categories refresh and keybinding unchanged.
- Positions Refresh beside Backpack Sort, moving to the left of Transfer or
  other small header buttons when they occupy the space immediately left of Sort.
- Includes a bank-open fallback for context buttons not registered in the skin API.
- /bgrdebug reports the active positioning target and bank fallback status.
- /bgrtest is a visual test: run once to show the button at screen center,
  and again to return it to the backpack header. It is OFF at every login.

Install
1. Exit WoW completely.
2. Delete the old AddOns/BaganatorRefreshButton folder.
3. Extract this ZIP into _forever_/Interface/AddOns/.
4. Restart WoW, and open Categories view.

Controls
- Click the Refresh icon to clear empty placeholders without sorting items.
- Assign a shortcut in Options > Keybindings > AddOns.
- /bgrr or /bgrrefresh: refresh categories
- /bgrdebug: location and visibility diagnostics
- /bgrtest: toggle center-screen visibility test

Note: The button placement is based on live client diagnostics and has not
been verified in the Forever client itself. If there is still an overlap,
run /bgrdebug while the backpack and bank are both open.
