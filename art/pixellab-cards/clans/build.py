"""Stage the picked clan backdrops (the clan's own dark shades, at most 63 colours, PNG8) and mock the seven cards. python3 art/pixellab-cards/clans/build.py"""
import sys; sys.path.insert(0,'tool'); sys.path.insert(0,'art/pixellab-cards')
import apollo_remap as AR, build as B, mock as M
from PIL import Image
KS=['dominion','crows','compact','mire','vigil','penitents','wayfarer']
PICK={k:1 for k in KS}
for k in KS:
    im=Image.open(f'art/pixellab-cards/clans/raw/{k}_s{PICK[k]}/get_image_0.png').convert('RGBA')   # kept in the clan's own dark shades (Apollo has no dark tint of every clan colour); the sign shows through
    B.png8(im,f'art/pixellab-cards/clans/final/backdrop_{k}.png')
G=[('dominion','rare','Fireball','+1 damage · x1.8','Hurl a bolt of fire.','Rare','fireball','Fire','#CF573C','The Lantern Dominion','#2F62B5','Kneel to the flame, not to me.'),
   ('crows','rare','Frost Nova','+2 damage · x1.3','A burst of freezing energy.','Rare','mage_frost_nova','Water','#4F8FBA','The Salt Crows','#B0303F','Buying, owing or competing?'),
   ('compact','uncommon','Iron Stance','heals 3','Plant your feet.','Uncommon','bastion_of_stone','Earth','#BE772B','The Cinder Compact','#B86B3C','You want steel. Tell us why.'),
   ('mire','epic','Multi Shot','+2 damage · x1.4','Loose three at once.','Epic','mage_arcane_missile','Wind','#73BED3','The Mire Courts','#3F8F5A','Mind the water.'),
   ('vigil','uncommon','Quick Heal','heals 3','A hand on the wound.','Uncommon','mage_arcane_missile','Water','#4F8FBA','The Grey Vigil','#8A8F98','Sit with your back to the wall.'),
   ('penitents','legendary','Second Dawn','heals 4','The light comes back.','Legendary','archon_eclipse','Light','#E8C170','The Ashen Penitents','#CBB68E','We take no coin. We take names.'),
   ('wayfarer','common','Keen Eye','+5% critical hit','Take what helps.','Common','improvised_strike','Perk','#A8B5B2','The Wayfarer','#7A5A44','No banner, no price.')]
import os
def card(k,tier,nm,eff,desc,rar,icon,el,elc,cn,col,words):
    M.CLAN['_x']=(cn,col,{'dominion':'clan_dominion','crows':'clan_crows','compact':'clan_compact','mire':'clan_mire','vigil':'clan_vigil','penitents':'clan_penitents','wayfarer':'clan_dominion'}[k],words)
    M.SK['_s']=(nm,eff,desc,rar,icon); M.TIERCOL.setdefault(rar,'#819796')
    # swap in the clan backdrop for the tier one
    M.F='art/pixellab-cards/final/'
    src=Image.open(f'art/pixellab-cards/clans/final/backdrop_{k}.png'); src.save('/tmp/claude-0/-home-user-NarrativeApp/644fb7e7-6d1c-53db-86ff-44fea4844d60/scratchpad/bd_tmp.png')
    return M.card_with(tier,'_x','_s',src,el,elc)
if __name__=='__main__':
    cards=[card(*g[:1],*g[1:]) for g in G]
    for sc,n in ((1,'1x'),(2,'2x')):
        W=Image.new('RGBA',(len(cards)*230+20,346+40),(21,22,32,255))
        for i,c in enumerate(cards): W.alpha_composite(c,(20+i*230,20))
        if sc!=1: W=W.resize((W.width*sc,W.height*sc),0)
        W.save(f'docs/art/boards/card-clan-backdrops-{n}.png')
