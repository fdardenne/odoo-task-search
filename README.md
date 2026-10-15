# Odoo Task Search

A Claude Code skill that searches a project's Odoo tasks by meaning instead
of exact keywords. Just ask Claude something like "find the odoo task about
the invoice rounding bug" and get back the tasks that actually match,
ranked by relevance, linked straight to each one.

## How it works

Every open task in the configured project is fetched in a single call to
odoo.com's `project.task` API (closed/canceled tasks are excluded by
default, since a long-running project can have thousands of them). That
list of task id, title, and description is then handed to Claude, which
picks out the tasks that genuinely match the query by meaning (title and
description), not literal keyword overlap, and returns them ranked by
relevance. Nothing is ever invented: Claude can only point back at tasks
that were actually in the fetched list.

A shell script (`fetch_tasks.sh`) does the authenticated fetch, reading your
Odoo token from your own shell environment. Claude only ever runs the
script and reads its plain output, so the token never appears in a prompt,
a tool call, or anywhere in the conversation. It's used by `curl`, inside
the script, and nowhere else, and is only ever sent to odoo.com itself.

## One-time setup

1. Get an Odoo API token: odoo.com, your profile, My Account, Account
   Security, generate an API key.
2. Add these two lines to your shell profile (`~/.zshrc` on macOS,
   `~/.bashrc` on most Linux), filling in your own values:

   ```bash
   export ODOO_API_TOKEN="paste-your-token-here"
   export ODOO_PROJECT_ID="1234"   # the number in your project's URL
   ```

   Open a new terminal (or run `source ~/.zshrc`) afterwards.
3. Clone this repo into `~/.claude/skills/odoo-task-search/`, so it's
   `~/.claude/skills/odoo-task-search/skill.md` and
   `~/.claude/skills/odoo-task-search/fetch_tasks.sh`. This makes it
   available in every Claude Code session, not just one project.

## Use it

In any Claude Code session, just ask in plain language:

> search odoo tasks for the invoice rounding bug

Say "include closed tasks" to widen the search to done/canceled tasks too.

## Requirements

- The [Claude Code](https://claude.com/claude-code) CLI, installed and
  logged in.
- `curl`.
