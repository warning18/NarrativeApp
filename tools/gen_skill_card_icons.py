# Draws the 40 clan-card skill icons (fusions, ascensions, sub-clan skills,
# secrets) as 16x16 pixel art scaled to 128x128 into assets/icons/skills/.
# Run from the repository root: python3 tools/gen_skill_card_icons.py
# Replace any of the PNGs with hand-drawn art at will: nothing else reads this.
import json, sys
from PIL import Image
OUT='assets/icons/skills'
OL=(24,18,28,255)
EL={
 'None':((70,76,90),(138,146,160),(214,220,230)),
 'Fire':((140,52,24),(222,104,40),(255,200,96)),
 'Water':((24,84,140),(64,160,224),(176,232,255)),
 'Earth':((84,60,40),(150,112,72),(214,180,128)),
 'Wind':((60,130,110),(130,206,170),(220,255,230)),
 'Void':((60,34,100),(122,80,190),(208,170,255)),
 'Light':((166,128,24),(240,212,72),(255,250,200)),
 'Electricity':((30,100,130),(80,190,230),(240,250,120)),
 'Ice':((90,150,190),(170,220,245),(245,252,255)),
}
G={
'shield':["#######","#ooooo#","#ooooo#","#ooooo#",".#ooo#.","..#o#..","...#..."],
'banner':["#######","#oooooo","#oo####","#ooooo.","#oo.##.","#o.....","#......"],
'bolt':["...###.","..###..",".###...","#######","...###.","..##...",".#....."],
'drop':["...#...","...#...","..###..",".#####.","#######","#######",".#####."],
'hourglass':["#######",".#ooo#.","..#o#..","...#...","..#o#..",".#ooo#.","#######"],
'blade':["......#",".....##","....##.","...##..","#.##...",".##....","##o...."],
'cross':["..###..","..#o#..","###o###","#ooooo#","###o###","..#o#..","..###.."],
'bow':[".##....","#..#...","#...#..","#....#.","#...#..","#..#...",".##...."],
'paw':[".#.#.#.","#o#o#o#",".#...#.","..###..",".#ooo#.",".#ooo#.","..###.."],
'wave':[".......","..##...",".#..#.#","#....#.",".......","..##...",".#..#.#"],
'eye':[".......","..###..",".#ooo#.","#o###o#",".#ooo#.","..###..","......."],
'mask':[".#####.","#ooooo#","#.#o#.#","#ooooo#",".#o#o#.","..###..","......."],
'candle':["...#...","..#o#..","..###..","..#o#..","..#o#..","..#o#..",".#####."],
'horn':["....###","..##ooo",".#ooo##","#ooo#..","#oo#...",".##....","......."],
'flame':["...#...","..###..",".#####.",".##o##.",".#ooo#.","..#o#..","...#..."],
'hammer':["..#####","..#ooo#","...###.","...#o#.","...#o#.","...#o#.","...###."],
'lantern':["..###..",".#####.",".#ooo#.",".#ooo#.",".#ooo#.",".#####.","..###.."],
'book':["#######","#ooo#o#","#ooo#o#","#ooo#o#","#ooo#o#","#######","......."],
'leaf':["....###","..#####",".###oo#","###oo#.","#oo##..","#o#....","##....."],
'note':["...####","...#oo#","...#...","...#...","..##...",".###...","..#...."],
'star':["...#...","...#...","#######",".#ooo#.","..###..",".##.##.","#.....#"],
'skull':[".#####.","#ooooo#","#o#o#o#","#ooooo#",".#ooo#.",".#.#.#.","......."],
'card':[".#####.","#ooooo#","#o#.#o#","#o.#.o#","#o#.#o#","#ooooo#",".#####."],
'hand':["..#.#..",".#o#o#.",".#ooo#.","#ooooo#","#ooooo#",".#ooo#.","..###.."],
'gate':["#.#.#.#","#######","#o#o#o#","#o#o#o#","#o#o#o#","#o#o#o#","#######"],
}
def blank(): return [[None]*16 for _ in range(16)]
def put(img,x,y,c):
    if 0<=x<16 and 0<=y<16: img[y][x]=c
def diamond(img,cx,cy,r,cols):
    d,m,l=cols
    for y in range(16):
        for x in range(16):
            dist=abs(x+0.5-cx)+abs(y+0.5-cy)
            if dist<=r:
                c=d if dist>r-1.6 else (m if dist>r-3.6 else l)
                put(img,x,y,c+(255,))
def outline(img):
    out=[row[:] for row in img]
    for y in range(16):
        for x in range(16):
            if img[y][x] is None:
                for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
                    nx,ny=x+dx,y+dy
                    if 0<=nx<16 and 0<=ny<16 and img[ny][nx] is not None and img[ny][nx]!=OL:
                        out[y][x]=OL;break
    return out
def glyph(img,name,ox,oy,main,acc,shadow=True):
    if shadow:
        pts={(ox+i,oy+j) for j,row in enumerate(G[name]) for i,ch in enumerate(row) if ch!='.'}
        for (x,y) in pts:
            for dx,dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,1)):
                if (x+dx,y+dy) not in pts and 0<=x+dx<16 and 0<=y+dy<16 and img[y+dy][x+dx] is not None:
                    img[y+dy][x+dx]=(30,22,40,255)
    for j,row in enumerate(G[name]):
        for i,ch in enumerate(row):
            if ch=='#': put(img,ox+i,oy+j,main+(255,))
            elif ch=='o': put(img,ox+i,oy+j,acc+(255,))
def shield_frame(img,cols):
    d,m,l=cols
    widths=[12,12,12,12,12,11,10,9,8,6,5,3,1]
    for j,w in enumerate(widths):
        y=2+j; x0=8-w//2-(0 if w%2==0 else 0)
        for i in range(w):
            x=x0+i
            edge=(i<2 or i>=w-2 or j>=len(widths)-3)
            c=d if (i==0 or i==w-1 or j==len(widths)-1) else (m if not (j<2) else l)
            put(img,x,y,c+(255,))
def make(kind,glyph_name,elem,elemB=None):
    cols=EL[elem]
    img=blank()
    if kind=='ascension':
        diamond(img,8,9.6,6.2,cols)
        # a rising crest above the gem: three stacked chevrons
        for (x,y) in [(8,0),(7,1),(9,1),(6,2),(10,2)]:
            put(img,x,y,cols[2]+(255,))
        for (x,y) in [(8,1),(7,2),(9,2)]:
            put(img,x,y,cols[1]+(255,))
        for (x,y) in [(1,8),(14,8),(2,7),(13,7)]:
            put(img,x,y,cols[2]+(255,))
        glyph(img,glyph_name,4,6,(255,255,255),cols[2])
    elif kind=='fusion':
        colsB=EL[elemB or elem]
        diamond(img,5.0,8.5,5.0,cols)
        imgB=blank(); diamond(imgB,11.0,8.5,5.0,colsB)
        for y in range(16):
            for x in range(16):
                if imgB[y][x] is not None:
                    if img[y][x] is not None: img[y][x]=((cols[2][0]+colsB[2][0])//2,(cols[2][1]+colsB[2][1])//2,(cols[2][2]+colsB[2][2])//2,255)
                    else: img[y][x]=imgB[y][x]
        # small glyph
        glyph(img,glyph_name,4,5,(255,255,255),(236,236,255))
    elif kind=='subclan':
        shield_frame(img,cols)
        glyph(img,glyph_name,4,4,(255,255,255),cols[2])
    elif kind=='secret':
        # octagon dark plate, glowing ring in the element colour
        for y in range(16):
            for x in range(16):
                dx,dy=abs(x+0.5-8),abs(y+0.5-8)
                if dx<=7 and dy<=7 and dx+dy<=10.2:
                    ring=dx+dy>8.2 or dx>6 or dy>6
                    put(img,x,y,(cols[1] if ring else (22,16,38))+(255,))
        for (x,y) in [(1,1),(14,1),(1,14),(14,14),(8,0),(8,15)]: pass
        glyph(img,glyph_name,4,4,cols[2],cols[1])
        for (x,y) in [(3,3),(12,3),(12,12),(3,12)]: put(img,x,y,(255,255,255,255))
    img=outline(img)
    im=Image.new('RGBA',(16,16),(0,0,0,0))
    for y in range(16):
        for x in range(16):
            if img[y][x] is not None:
                c=img[y][x]; im.putpixel((x,y),c if len(c)==4 else c+(255,))
    return im.resize((128,128),Image.NEAREST)
SK=json.load(open('assets/gamedata/skills.json'))
SPEC={
# fusion: (glyph, parentA, parentB elems resolved from skills)
'warrior_bastion_charge':('fusion','shield'),'warrior_writ_banner':('fusion','banner'),
'mage_scalding_tempest':('fusion','bolt'),'mage_ember_aegis':('fusion','shield'),
'rogue_viper_kiss':('fusion','drop'),'rogue_borrowed_time':('fusion','hourglass'),
'cleric_sentinel_verdict':('fusion','blade'),'cleric_absolution':('fusion','cross'),
'ranger_snared_shot':('fusion','bow'),'ranger_pack_ambush':('fusion','paw'),
'warrior_unbroken_stance':('ascension','shield'),'warrior_reaping_whirl':('ascension','blade'),
'mage_pyre_heart':('ascension','flame'),'mage_mending_tide':('ascension','wave'),
'rogue_deadeye_thrust':('ascension','eye'),'rogue_second_skin':('ascension','mask'),
'cleric_hallowed_sanctuary':('ascension','cross'),'cleric_unyielding_vigil':('ascension','candle'),
'ranger_deadeye_volley':('ascension','bow'),'ranger_call_of_the_wilds':('ascension','horn'),
'warrior_quarry_break':('subclan','hammer'),'warrior_last_watch_stand':('subclan','lantern'),
'mage_emberwife_coal':('subclan','flame'),'mage_whispered_ledger':('subclan','book'),
'rogue_tar_snare':('subclan','drop'),'rogue_heron_step':('subclan','leaf'),
'cleric_candle_vigil':('subclan','candle'),'cleric_scorched_hymn':('subclan','note'),
'ranger_moss_dirge':('subclan','leaf'),'ranger_wayside_ward':('subclan','star'),
'warrior_matriarch_reckoning':('secret','skull'),'warrior_gate_oath':('secret','gate'),
'mage_tear_sight':('secret','eye'),'mage_ash_ledger':('secret','book'),
'rogue_marked_deck':('secret','card'),'rogue_borrowed_face':('secret','mask'),
'cleric_absolved_penance':('secret','hand'),'cleric_kept_lantern':('secret','lantern'),
'ranger_followed_trail':('secret','paw'),'ranger_horn_call':('secret','horn'),
}
made=[]
for sid,(kind,gl) in SPEC.items():
    s=SK[sid]; el=s['element']; elB=None
    if kind=='fusion':
        a,b=s['fusionOf']; el=SK[a]['element']; elB=SK[b]['element']
        if el==elB: elB=s['element'] if s['element']!=el else 'Light'
    im=make(kind,gl,el,elB)
    im.save(f'{OUT}/{sid}.png'); made.append(sid)
print(len(made))
# contact sheet
sheet=Image.new('RGBA',(128*10,128*4),(52,52,60,255))
for i,sid in enumerate(SPEC):
    im=Image.open(f'{OUT}/{sid}.png'); sheet.paste(im,((i%10)*128,(i//10)*128),im)
sheet.save('/tmp/skill_card_icons_sheet.png')
