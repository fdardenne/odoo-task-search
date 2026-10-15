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

A shell script (`fetch_tasks.sh`) does the authenticated fetch. It reads
your Odoo token from the OS keychain (macOS Keychain, or libsecret on
Linux) at the moment it runs, hands it to `curl` through stdin, and drops
it. The token is never stored in plaintext, never exported as an
environment variable (so neither Claude Code nor any other program you run
inherits it), and never appears on a command line visible in `ps`. Claude
only ever runs the script and reads its plain output, and the token is only
ever sent to odoo.com itself.

## One-time setup

1. Get an Odoo API token: odoo.com, your profile, My Account, Account
   Security, generate an API key.
2. Store the token in your OS keychain. Each command prompts for the
   token, so it never lands in your shell history or a dotfile:

   - **macOS**: `security add-generic-password -a "$USER" -s odoo-api-token -w`
     (paste the token when asked for the password, twice).
   - **Linux** (GNOME Keyring / KWallet via libsecret):
     `secret-tool store --label="Odoo API token" service odoo-api-token`

3. Add your project ID to your shell profile (`~/.zshrc` on macOS,
   `~/.bashrc` on most Linux). It's not a secret:

   ```bash
   export ODOO_PROJECT_ID="1234"   # the number in your project's URL
   ```

   Open a new terminal (or run `source ~/.zshrc`) afterwards.
4. Clone this repo into `~/.claude/skills/odoo-task-search/`, so it's
   `~/.claude/skills/odoo-task-search/skill.md` and
   `~/.claude/skills/odoo-task-search/fetch_tasks.sh`. This makes it
   available in every Claude Code session, not just one project.

## Use it

In any Claude Code session, just ask in plain language:

> search odoo tasks for the invoice rounding bug

Say "include closed tasks" to widen the search to done/canceled tasks too.

## Rotating or removing the token

- **macOS**: `security delete-generic-password -s odoo-api-token`
- **Linux**: `secret-tool clear service odoo-api-token`

Then repeat step 2 with the new token.

## Requirements

- The [Claude Code](https://claude.com/claude-code) CLI, installed and
  logged in.
- `curl` 7.55 or newer.
- macOS, or Linux with `secret-tool` (libsecret).
