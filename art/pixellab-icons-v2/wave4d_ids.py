"""Wave 4 redo in the DARK look: 64 foe icons, 32 px. Same objects as wave4_ids.py with the dark prefix and a rim light by kind/faction."""
import json,sys
sys.path.insert(0,'art/pixellab-icons-v2');import wave4_ids as W4
E4=json.load(open('assets/gamedata/enemies.json'))
M="grim dark fantasy chibi pixel art, worn and weathered, ominous mood, muted desaturated colours, deep black shadows, heavy chunky silhouette, thick dark outline, one strong rim light of "
RIM={'dominion':'cold blue','choir':'cold blue','crows':'ember gold','compact':'ember gold','vigil':'ember gold','mire':'sickly green','penitents':'void violet','pit':'ember gold','giants':'cold blue','tidekin':'sickly green'}
KIND={'undead':'sickly green','void':'void violet','demon':'ember gold','beast':'ember gold','construct':'ember gold','angel':'cold blue','giant':'cold blue'}
def rim(k):
    e=E4[k];return RIM.get(e.get('faction') or '') or KIND.get(e.get('kind')) or 'cold blue'
IDS={k:M+rim(k)+", "+v for k,v in W4.IDS.items()}
SUFFIX=", game icon, no text, centred"
T=""
RETRY={}

RETRY={
'harbor_rat':M+"ember gold, a chibi whole small creature, chunky, a fat grey harbour rat seen from the side, big round body, long pink tail, red eyes, sharp teeth, filling the whole frame, not a person",
'kraken_arm':M+"sickly green, a long thick dark grey-green tentacle rising up from the bottom edge, curved at the tip, rows of pale round suckers, wet shine, filling the frame, only a tentacle, no eyes, no face, not cute",
'void_wisp':M+"void violet, a chibi whole small creature, chunky, a small floating flame wisp of cold pale blue-white fire with a dark hollow face and two small eyes, wisps of smoke below, not a ghost sheet",
'hollow_reflection':M+"void violet, a chibi bust, head and shoulders, big head, the grey mirror copy of an adventurer, a plain grey cloak and hood, a smooth featureless pale face, a faint violet outline glow",
}

RETRY={
'hollow_reflection':M+"void violet, a chibi bust, head and shoulders, big head, a pale silver mirror-copy of a hero: a bright pale grey face with a smooth blank mirror-like shine, silver armour shoulders, a thin violet outline glow, bright against the dark, not a hooded figure",
'tear_spawn':M+"void violet, a chibi whole small creature, chunky, a lumpy purple blob with three big round pale yellow eyes of different sizes and a crooked stitched mouth, tiny crawling legs, tear-shaped drips, low and wide, not a ghost",
}
