"""Darker chibi test: 4 foes, 2 shops, 2 chests, same objects as their current versions."""
M="grim dark fantasy chibi pixel art, worn and weathered, ominous mood, muted desaturated colours, deep black shadows, heavy chunky silhouette, thick dark outline, one strong rim light of "
IDS={
'inquisition_high_warden':M+"cold blue, a chibi bust, head and shoulders, big head, a heavy warden in dark battered white and blue plate armour with a plumed helm, a blue cloak, a mace",
'plague_hound':M+"sickly green, a chibi whole small creature, chunky, a feral hound with ragged grey fur, sunken ribs, sore marks, yellow eyes, bared teeth",
'bone_warden':M+"ember gold, a chibi bust, head and shoulders, big head, a skeleton knight in a rusty iron helmet, white bones lashed with rope, glowing red eye sockets",
'void_hound':M+"void violet, a chibi whole small creature, chunky, a hound of black smoke with glowing purple eyes and white teeth, a smoky tail",
'weaponsmith_forge':M+"ember gold, a chibi tiny shopfront seen from the front, chunky, a dark stone forge with a glowing orange fire, an anvil, a crossed sword and axe sign, the object alone, no people",
'apothecary_row':M+"sickly green, a chibi tiny shopfront seen from the front, chunky, a dark crooked shop with shelves of glowing potion bottles and a mortar sign, the object alone, no people",
'iron_closed':M+"cold blue, a chibi closed iron-bound chest, dark iron plates and rivets, a padlock, chunky, the object alone",
'iron_open':M+"ember gold, a chibi iron-bound chest seen from the front, the lid raised open at the back, a gold glow and coins inside, dark iron plates, chunky, the object alone",
}
SUFFIX=", game icon, no text, centred"
T=""

# Shop ELEMENT: a stall that sits in front of any background, with a transparent gap behind the counter for a 48 px NPC (96 x 64, transparent)
ST="grim dark fantasy chibi pixel art, worn and weathered, ominous mood, muted desaturated colours, deep black shadows, thick dark outline, a market stall seen straight from the front: two wooden posts holding a ragged awning on top, a heavy wooden counter across the bottom with wares on it, a trade sign hanging from the awning, the open space between the posts above the counter completely empty and transparent, no shopkeeper, no people, "
STALLS={
'stall_forge':ST+"a blacksmith's stall: a small glowing forge on the counter, swords, an axe and horseshoes laid out, an anvil, ember gold rim light, a crossed sword sign",
'stall_apothecary':ST+"an apothecary's stall: rows of glowing potion bottles and jars of herbs on the counter, a mortar and pestle, sickly green rim light, a mortar sign",
}
