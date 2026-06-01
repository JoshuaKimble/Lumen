Stage, commit, and push repository changes using the Lumen workflow.

Execution steps:

1. Run `git status --short` and summarize what is staged vs unstaged.
2. If there are no changes, stop and report that there is nothing to commit.
3. Stage all tracked and untracked changes with `git add -A`.
4. Run `git status --short` again and show the staged file list.
5. Ask for a Conventional Commit message if one was not provided by the user in the current conversation.
6. Run `git commit -m "<message>"`.
7. Detect current branch with `git branch --show-current`.
8. Push with `git push origin <branch>`.
9. Report commit hash, commit message, branch, and push result.

Rules:

- Do not use `git commit --amend`.
- Do not use destructive git commands.
- If commit fails because of hooks, surface the hook output and stop.
- If push fails, surface the error and stop.
