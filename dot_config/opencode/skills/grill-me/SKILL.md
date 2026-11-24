---
name: grill-me
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

## Overview

This skill defines an interview process that explores a plan, decision, or idea. Each decision forms a branch in a design tree. Each branch leads to the decisions that depend on it.

A round contains the current frontier. The frontier is the set of decisions whose prerequisites are settled. A question that depends on an open question in the current round belongs to a later round.

## Interview steps

1. Identify the current frontier of the design tree.
2. If a frontier question requires a fact from the environment, start a sub-agent with a new context window to find it.
3. Do not ask the user for facts that you can find yourself.
4. Do not wait for an active sub-agent before you ask the other frontier questions.
5. Treat the active sub-agent search as an unsettled prerequisite.
6. Hold the questions that depend on that search for a later round.
7. Ask the full current frontier in one round.
8. Wait for the answers from the user.
9. Update the design tree from the answers.
10. Find the next frontier.
11. Repeat steps 1 through 10 until the frontier is empty.
12. In chat, ask the user to confirm the shared understanding.
13. Do not use the `question` tool for this final confirmation.
14. Do not act on the plan until the user confirms this shared understanding.

## Round format

Choose one format for each round:

- If at least one frontier question has useful predefined options, use the `question` tool.
- If all frontier questions are open-ended and have no useful predefined options, use the Markdown format in chat.

Do not repeat a `question` tool round in chat.

### Question tool rounds

1. Send one `question` tool call that contains the full frontier in the `questions` array.
2. Keep related open-ended frontier questions in the same `question` tool call. The user can select "Type your own answer".
3. Set `header` to a short title of 30 characters or fewer.
4. Do not put `Q1` or `Q2` numbers in `header`.
5. Put the full question and required context in `question`.
6. Put the recommended choice first in `options`.
7. Add `(Recommended)` to the end of the recommended `label`.
8. Keep each option `label` to 1 to 5 words.
9. Put trade-offs and explanations in `description`.
10. If the user can select more than one valid option at the same time, set `multiple: true`.
11. Otherwise, set `multiple: false`.

Example `question` tool payload:

```json
{
	"questions": [
		{
			"header": "Storage backend",
			"question": "Which storage backend must this service use?",
			"multiple": false,
			"options": [
				{
					"label": "SQLite (Recommended)",
					"description": "Uses one local file and requires no separate server."
				},
				{
					"label": "PostgreSQL",
					"description": "Supports multiple writers and requires a database server."
				}
			]
		},
		{
			"header": "Retention policy",
			"question": "How long must the service keep audit records?",
			"multiple": false,
			"options": [
				{
					"label": "90 days (Recommended)",
					"description": "Matches the standard retention period for internal logs."
				},
				{
					"label": "1 year",
					"description": "Keeps records for annual review and uses more disk space."
				}
			]
		}
	]
}
```

### Markdown fallback rounds

1. Number the frontier questions as `Q1`, `Q2`, and so on.
2. Write each question so that the answer "yes" accepts your recommended answer.
3. Put your recommended answer after the question

Format a Markdown round like this:

```markdown
❓ **Q1** - **<question title>**: <question body>

➡️ <recommended answer>

---

❓ **Q2** - **<question title>**: <question body>

➡️ <recommended answer>
```
