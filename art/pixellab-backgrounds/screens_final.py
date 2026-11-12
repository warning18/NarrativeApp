"""Stage the screen backgrounds as UX-2 wants them: palette-reduced PNG8 (32 colours, no dither), one file per picture, named by id, in three folders:
final/life/<memory id>.png, final/character/<race|calling>.png, final/expeditions/<zone id>.png. python3 art/pixellab-backgrounds/screens_final.py [pilots|rest]   (repo root)"""
import os, sys
from PIL import Image
R='art/pixellab-backgrounds/screens/raw/'; O='art/pixellab-backgrounds/screens/final/'
PILOTS={('life','sparrow'):('life_age6_sparrow',11),('life','board'):('life_age16_board',12),('character','race'):('cc_race',11),('character','calling'):('cc_calling',11),
        ('expeditions','z_lantern_docks'):('exp_lantern_docks',12),('expeditions','z_cinder_row'):('exp_cinder_row',12),('expeditions','z_changeling_fen'):('exp_changeling_fen',11)}
# the rest: life ages 8, 10, 12, 14 (memory ids: the base band of the age: the race / calling variants are not drawn: mark_* and calling_* use the age's base band) and 17 zones
REST_LIFE={'mark':('life_age8_mark',None),'beggar':('life_age10_beggar',None),'calling':('life_age12_net',None),'lamp':('life_age14_lamp',None)}
ZONES=['fishermans_row','tanners_court','scaffold_yards','ossuary_galleries','drowned_stair','dead_heart_approach','shroud_vigil','beyond_the_tear','glass_strand','white_fleet_grave','exorcists_road','frost_quarry','salt_road','fever_bark','bell_road','ember_run','lantern_train']
def reduce(src,dst,n=32):
    im=Image.open(src).convert('RGB'); q=im.quantize(colors=n,method=Image.Quantize.MEDIANCUT,dither=Image.Dither.NONE); os.makedirs(os.path.dirname(dst),exist_ok=True); q.save(dst,optimize=True)
if __name__=='__main__':
    mode=sys.argv[1] if len(sys.argv)>1 else 'pilots'
    if mode in ('pilots','all'):
        for (folder,name),(k,s) in PILOTS.items(): reduce(f'{R}{k}_s{s}/get_image_0.png',f'{O}{folder}/{name}.png')
    if mode in ('rest','all'):
        for name,(k,sd) in {'mark':('life_age8_mark',12),'beggar':('life_age10_beggar2',12),'calling':('life_age12_net',11),'lamp':('life_age14_lamp',11)}.items(): reduce(f'{R}{k}_s{sd}/get_image_0.png',f'{O}life/{name}.png')
        pick={'frost_quarry':('exp_frost_quarry2',12),'ember_run':('exp_ember_run2',12),'white_fleet_grave':('exp_white_fleet_grave2',12)}
        for z in ZONES:
            k,sd=pick.get(z,(f'exp_{z}',11)); reduce(f'{R}{k}_s{sd}/get_image_0.png',f'{O}expeditions/z_{z}.png')
    print({d:len(os.listdir(O+d)) for d in os.listdir(O)})
