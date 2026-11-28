Baganator Refresh Button v0.9.2 — WoW Forever
================================================

One action now performs BOTH category cleanups:
1. Clear the Recent items category (same internal handler as left-clicking its
   header), returning recent items to their appropriate categories.
2. Refresh category sorting/layout to remove empty placeholder slots.

This works from the button, assigned hotkey, /bgrrefresh, or /bgrr.
There is NO automatic refresh when selling/looting items, and no physical
inventory slot sorting. If Baganator changes its internal Recent-header
handler in a future release, the normal refresh still operates.

All other v0.9.1 functionality is retained:
- Native Baganator button styling and gold arrow icon.
- Backpack header positioning and bank Transfer-button avoidance.
- Persistent /bgrgap override (your existing /bgrgap 0 is preserved).
- Binding category "Baganator Refresh Button" and action "Refresh".
- Existing binding identifier, so your chosen key remains assigned.

Install:
1. Exit WoW completely.
2. Replace Interface/AddOns/BaganatorRefreshButton with the folder in this ZIP.
3. Restart WoW.

Commands:
/bgrrefresh or /bgrr: clear Recent and refresh Categories in place
/bgrgap auto: detect native button spacing (default)
/bgrgap 0: manually set zero gap (recommended if you previously used it)
/bgrdebug: show placement details
/bgrtest: toggle centered visibility test

Binding: Options > Keybindings > Baganator Refresh Button > Refresh

Requires Baganator. Implementation follows Baganator 868's category header
OnClick behavior and is not yet verified in-game on WoW Forever.
