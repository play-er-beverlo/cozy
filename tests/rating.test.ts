import { describe, expect, it } from 'vitest'
import { applyTournamentResult, clampRating, handicapPoints } from '../app/utils/rating'

describe('handicapPoints', () => {
  it('returns zero for equal ratings', () => {
    expect(handicapPoints(4, 4)).toBe(0)
  })

  it('returns five points per rating gap', () => {
    expect(handicapPoints(2, 5)).toBe(15)
  })
})

describe('clampRating', () => {
  it('clamps values below minimum', () => {
    expect(clampRating(0)).toBe(1)
  })

  it('clamps values above maximum', () => {
    expect(clampRating(11)).toBe(10)
  })
})

describe('applyTournamentResult', () => {
  it('increments winner and decrements loser', () => {
    expect(applyTournamentResult(5, 4)).toEqual({
      winnerAfter: 6,
      loserAfter: 3
    })
  })

  it('applies clamping at boundaries', () => {
    expect(applyTournamentResult(10, 1)).toEqual({
      winnerAfter: 10,
      loserAfter: 1
    })
  })
})
