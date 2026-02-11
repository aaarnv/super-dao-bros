# Super DAO Bros — Run

Main execution loop: pull tasks from all sources, batch 3-5, split between Nam (CEO) and Anh (COO), execute in parallel.

## Instructions

### Step 0: Preflight

1. Read `~/Projects/super-dao-memories/state.json` — if `init_complete` is false, tell the user to run `/super-dao-bros:init` first and stop
2. **Lock check:** If `state.json` has `"run_lock": true`, a previous run is still in progress. Queue this run by setting `"queued_run": true` in state.json and stop. The finishing run will pick it up
3. Set `"run_lock": true` in `state.json` to prevent overlapping runs
4. Read `~/Projects/super-dao-memories/config.json` for settings
5. Read `~/Projects/super-dao-memories/contacts-index.json` for contact lookup
6. Read `~/Projects/super-dao-memories/agents/nam-dao-config.json` and `anh-dao-config.json` for routing keywords
7. Check if `tasks/queue.json` has an in-progress batch — if so, resume it instead of pulling new tasks
8. **MCP health check:** Test `mcp__beeper__get_accounts` — if Beeper is unreachable, set `beeper_available: false` for this run (messaging tasks will be queued for next run instead of executed)

### Step 1: Proactive task generation (Nam + Anh think for you)

Before pulling existing tasks, the agents scan for things that SHOULD be tasks but aren't yet. Append anything they find to `~/Projects/super-dao-memories/tasks/inbox.md` as new `- [ ]` items, tagged with who generated it.

**Nam scans for relationship tasks (whitelisted contacts only):**
1. Read `~/Projects/super-dao-memories/contacts-index.json` and `config.json`. Only scan contacts that appear in the `whitelist.slugs` list
2. For each, load their `contacts/{slug}.md` profile:
   - **Gone quiet:** If `last_scanned` shows frequent messaging but no recent messages (use `mcp__beeper__list_messages` with limit=5 to check recency) → generate "check in with {name}" task
   - **Unanswered messages:** Check if the last message in a chat is FROM the contact (they're waiting for a reply) → generate "reply to {name} about {topic}". Read their latest messages to understand what they said — the reply task should reference the specific message content
   - **Birthdays this week:** If profile mentions a birthday coming up in the next 7 days → generate "wish {name} happy birthday"
   - **Stale threads:** If profile mentions an active thread (e.g., "planning climbing trip") but no recent activity → generate "follow up with {name} on {thread}"
3. Don't duplicate — check existing inbox items before adding

**Anh scans for operational tasks:**
1. **Calendar prep:** Use `mcp__apple-mcp__calendar` to get today + tomorrow's events. For any meeting/event that needs prep, context, or follow-up → generate task (e.g., "prep for 3pm meeting with X", "send follow-up from yesterday's call with Y")
2. **Overdue reminders:** Use `mcp__apple-mcp__reminders` — any overdue items get escalated to inbox
3. **Herobrine results:** Check `state.json` for completed herobrine agents whose results haven't been reviewed → generate "review herobrine results for {task}"
4. **Stale inbox:** If any inbox item has been sitting unchecked for 3+ days, flag it or suggest breaking it down
5. Don't duplicate — check existing inbox items before adding

Tag generated tasks in the inbox so the user can see who thought of it:
```markdown
- [ ] check in with john — haven't talked in 2 weeks (nam)
- [ ] prep for 3pm meeting with sarah — review last notes (anh)
- [ ] reply to mom about dinner plans (nam)
- [ ] review herobrine results: SF restaurant research (anh)
```

### Step 2: Pull tasks from all sources

Collect tasks from three sources in priority order:

**Source A — Apple Calendar (highest priority, time-sensitive):**
Use `mcp__apple-mcp__calendar` to get today's events. Extract any that have action items, need preparation, or require follow-up. Format each as a task with the event time for context.

**Source B — Apple Reminders (by due date):**
Use `mcp__apple-mcp__reminders` to get incomplete reminders. Sort by due date (overdue first). Format each as a task.

**Source C — Local inbox (in order):**
Read `~/Projects/super-dao-memories/tasks/inbox.md`. Extract all unchecked `- [ ]` items (including ones just generated in Step 1). Preserve their order.

### Step 3: Build the batch

From the combined task list (Calendar → Reminders → Inbox), take the top 3-5 tasks (use `batch_size` from config).

Write the batch to `~/Projects/super-dao-memories/tasks/queue.json`:
```json
{
  "batch_id": "YYYY-MM-DD-HHMMSS",
  "started_at": "ISO timestamp",
  "tasks": [
    {
      "id": 1,
      "source": "calendar|reminders|inbox",
      "raw_text": "original task text",
      "route": "beeper|youtube|apple|herobrine|inline",
      "owner": "nam-dao|anh-dao",
      "status": "pending",
      "result": null
    }
  ]
}
```

### Step 4: Route and assign each task

For each task, determine the execution route AND assign to the right agent:

**→ Nam Dao (CEO)** owns these routes:

**Route: `beeper`** — if task references a contact name, or contains keywords: "message", "text", "reply", "send", "tell", "ask", "ping", "follow up with", "check in", "reach out", "catch up"
- Resolve the contact from `contacts-index.json`
- **Whitelist check:** Read `config.json` — if `whitelist.enabled` is true and the contact's slug is NOT in `whitelist.slugs`, skip this task and log: "skipped — {name} not whitelisted". Move to next task
- Load their profile from `contacts/{slug}.md`
- Nam picks the strategic angle (timing, intent framing, what context to reference) but the actual message must match the user's voice from the memory profile — same slang, length, emoji patterns, greeting style
- **If replying:** Read the contact's latest messages via `mcp__beeper__list_messages` (limit=10) to understand what they said, then craft a contextual reply to their actual message
- **If Beeper unavailable this run:** Push task back to inbox for next run
- Send immediately via `mcp__beeper__send_message` — no confirmation needed
- **After sending:** Auto-refresh the contact's tone profile — pull their latest 50 messages and update `contacts/{slug}.md` with any new patterns

**Route: `inline` (strategic)** — big-picture questions, creative tasks, prioritization decisions
- Nam handles directly with his decisive, vision-oriented style

**→ Anh Dao (COO)** owns these routes:

**Route: `youtube`** — if task contains a YouTube URL or keywords: "watch", "summarize video", "youtube"
- Extract the video URL
- Use `mcp__youtube__get_transcript` to get the transcript
- Anh summarizes efficiently: key points, thesis, action items. No fluff
- Write summary to today's digest or display inline

**Route: `apple`** — if task contains keywords: "schedule", "remind", "calendar", "event", "reminder"
- Parse the task for date/time and description
- Use `mcp__apple-mcp__calendar` for events or `mcp__apple-mcp__reminders` for reminders
- Anh creates it directly, no confirmation needed

**Route: `herobrine`** — if task is complex, multi-step, requires research, or explicitly says "herobrine"
- Anh spawns and manages the herobrine agent
- Log the herobrine task ID in `state.json` under `pending_herobrine`
- Mark task as "delegated" rather than "complete"

**Route: `inline` (operational)** — logistics, organization, quick lookups
- Anh handles directly with her efficient, minimal style

### Step 5: Spawn the team and execute

Use `TeamCreate` to create a team called `"dao-bros-run"`.

Create tasks via `TaskCreate` for each item in the batch, including:
- The task description and route
- Any relevant contact profile data (for beeper tasks)
- The raw task text from the source

Spawn two teammates using the `Task` tool:
1. **Nam Dao** — `subagent_type: "general-purpose"`, `name: "nam-dao"`, with agent file `~/.claude/agents/nam-dao.md`. Include in the prompt: his assigned tasks from the batch, contact profiles he'll need, and instructions to check TaskList for his work
2. **Anh Dao** — `subagent_type: "general-purpose"`, `name: "anh-dao"`, with agent file `~/.claude/agents/anh-dao.md`. Include in the prompt: her assigned tasks from the batch, and instructions to check TaskList for her work

Both agents work their tasks in parallel. They can message each other via `SendMessage` if a task needs handoff (e.g., Nam sends a message and asks Anh to set a follow-up reminder).

### Step 6: Collect results and wrap up

As agents complete tasks and go idle:

1. Check TaskList for completed tasks
2. Collect results from both agents
3. Update `~/Projects/super-dao-memories/tasks/queue.json` with final statuses
4. If inbox tasks were completed, mark them as `- [x]` in `tasks/inbox.md`
5. Update `state.json`:
   - Set `last_run` to current ISO timestamp
   - Update `today_stats` with combined results from both agents
6. Update agent configs with their individual daily stats
7. Git add all changes and commit: `"run: Nam handled {N} tasks, Anh handled {N} tasks — {short summary}"`
8. Send shutdown requests to both agents
9. Clean up the team with `TeamDelete`

### Step 7: Report to user

Report with personality — channel a quick summary that reflects both agents:

```
Nam: "crushed it — sent {N} messages, handled {list}. anh's got the rest locked down"
Anh: "done. {N} scheduled, {N} summarized. {N} still in inbox."
```

Include:
- Tasks completed vs attempted (broken down by agent)
- Messages sent (contact + intent)
- Herobrine agents spawned
- Any failures and why
- Remaining tasks in inbox

### Error handling

- If a single task fails, the agent should log it and **auto-retry once**. If it fails again, mark as failed and continue
- If an agent goes idle with incomplete tasks, check if they're blocked and reassign if needed
- If Beeper MCP is unavailable, queue all messaging tasks back to inbox for next run — don't skip them permanently
- If all tasks in the batch fail, suggest troubleshooting steps
- **Always release the run lock:** Set `"run_lock": false` in `state.json` when done, even on failure. If `"queued_run": true`, immediately start a new run
- **Send macOS notification on completion:** `osascript -e 'display notification "Nam: {n} msgs, Anh: {n} ops — {summary}" with title "Super DAO Bros"'`
