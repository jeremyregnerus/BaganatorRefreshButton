Baganator Refresh Button v0.8.0 — WoW Forever
================================================

Visual styling update from v0.7.0:
- Uses BaganatorTooltipIconButtonTemplate, the same XML template inherited
  by Baganator's Sort button. Inherits the actual border, panel, highlight
  and pushed textures, no handmade substitutes.
- Registers as an IconButton with Baganator's active skin (when available).
- Reads both the actual Sort button size and the Sort icon size at runtime.
- Keeps the transparent gold refresh-arrow artwork you liked.
- Does NOT change the working manual refresh command, keybinding, positioning,
  bank Transfer-button avoidance, diagnostic commands, or test-mode behavior.

Install:
1. Exit WoW completely.
2. Replace Interface/AddOns/BaganatorRefreshButton with the folder in this ZIP.
3. Restart and compare Refresh directly beside Sort.

Commands:
/bgrrefresh or /bgrr: refresh categories in place
/bgrdebug: show position and size info
/bgrtest: toggle centered button positioning for diagnosis

Requires Baganator. This has not been tested within the Forever client.
If your active Baganator skin customizes the Sort button differently from
its standard IconButton style, a screenshot will help identify that difference.
