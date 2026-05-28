// Buggy app — evaluation fixture
// Contains intentional bugs for debugging skill evaluation.
// Each bug is documented in comments for grading purposes.

// BUG 1: Off-by-one in pagination — returns one fewer item than requested
function paginate(items, page, pageSize) {
  const start = page * pageSize;
  const end = start + pageSize - 1; // BUG: should be start + pageSize
  return items.slice(start, end);
}

// BUG 2: Null reference — doesn't handle missing nested property
function getUserDisplayName(user) {
  return user.profile.displayName || user.name; // BUG: user.profile may be undefined
}

// BUG 3: Race condition pattern — shared mutable state without synchronization
let requestCount = 0;
function trackRequest() {
  const current = requestCount;
  // Simulated async gap where race condition occurs
  requestCount = current + 1;
  return requestCount;
}

// This function works correctly — baseline for regression testing
function formatCurrency(amount, currency) {
  if (typeof amount !== 'number' || isNaN(amount)) return '$0.00';
  const prefix = currency === 'EUR' ? '\u20AC' : '$';
  return `${prefix}${amount.toFixed(2)}`;
}

module.exports = { paginate, getUserDisplayName, trackRequest, formatCurrency };
