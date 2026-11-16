"""Mock the tiered clan card (210x346 dp at 1 dp = 1 px, art pieces at 2x). python3 art/pixellab-cards/mock.py"""
from PIL import Image, ImageDraw, ImageFont
F='art/pixellab-cards/final/'
def font(n,s): return ImageFont.truetype(f'assets/fonts/{n}.ttf',s)
def hexc(s): return tuple(int(s[i:i+2],16) for i in (1,3,5))
CLAN={'dominion':('The Lantern Dominion','#2F62B5','clan_dominion','Kneel to the flame, not to me.'),
      'crows':('The Salt Crows','#B0303F','clan_crows','Buying, owing or competing?'),
      'penitents':('The Ashen Penitents','#CBB68E','clan_penitents','We take no coin. We take names.')}
SK={'strike':('Power Strike','+1 damage','A blunt, honest blow.','Common','improvised_strike'),
    'missile':('Arcane Missile','+2 damage · x1.2','A bolt that does not miss.','Uncommon','mage_arcane_missile'),
    'fireball':('Fireball','+1 damage · x1.8','Hurl a bolt of fire at the enemy.','Rare','fireball')}
TIERCOL={'Common':'#819796','Uncommon':'#DE9E41','Rare':'#73BED3'}
def card(tier,clan,sk):
    cname,col,ban,words=CLAN[clan];nm,eff,desc,rar,icon=SK[sk];col=hexc(col)
    im=Image.new('RGBA',(210,346),(21,29,40,255));g=ImageDraw.Draw(im)
    bd=Image.open(f'{F}backdrop_{tier}.png').convert('RGBA').resize((208,152),0);im.paste(bd,(1,1))
    tint=Image.new('RGBA',(208,152),col+(46,));im.alpha_composite(tint,(1,1))
    b=Image.open(f'assets/visuals/banners/{ban}.png').convert('RGBA');b=b.resize((48,96),0);im.alpha_composite(b,(24,14))
    pl=Image.open(f'{F}plate_{tier}.png').convert('RGBA').resize((80,80),0);im.alpha_composite(pl,(112,42))
    ic=Image.open(f'art/pixellab-apollo-skills/icons/{icon}.png').convert('RGBA').resize((48,48),0);im.alpha_composite(ic,(128,58))
    g.rectangle([1,153,208,194],fill=col);tc=(9,10,20) if sum(col)>400 else (235,237,233)
    f=font('IMFellEnglishSC-Regular',22);w=g.textlength(nm,font=f);g.text((105-w/2,158),nm,font=f,fill=tc)
    f=font('PixelifySans-Regular',13);w=g.textlength(eff,font=f);g.text((105-w/2,202),eff,font=f,fill=(235,237,233))
    f=font('Spectral-Regular',13);w=g.textlength(desc,font=f);g.text((105-w/2,224),desc,font=f,fill=(168,181,178))
    f=font('PixelifySans-Regular',11);x=62
    for lab,c in (('Fire' if sk=='fireball' else 'Arcane','#CF573C' if sk=='fireball' else '#A23E8C'),(rar,TIERCOL[rar])):
        w=g.textlength(lab,font=f);g.rectangle([x-4,252,x+w+4,270],outline=hexc(c));g.text((x,254),lab,font=f,fill=hexc(c));x+=w+14
    g.line([(14,282),(196,282)],fill=(57,74,80))
    f=font('Spectral-Italic',12);w=g.textlength('"'+words+'"',font=f);g.text((105-w/2,288),'"'+words+'"',font=f,fill=(168,181,178))
    f=font('PixelifySans-Regular',10);g.text((16,314),cname.upper(),font=f,fill=col if sum(col)>200 else (200,200,200));g.text((178,314),'+6',font=f,fill=(232,193,112))
    fr=Image.open(f'{F}frame_{tier}.png').convert('RGBA').resize((208,344),0);im.alpha_composite(fr,(1,1))
    return im
def sheet(cards,out,scale):
    W=Image.new('RGBA',(len(cards)*(210+20)+20,346+40),(21,22,32,255))
    for i,c in enumerate(cards): W.alpha_composite(c,(20+i*230,20))
    if scale!=1: W=W.resize((W.width*scale,W.height*scale),0)
    W.save(out)
if __name__=='__main__':
    B='docs/art/boards/'
    t1=[card('common','dominion','strike'),card('uncommon','dominion','missile'),card('rare','dominion','fireball')]
    t2=[card('rare',c,'fireball') for c in ('dominion','crows','penitents')]
    sheet(t1,B+'card-tiers-1x.png',1);sheet(t1,B+'card-tiers-2x.png',2)
    sheet(t2,B+'card-rare-clans-1x.png',1);sheet(t2,B+'card-rare-clans-2x.png',2)
