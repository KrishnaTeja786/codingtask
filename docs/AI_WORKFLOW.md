# AI Workflow

How AI tools (Claude Code, GitHub Copilot, Cursor) were used responsibly to scaffold and iterate on Smart DevHub — and the guardrails that kept the codebase coherent.

## The thesis

> AI tools are for *velocity*, not *judgement*. The architecture, the test boundary, and the public API of every layer are decided by the engineer; the AI fills in the typing.

Used as a code generator, an LLM is roughly as fast as your most senior pair-programmer at boilerplate, and roughly as careless as your laziest junior on edge cases. The workflow below is structured to capture the first and contain the second.

## Prompt-driven scaffolding

Each new feature was scaffolded with a constraint-prompt of the form:

> "Generate the data layer for `X`. It must:
>  - return `Result<T>`, never throw
>  - be testable with a mocked datasource
>  - log a perf timing for every DB read
>  - follow the directory layout in `docs/ARCHITECTURE.md`
>  - not import `package:flutter`"

Constraints in the prompt → reviewable output. Without them, AI defaults to its training distribution: random Either packages, untyped exceptions, mixed Flutter+pure-Dart files, and `print` instead of metrics.

## The "PR review" rule

Every AI-generated file was treated as a pull request from a new contributor:

1. **Read the whole file** before saving. Skim-accepting is how subtle bugs land.
2. **Run `flutter analyze`** against the whole project, not just the file.
3. **Run the tests** — including the ones the AI just wrote.
4. **Type-check the boundaries**: does this file import what it should, and only what it should?
5. **Reject anything that breaks the layering rule**, even if it works. The architecture earns its keep over time, not in any single PR.

## Test generation

AI is excellent at writing the *enumeration* of test cases (loading, success, empty, network failure, timeout, cache fallback, pagination, favorite add/remove, …). It is *bad* at picking the *invariants*: what assertion proves the system is correct?

Workflow:

1. Engineer writes the **first** test by hand. This anchors the assertion style and the fakes/mocks setup.
2. AI is asked to generate **N more cases** following the same shape.
3. Engineer **mutates the production code** — flip a `>` to `<`, remove a guard — and runs the tests. Any test that still passes is suspect; engineer rewrites it.

This is the single biggest discipline that prevents "passing tests that test nothing." See `test/features/github_trends/presentation/github_trends_bloc_test.dart` for the result.

## Performance analysis

AI is asked to *propose* perf optimizations, not to *apply* them. Proposed optimizations land only after:

1. The Performance Lab shows a measurable problem (e.g. avg API > 600ms, frame skip during search).
2. The proposed fix is implemented in a small commit.
3. The Performance Lab shows the measurable improvement.

The "measure → hypothesize → measure again" loop is what separates premature optimization from real engineering. The Performance Lab tab exists in part to make this loop fast.

## Avoiding blind acceptance

Concrete habits that prevented blind merges:

- Every AI-suggested package was **looked up on pub.dev** for the last release date. Two suggestions (`isar` v3 abandonware, `flutter_workmanager` typo) were rejected at this gate.
- Every "this is the modern way" claim was **diffed against the official Flutter sample repo** (`flutter/samples`). The IndexedStack pattern survived; an "I just generated my own switchMap" pattern did not — it was replaced with `bloc_concurrency`.
- AI was never allowed to **silently rewrite** existing files. Every edit was a focused diff, reviewed.

## Keeping architecture consistent

The single most useful artifact for staying consistent across many small AI edits is **`docs/ARCHITECTURE.md` itself**. Every prompt for a new feature linked to it. When an edit drifted (e.g. trying to import Drift from the domain layer), the fix was: "re-read `docs/ARCHITECTURE.md` and rewrite this file."

This is the pattern that scales: **document the rules once, point the tool at them, reject anything that violates them.**

## What AI was *not* used for

- Choosing the state management library (BLoC vs. Riverpod) — that's an architectural decision tied to team familiarity, not a code task.
- Choosing the database (Drift vs. Isar vs. sqflite) — same.
- Writing the CI workflow secrets / signing keys — anything touching credentials stays human.
- Final security review of permissions in `AndroidManifest.xml` — every permission was added explicitly with a rationale comment.

## Talking points for an interview

- "I treat AI as an accelerated junior. It writes the typing; I write the test that proves the typing is correct."
- "My AI prompts include the architectural rules of the project. The output then has a fighting chance of being shaped right on the first try."
- "I always run `flutter analyze` and the test suite after AI edits, because the LLM doesn't know what it doesn't know about the rest of the codebase."
- "When AI proposes a performance optimization, I require it to point at a metric in the Performance Lab. No metric, no merge."
