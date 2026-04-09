const { describe, it } = require('node:test');
const assert = require('node:assert');
const { greet, add } = require('./index');

describe('greet', () => {
  it('returns greeting with name', () => {
    assert.strictEqual(greet('World'), 'Hello, World!');
  });

  it('returns default for empty input', () => {
    assert.strictEqual(greet(''), 'Hello, stranger!');
  });
});

describe('add', () => {
  it('adds two numbers', () => {
    assert.strictEqual(add(2, 3), 5);
  });
});
