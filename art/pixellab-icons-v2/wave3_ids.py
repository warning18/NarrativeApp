"""Wave 3 (the other items): 44 icons. The object alone, empty, no body, no person (said in every prompt via O)."""
O=", the object alone, no body, no head, no face, no person"
IDS={
# 11 other equippables
'sword_001':"a chibi plain iron sword, stubby and fat, grey blade, brown grip, lying diagonally",
'rat_king_tooth':"a chibi huge curved yellowed rat tooth as a weapon, chunky, wrapped at the root with brown cord",
'thug_knuckle_wrap':"a chibi pair of knuckle dusters with a cloth wrap, chunky, brass rings and a grey cloth strip",
'blackened_fang':"a chibi long curved black fang dagger, stubby and fat, ember red edge",
'dawnward_shield':"a chibi heater shield with a pointed bottom, pale gold with a sunrise ray emblem, chunky",
'halo_lance':"a chibi lance with a golden ring halo behind the head, chunky, lying diagonally",
'tear_glass_blade':"a chibi sword made of dark glass with purple cracks, stubby and fat, lying diagonally",
'harborwatch_cutlass':"a chibi navy-grip cutlass with a curved blade and a brass guard, stubby and fat, lying diagonally",
'hollow_court_blade':"a chibi dark violet sword with a black crossguard and a pale gem, stubby and fat, lying diagonally",
'bloodthorn_blade':"a chibi red-brown sword with thorns along the blade, stubby and fat, lying diagonally",
'siphon_wand':"a chibi short wand with a swirling red crystal on top, chunky",
# 13 spellbooks: a closed book, coloured cover and one emblem
'spellbook_frost_bind':"a chibi closed spellbook, chunky, teal cover with a white snowflake emblem, lying flat",
'spellbook_ember_wave':"a chibi closed spellbook, chunky, orange-red cover with a wave of flame emblem, lying flat",
'spellbook_sanctified_ground':"a chibi closed spellbook, chunky, white and gold cover with a gold cross on a square emblem, lying flat",
'spellbook_smite_the_wicked':"a chibi closed spellbook, chunky, gold cover with a yellow lightning bolt emblem, lying flat",
'spellbook_venom_hex':"a chibi closed spellbook, chunky, green cover with a purple skull-less drop emblem, lying flat",
'spellbook_hunters_mark':"a chibi closed spellbook, chunky, brown leather cover with a red target ring emblem, lying flat",
'spellbook_war_shout':"a chibi closed spellbook, chunky, red cover with a open-mouth horn emblem, lying flat",
'spellbook_rally_the_line':"a chibi closed spellbook, chunky, blue cover with a small flag emblem, lying flat",
'spellbook_sundering_roar':"a chibi closed spellbook, chunky, dark red cover with a cracked circle emblem, lying flat",
'spellbook_smoke_veil':"a chibi closed spellbook, chunky, grey cover with a swirl of smoke emblem, lying flat",
'spellbook_bleeding_cut':"a chibi closed spellbook, chunky, dark cover with a red slash emblem, lying flat",
'spellbook_arrow_volley':"a chibi closed spellbook, chunky, green-brown cover with three arrows emblem, lying flat",
'spellbook_snare_shot':"a chibi closed spellbook, chunky, tan cover with a rope loop emblem, lying flat",
# 11 materials and trophies
'material_iron_ore':"a chibi lump of grey iron ore with rusty orange flecks, chunky rock",
'boss_trophy':"a chibi golden champion's trophy cup, chunky, two handles",
'material_timber':"a chibi stack of three thick wooden logs with pale cut ends, chunky",
'material_cut_stone':"a chibi cut grey stone block, chunky, a few chiselled lines",
'material_slag_glass':"a chibi lump of dark slag glass, chunky, green sheen, rough edges",
'material_ash_steel':"a chibi ash-grey steel ingot bar, chunky, a dark ember stripe",
'material_rime_crystal':"a chibi pale blue rime crystal cluster, chunky, frost-white tips",
'material_tear_glass':"a chibi shard of dark glass with a purple glow, chunky, jagged",
'material_shroud_thread':"a chibi spool of dark violet thread with a loose end, chunky",
'material_lantern_brass':"a chibi brass lump and a small brass ring, chunky, shiny gold-brown",
'material_white_fleet_oak':"a chibi curved pale oak plank with grain lines, chunky, a rope knot",
# 4 charms, 2 tomes, 1 scroll, 1 quest, 1 trophy
'charm_fourth_roll':"a chibi single knucklebone die with four dots, chunky, bone white on a cord",
'charm_lucky_coin':"a chibi lucky round gold coin with a four-leaf mark, chunky, on a short cord",
'charm_iron_skin':"a chibi small grey tin of salve with a red lid, chunky",
'charm_warding':"a chibi warding knot, a chunky thick knotted cord in a loop, tan and red",
'tome_of_insight':"a chibi thick blue tome with a gold eye emblem, chunky, closed, lying flat",
'tome_of_mastery':"a chibi thick dark violet tome with a gold star emblem and gold corners, chunky, closed, lying flat",
'scroll_fireball':"a chibi rolled parchment scroll tied with red ribbon, with a small flame mark, chunky",
'quest_sealed_letter':"a chibi sealed letter, a cream envelope with a big red wax seal, chunky",
'elite_trophy':"a chibi round bronze medal on a short ribbon with a skull-less star mark, chunky",
}
IDS={k:v+O for k,v in IDS.items()}
assert len(IDS)==44,len(IDS)
