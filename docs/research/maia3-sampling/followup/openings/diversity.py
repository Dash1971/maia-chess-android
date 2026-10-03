"""Supplementary label diversity and final-input provenance checks."""
import argparse,collections,json,math
from pathlib import Path
from mobile_policy import sha256
from conditional import HERE

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--source-study',required=True,type=Path);args=ap.parse_args();source=args.source_study.resolve()/'openings'
    new=json.loads((HERE/'rollouts95.json').read_text());old=json.loads((source/'rollouts.json').read_text())
    run=json.loads((HERE/'run.json').read_text());prior=json.loads((source/'run.json').read_text());summary=json.loads((HERE/'summary95.json').read_text())
    assert run['status']=='complete' and run['completed']==2000
    assert run['source_sha256']['old_rollouts']==summary['old_rollout_sha256']==sha256(source/'rollouts.json')
    assert run['source_sha256']['human']==summary['human_sha256']==sha256(source/'human-sample.json')
    assert run['source_sha256']['model']==prior['model_sha256']
    rs={'full95':new,'full':[r for r in old if r['setting']=='full'],'app_default':[r for r in old if r['setting']=='app_default']}
    assert all(len(r)==2000 for r in rs.values())
    validation={'status':'passed','counts':{k:len(v) for k,v in rs.items()},'historical_run_complete':prior['rollouts_per_stochastic_setting']==2000,
        'historical_model_matches':True,'new_rollout_sha256':sha256(HERE/'rollouts95.json'),'old_rollout_sha256':sha256(source/'rollouts.json'),
        'human_sha256':sha256(source/'human-sample.json'),'historical_run_sha256':sha256(source/'run.json'),'new_run_sha256':sha256(HERE/'run.json'),
        'script_sha256':sha256(Path(__file__))}
    (HERE/'input-validation95.json').write_text(json.dumps(validation,indent=2));out={}
    for setting,rows in rs.items():
        out[setting]={}
        for depth in (8,12,16):
            c=collections.Counter(r['labels'][depth-1]['family'] for r in rows if len(r['moves'])>=depth);n=sum(c.values())
            entropy=-sum(v/n*math.log2(v/n) for v in c.values())
            out[setting][str(depth)]={'survivors':n,'observed_families':len(c),'effective_families':2**entropy,
                'top_families':[{'family':k,'games':v,'fraction':v/n} for k,v in c.most_common(8)]}
    (HERE/'family-diversity95.json').write_text(json.dumps(out,indent=2));print('Complete; all three model sample counts = 2000')

if __name__=='__main__':main()
