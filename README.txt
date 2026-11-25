Baganator Refresh Button v0.3.0 — WoW Forever
=============================================

CHANGES
-------
- Keybinding code is unchanged from v0.2.0 (confirmed working by user).
- Rebuilt the on-screen control as an independent button attached to UIParent,
  anchored immediately to the left of Baganator's Sort button.
- No longer inherits Sort's alpha or uses the internal Sort button template,
  either of which could cause the created button to be invisible.
- Checks visibility and transfer-button positioning while the bag is open,
  retaining the button next to Sort when Baganator updates the header.
- Added expanded /bgrdebug diagnostics for visibility, alpha, coordinates,
  and whether the backpack/transfer container was discovered.

INSTALL
-------
1. Exit World of Warcraft.
2. Remove the old AddOns/BaganatorRefreshButton folder.
3. Extract this zip into .../_forever_/Interface/AddOns/.
4. Start WoW and open your bags in Categories view.

CONTROLS
--------
Click the circular-arrow button directly left of Sort (if it appears).
Bind a key under Options -> Keybindings -> AddOns.
/bgrr or /bgrrefresh to manually refresh Categories.
/bgrdebug to report the on-screen button state (run with bags open).

The internal Baganator refresh call is the one verified in-game:
Baganator.CallbackRegistry:TriggerEvent("RefreshStateChange", {[2]=true,[128]=true})

No automatic vendoring updates, physical sorting, or bag closing.

NOTE
----
This release is a targeted, untested-in-game fix for the invisible button.
The source in the latest user-installed Forever release may differ from
public Baganator mirrors. If the button still fails, send the full output
of /bgrdebug while the bags are open so we can diagnose the remaining cause.
