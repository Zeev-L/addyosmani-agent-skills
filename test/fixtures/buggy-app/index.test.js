const { describe, it } = require('node:test');
const assert = require('node:assert');
const { paginate, getUserDisplayName, formatCurrency } = require('./index');

describe('paginate', () => {
  const items = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];

  it('returns correct page size', () => {
    // This test EXPOSES BUG 1: returns 2 items instead of 3
    const result = paginate(items, 0, 3);
    assert.strictEqual(result.length, 3);
  });

  it('returns correct page offset', () => {
    const result = paginate(items, 1, 3);
    assert.deepStrictEqual(result, ['d', 'e', 'f']);
  });
});

describe('getUserDisplayName', () => {
  it('returns display name when present', () => {
    const user = { name: 'Alice', profile: { displayName: 'alice123' } };
    assert.strictEqual(getUserDisplayName(user), 'alice123');
  });

  it('handles missing profile', () => {
    // This test EXPOSES BUG 2: throws TypeError
    const user = { name: 'Bob' };
    assert.strictEqual(getUserDisplayName(user), 'Bob');
  });
});

describe('formatCurrency', () => {
  it('formats USD correctly', () => {
    assert.strictEqual(formatCurrency(42.5, 'USD'), '$42.50');
  });

  it('handles invalid input', () => {
    assert.strictEqual(formatCurrency(NaN, 'USD'), '$0.00');
  });
});
