# Super DAO Bros

A personal life management AI skill suite for Claude Code. Two AI agents — **Nam Dao (CEO)** and **Anh Dao (COO)** — autonomously manage your communications, schedule, and tasks.

Nam handles relationships and messaging strategy. Anh handles operations, scheduling, and research. Both work in parallel, pulling tasks from your calendar, reminders, and a local inbox.

## What It Does

- Scans all your Beeper contacts and builds tone/style memory profiles
- Proactively generates tasks (unanswered messages, check-ins, calendar prep, overdue reminders)
- Sends messages that match your actual communication style with each person
- Schedules events and reminders via Apple Calendar/Reminders
- Summarizes YouTube videos
- Spawns background agents for complex research tasks
- Delivers end-of-day digests with full activity summary
- Responds to incoming messages in real-time via nchook + macOS Notification Center
- Runs autonomously on a schedule via herobrine

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) CLI
- [Beeper Desktop](https://beeper.com) running with the Beeper MCP plugin enabled
- Apple MCP plugin enabled (Settings > Extensions)
- YouTube MCP plugin enabled (Settings > Extensions)
- [Herobrine skill](https://github.com/...) installed (for scheduled execution)
- [nchook](https://github.com/Who23/nchook) installed for real-time message watching (`brew install who23/formulae/nchook`)

## Install

```bash
git clone https://github.com/yourusername/super-dao-bros.git
cd super-dao-bros
chmod +x install.sh
./install.sh
```

This installs:
- Slash commands to `~/.claude/commands/super-dao-bros/`
- Agent definitions to `~/.claude/agents/`
- Memories repo scaffold to `~/Projects/super-dao-memories/`

## Quick Start

```
/super-dao-bros:init
```

Init will:
1. Verify MCP servers are connected
2. Scan all your Beeper chats (DMs + groups)
3. Build tone profiles for each contact
4. Ask you to whitelist contacts for autonomous messaging
5. Schedule three herobrine agents (morning run, afternoon run, EOD digest)

Then just add tasks to `~/Projects/super-dao-memories/tasks/inbox.md` and let Nam and Anh handle the rest.

## Commands

| Command | Description |
|---------|-------------|
| `/super-dao-bros:init` | First-run setup — scan contacts, build profiles, schedule agents |
| `/super-dao-bros:run` | Pull tasks, route to Nam/Anh, execute batch of 3-5 |
| `/super-dao-bros:send-message <contact> <intent>` | Send a tone-matched message |
| `/super-dao-bros:watch-video <url>` | Summarize a YouTube video |
| `/super-dao-bros:eod` | Generate end-of-day digest |
| `/super-dao-bros:status` | Dashboard — tasks, stats, contacts |
| `/super-dao-bros:help` | Command reference |

## Task Routing

| Task type | Agent | Route |
|-----------|-------|-------|
| Message someone | Nam (CEO) | Beeper |
| Reply to someone | Nam (CEO) | Beeper |
| Schedule an event | Anh (COO) | Apple Calendar |
| Set a reminder | Anh (COO) | Apple Reminders |
| Summarize a video | Anh (COO) | YouTube |
| Complex research | Anh (COO) | Herobrine |
| Strategic decisions | Nam (CEO) | Inline |

## How Messaging Works

1. Nam decides the strategy — what to say, what angle, what context to reference
2. The contact's memory profile dictates the voice — matching your actual slang, emoji patterns, message length, greeting style
3. Messages are indistinguishable from ones you'd send yourself
4. After sending, the contact's profile auto-refreshes with the latest conversation patterns

## File Structure

```
~/.claude/commands/super-dao-bros/   # Slash commands
~/.claude/agents/nam-dao.md          # CEO agent personality
~/.claude/agents/anh-dao.md          # COO agent personality
~/Projects/super-dao-memories/       # Runtime data (git tracked)
  config.json                        # Settings + whitelist
  state.json                         # Runtime state + locks
  contacts-index.json                # Contact lookup tables
  my-style.md                        # Your master texting style + tier variations
  contacts/{slug}.md                 # Per-contact memory profiles
  agents/                            # Agent runtime configs
  tasks/inbox.md                     # Task inbox
  tasks/queue.json                   # Current batch
  logs/YYYY-MM-DD-messages.json      # Daily message audit (7-day retention)
  digests/YYYY-MM-DD.md              # Daily digests (permanent)
```

## Configuration

Edit `~/Projects/super-dao-memories/config.json`:

- `whitelist.slugs` — contacts that can receive autonomous messages
- `whitelist.enabled` — set to `false` to disable whitelist (full auto)
- `batch_size` — tasks per run (default: 5)
- `scan_depth` — messages to analyze per contact (default: 200)
- `tier_thresholds` — message frequency thresholds for contact tiers

## License

MIT
