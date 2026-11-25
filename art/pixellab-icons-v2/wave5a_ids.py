"""Wave 5a: 14 shops + 10 chests (32 px, V2 chibi colour, extended palette). The object alone."""
O=", the object alone, no people, no characters"
S=lambda s:"a chibi tiny shopfront seen from the front, chunky, small awning and counter, "+s
IDS={
# 14 shops (ids = shops.json keys)
'blind_beggar_stall':S("a ragged cloth stall with a tin bowl on the counter, a walking stick, grey and brown patched cloth"),
'black_market_docks':S("a dark cellar door under a barrel and rope, a faint red lantern, a crate of bottles"),
'weaponsmith_forge':S("a stone forge with a glowing orange fire, an anvil, a crossed sword and axe sign"),
'shieldwrights_hall':S("a wooden hall front with three round shields hanging, a shield sign above the door"),
'arcane_bazaar':S("a violet striped tent stall with a crystal ball and a star sign, glowing purple trinkets"),
'apothecary_row':S("a green-roofed shop with shelves of colourful potion bottles and a mortar sign"),
'smugglers_vault':S("a stone vault door half open, a barrel, a hanging pink lantern, a rope coil"),
'hammersmith_forge':S("a heavy stone smithy with a huge hammer sign, orange glowing furnace, an anvil"),
'arcane_academy':S("a blue-roofed tower front with a big open book sign and a floating star"),
'sharpweave_den':S("a tailor's shop with a big needle and thread sign, bolts of cloth, a red curtain door"),
'ossuary_relics':S("a pale bone-white stall with stacked skulls and bones, a candle, a dark curtain"),
'last_lantern':S("a small inn front with a big glowing yellow lantern hanging, a warm window"),
'anchorage_chandlery':S("a harbour shop with a big anchor sign, coiled ropes and a ship's lamp, teal and wood"),
'wayfarer_caravan':S("a covered wagon with a patched canvas roof and a lantern, wooden wheels, goods hanging"),
# 10 chests, closed and open per tier
'wooden_closed':"a chibi small closed wooden chest, brown planks, iron straps, a small lock, chunky",
'wooden_open':"a chibi small open wooden chest with the lid up, a few coins and a potion inside, brown planks, chunky",
'iron_closed':"a chibi closed iron-bound chest, dark grey iron plates and rivets, a padlock, chunky",
'iron_open':"a chibi open iron-bound chest with the lid up, a sword hilt and coins inside, grey iron, chunky",
'silver_closed':"a chibi closed silver chest, pale silver plates, blue gem on the lock, chunky",
'silver_open':"a chibi open silver chest with the lid up, blue glow and a few gems inside, chunky",
'gold_closed':"a chibi closed golden chest, gold plates, a red gem on the lock, chunky",
'gold_open':"a chibi open golden chest with the lid up, a pile of gold coins and a gem inside, glowing, chunky",
'void_closed':"a chibi closed dark violet chest, black plates, glowing purple cracks, a purple eye lock, chunky",
'void_open':"a chibi open dark violet chest with the lid up, a swirling purple glow inside, black plates, chunky",
}
IDS={k:v+O for k,v in IDS.items()}
assert len(IDS)==24,len(IDS)
SUFFIX=", game icon, no text, centred"

RETRY={
'wooden_closed':"a chibi closed wooden treasure chest, warm brown planks with two dark iron bands and a gold lock, rounded lid, chunky"+O,
'wooden_open':"a chibi wooden treasure chest seen from the front, the lid raised open at the back, gold coins and a red potion heaped inside, brown planks, chunky"+O,
'iron_open':"a chibi iron-bound chest seen from the front, the lid raised open at the back, a sword hilt and coins inside, grey iron plates, chunky"+O,
'silver_open':"a chibi silver chest seen from the front, the lid raised open at the back, blue gems and a blue glow inside, pale silver plates, chunky"+O,
'void_open':"a chibi dark violet chest seen from the front, the lid raised open at the back, a bright purple glow and sparks inside, black plates, chunky"+O,
}
