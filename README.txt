Baganator Refresh Button v0.4.0 — WoW Forever
============================================

CHANGELOG
- Keep working /bgrrefresh, /bgrr, and keyboard binding unchanged.
- Use one button, selected from the currently on-screen Sort controls.
- Prefer the backpack sort (by frame hierarchy) rather than bank sort.
- Raise the button above the bag header so it cannot be hidden by another header layer.
- Force a visible border and use the original refresh artwork (explicit .tga path).
- /bgrdebug now lists EVERY Sort candidate with its parents, screen coordinates,
  and the UI dimensions (v0.3 accidentally only printed one Sort).
- /bgrtest toggles a centered version of the SAME clickable button as a visibility
  test, independent of the Baganator header. Run again to restore placement.

INSTALL
1. Exit WoW and delete the old AddOns/BaganatorRefreshButton directory.
2. Extract the package to .../_forever_/Interface/AddOns/.
3. Restart WoW and open Categories view.
4. The refresh icon should appear to the left of the visible Sort control.
5. If invisible, use /bgrdebug and /bgrtest to distinguish wrong positioning
   from a texture/layer problem; send output and whether center test appears.

CONTROLS
Click Refresh to rebuild Categories view without closing bags or sorting items.
Assign a shortcut under Options > Keybindings > AddOns.
/bgrr or /bgrrefresh : refresh
/bgrdebug           : detailed button/Sort diagnostics
/bgrtest            : toggle a centered, clickable visibility test

Compatibility note: Baganator 868 changed its header buttons and this remains an
untested-in-game companion integration. The refresh action itself was verified.
