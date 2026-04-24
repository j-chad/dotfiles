# Architect Agent

## Problem

After producing a spec (via the spec agent) or when working with an existing codebase, there's no agent that focuses specifically on software design quality — identifying the right patterns, spotting structural problems, and recommending how code should be organised. The Guide explains what exists, Dwight finds security issues, Kevin builds — but nobody asks "is this the right structure?"

## Goals

- Provide actionable architecture and design recommendations for both specs and existing codebases.
- Be pragmatic: recommend patterns when they solve real problems, not for academic correctness.
- Fit naturally into the workflow as a refinement step between planning (spec) and building (kevin).

## Non-Goals

- Does not modify code or files. Read-only planner.
- Does not generate architecture diagrams (delegates to docs agent).
- Does not write tests, fix bugs, or build features.
- Does not include a design patterns skill in v1. May add later based on real usage.

## Overview

The architect agent reviews codebases and specs to provide design and architecture recommendations. It explores code to understand existing patterns, identifies code smells and structural problems, and suggests concrete improvements. When reviewing a spec, it considers both the spec itself and the existing codebase to ensure recommendations are grounded in reality. Output is conversational by default, with structured reports when asked.

## Detailed Design

### Mode 1: Codebase Review

**Trigger:** User invokes the architect agent and asks it to review a codebase, module, or specific area of code.

**Behaviour:**
1. Explores the codebase using the Task tool (subagents for broad exploration, preserving context).
2. Identifies the current architecture, patterns in use, and overall structure.
3. Produces a report covering:
   - **What's there:** Current patterns and architecture observed.
   - **What's working:** Good structural decisions worth preserving.
   - **What smells:** Code smells, structural problems, over-engineering, under-engineering.
   - **Recommendations:** Concrete suggestions with reasoning. For each recommendation, explain the problem it solves and when/why the suggested pattern is appropriate.
4. Report depth scales with the user's request — a focused question gets a focused answer, a broad "review this codebase" gets a comprehensive report.

**Code smells to look for (non-exhaustive):**
- God classes / god modules (too many responsibilities)
- Feature envy (code that uses another module's data more than its own)
- Tight coupling between modules that should be independent
- Leaky abstractions
- Premature abstraction (interfaces with one implementation, patterns applied speculatively)
- Missing abstraction (duplicated logic that should be extracted)
- Circular dependencies
- Deep nesting / complex control flow
- Inconsistent patterns across the codebase
- Wrong level of abstraction (business logic in controllers, infrastructure in domain)

### Mode 2: Spec Review

**Trigger:** User invokes the architect agent and points it at a spec (typically in `.opencode/plans/`).

**Behaviour:**
1. Reads the spec.
2. Explores the existing codebase to understand current patterns, conventions, and architecture.
3. Has a conversation with the user about design considerations:
   - Which patterns would serve the spec's requirements well, and why.
   - Where the spec's approach aligns with or diverges from existing codebase patterns.
   - Whether divergence is justified (existing patterns may not be optimal).
   - Potential structural problems that will emerge as the feature grows.
   - Suggestions for module/package/file organisation.
4. For large or complex specs, may produce a separate architecture document if the user requests it.

### Design Pattern Recommendations

The agent should be familiar with common patterns across these categories, but recommend them pragmatically — only when they solve a real problem in the code at hand:

- **Structural:** Adapter, Facade, Decorator, Composite, etc.
- **Behavioural:** Strategy, Observer, Command, State, etc.
- **Creational:** Factory, Builder, Singleton (with appropriate caveats), etc.
- **Architectural:** Clean Architecture, Hexagonal/Ports & Adapters, MVC, Event-driven, CQRS, etc.
- **Principles:** SOLID, DRY, YAGNI, Composition over inheritance, Separation of concerns, etc.
- **DDD concepts:** Aggregates, bounded contexts, value objects, domain services — when the project warrants it.

Key: never recommend a pattern without explaining what problem it solves in this specific context. "You should use the Strategy pattern here because you have three payment methods and will likely add more — Strategy lets you add new methods without modifying the existing ones."

## Technical Approach

- OpenCode agent defined in `dot_config/opencode/agents/architect.md`
- YAML frontmatter: `name: architect`, `primary: true`, `color: "#E07A5F"` (terracotta — warm, distinct from existing palette)
- Markdown body containing the full system prompt
- Uses Task tool for codebase exploration (same pattern as Guide and Dwight)
- Read-only: uses Read, Glob, Grep, Task tools. Does not use Write, Edit, or Bash for code changes.
- Uses TodoWrite to track areas explored during a review.
- No skills loaded in v1.

## Open Questions

- Should the architecture document (for large specs) have a defined format, or freeform? Defer until real usage reveals what's useful.
- Should the agent have a way to formally hand off to the docs agent for diagram generation, or just suggest the user do it? Start with suggesting.
- A design patterns skill may be valuable later. Build the agent first, observe what reference material would actually help.

## Milestones

- **v0.1** — Agent definition with system prompt. Both modes (codebase review, spec review) working conversationally.
- **v0.2** — (Future) Design patterns skill as a loadable reference, based on real usage patterns.
