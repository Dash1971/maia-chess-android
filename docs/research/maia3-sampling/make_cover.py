"""Chess-fan cover from archived evidence; PNG/SVG/PDF, no inference."""
import argparse,json,os
from pathlib import Path
os.environ.setdefault('MPLCONFIGDIR','/tmp/mobile-maia-cover-mpl')
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle,FancyBboxPatch
ROOT=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--followup',type=Path,default=ROOT/'followup');args=ap.parse_args()
OUT=ROOT/'figures';OUT.mkdir(exist_ok=True)
data=json.loads((ROOT/'first-move-probabilities.json').read_text())
exact=next(iter(json.loads((args.followup/'openings/exact-policy95.json').read_text()).values()))
q95=exact['first_move']['full95'];p95={'e4':q95['e2e4'],'d4':q95['d2d4']}
families=json.loads((args.followup/'openings/family-diversity95.json').read_text())
summary=json.loads((args.followup/'openings/summary95.json').read_text())
full_families=families['full']['16']['observed_families'];full_starts=summary['rollout']['repertoire']['full']['distinct_prefixes']['4']
assert full_families==85 and full_starts==711
plt.rcParams.update({'font.family':'DejaVu Sans','svg.fonttype':'none','pdf.fonttype':42,'svg.hashsalt':'mobile-maia-cover-20261003'})
BG,NAVY,TEAL,BLUE,OTHER,MUTED='#F8FAF8','#173C4B','#087F83','#48879B','#D4DED4','#62747B'
fig=plt.figure(figsize=(9,12),dpi=120,facecolor=BG);ax=fig.add_axes([0,0,1,1]);ax.set(xlim=(0,1080),ylim=(1440,0));ax.axis('off')
def text(x,y,value,size=12,color=NAVY,weight='normal',**kw):return ax.text(x,y,value,fontsize=size,color=color,fontweight=weight,va='center',**kw)
def rect(x,y,w,h,color):ax.add_patch(Rectangle((x,y),w,h,facecolor=color,edgecolor='none'))
for row in range(4):
 for col in range(4):rect(72+col*9,54+row*9,8,8,TEAL if (row+col)%2==0 else '#CFE2DB')
text(123,72,'Mobile Maia',19,weight='bold');text(1008,72,'SETTINGS GUIDE · OCT 2026',10,MUTED,ha='right')
rect(72,143,72,5,TEAL)
text(72,205,'Settings for enjoyable,',33,weight='bold');text(72,270,'more varied chess',33,weight='bold')
text(72,334,'Explore more openings. Keep the game interesting.',13,MUTED)
ax.add_patch(FancyBboxPatch((72,389),936,211,boxstyle='round,pad=0,rounding_size=17',facecolor='#E7F1EB',edgecolor='none'))
text(106,428,'OUR PICK FOR OPENING VARIETY',10,TEAL,'bold')
text(106,472,'TEMPERATURE',9.5,MUTED,'bold');text(374,472,'TOP-P',9.5,MUTED,'bold')
text(102,541,'1.0',48,TEAL,'bold');text(370,541,'1.0',48,TEAL,'bold');rect(640,469,1.5,92,'#BBD6C8')
text(679,510,'More openings to explore.\nLess repetition early on.',12.5,NAVY,linespacing=1.6)
text(72,646,'WHAT 1/1 EXPLORED IN 2,000 SAMPLE OPENINGS',9.5,MUTED,'bold')
text(72,707,str(full_families),35,TEAL,'bold');text(72,756,'opening families',14,NAVY,'bold')
text(72,791,'After 8 full moves',9.5,MUTED)
text(72,825,'1/0.95 explored 67; 0.5/0.9 explored 28.',10.5,MUTED)
text(563,707,str(full_starts),35,NAVY,'bold');text(563,756,'different opening starts',14,NAVY,'bold')
text(563,791,'After 2 full moves',9.5,MUTED)
text(563,825,'1/0.95 explored 470; 0.5/0.9 explored 43.',10.5,MUTED)
rect(72,858,936,1.5,'#DBE4DE')
text(72,901,'How often does each first move appear?',17,weight='bold')
for x,label,color in [(72,'e4',TEAL),(155,'d4',BLUE),(242,'Other',OTHER)]:rect(x,942,14,14,color);text(x+23,950,label,10,MUTED)
rows=[('Human players',data['books']['blitz_2026-05']['probabilities']),
 ('T 0.5 / P 0.9',data['profiles']['current_default']['probabilities']),
 ('T 1 / P 0.95',p95),('T 1 / P 1',data['profiles']['full_policy']['probabilities'])]
for i,(label,q) in enumerate(rows):
 y=991+i*56;text(72,y+17,label,10.5,NAVY,'bold' if i==3 else 'normal');left=311
 vals=[q.get('e4',0),q.get('d4',0),max(0,1-q.get('e4',0)-q.get('d4',0))]
 for value,color in zip(vals,(TEAL,BLUE,OTHER)):
  width=697*value
  if value>1e-9:rect(left,y,width,34,color);text(left+width/2,y+17,f'{value*100:.1f}%',10,NAVY if color==OTHER else 'white','bold',ha='center')
  left+=width
text(72,1230,'Human comparison: Lichess blitz. T = Temperature; P = Top-P.',9,MUTED)
rect(72,1267,936,1.5,'#DBE4DE')
text(72,1310,'Want a stronger opponent? Try 1 / 0.95.',13,weight='bold')
text(72,1347,'Choose 1 / 1 when a wider opening repertoire matters more to you.',11,MUTED)
text(72,1394,'Maia3-79M · 1600 setting · No opening book chooses the moves',9,MUTED)
for ext in ('svg','png','pdf'):fig.savefig(OUT/f'cover.{ext}',dpi=180,facecolor=BG)
plt.close(fig)
svg=OUT/'cover.svg';svg.write_text('\n'.join(line.rstrip() for line in svg.read_text().splitlines())+'\n')
print(OUT/'cover.png')
