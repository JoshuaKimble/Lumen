# Lumen Engineering Principles

Lumen uses clean code principles as its default engineering posture. Clean code
is code another engineer can read, understand, change, extend, and maintain
without needing the original author nearby.

## General Principles

- Follow standard Flutter and Dart conventions.
- Follow Conventional Commits v1.0.0 for commit messages.
- Prefer simple solutions. Reduce complexity before adding abstraction.
- Leave touched code cleaner than it was.
- Find the root cause before fixing a bug.
- Be consistent. Similar problems should be solved in similar ways.

## Git History

- Commit messages use `<type>[optional scope]: <description>`.
- Use `feat` for features and `fix` for bug fixes.
- Use supporting types such as `docs`, `test`, `refactor`, `style`, `build`,
  `ci`, `chore`, `perf`, and `revert` when they fit the change.
- Use `!` or a `BREAKING CHANGE:` footer for breaking API or behavior changes.
- Keep each commit focused on one coherent change.
- Prefer multiple commits over one mixed commit when the changes are unrelated.

## Design

- Keep configurable data near app or feature composition boundaries.
- Prevent over-configurability. Add options only when there is a real product or
  platform need.
- Use dependency injection through Riverpod providers and constructors.
- Follow the Law of Demeter: code should talk to its direct dependencies, not
  reach through chains of objects.
- Prefer polymorphism or separate collaborators over large `if`, `switch`, or
  flag-driven behavior when the variation is durable.
- Isolate asynchronous, platform, persistence, and future sync concerns behind
  repository or service boundaries.

## Understandability

- Use explanatory variables for complex expressions.
- Encapsulate boundary conditions in one place.
- Prefer dedicated value objects when primitives would make domain meaning
  ambiguous.
- Avoid logical dependencies where one method only works after another method
  has been called.
- Prefer positive conditionals.

## Names

- Choose descriptive and unambiguous names.
- Make meaningful distinctions; avoid names that differ only by noise words.
- Use pronounceable and searchable names.
- Replace domain magic numbers or strings with named constants.
- Avoid prefixes, type encodings, and Hungarian-style notation.

## Functions

- Keep functions small.
- Make each function do one thing.
- Use descriptive function names.
- Prefer fewer arguments.
- Avoid hidden side effects.
- Do not use flag arguments. Split behavior into separate functions, providers,
  widgets, or collaborators.

## Comments

- Prefer explaining intent through names and structure.
- Do not add redundant or obvious comments.
- Do not use closing-brace comments.
- Do not comment out code; remove it.
- Use comments for intent, clarification, warnings, or consequences that are not
  obvious from the code.

## Source Structure

- Separate concepts vertically.
- Keep related code vertically dense.
- Declare variables close to usage.
- Keep dependent and similar functions close.
- Order code so higher-level behavior appears before lower-level details when it
  improves scanning.
- Keep lines short enough to read comfortably.
- Do not use horizontal alignment.
- Use whitespace to group related ideas and separate weakly related ideas.
- Preserve indentation.

## Objects And Data

- Hide internal structure.
- Prefer plain data structures for data transfer and rich objects or services
  for behavior; avoid half-object, half-data hybrids.
- Keep classes and widgets small.
- Keep instance variables few.
- Base abstractions should not know about implementations.
- Prefer explicit functions or collaborators over passing code to select
  behavior unless Flutter or Dart conventions make callbacks the natural API.
- Prefer instance behavior and injected dependencies over static methods for
  logic that may need tests, state, or replacement.

## Tests

- Tests should be readable, fast, independent, and repeatable.
- Prefer one behavioral reason to fail per test. Multiple assertions are fine
  when they verify one coherent outcome.
- Name tests by behavior, not implementation.
- Use widget tests for user-visible flows and provider or repository tests for
  business/data behavior.

## Smells To Watch

- Rigidity: small changes cause cascading edits.
- Fragility: one change breaks unrelated behavior.
- Immobility: useful code cannot be reused without high risk.
- Needless complexity.
- Needless repetition.
- Opacity: code is hard to understand.
