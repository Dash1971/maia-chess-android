// GPL-3.0 reference oracle: regenerate with Node >=22.18, no Dart dependency.
import {getAnnotation, getWinChance} from './reference/score.ts';
import {readFileSync, writeFileSync} from 'node:fs';
const sourcePath = 'test/fixtures/classification/stockfish18-fast.json';
const source = JSON.parse(readFileSync(sourcePath, 'utf8'));
const contexts = [
  ['initial-e4-white', 'opera-1858', 1, false],
  ['ordinary-white', 'ruy-lopez', 3, false],
  ['ordinary-black', 'byrne-fischer-1956', 2, false],
  ['qa3-white-sacrifice', 'byrne-fischer-1956', 23, true],
  ['na4-black-sacrifice', 'byrne-fischer-1956', 22, true],
].map(([name, gameName, ply, sacrifice]) => {
  const game = source.runs.find(g => g.name === gameName);
  const move = game.moves[ply - 1];
  const alternative = game.scores[ply - 1].lines.find(l => l.moves[0] !== move).moves[0];
  const positions = game.positions.slice(Math.max(0, ply - 2), ply + 1);
  const material = game.material.slice(Math.max(0, ply - 2), ply + 1);
  if ((material.at(-2) > -material.at(-1) + 100) !== sacrifice) throw Error(name);
  return {name, sourceGame: gameName, sourcePly: ply, positions,
    moves: game.moves.slice(Math.max(0, ply - 2), ply), material, alternative, sacrifice,
    color: positions.at(-2).split(' ')[1] === 'w' ? 'white' : 'black'};
});
// Packed vector: beforePrevious,before,after,PV1,PV2,playedBest,PVcount.
// Integers are cp; strings mN are mate N. Values are mover-relative here.
const vectors = [];
const add = (...v) => vectors.push(v);
const anchors = [-1200,-1000,-500,-200,0,200,500,1000,1200];
const inverse = chance => Math.log(chance / (100 - chance)) / 0.00368208;
function around(chance) {
  if (chance <= 0 || chance >= 100) return [];
  const cp = Math.round(inverse(chance));
  return [cp - 1, cp, cp + 1];
}
for (const anchor of anchors) {
  const clamped = Math.max(-1000, Math.min(1000, anchor));
  for (const threshold of [5,10,20]) {
    for (const after of around(getWinChance(clamped) - threshold)) {
      for (const played of [true,false]) add(0,anchor,after,anchor,-1000,played,2);
    }
  }
  for (const second of around(getWinChance(clamped) - 10)) {
    for (const played of [true,false]) add(0,anchor,anchor,anchor,second,played,2);
  }
  for (const previous of around(getWinChance(clamped) - 5)) {
    add(previous,anchor,anchor,anchor,-1000,true,2);
  }
}
// Interesting uses a strict -200cp cutoff; losses and best-move comparison
// must already allow this branch. Test both sides including exact equality.
for (const next of [-201,-200,-199]) {
  for (const played of [true,false]) add(0,next,next,next,next,played,2);
}
const scores = [-1200,-1000,-201,-200,-199,0,199,200,201,1000,1200,'m-5','m-1','m0','m1','m5'];
for (const before of scores) {
  for (const after of scores) {
    add(0,before,after,before,-1000,true,2);
  }
  for (const count of [0,1,2]) {
    for (const played of [true,false]) add(0,before,before,before,-1000,played,count);
  }
}
// Prevprev mate signs and clamp affect Good even when the move itself is safe.
for (const previous of scores) {
  for (const best of [0,200,1000,'m-1','m0','m1']) {
    add(previous,best,best,best,-1000,true,2);
  }
}
const unique = [...new Map(vectors.map(v => [JSON.stringify(v),v])).values()];
function value(packed, color) {
  const mate = typeof packed === 'string';
  const n = mate ? Number(packed.slice(1)) : packed;
  return {type: mate ? 'mate' : 'cp', value: color === 'black' ? -n : n};
}
const expected = contexts.map(c => unique.map(v => {
  const [pp,prev,next,best,second,played,count] = v;
  const roots = played ? [c.moves.at(-1),c.alternative] : [c.alternative,c.moves.at(-1)];
  const lines = [best,second].slice(0,count).map((s,i) => ({
    score: {value: value(s,c.color)}, sanMoves: [roots[i]],
  }));
  return getAnnotation(c.moves.length > 1 ? value(pp,c.color) : null,value(prev,c.color),value(next,c.color),
    c.color,lines,c.sacrifice,c.moves.at(-1));
}));
const output = {reference:'En Croissant v0.15.0 getAnnotation', source:sourcePath,
  vectorFields:['beforePrevious','before','after','pv1','pv2','playedBest','pvCount'],
  encoding:'integer cp or mN mate, mover-relative; expected indexed [context][vector]',
  contexts,vectors:unique,expected};
writeFileSync('test/fixtures/classification/annotation-boundaries.json', JSON.stringify(output)+'\n');
console.log(`${contexts.length} contexts × ${unique.length} vectors = ${contexts.length*unique.length} exact oracle cases`);
