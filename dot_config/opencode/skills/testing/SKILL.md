---
name: testing
description: "Test writing reference. How to write thorough, maintainable, behaviour-focused tests. Covers unit, integration, edge cases, test structure, and when to mock."
---

# Testing — Writing Good Tests

A reference for writing thorough, maintainable tests. Load this skill when writing tests for new or existing code.

## Before Writing Tests

1. **Read the code under test.** Understand what it does, what it depends on, and what can go wrong.
2. **Check for existing tests.** Don't duplicate. Extend what's there. Follow the existing patterns — test framework, file naming, helper conventions.
3. **Check for test utilities.** Most projects have test helpers, fixtures, factories, or builders. Use them. Don't reinvent.

### When There Are No Existing Tests

If the project has no tests at all, **ask the user before writing any.** Don't guess at conventions. Ask about:

- Test framework preference (or infer from project dependencies if obvious)
- File naming and location conventions
- Any specific patterns they want to follow

Once you have direction, the rest of this skill applies as the default approach.

## What to Prioritise

When asked to test a module or package, don't try to exhaustively test everything. Prioritise by risk:

1. **Exported API / public interface** — this is the contract. If it breaks, callers break.
2. **Complex logic** — branching, state transitions, calculations. The more paths through the code, the more likely a bug hides there.
3. **Error-prone code paths** — error handling, boundary conditions, anything that deals with external input.
4. **Recent changes** — new or recently modified code is the most likely to have bugs.

Skip trivial code. Getters, setters, and simple pass-throughs don't need tests unless they contain logic.

## What to Test

### The Happy Path

The primary use case working correctly. This is the baseline. If this breaks, everything breaks.

### Edge Cases

The inputs and states that live at the boundaries:

- **Empty/zero values:** empty string, nil/null, zero, empty slice/array, empty map
- **Boundary values:** off-by-one, max int, min int, exactly-at-limit, one-over-limit
- **Single element:** one item in a collection (different from empty, different from many)
- **Duplicates:** same input twice, duplicate keys, repeated calls
- **Unicode and special characters:** emoji, multi-byte characters, null bytes, very long strings
- **Concurrent access:** if the code is meant to be thread-safe, test it under contention

### Error Cases

Every way the code can fail:

- Invalid input (wrong type, out of range, malformed)
- Missing dependencies (nil pointer, missing config, unavailable service)
- External failures (network timeout, disk full, permission denied)
- Partial failures (half the batch succeeds, then one fails — what state is left?)

### State Transitions

If the code changes state (database, cache, file system, in-memory):

- Verify the state BEFORE and AFTER the operation
- Test idempotency — calling the same operation twice should be safe (or error correctly)
- Test rollback — if the operation fails partway, is the state consistent?

## Test Structure

### One Concept Per Test

Each test should verify one behaviour. Not one function — one behaviour. A function with three distinct behaviours needs at least three tests.

Bad: `TestProcessOrder` that checks validation, pricing, inventory, and notification in one test.
Good: `TestProcessOrder_RejectsEmptyCart`, `TestProcessOrder_AppliesDiscount`, `TestProcessOrder_DecrementsInventory`.

### Name Tests Descriptively

Test names should describe the scenario and expected outcome. Someone reading the test name alone should understand what's being verified.

Pattern: `Test_<Unit>_<Scenario>_<ExpectedBehaviour>` or `Test<Unit>_<Scenario>` — adapt to the project's existing convention.

Examples:

- `TestCache_ExpiredEntry_ReturnsNil`
- `TestParseConfig_MissingRequiredField_ReturnsError`
- `TestHandler_ValidRequest_Returns200WithBody`

### Arrange-Act-Assert

Structure every test in three phases:

1. **Arrange** — set up inputs, dependencies, and expected state
2. **Act** — call the thing being tested
3. **Assert** — verify the result

Keep these visually separated. A blank line between each phase is enough.

### Table-Driven Tests

When testing the same behaviour with different inputs, use table-driven tests instead of copy-pasting test functions. This is idiomatic in Go and useful in any language.

```go
tests := []struct {
    name     string
    input    string
    expected int
    wantErr  bool
}{
    {"empty string", "", 0, true},
    {"single digit", "5", 5, false},
    {"negative", "-3", -3, false},
    {"overflow", "99999999999999", 0, true},
    {"non-numeric", "abc", 0, true},
}

for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        got, err := Parse(tt.input)
        if tt.wantErr {
            require.Error(t, err)
            return
        }
        require.NoError(t, err)
        assert.Equal(t, tt.expected, got)
    })
}
```

Add new cases to the table when bugs are found. The table becomes a living record of known edge cases.

### Test Isolation

- Each test must be independent. No test should depend on another test running first.
- Clean up after yourself. If a test creates a file, database row, or temp directory, remove it.
- Don't rely on execution order. Tests should pass when run individually, in any order, and in parallel.

## What NOT to Test

- **Don't test the framework.** If you're using an ORM, don't test that `Save()` writes to the database. Test your logic around it.
- **Don't test private implementation details.** Test behaviour through the public interface. If you refactor internals, tests shouldn't break unless behaviour changed.
- **Don't test trivial getters/setters.** If a method is `return s.name`, it doesn't need a test.
- **Don't write tests that restate the implementation.** If the test is just a copy of the function with hardcoded values, it tests nothing.

## Test Types

### Unit Tests

Test a single unit of behaviour in isolation. Fast, deterministic, no external dependencies. These are the default when testing pure logic, calculations, and data transformations.

### Integration Tests

Test code that crosses boundaries — database, HTTP, file system, external APIs.

- **Use real dependencies when practical.** Testcontainers, in-memory databases, local servers. See the Mocking section for when to substitute.
- **Test the boundary, not the internals.** An integration test for a database repository should verify that data round-trips correctly, not how the SQL is constructed.
- **Keep them focused.** Integration tests are expensive. Test the integration point, not every permutation of business logic through it.
- **Mark them clearly.** Use build tags, test categories, or naming conventions (`_integration_test.go`, `describe.skip` for CI) so they can be run separately.

### End-to-End Tests

E2E tests are highly project-specific and depend on the project's tooling and infrastructure. **Don't write e2e tests unless the project already has an e2e setup and conventions.**

Instead, flag when something likely needs e2e coverage. Good candidates:

- Critical user-facing flows (signup, checkout, onboarding)
- Flows that cross multiple services or systems
- Anything where a bug would have serious business impact

When you identify a candidate, tell the user: "This flow is a good candidate for an e2e test" and explain why, rather than attempting to write one.

### Situational: Property-Based Tests

Instead of specific examples, define properties that should always hold and let the framework generate random inputs. Useful for:

- Parsers and serializers (roundtrip: `parse(serialize(x)) == x`)
- Sorting and ordering (idempotent, length-preserving)
- Mathematical properties (commutativity, associativity)

Don't default to these. Suggest them when the code has clear invariants that are hard to cover with example-based tests.

### Situational: Snapshot Tests

Capture the output of a function and compare it against a stored snapshot. Useful for:

- Serialization formats (JSON, HTML, CLI output)
- UI components (rendered output)

Be cautious — snapshots are easy to write but easy to blindly update. Only suggest them when the output is complex and manually writing assertions would be impractical.

## Mocking and Test Doubles

### When to Use the Real Thing

If a dependency is **fast, deterministic, and has no side effects**, just use it. Don't mock things that don't need mocking. An in-memory data structure, a pure function, a local calculation — these are fine as-is.

### When to Substitute

If a dependency has **any side effect** — sends an email, writes to a database, makes a network call, charges money, writes to the file system — it must be substituted in unit tests. No exceptions.

### Prefer Fakes Over Mocks

- A **fake** is a working in-memory implementation (e.g. an in-memory store that implements the repository interface). Fakes test behaviour.
- A **mock** records calls and asserts on them. Mocks test implementation.

Prefer fakes. They make tests resilient to refactoring because they don't care *how* the code interacts with the dependency, only that the end result is correct.

### When Mocks Are the Right Tool

Use mocks when you specifically need to verify that a side effect happened:

- An email notification was sent
- A metric was recorded
- An audit log entry was created
- An external API was called with specific parameters

These are cases where the *call itself* is the important behaviour, not just the end state.

### Don't Over-Mock

If a test mocks five things, it's probably testing the wrong level of abstraction. Step up to an integration test, or reconsider what you're actually trying to verify.

Don't mock your own code unless there's no alternative.

## Test Architecture

### File Location

Place test files next to the code they test. Not in a separate `tests/` tree — right next to the source file.

- `handler.go` → `handler_test.go` (same directory)
- `parser.ts` → `parser.test.ts` (same directory)
- `service.py` → `test_service.py` (same directory)

This makes it obvious what's tested and what isn't. When tests live far from source, they drift apart.

**Exception:** e2e tests and other high-level tests that don't correspond to a single source file. These typically live in a dedicated directory. Follow the project's existing convention.

### Test Helpers and Utilities

When test helpers are general-purpose and used across many unrelated tests, extract them into a shared location (e.g. `testutil/`, `internal/testhelpers/`, or whatever the project convention is). Examples: fake implementations, request builders, fixture loaders, custom assertion helpers.

If a helper is only used by tests in one package or module, keep it there. Don't prematurely centralise.

### Shared Setup vs Duplication

- **Use shared setup** (`beforeEach`, `TestMain`, test fixtures) when multiple tests in the same file need identical setup. It reduces maintenance — change the setup once, not in twenty places.
- **Duplicate setup** when tests need slightly different contexts or when the shared setup would become a complex conditional mess. A slightly longer test that reads top-to-bottom is better than a short test that requires jumping to three helper functions to understand.

The rule: if you're copying the exact same five lines into every test in a file, extract it. If each test's setup differs by a line or two, keep them independent.

### Integration Test Organisation

Integration tests often need different infrastructure (database containers, test servers, environment variables). How they're organised varies significantly by project — build tags, separate directories, naming conventions, CI configuration. Follow whatever the project already does. If there's no convention, ask the user.

## Test Quality Checklist

Before considering tests complete, verify:

- [ ] Happy path covered
- [ ] Error cases covered (every error return/throw has a test)
- [ ] Edge cases covered (empty, nil, boundary, duplicate)
- [ ] Test names describe what's being tested
- [ ] No test depends on another test
- [ ] Tests run in under a few seconds (unit) or are marked as integration
- [ ] No hardcoded sleep/delays (use polling, channels, or condition waits)
- [ ] Assertions check the RIGHT thing (not just "no error" — check the actual output)

## Language-Specific Notes

Adapt to the project's language and test framework. Common patterns:

**Go:** use `testing` + `testify` (assert/require). Table-driven tests are idiomatic. Use `t.Helper()` in test helpers. Use `t.Parallel()` where safe.

**TypeScript/JavaScript:** use `vitest`, `jest`, or the project's existing framework. Use `describe`/`it` blocks for grouping. Use `beforeEach`/`afterEach` for setup/teardown.

**Python:** use `pytest`. Use fixtures for setup. Use `parametrize` for table-driven style.

**Rust:** use the built-in `#[test]` attribute and `mod tests`. Use `#[should_panic]` for expected failures. For async, use `#[tokio::test]`.

Always follow whatever the project already uses. Don't introduce a new test framework.
