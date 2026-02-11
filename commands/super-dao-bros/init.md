# Super DAO Bros — Init

First-run initialization: scan all Beeper contacts and build memory profiles.

## Instructions

You are running the Super DAO Bros initialization sequence. Follow these steps precisely:

### Step 1: Preflight — verify MCP servers and repo

**Check repo exists:**
If `~/Projects/super-dao-memories/` doesn't exist, create the full scaffold:
- `mkdir -p ~/Projects/super-dao-memories/{contacts,tasks,logs,digests,agents}`
- Create `config.json`, `state.json`, `contacts-index.json`, `tasks/inbox.md`, `tasks/queue.json` with default templates
- `git init` and commit

**Verify required MCP servers are accessible by calling each one:**

1. **Beeper (required):** Use `mcp__beeper__get_accounts` — if this fails, Beeper MCP is not configured. Tell the user: "Beeper MCP is not available. Make sure Beeper Desktop is running and the Beeper plugin is enabled in Claude settings (Settings → Extensions)." Stop init.

2. **Apple MCP (required):** Use `mcp__apple-mcp__calendar` to try reading today's calendar — if this fails, tell the user: "Apple MCP is not available. Enable it in Claude settings (Settings → Extensions → Apple integration)." Note this as degraded but continue — the system can work without it (just no calendar/reminder integration).

3. **YouTube (optional):** Use `mcp__youtube__get_transcript` with a test — if unavailable, note it: "YouTube MCP not available — video summaries will be disabled." Continue.

Report MCP status:
```
MCP Status:
  Beeper:   ✓ connected
  Apple:    ✓ connected
  YouTube:  ✓ connected
```
or with failures:
```
MCP Status:
  Beeper:   ✓ connected
  Apple:    ✗ not available — calendar/reminders disabled
  YouTube:  ✗ not available — video summaries disabled
```

Save MCP availability to `config.json` under `mcp_status`:
```json
{
  "mcp_status": {
    "beeper": true,
    "apple": true,
    "youtube": false
  }
}
```

### Step 2: Load or create config

Read `~/Projects/super-dao-memories/config.json` and `~/Projects/super-dao-memories/state.json`.

If `state.json` shows `init_complete: true`, tell the user init already ran and ask if they want to re-scan. If they say no, stop.

If `init_progress.phase` is not null, resume from where we left off (use `last_chat_id` to skip already-scanned chats).

### Step 3: Discover self-chat ID

Use the `mcp__beeper__get_accounts` tool to find the user's account info. Look for the self-chat or note-to-self chat ID. Save it to `config.json` under `self_chat_id`.

### Step 3: Scan all chats

Use `mcp__beeper__search_chats` with parameters:
- `limit`: 200

Paginate if needed using the returned cursor. Collect all chat objects — both DMs and group chats. Group chats get profiles too (with `type: "group"` in frontmatter).

Update `state.json`:
```json
{
  "init_progress": {
    "phase": "scanning",
    "chats_total": <total found>,
    "chats_scanned": 0
  }
}
```

### Step 5: Build contact profiles

For each chat, process it:

1. **Paginate to fetch up to 200 messages:** The `mcp__beeper__list_messages` tool returns ~20 messages per page. You MUST paginate to get sufficient history:
   - Call `mcp__beeper__list_messages` with `chatID`
   - If `hasMore` is true, use the oldest message's `id` as the `cursor` with `direction: "before"` to fetch the next page
   - Repeat until you have ~200 messages OR `hasMore` is false
   - **This is critical for voice calibration** — a single page often misses the user's own messages, making tone matching impossible
   - Collect ALL messages into a single array before analysis
2. **Sparse chat check:** If fewer than 10 total messages are found after pagination, create a minimal profile with `data_quality: "insufficient"` in the frontmatter. Set tone profile to "insufficient data — will use default friendly casual" and skip sample exchanges. The contact still gets indexed and tiered
3. Analyze the full message history to determine:
   - **Network**: Extract from chat metadata (whatsapp, imessage, instagram, etc.)
   - **Message count**: Total messages in the window, and how many are from the user (`isSender: true`)
   - **Frequency**: Calculate messages per week based on date range of the full message window
   - **Topics**: Extract 3-5 recurring topics from message content
   - **Tone profile**: Characterize both sides' communication style (formal/casual, emoji usage, message length, slang patterns)
   - **Sample exchanges**: Pick 2-3 representative back-and-forth pairs
   - **Relationship context**: Any birthday mentions, shared activities, current threads
3. **Tier assignment** based on message frequency:
   - `inner-circle`: ≥5 messages/week from them
   - `regular`: ≥1 message/week
   - `acquaintance`: ≥1 message/month
   - `low-priority`: below that
4. Generate a slug from the contact name (lowercase, hyphenated)
5. Write the profile to `~/Projects/super-dao-memories/contacts/{slug}.md` in this format:

```markdown
---
name: "{display name}"
slug: "{slug}"
chat_id: "{chat_id}"
network: "{network}"
tier: "{tier}"
type: "{single or group}"
last_scanned: "{ISO timestamp}"
message_count: {count}
my_message_count: {my_count}
data_quality: "{sufficient or insufficient}"
topics: [{topics}]
---

## Tone Profile
**Their style:** {description}
**My style with them:** {description}

## Sample Exchanges
{2-3 representative exchanges}

## Relationship Context
{any notable context extracted from messages}
```

6. After each chat, update `state.json` with incremented `chats_scanned` and `last_chat_id`

**Important:** Process chats serially to avoid rate limits. If there are 200+ chats, after every 50 chats, commit progress to git and report status to the user.

### Step 6: Whitelist approval (experimental mode)

After all profiles are built, present the full contact list to the user grouped by tier for whitelist approval. Only whitelisted contacts will be eligible for autonomous messaging, proactive task generation, and auto-replies.

Display the list like this:
```
═══ Contact Whitelist Approval ═══

We're in experimental mode — only whitelisted contacts
will receive autonomous messages from Nam/Anh.

── Inner Circle ({N}) ──
  1. John Smith (whatsapp, 847 msgs)
  2. Sarah Lee (imessage, 623 msgs)
  ...

── Regular ({N}) ──
  3. Alex Chen (whatsapp, 210 msgs)
  ...

── Acquaintance ({N}) ──
  7. Mike Jones (instagram, 45 msgs)
  ...

── Low Priority ({N}) ──
  12. Random Guy (sms, 8 msgs)
  ...

═══════════════════════════════════
```

Then ask the user: **"Which contacts should I enable? Give me numbers, names, tiers (e.g., 'all inner-circle'), or 'all'."**

Based on their response, set `whitelisted: true` or `whitelisted: false` in each contact's YAML frontmatter.

Save the whitelist to `~/Projects/super-dao-memories/config.json` under a `whitelist` key:
```json
{
  "whitelist": {
    "enabled": true,
    "slugs": ["john-smith", "sarah-lee", "alex-chen"]
  }
}
```

Profiles are still created for ALL contacts (so the system has memory), but only whitelisted contacts are actionable.

### Step 7: Build user style profile

After all contact profiles are built, aggregate your outgoing messages across ALL chats to build `~/Projects/super-dao-memories/my-style.md` — your master texting fingerprint.

1. **Collect all your outgoing messages** from the profiles already scanned (you already have the data from Step 5 — no need to re-fetch)
2. **Analyze your baseline style** across all conversations:
   - Average message length
   - Punctuation habits (periods? no periods? ellipsis?)
   - Capitalization patterns (all lowercase? proper? mixed?)
   - Emoji frequency and favorites
   - Common slang, filler words, catchphrases
   - Greeting/sign-off patterns
   - Response patterns (one-liners? paragraphs? voice notes?)
3. **Break down variations by tier:**
   - How you text inner-circle vs regular vs acquaintance vs low-priority
   - What changes: formality, length, emoji usage, slang density
4. **Break down notable per-contact variations:**
   - Contacts where your style significantly deviates from the tier norm
   - Example: "With mom — full sentences, no slang, more emojis. With john — extremely casual, abbreviations, zero punctuation"
5. **Write the profile** to `~/Projects/super-dao-memories/my-style.md`:

```markdown
---
last_updated: "{ISO timestamp}"
total_messages_analyzed: {count}
contacts_analyzed: {count}
---

## Baseline Style
**Message length:** {avg words per message}
**Capitalization:** {pattern}
**Punctuation:** {pattern}
**Emoji usage:** {frequency + favorites}
**Common phrases:** {list}
**Greeting style:** {pattern}
**Response style:** {pattern}

## Tier Variations

### Inner Circle
{how style shifts — more casual? shorter? more slang? specific patterns}

### Regular
{shift description}

### Acquaintance
{shift description}

### Low Priority
{shift description}

## Notable Contact Variations
- **{name}**: {what's different and why — e.g., "all caps energy, lots of exclamation marks, inside jokes about X"}
- **{name}**: {variation}
- ...

## Anti-Patterns (Things I Never Do)
{list of things the user NEVER does in texts — helps prevent AI-sounding messages}
```

This file is the ultimate reference for tone-matching. Contact-specific profiles override it, but when a contact has `data_quality: "insufficient"` or no profile, `my-style.md` is the fallback instead of generic "friendly casual."

### Step 8: Build contacts index

After whitelist is set, read all `contacts/*.md` files and build `contacts-index.json`:

```json
{
  "by_slug": { "john-smith": "!chatid:beeper.com", ... },
  "by_chat_id": { "!chatid:beeper.com": "john-smith", ... },
  "tiers": {
    "inner-circle": ["slug1", "slug2"],
    "regular": ["slug3"],
    "acquaintance": ["slug4"],
    "low-priority": ["slug5"]
  },
  "whitelisted": ["slug1", "slug2", "slug3"],
  "last_updated": "ISO timestamp"
}
```

### Step 9: Finalize

Update `state.json`:
```json
{
  "init_complete": true,
  "init_progress": { "phase": "complete", ... }
}
```

Git add all changes and commit: `"init: scan {N} contacts, whitelist {M}, build memory profiles"`

### Step 10: Schedule autonomous execution

Use the `/herobrine` skill to create three scheduled agents:

1. **dao-morning** — runs daily at 8:00 AM
   - Prompt: `Run /super-dao-bros:run`
   - This is the first run of the day — proactive task generation + batch execution

2. **dao-afternoon** — runs daily at 1:00 PM
   - Prompt: `Run /super-dao-bros:run`
   - Midday sweep — picks up new inbox items, calendar changes, unanswered messages

3. **dao-eod** — runs daily at 9:00 PM
   - Prompt: `Run /super-dao-bros:eod`
   - End-of-day digest generation + delivery + stats reset

After creating all three, report the schedule to the user:
```
Scheduled:
  dao-morning  → 8:00 AM daily  → /super-dao-bros:run
  dao-afternoon → 1:00 PM daily → /super-dao-bros:run
  dao-eod      → 9:00 PM daily  → /super-dao-bros:eod
```

Ask the user if they want to adjust any of the times.

### Step 11: Report

Report summary to user:
- Total contacts scanned
- Breakdown by tier
- How many whitelisted (and who)
- Any chats that were skipped (empty, etc.)
- Scheduled herobrine agents and their times
- Remind them they can edit the whitelist anytime in `config.json` or re-run `/super-dao-bros:init`
- Remind them they can also manually invoke `/super-dao-bros:run` anytime
