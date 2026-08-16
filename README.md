Ashamane GM Panel v0.2.0

Install
1. Extract/copy the AshamaneGMPanel folder to your Legion client AddOns folder:
   World of Warcraft/Interface/AddOns/AshamaneGMPanel/
2. Confirm the folder contains AshamaneGMPanel.toc and AshamaneGMPanel.lua directly.
3. At the character-selection screen, click AddOns and enable Ashamane GM Panel.
4. In game, type /gmpanel or /agm.

Behavior
- The addon does NOT send commands automatically.
- Clicking a button places the generated GM command into the chat-edit box.
- Review the command and press Enter to submit it.
- AshamaneCore remains responsible for accepting or rejecting commands based on your GM permissions.

Examples
- Select a player, then click Player > Kill selected target. It places .die in chat.
- Select a dead player, then click Player > Revive selected target. It places .revive in chat.
- Select a player, then Spells & Auras > Apply aura to selected target, enter 642. It places .aura 642 in chat.

Notes
- This first version is intentionally compact and uses only native WoW UI APIs suitable for a Legion-era addon.
- It does not claim to verify GM status. The server is the authoritative permission checker.
