# Architecture Review: Architect Agent Spec

## Overall Assessment

This is a well-scoped spec. The problem is clearly defined, the two modes are distinct, and the non-goals show good restraint. Most of my feedback is about gaps and edge cases rather than fundamental design issues.

## What's Working

- **Pragmatism as a core principle.** "Recommend patterns when they solve real problems" is threaded through the whole spec, not just stated once. This is the right framing — it prevents the agent from becoming a pattern-dispensing machine.
- **Read-only constraint.** Clean separation of concerns. The architect plans, other agents build. This avoids the temptation to "just fix it while we're here" which muddies agent roles.
- **Scaling depth to the request.** Good call. A focused question shouldn't trigger a full codebase audit.
- **Deferring the design patterns skill.** Building the agent first and observing what reference material is actually needed is the right order of operations.

## Gaps and Concerns

### 1. No guidance on report structure or output location

The spec says codebase reviews produce a "report" but doesn't specify where it goes. Conversational output disappears. If the user asks for a broad review, should the agent write a markdown file? If so, where? The spec says the agent is read-only and doesn't modify files, but then how does a persistent report get created?

**Recommendation:** Clarify that the agent can write review/report files (this is output, not code modification). Define a conventional location like `.opencode/reviews/` or allow the user to specify. The system prompt should distinguish between "doesn't modify source code" and "can produce analysis documents."

### 2. Mode detection is implicit

The spec describes two modes but provides no guidance on how the agent distinguishes between them. If a user says "review this" and points at a spec file that references code, is that Mode 1 or Mode 2? What if they ask to review a module but want to understand if it aligns with a spec?

**Recommendation:** This probably doesn't need rigid mode detection — the agent can infer from context. But the system prompt should acknowledge the overlap and tell the agent to blend approaches when appropriate rather than treating modes as mutually exclusive.

### 3. Anti-patterns are missing from the smell list

The code smells list (lines 41–50) covers structural smells well, but the spec doesn't mention common anti-patterns by name: Big Ball of Mud, Golden Hammer, Lava Flow, Cargo Cult Programming, etc. These are useful vocabulary for communicating findings clearly.

**Recommendation:** Add a short anti-patterns section alongside the code smells. Naming things precisely helps users act on findings.

### 4. No mention of how the agent handles disagreement with existing architecture

The spec review mode (line 59–63) says the agent should note where the spec diverges from existing patterns and whether divergence is justified. Good. But the codebase review mode has no equivalent — it doesn't explicitly say the agent should challenge existing architecture when it's suboptimal, not just describe it.

**Recommendation:** Add explicit guidance in Mode 1 that the agent should evaluate whether existing patterns are serving the codebase well, not just catalogue them. "What's there" should include "and here's whether it's the right choice."

### 5. TodoWrite usage is underspecified

Line 87 says the agent uses TodoWrite to track areas explored during a review. This is a good idea for broad reviews, but there's no guidance on when to use it versus when it's overkill. For a focused "is this module well-structured?" question, TodoWrite adds overhead for no benefit.

**Recommendation:** Specify that TodoWrite is for broad codebase reviews only. Focused questions should skip it.

### 6. No guidance on severity or prioritisation of findings

The spec says recommendations should be concrete with reasoning, but doesn't mention how the agent should communicate severity. A circular dependency is more urgent than a slightly inconsistent naming pattern. Without severity guidance, reports may present all findings as equally important.

**Recommendation:** Add guidance to the system prompt: distinguish between findings that will cause real problems (high), things that impede maintainability (medium), and things that could be better but aren't hurting (low). Don't over-formalise it — just make sure the agent differentiates.

## Minor Notes

- **Color choice** (line 83): Terracotta is fine. No conflict with existing agents as far as I can tell, though the spec doesn't list the existing palette for comparison.
- **Open question on handoff to docs agent** (line 93): "Just suggest" is the right v1 answer. Formal handoff mechanisms add complexity for unclear benefit at this stage.
- **Open question on architecture document format** (line 91): Freeform for now is correct. If a format emerges naturally from usage, codify it then.

## Summary

The spec is solid and ready to build. The main thing to resolve before implementation is the report output question (Gap #1) — it's a contradiction that needs a clear answer in the system prompt. The other gaps are refinements that can be addressed in the system prompt without changing the spec's design.
