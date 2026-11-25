"""12 stall list icons, dark look, 32 px, a big readable trade sign (weaponsmith_forge and apothecary_row use the test icons)."""
M="grim dark fantasy chibi pixel art, worn and weathered, ominous mood, muted desaturated colours, deep black shadows, heavy chunky silhouette, thick dark outline, one strong rim light of "
P=", a chibi tiny market stall seen from the front, chunky, ragged awning, a counter with wares, "
Q=", no people, the object alone"
IDS={
'blind_beggar_stall':M+"cold blue"+P+"a big clear eye symbol on a hanging board, a tin bowl on the counter, grey patched cloth"+Q,
'black_market_docks':M+"ember gold"+P+"a big clear fish hook symbol on a hanging board, barrels and a red lantern"+Q,
'shieldwrights_hall':M+"cold blue"+P+"a big clear round shield symbol on a hanging board, shields leaning on the counter"+Q,
'arcane_bazaar':M+"void violet"+P+"a big clear star symbol on a hanging board, a crystal ball on the counter, violet awning"+Q,
'smugglers_vault':M+"ember gold"+P+"a big clear key symbol on a hanging board, crates and a small locked chest"+Q,
'hammersmith_forge':M+"ember gold"+P+"a big clear hammer symbol on a hanging board, a glowing furnace and iron ingots"+Q,
'arcane_academy':M+"cold blue"+P+"a big clear open book symbol on a hanging board, a lit candle and scrolls, blue awning"+Q,
'sharpweave_den':M+"void violet"+P+"a big clear needle and thread symbol on a hanging board, bolts of dark cloth, red curtain"+Q,
'ossuary_relics':M+"sickly green"+P+"a big clear skull symbol on a hanging board, stacked skulls and bones, a candle"+Q,
'last_lantern':M+"ember gold"+P+"a big clear glowing lantern hanging from the awning, tankards on the counter"+Q,
'anchorage_chandlery':M+"cold blue"+P+"a big clear anchor symbol on a hanging board, coiled rope and a ship's lamp"+Q,
'wayfarer_caravan':M+"ember gold"+P+"a big clear wagon wheel symbol on a hanging board, packs and a water skin, canvas awning"+Q,
}
SUFFIX=", game icon, no text, centred"
T=""
RETRY={}

# Round 2: the SIGN is the icon: a bold symbol on a hanging board under a small awning, bright glow behind it
S2=lambda rim,sym,extra="":M+rim+", a chibi game icon: a big bold clear "+sym+" symbol filling the middle on a hanging wooden sign board, a tiny ragged awning above and a tiny counter below"+extra+", high contrast, readable at small size, no people, the object alone"
RETRY={
'hammersmith_forge':S2("ember gold","war hammer",", orange furnace glow behind"),
'ossuary_relics':S2("sickly green","skull",", green candle glow"),
'anchorage_chandlery':S2("cold blue","ship anchor"),
}
