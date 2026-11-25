Baganator Refresh Button v0.9.1 — WoW Forever
================================================

Retains the working v0.9.0 design with a keybinding label adjustment:
- Uses Baganator's exact native button template and the same gold refresh glyph.
- Detects the actual space between native Baganator header controls and matches
  that gap for Refresh. Defaults to 2 UI units if no neighbors are available.
- Optional /bgrgap N (0 to 10) persists a manual gap if necessary; /bgrgap auto
  returns to automatic detection.
- Moves the binding from the generic AddOns group to its own named category:
  "Baganator Refresh Button" with action "Refresh".
- Keeps the old binding action ID, so your chosen key is preserved.
- Preserves bank Transfer-button avoidance, slash commands, and in-place refresh.

Install:
1. Exit WoW completely.
2. Replace Interface/AddOns/BaganatorRefreshButton with the folder in this ZIP.
3. Restart WoW.

Commands:
/bgrrefresh or /bgrr: refresh Categories in place
/bgrgap auto: use native header-gap measurement (default)
/bgrgap 2: manually set button spacing to 2 UI units
/bgrdebug: show placement details, including gap
/bgrtest: toggle centered visibility test

Binding: Options > Keybindings > Baganator Refresh Button > Refresh

Why a separate binding category?
The modern WoW bindings interface does not reliably support merging actions into
another addon's existing subsection using the old XML header field. This keeps
Baganator untouched and avoids relying on its implementation details.

Requires Baganator. The native UI integration is not in-game verified on Forever.
