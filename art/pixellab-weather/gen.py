"""Weather overlays: master drifts at 340 px, transparent. 24 generations. python3 art/pixellab-weather/gen.py"""
import sys, json
sys.path.insert(0,'art/pixellab-backgrounds'); import batchA_gen as A
B="pixel art, black ink brush painting style, soft irregular drift lying on a flat top edge, thicker toward the middle and thin at both ends, a few loose flakes above, no regular scallops, flat base along the bottom edge, transparent background, "
SNOW={'dusting':(8,"a very thin dusting of snow, paper white with cold grey shade"),'light':(16,"a light layer of snow, paper white with cold grey shade"),'medium':(24,"a medium pile of snow, paper white with cold grey shade"),'heavy':(32,"a heavy deep pile of snow, paper white with cold grey shade")}
SAND={'dusting':(8,"a very thin dusting of sand dust, ochre and warm grey"),'light':(16,"a light drift of sand, ochre and warm grey"),'medium':(24,"a medium dune-like drift of sand, ochre and warm grey"),'heavy':(32,"a heavy deep drift of sand, ochre and warm grey")}
ASH={'dusting':(8,"a thin dusting of dark grey ash and soot specks"),'heavy':(16,"a layer of dark grey ash and soot with a few specks")}
jobs=[]
def go(kind,stage,w,h,desc,s):
    r=A.call('create_image_pixen',{"description":B+desc+", no text","width":w,"height":h,"no_background":True,"outline":"lineless","detail":"medium detail","seed":s})
    jobs.append((kind,stage,s,A.field(r,'job_id')));print(kind,stage,s,r[:30].replace('\n',' '))
if __name__=='__main__':
    for s in (1,2):
        for k,(h,d) in SNOW.items(): go('snow',k,340,h,d,s)
        for k,(h,d) in SAND.items(): go('sand',k,340,h,d,s)
        for k,(h,d) in ASH.items(): go('ash',k,340,h,d,s)
        go('frost','corner_a',64,64,"a frost corner of white ice crystals growing into the top left corner, paper white and pale cold grey, no background",s)
        go('frost','corner_b',64,64,"a frost corner of white ice crystals with a few long branching crystals growing into the top left corner, paper white and pale cold grey, no background",s)
    json.dump(jobs,open('art/pixellab-weather/jobs.json','w'))
