"""Plan data and constants for the Ashen Quarter and the Gilded Casino (from city_plans.json and RoomPlan._casino); shared by the tileset renderer."""
import json, math
# ================= (a) Ashen Quarter =================
CITY=json.load(open('assets/gamedata/city_plans.json'))['ashen_quarter']
def centroid(pts): return (sum(p[0] for p in pts)/len(pts),sum(p[1] for p in pts)/len(pts))
def bbox_poly(pts): xs=[p[0] for p in pts]; ys=[p[1] for p in pts]; return min(xs),min(ys),max(xs),max(ys)
# ================= (b) the Gilded Casino =================
BOX=(140,90,860,910)
ROOMS={'floor':(140,330,860,910),'cashier':(140,90,340,330),'vip1':(340,90,520,330),'vip2':(520,90,700,330),'vault':(700,90,860,330)}
DOORS=[('door',500,910,'h',70),('back',240,90,'h',50),('cashier',250,330,'h',60),('vip1',430,330,'h',60),('vip2',610,330,'h',60),('vault',780,330,'h',50)]
HW=[(330,140,860,[(250,60),(430,60),(610,60),(780,50)])]
TABLES=[(500+math.cos(i*math.pi/3)*270,560+math.sin(i*math.pi/3)*130) for i in range(6)]+[(430,205),(610,205)]
BOXES=[(305,130,44,32),(740,130,44,32),(820,130,44,32),(780,205,44,32)]
