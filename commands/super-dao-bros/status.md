# Super DAO Bros — Status

Show current state with both agents' perspectives.

## Instructions

### Step 1: Read all state files

Read these files from `~/Projects/super-dao-memories/`:
- `config.json`
- `state.json`
- `contacts-index.json`
- `tasks/inbox.md`
- `tasks/queue.json`
- `agents/nam-dao-config.json`
- `agents/anh-dao-config.json`

### Step 2: Display status dashboard

```
═══ Super DAO Bros — Status ═══

Nam 🔥  |  Anh 🧊

── System ──
Initialized: {yes/no}
Last run: {timestamp or "never"}

── Today's Stats ──
         Nam    Anh    Total
Tasks:   {n}    {n}    {N}
Msgs:    {n}    —      {N}
Videos:  —      {n}    {N}
Herobrine: —    {n}    {N}

── Task Queue ──
Inbox items: {N unchecked}
Current batch: {in-progress/empty}
{list first 5 unchecked inbox items with suggested routing}
  → "message john about lunch" (Nam 📤)
  → "schedule dentist tuesday" (Anh 📅)
  → "watch youtube.com/..." (Anh 🎥)

── Contacts ──
Total: {N}
Inner circle: {N} — {list names}
Regular:      {N}
Acquaintance: {N}
Low priority: {N}

── Pending Herobrine ──
{list any pending herobrine tasks or "all clear"}

═══════════════════════════════
```

### Step 3: Agent commentary

Add a quick line from each agent:

```
Nam: "{comment on what's pending — excited about something, or noting who needs a reply}"
Anh: "{operational suggestion — what to run next, or noting the inbox is clean}"
```

### Step 4: Suggest next action

Based on the state:
- If not initialized: "Run `/super-dao-bros:init` to get started"
- If inbox has items: "Run `/super-dao-bros:run` to process {N} pending tasks"
- If end of day: "Run `/super-dao-bros:eod` to generate today's digest"
- If no pending tasks: "Add tasks to `~/Projects/super-dao-memories/tasks/inbox.md`"
