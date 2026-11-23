"""The 7th combat screen: an ink-brush pixel homage. 14 generations. python3 art/pixellab-ink/gen.py"""
import sys, json, subprocess, re
sys.path.insert(0,'art/pixellab-backgrounds'); import batchA_gen as A
INK="pixel art, black ink brush painting, dry-brush texture, strong contrast, large areas of solid black, cold grey and paper white, only deep red accents, "
jobs=[]
def img(name,desc,w,h,nb,seed):
    r=A.call('create_image_pixflux',{"description":INK+desc+", no text","width":w,"height":h,"no_background":nb,"outline":"selective outline","shading":"detailed shading","detail":"highly detailed","seed":seed})
    jobs.append((name,seed,A.field(r,'job_id'),'img')); print(name,seed,r[:40].replace('\n',' '))
def char(name,desc,k):
    r=A.call('create_character',{"description":INK+desc,"mode":"standard","size":96,"proportions":'{"type": "preset", "name": "realistic_male"}',"view":"side","n_directions":8,"outline":"single color black outline","detail":"high detail","name":name})
    jobs.append((name,k,A.field(r,'id') or A.field(r,'character_id'),'char')); print(name,k,r[:60].replace('\n',' '))
if __name__=='__main__':
    for s in (1,2):
        img('background',"a snowy mountain pass in a storm, a black mountain ridge, falling snow and wind lines, a pale cold sky, ground empty, a few red banners tattered in the wind",360,640,False,s)
        img('frame',"a card frame made of rough black brush strokes with dry-brush edges, a single deep red brush stroke on one corner, white paper inside",112,160,True,s)
        img('hit',"an ink splash hit effect with black speed lines radiating from a point and a deep red splatter",128,128,True,s)
        img('d6',"a six sided die drawn in black ink on white, pips readable, one red pip",88,88,True,s)
        img('d12',"a twelve sided die drawn in black ink on white, readable faces, a red edge",88,88,True,s)
    for k in (1,2):
        char('ink_hero',"a tall lean ronin swordsman in a black coat with a straw hat and a katana, a deep red sash, strong silhouette, standing idle",k)
        char('ink_foe',"a tall hooded inquisition warden in a long black robe and a pale mask, a deep red sash, strong silhouette, standing idle",k)
    json.dump(jobs,open('art/pixellab-ink/jobs.json','w'))
