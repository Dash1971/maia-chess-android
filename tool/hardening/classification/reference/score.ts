// GPL-3.0: functions copied verbatim from En Croissant v0.15.0 src/utils/score.ts.
// Only imports/formatScore removed; external clamp supplied below. Node 22.18+.
type Color = "white" | "black";
type ScoreValue = {type: string; value: number};
type BestMoves = {score: {value: ScoreValue}; sanMoves: string[]};
type Annotation = string;
const minMax = (value: number, min: number, max: number) => Math.max(min, Math.min(max, value));
const CP_CEILING = 1000;

export function getWinChance(centipawns: number) {
    return 50 + 50 * (2 / (1 + Math.exp(-0.00368208 * centipawns)) - 1);
}

export function normalizeScore(score: ScoreValue, color: Color): number {
    let cp = score.value;
    if (color === "black") {
        cp *= -1;
    }
    if (score.type === "mate") {
        cp = CP_CEILING * Math.sign(cp);
    }
    return minMax(cp, -CP_CEILING, CP_CEILING);
}

function normalizeScores(
    prev: ScoreValue,
    next: ScoreValue,
    color: Color,
): { prevCP: number; nextCP: number } {
    return {
        prevCP: normalizeScore(prev, color),
        nextCP: normalizeScore(next, color),
    };
}

export function getAccuracy(prev: ScoreValue, next: ScoreValue, color: Color): number {
    const { prevCP, nextCP } = normalizeScores(prev, next, color);
    return minMax(
        103.1668 * Math.exp(-0.04354 * (getWinChance(prevCP) - getWinChance(nextCP))) - 3.1669 + 1,
        0,
        100,
    );
}

export function getCPLoss(prev: ScoreValue, next: ScoreValue, color: Color): number {
    const { prevCP, nextCP } = normalizeScores(prev, next, color);

    return Math.max(0, prevCP - nextCP);
}

export function getAnnotation(
    prevprev: ScoreValue | null,
    prev: ScoreValue | null,
    next: ScoreValue,
    color: Color,
    prevMoves: BestMoves[],
    is_sacrifice?: boolean,
    move?: string,
): Annotation {
    const { prevCP, nextCP } = normalizeScores(prev || { type: "cp", value: 0 }, next, color);
    const winChanceDiff = getWinChance(prevCP) - getWinChance(nextCP);

    if (winChanceDiff > 20) {
        return "??";
    }
    if (winChanceDiff > 10) {
        return "?";
    }
    if (winChanceDiff > 5) {
        return "?!";
    }

    if (prevMoves.length > 1) {
        const scores = normalizeScores(prevMoves[0].score.value, prevMoves[1].score.value, color);
        if (
            getWinChance(scores.prevCP) - getWinChance(scores.nextCP) > 10 &&
            move === prevMoves[0].sanMoves[0]
        ) {
            const scores = normalizeScores(
                prevprev || { type: "cp", value: 0 },
                prevMoves[0].score.value,
                color,
            );
            if (is_sacrifice) {
                return "!!";
            }
            if (getWinChance(scores.nextCP) - getWinChance(scores.prevCP) > 5) {
                return "!";
            }
        } else if (is_sacrifice && nextCP > -200) {
            return "!?";
        }
    }
    return "";
}
