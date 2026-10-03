import json, collections, csv, re, math, sys, io
from pathlib import Path
import numpy as np
import pyarrow.parquet as pq
import chess
from experiment import HERE,metrics,opening_map,SETTINGS,SEED

def boot_mean(rows,field,setting,seed=SEED):
    clusters=collections.defaultdict(list)
    for r in rows:clusters[r['trajectory']].append(r['settings'][setting][field])
    sums=np.array([sum(v) for v in clusters.values()]);ns=np.array([len(v) for v in clusters.values()]);rng=np.random.default_rng(seed)
    ids=rng.integers(0,len(sums),(2000,len(sums)))
    vals=sums[ids].sum(1)/ns[ids].sum(1)
    return {'mean':float(sums.sum()/ns.sum()),'ci95':[float(x) for x in np.quantile(vals,[.025,.975])]}

def conditional_summary(rows):
    out={}
    for book in sorted({r['book'] for r in rows}):
        group=[r for r in rows if r['book']==book];out[book]={'observations':len(group),'unique_positions':len({r['fen'] for r in group}),'coverage_by_ply':{p:sum(r['ply']==p for r in group)/150 for p in range(16)},'settings':{}}
        for setting in SETTINGS:
            fields=['tv','js_bits','human_entropy_bits','model_entropy_bits','excluded_human_mass','human_supported_model_mass','human_collision','model_collision']
            out[book]['settings'][setting]={field:boot_mean(group,field,setting) for field in fields}
        out[book]['depth_groups']={}
        for a,b in ((0,3),(4,7),(0,7),(8,11),(12,15)):
            gr=[r for r in group if a<=r['ply']<=b]
            out[book]['depth_groups'][f'{a}-{b}']={setting:{f:boot_mean(gr,f,setting) for f in ('tv','js_bits','excluded_human_mass')} for setting in SETTINGS}
        # Paired trajectory bootstrap: full minus app-default TV; same sampled paths.
        cl=collections.defaultdict(list)
        for r in group:cl[r['trajectory']].append(r['settings']['full']['tv']-r['settings']['app_default']['tv'])
        sums=np.array([sum(v) for v in cl.values()]);ns=np.array([len(v) for v in cl.values()]);rng=np.random.default_rng(SEED);ids=rng.integers(0,len(sums),(2000,len(sums)))
        out[book]['full_minus_default_tv']={'mean':float(sums.sum()/ns.sum()),'ci95':[float(x) for x in np.quantile(sums[ids].sum(1)/ns[ids].sum(1),[.025,.975])]}
    return out

def cutoff(rows):
    out=[]
    for r in rows:
        q=r['settings']['full']['distribution'];keys=sorted(q,key=q.get,reverse=True);p=np.array([q[k]**2 for k in keys]);p/=p.sum()
        mask=np.cumsum(p)<=.9;mask[0]=True;ex={k:float(v/p[mask].sum()) for k,v,z in zip(keys,p,mask) if z}
        inc=r['settings']['app_default']['distribution'];mi=metrics(r['human'],inc);me=metrics(r['human'],ex)
        out.append({'book':r['book'],'trajectory':r['trajectory'],'fen':r['fen'],'ply':r['ply'],'inclusive_exclusive_tv':metrics(inc,ex)['tv'],'human_tv_change_exclusive_minus_inclusive':me['tv']-mi['tv'],'human_js_change_exclusive_minus_inclusive':me['js_bits']-mi['js_bits'],'inclusive_support':len(inc),'exclusive_support':len(ex)})
    (HERE/'cutoff-sensitivity.json').write_text(json.dumps(out))
    return {book:{'observations':len(g),'different_fraction':sum(r['inclusive_exclusive_tv']>1e-6 for r in g)/len(g),'mean_sampler_tv':float(np.mean([r['inclusive_exclusive_tv'] for r in g])),'mean_human_tv_change_exclusive_minus_inclusive':float(np.mean([r['human_tv_change_exclusive_minus_inclusive'] for r in g])),'mean_human_js_change_exclusive_minus_inclusive':float(np.mean([r['human_js_change_exclusive_minus_inclusive'] for r in g]))} for book in sorted({r['book'] for r in out}) if (g:=[r for r in out if r['book']==book])}

def human_sample():
    out=[];errors=0;seen=set()
    files=sorted((HERE/'source').glob('games-*.parquet'))
    if not files and (HERE/'human-sample.json').exists():
        # The publication fixture retains these already parsed games without the raw range cache.
        return json.loads((HERE/'human-sample.json').read_text()),0
    if not files:raise FileNotFoundError('Supply archived human-sample.json or collect the source Parquet sample first')
    omap=opening_map()
    for f in files:
        for r in pq.read_table(f).to_pylist():
            if r['Site'] in seen:continue
            seen.add(r['Site'])
            if 'Rated' not in r['Event'] or r['WhiteTitle']=='BOT' or r['BlackTitle']=='BOT':continue
            if abs(r['WhiteElo']-r['BlackElo'])>200:continue
            b=chess.Board();moves=[];labels=[];eco='none';family='Unclassified'
            text=re.sub(r'\{[^}]*\}',' ',r['movetext']);text=re.sub(r'\d+\.(?:\.\.)?',' ',text)
            try:
                for token in text.split():
                    if token in ('1-0','0-1','1/2-1/2','*'):break
                    if token.startswith('$'):continue
                    token=token.rstrip('!?')
                    move=b.parse_san(token);moves.append(move.uci());b.push(move)
                    epd=' '.join(b.fen().split()[:4])
                    if epd in omap:eco,family=omap[epd]
                    labels.append({'eco':eco,'family':family,'fen':epd})
                    if len(moves)>=16:break
            except Exception:errors+=1;continue
            if len(moves)<6:continue # Match book builder's opening-length inclusion.
            out.append({'source_group':f.stem,'site':r['Site'],'white':r['White'],'black':r['Black'],'white_elo':r['WhiteElo'],'black_elo':r['BlackElo'],'mean_elo':(r['WhiteElo']+r['BlackElo'])//2,'mean_elo_exact':(r['WhiteElo']+r['BlackElo'])/2,'speed':'blitz' if 'Blitz' in r['Event'] else 'rapid','date':str(r['UTCDate']),'time_control':r['TimeControl'],'moves':moves,'labels':labels})
    (HERE/'human-sample.json').write_text(json.dumps(out));return out,errors

def marginal(rows,depth,kind):
    counts=collections.Counter()
    for r in rows:
        if len(r['moves'])<depth:continue
        k=' '.join(r['moves'][:depth]) if kind=='prefix' else r['labels'][depth-1][kind]
        counts[k]+=1
    return counts
def marginal_stats(h,m,bins,hrows,depth,kind):
    def coarsen(d):
        c=collections.Counter()
        for k,v in d.items():c[k if k in bins else 'OTHER']+=v
        n=sum(c.values());return {k:v/n for k,v in c.items()}
    p=coarsen(h);q=coarsen(m);v=metrics(p,q)
    keys=sorted(set(p)|set(q));pp=np.array([p.get(k,0) for k in keys]);qq=np.array([q.get(k,0) for k in keys]);rng=np.random.default_rng(SEED)
    clusters=collections.defaultdict(collections.Counter)
    for r in hrows:
        if len(r['moves'])<depth:continue
        k=' '.join(r['moves'][:depth]) if kind=='prefix' else r['labels'][depth-1][kind]
        clusters[r['source_group']][k if k in bins else 'OTHER']+=1
    matrix=np.array([[c.get(k,0) for k in keys] for c in clusters.values()]);ids=rng.integers(0,len(matrix),(1000,len(matrix)))
    hs=matrix[ids].sum(1);hs=hs/hs.sum(1)[:,None]
    ms=rng.multinomial(sum(m.values()),qq,size=1000)/sum(m.values())
    tv=abs(hs-ms).sum(1)/2
    return {**v,'tv_ci95':[float(x) for x in np.quantile(tv,[.025,.975])],'human_n':sum(h.values()),'model_n':sum(m.values()),'human':p,'model':q,'bins':len(bins)+1}

def rollout_summary(rollouts,human):
    out={}
    groups={'mean1550-1650_blitz':[r for r in human if 1550<=r['mean_elo']<=1650 and r['speed']=='blitz'],'mean1550-1650_rapid':[r for r in human if 1550<=r['mean_elo']<=1650 and r['speed']=='rapid'],'mean1500-1700_combined':[r for r in human if 1500<=r['mean_elo']<=1700]}
    groups['september2025_mean1500-1700']=[r for r in human if 1500<=r['mean_elo']<=1700 and r['date'].startswith('2025-09')]
    for gname,h in groups.items():
        if len(h)<50:continue
        out[gname]={'games':len(h),'comparisons':{}}
        for depth,kind in ((1,'prefix'),(2,'prefix'),(4,'prefix'),(8,'family'),(12,'family'),(16,'family'),(12,'eco')):
            hc=marginal(h,depth,kind);n=sum(hc.values());bins={k for k,v in hc.items() if v/n>=.005}
            comp={}
            for setting in SETTINGS:
                rs=[r for r in rollouts if r['setting']==setting];mc=marginal(rs,depth,kind)
                if not mc:continue
                if setting=='argmax':mc=collections.Counter({k:v*2000 for k,v in mc.items()})
                comp[setting]=marginal_stats(hc,mc,bins,h,depth,kind)
            out[gname]['comparisons'][f'{depth}ply_{kind}']=comp
    out['model_repertoire']={}
    for setting in SETTINGS:
        rs=[r for r in rollouts if r['setting']==setting]
        if not rs:continue
        out['model_repertoire'][setting]={'games':len(rs),'survivors_by_ply':{p:sum(len(r['moves'])>=p for r in rs) for p in (2,4,8,12,16)},'book_coverage_by_ply':{p:sum(len(r['book_covered'])>p and r['book_covered'][p] for r in rs)/len(rs) for p in range(16)},'distinct_prefixes':{p:len(marginal(rs,p,'prefix')) for p in (2,4,8,12,16)},'effective_families_12ply':2**metrics(dict.fromkeys([],0),{k:v/sum(marginal(rs,12,'family').values()) for k,v in marginal(rs,12,'family').items()})['model_entropy_bits']}
    return out

def main():
    runfile=HERE/'run.json'
    if not runfile.exists():raise RuntimeError('Free rollout run is not complete: run.json is absent. Use conditional-summary.json for completed conditional results.')
    run=json.loads(runfile.read_text())
    rows=json.loads((HERE/'conditional.json').read_text());rollouts=json.loads((HERE/'rollouts.json').read_text());hum,errors=human_sample()
    expected=run['rollouts_per_stochastic_setting'];counts=collections.Counter(r['setting'] for r in rollouts)
    assert counts['argmax']==1 and counts['app_default']==expected and counts['full']==expected,(counts,expected)
    summary={'status':'complete','run':run,'conditional':conditional_summary(rows),'cutoff_sensitivity':cutoff(rows),'human_sample_games':len(hum),'human_parse_errors':errors,'rollout':rollout_summary(rollouts,hum),'first_move_exact':{book:{'human':r['human'],'settings':{s:r['settings'][s]['distribution'] for s in SETTINGS}} for book in sorted({r['book'] for r in rows}) if (r:=next(x for x in rows if x['book']==book and x['ply']==0))}}
    (HERE/'summary.json').write_text(json.dumps(summary,indent=2));print(json.dumps({k:v for k,v in summary.items() if k not in ('rollout','first_move_exact')},indent=2))

if __name__=='__main__':main()
