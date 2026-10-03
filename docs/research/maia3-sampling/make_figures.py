"""Readable chess-fan figures from archived evidence; no inference.

All default data paths are inside this published folder. --followup accepts an
explicit archive location while integrating a newly finalized follow-up.
"""
import argparse,json,os
from pathlib import Path
os.environ.setdefault('MPLCONFIGDIR','/tmp/mobile-maia-sampling-mpl')
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
ROOT=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--followup',type=Path,default=ROOT/'followup');args=ap.parse_args()
FOLLOW=args.followup;OUT=ROOT/'figures';OUT.mkdir(exist_ok=True)
BG,NAVY,TEAL,BLUE,MUTED,OTHER='#F8FAF8','#173C4B','#087F83','#48879B','#62747B','#D4DED4'
COLORS=[NAVY,BLUE,TEAL]
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11,'svg.fonttype':'none','pdf.fonttype':42,
 'figure.facecolor':BG,'axes.facecolor':BG,'text.color':NAVY,'axes.labelcolor':NAVY,'xtick.color':MUTED,
 'ytick.color':NAVY,'axes.spines.top':False,'axes.spines.right':False})
load=lambda p:json.loads(p.read_text())
first=load(ROOT/'first-move-probabilities.json')
exact=next(iter(load(FOLLOW/'openings/exact-policy95.json').values()))
summary=load(FOLLOW/'openings/summary95.json');families=load(FOLLOW/'openings/family-diversity95.json')
p95=exact['first_move']['full95']
p95_san={'e4':p95.get('e2e4',0),'d4':p95.get('d2d4',0),'c4':p95.get('c2c4',0),'Nf3':p95.get('g1f3',0),'e3':p95.get('e2e3',0)}

def save(fig,name):
 for ext in ('png','svg','pdf'):fig.savefig(OUT/f'{name}.{ext}',dpi=180,bbox_inches='tight',facecolor=BG)
 plt.close(fig);print(OUT/f'{name}.png')

def clean(ax):
 ax.spines['left'].set_visible(False);ax.spines['bottom'].set_color('#D6E0D9')
 ax.tick_params(axis='y',length=0,pad=12);ax.tick_params(axis='x',length=0)

rows=[('Human players',first['books']['blitz_2026-05']['probabilities']),
 ('Temperature 0 · Top-P 0',first['profiles']['argmax']['probabilities']),
 ('Temperature 0.5 · Top-P 0.9',first['profiles']['current_default']['probabilities']),
 ('Temperature 1 · Top-P 0.95',p95_san),
 ('Temperature 1 · Top-P 1',first['profiles']['full_policy']['probabilities'])]
fig,ax=plt.subplots(figsize=(11,6));fig.subplots_adjust(left=.31,right=.97,top=.79,bottom=.20)
left=np.zeros(len(rows))
for move,color in [('e4',TEAL),('d4',BLUE),('Other',OTHER)]:
 vals=np.array([q.get(move,0) if move!='Other' else max(0,1-q.get('e4',0)-q.get('d4',0)) for _,q in rows])*100
 ax.barh(np.arange(len(rows)),vals,left=left,color=color,height=.62,label=move)
 for i,v in enumerate(vals):
  if v>2:ax.text(left[i]+v/2,i,f'{v:.1f}%',ha='center',va='center',fontweight='bold',color=NAVY if move=='Other' else 'white')
 left+=vals
ax.set(yticks=np.arange(len(rows)),yticklabels=[r[0] for r in rows],xlim=(0,100),xlabel='Share of first moves (%)');ax.invert_yaxis();clean(ax)
fig.text(.035,.94,'Which first moves does Maia choose?',fontsize=21,fontweight='bold')
fig.text(.035,.885,'1/1 leaves room for more than the most popular starts.',fontsize=12,color=MUTED)
fig.legend(*ax.get_legend_handles_labels(),ncol=3,loc='upper center',bbox_to_anchor=(.68,.855),frameon=False)
fig.text(.035,.025,'Exact model probabilities at 1600/1600. Human comparison: Lichess blitz book, May 2026.',fontsize=9,color=MUTED)
save(fig,'first-moves')

settings=[('app_default','T 0.5 · P 0.9'),('full95','T 1 · P 0.95'),('full','T 1 · P 1')]
family_counts=[families[k]['16']['observed_families'] for k,_ in settings]
line_counts=[summary['rollout']['repertoire'][k]['distinct_prefixes']['4'] for k,_ in settings]
assert family_counts==[28,67,85] and line_counts==[43,470,711]
fig,axes=plt.subplots(1,2,figsize=(11,5.9));fig.subplots_adjust(left=.14,right=.95,top=.73,bottom=.20,wspace=.40)
for ax,vals,title in zip(axes,[family_counts,line_counts],['Opening families','Different two-move starts']):
 ax.barh(np.arange(3),vals,color=COLORS,height=.57)
 for i,v in enumerate(vals):ax.text(v+max(vals)*.035,i,str(v),va='center',fontsize=17,fontweight='bold')
 ax.set(yticks=np.arange(3),yticklabels=[x[1] for x in settings],xlim=(0,max(vals)*1.20));ax.invert_yaxis();clean(ax)
 ax.set_title(title,loc='left',fontsize=15,pad=15,fontweight='bold')
fig.text(.035,.94,'More opening variety with 1/1',fontsize=21,fontweight='bold')
fig.text(.035,.875,'2,000 sampled openings per setting.',fontsize=12,color=MUTED)
fig.text(.035,.075,'Families: opening labels after eight moves by each side. Two-move starts: White and Black each move twice.',fontsize=9,color=MUTED)
fig.text(.035,.035,'Both colors use the same setting; no opening book chooses moves. 1/1 and 0.5/0.9 samples are reused.',fontsize=9,color=MUTED)
save(fig,'opening-variety')

historical=load(ROOT/'strength/results-79m-app-draw.json');p95match=load(FOLLOW/'strength/results-primary.json')
matches=[]
for profile,label,color in [('argmax','T 0 · P 0',MUTED),('baseline','T 0.5 · P 0.9',NAVY)]:
 m=next(r for r in historical['pairs'] if r['first']==profile and r['second']=='full');matches.append((label,m,color))
matches.append(('T 1 · P 0.95',p95match,BLUE));assert p95match['n']==1200
fig,ax=plt.subplots(figsize=(11,5.5));fig.subplots_adjust(left=.18,right=.97,top=.73,bottom=.24)
ax.axvline(50,color='#A5B5B1',linestyle='--',linewidth=1.4)
for i,(label,m,color) in enumerate(matches):
 v=m['score']*100;lo,hi=np.array(m['score_95_ci'])*100
 ax.errorbar(v,i,xerr=[[v-lo],[hi-v]],fmt='o',color=color,markersize=10,elinewidth=2.5,capsize=5)
 ax.text(hi+1.2,i,f"{v:.1f}%  ·  +{m['elo_difference']:.0f} Elo",va='center',fontsize=12,fontweight='bold',color=color)
ax.set(yticks=np.arange(3),yticklabels=[m[0] for m in matches],xlim=(46,105),ylim=(2.7,-.65),xticks=[50,60,70,80,90],xlabel='Points scored against Temperature 1 / Top-P 1 (%)');clean(ax)
fig.text(.035,.94,'Stronger settings trade some variety for wins',fontsize=21,fontweight='bold')
fig.text(.035,.875,f"Top-P 0.95 scored {p95match['score']*100:.1f}% against 1/1: about +{p95match['elo_difference']:.0f} relative Elo.",fontsize=12,color=MUTED)
fig.text(.035,.10,'A win scores 1 point; a draw scores ½. Dashed line = an even result. Bars show 95% uncertainty intervals.',fontsize=9,color=MUTED)
fig.text(.035,.055,'600 games each for 0/0 and 0.5/0.9; 1,200 for 1/0.95. Colors balanced; Maia3-79M at 1600/1600.',fontsize=9,color=MUTED)
fig.text(.035,.015,'1/0.95 relative strength gain: +71 Elo, with a 95% range of +52 to +90.',fontsize=9,color=MUTED)
save(fig,'match-strength')

data=load(ROOT/'openings/conditional-summary.json');new=load(FOLLOW/'openings/conditional-summary95.json')
fig,ax=plt.subplots(figsize=(11,6.5));fig.subplots_adjust(left=.20,right=.97,top=.79,bottom=.26)
profiles=[('argmax','T 0 / P 0','#ADBDB7'),('app_default','T 0.5 / P 0.9',NAVY),('full95','T 1 / P 0.95',BLUE),('full','T 1 / P 1',TEAL)]
keys=list(data);y=np.arange(3)
for j,(setting,label,color) in enumerate(profiles):
 source=new if setting=='full95' else data
 vals=np.array([source[k]['settings'][setting]['tv']['mean'] for k in keys]);ci=np.array([source[k]['settings'][setting]['tv']['ci95'] for k in keys])
 yy=y+(j-1.5)*.18;ax.barh(yy,vals,height=.16,color=color,label=label,xerr=np.vstack([vals-ci[:,0],ci[:,1]-vals]),error_kw={'capsize':2,'ecolor':NAVY})
 for z,v in enumerate(vals):ax.text(max(v,ci[z,1])+.007,yy[z],f'{v:.3f}',va='center',fontsize=9)
ax.set(yticks=y,yticklabels=['Blitz · May 2026','Rapid · May 2026','Rapid · July 2026'],xlim=(0,.57),xlabel='Mean TV distance from human move choices (lower is closer)');ax.invert_yaxis();clean(ax)
fig.text(.035,.94,'How closely do the move choices match people?',fontsize=20,fontweight='bold')
fig.text(.035,.88,'Technical check: 1/1 is closest on these fixed human-opening positions.',fontsize=12,color=MUTED)
ax.legend(ncol=2,loc='upper center',bbox_to_anchor=(.5,-.20),frameon=False,fontsize=10)
fig.text(.035,.065,'Maia3-79M, 1600/1600. Same 450 human-book paths and 4,581 position comparisons; 95% trajectory-bootstrap intervals.',fontsize=9,color=MUTED)
fig.text(.035,.025,'These filtered books cover common positions best. Later coverage is limited; this is one measure of opening fit.',fontsize=9,color=MUTED)
save(fig,'opening-distance')
for name in ('first-moves','opening-variety','match-strength','opening-distance'):
 svg=OUT/f'{name}.svg';svg.write_text('\n'.join(line.rstrip() for line in svg.read_text().splitlines())+'\n')
