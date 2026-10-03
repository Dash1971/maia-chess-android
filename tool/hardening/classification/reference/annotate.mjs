import {getAnnotation} from "./score.ts";
import {readFileSync} from "node:fs";
const cases=JSON.parse(readFileSync(0,"utf8"));
console.log(JSON.stringify(cases.map(c=>getAnnotation(c.prevprev,c.prev,c.next,c.color,c.prevMoves,c.is_sacrifice,c.move))));
