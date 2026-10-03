"""Independent first-move arithmetic from archived exact probabilities."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parent
source=ROOT.parent/'sampling-research-20261002/first-move-probabilities.json'
data=json.loads(source.read_text());full=data['profiles']['full_policy']['probabilities']
ranked=sorted(full,key=full.get,reverse=True);keep=[];mass=0
for move in ranked:
 keep.append(move);mass+=full[move]
 if mass>=.95:break
q={m:full[m]/mass for m in keep}
def tv(p,q):return sum(abs(p.get(m,0)-q.get(m,0)) for m in set(p)|set(q))/2
result={'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'temperature':1.,'top_p':.95,'cutoff':'include crossing move as in Mobile Maia','retained_moves':keep,'retained_full_probability':mass,'removed_full_probability':1-mass,'p95_probabilities':q,'full_probabilities':full,'p95_vs_full_tv':tv(q,full),'human_first_move_distances':{k:{'p95_tv':tv(book['probabilities'],q),'full_tv':tv(book['probabilities'],full)} for k,book in data['books'].items()},'one_position_bound':'With inclusive threshold .95, removed mass is at most .05; total variation from full policy equals removed mass. This is not a bound of five percent on whole-game changes or Elo.','length_16_coupling_bound_upper':1-.95**16}
assert abs(tv(q,full)-(1-mass))<1e-12
(ROOT/'first-move-check.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
