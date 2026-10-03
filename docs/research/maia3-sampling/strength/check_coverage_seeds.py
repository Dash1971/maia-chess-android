import collections,json
from pathlib import Path
BASE=Path(__file__).resolve().parent
specs=[('79m',['79m-pair0','79m-pair1','79m-pair2'],'79m-app-draw',600,3000000000),('single-knob',['79m-temp-only','79m-topp-only'],'79m-single-knob-app-draw',300,4000000000),('5m',['5m'],'5m-app-draw',200,2026100202)]
report={};seedsets={}
for name,dirs,sensitivity,nper,contbase in specs:
 rows=[r for d in dirs for r in map(json.loads,(BASE/d/'games.jsonl').read_text().splitlines())];continued=list(map(json.loads,(BASE/sensitivity/'games.jsonl').read_text().splitlines()));ids=[r['id'] for r in rows];sids=[r['id'] for r in continued];assert len(ids)==len(set(ids));assert len(sids)==len(set(sids));assert set(ids)==set(sids)
 groups=collections.defaultdict(list)
 for r in rows:groups[r['pair_index']].append(r)
 color={}
 for index,group in groups.items():
  assert len(group)==nper;assert set(r['number'] for r in group)==set(range(nper));w=sum(r['white']==r['first'] for r in group);assert w==nper//2;color[str(index)]={'white_first':w,'black_first':len(group)-w}
 primaryseeds=[s for r in rows for s in [r['seed_white'],r['seed_black']]];futureseeds=[s for r in continued for s in [r['sensitivity_seed_white'],r['sensitivity_seed_black']]];assert len(set(primaryseeds))==len(primaryseeds);assert len(set(futureseeds))==len(futureseeds);assert not(set(primaryseeds)&set(futureseeds))
 for r in continued:assert r['sensitivity_seed_white']==contbase+1000000*r['pair_index']+2*r['number'];assert r['sensitivity_seed_black']==r['sensitivity_seed_white']+1
 seedsets[name]={'initial':set(primaryseeds),'future':set(futureseeds)};report[name]={'standard_games':len(rows),'sensitivity_rows':len(continued),'ids_unique_complete_equal':True,'number_coverage_complete':True,'color_counts':color,'within_study_seeds_unique':True,'within_study_initial_future_disjoint':True,'future_base':contbase,'caps_standard':sum(r['termination']=='max_plies' for r in rows),'caps_sensitivity':sum(r['termination']=='max_plies' for r in continued)}
assert not(seedsets['79m']['initial']&seedsets['single-knob']['initial'])
assert not(seedsets['79m']['future']&seedsets['single-knob']['future'])
assert not((seedsets['79m']['initial']|seedsets['79m']['future'])&(seedsets['single-knob']['initial']|seedsets['single-knob']['future']))
assert seedsets['5m']['initial']<=seedsets['79m']['initial']
report['cross_study']={'all_79m_primary_single_knob_initial_future_streams_disjoint':True,'5m_initial_seeds_reuse_primary_subset':True,'models_not_pooled':True,'note':'Cross-model streams can overlap, including5M futures and single-knob originals; those model sets are separately analyzed, not independent replications.'}
(BASE/'coverage-seed-integrity.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
