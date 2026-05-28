// Feature app — evaluation fixture
// Provides a minimal codebase for TDD and spec-driven scenarios.
// Agents are asked to add functionality here following skill workflows.

function greet(name) {
  if (!name || typeof name !== 'string') return 'Hello, stranger!';
  return `Hello, ${name}!`;
}

function add(a, b) {
  return a + b;
}

module.exports = { greet, add };
