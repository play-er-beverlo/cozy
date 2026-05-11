export const MIN_RATING = 1
export const MAX_RATING = 10
export const HANDICAP_POINTS_PER_LEVEL = 5

export function clampRating(value: number): number {
  return Math.min(MAX_RATING, Math.max(MIN_RATING, value))
}

export function handicapPoints(lowerRating: number, higherRating: number): number {
  return Math.max(0, higherRating - lowerRating) * HANDICAP_POINTS_PER_LEVEL
}

export function applyTournamentResult(winnerRating: number, loserRating: number) {
  return {
    winnerAfter: clampRating(winnerRating + 1),
    loserAfter: clampRating(loserRating - 1)
  }
}
