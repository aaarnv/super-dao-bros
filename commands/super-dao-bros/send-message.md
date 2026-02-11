# Super DAO Bros — Send Message

Tone-matched autonomous messaging, delivered through Nam Dao's CEO personality.

**Arguments:** $ARGUMENTS (format: `<contact-name-or-slug> <intent/message description>`)

## Instructions

### Step 1: Parse arguments

Extract the contact identifier and the message intent from `$ARGUMENTS`.

Examples:
- `john hey, want to grab lunch tomorrow?` → contact: "john", intent: casual lunch invite
- `mom happy birthday!` → contact: "mom", intent: birthday wish
- `john-smith follow up on the climbing trip plans` → contact: "john-smith", intent: follow up

### Step 2: Resolve contact

1. Read `~/Projects/super-dao-memories/contacts-index.json`
2. Search `by_slug` for an exact or partial match on the contact identifier
3. If no match, search all `contacts/*.md` files for name matches (case-insensitive, partial OK)
4. If multiple matches, list them and ask the user to pick
5. If no match at all, tell the user the contact wasn't found and suggest running `/super-dao-bros:init`

### Step 3: Whitelist check

Read `~/Projects/super-dao-memories/config.json`. If `whitelist.enabled` is true and the resolved contact's slug is NOT in `whitelist.slugs`, warn the user: "{name} is not on the whitelist. Add them to `config.json` whitelist or re-run `/super-dao-bros:init` to update." Stop — do not send.

### Step 4: Load contact profile + user style

**Always load `~/Projects/super-dao-memories/my-style.md` first** — this is your baseline voice reference.

Then read `~/Projects/super-dao-memories/contacts/{slug}.md` and parse:
- Tone profile (their style + my style with them)
- Sample exchanges (for calibration)
- Topics (for natural references)
- Network (to know platform constraints — e.g., WhatsApp has message length limits)
- Tier (inner-circle gets more personal touch)
- `data_quality` — if `"insufficient"`, fall back to `my-style.md` tier variation for this contact's tier
- `my_message_count` — if this is 0 or very low (< 3), the profile likely doesn't have your voice in this chat

**Low voice data safety net:** If `my_message_count < 3` in the profile, paginate deeper into the chat history (3-5 pages using `cursor` + `direction: "before"`) to find your actual messages before composing. This prevents AI-sounding messages in chats where init didn't capture enough of your voice. Also read `my-style.md` for baseline patterns.

**Fallback chain:**
1. Contact-specific profile (best — exact voice for this person)
2. `my-style.md` tier variation (good — your style with people at this tier level)
3. `my-style.md` baseline (minimum — your general texting style)

**If no profile exists at all**, use `my-style.md` baseline. If `my-style.md` also doesn't exist, use default friendly casual. Never block a send.

### Step 5: Compose message (Nam strategizes, memory dictates voice)

Nam Dao is the brain behind this message — he decides the angle, timing, and intent. But the actual words must sound exactly like the user based on the contact's memory profile.

**Nam's strategic layer** (internal, not visible in the message):
1. Assess the intent — what's the real goal? (e.g., "grab lunch" might really mean "reconnect after going quiet")
2. Pick the angle — direct ask? casual mention? reference a shared topic? open-ended question?
3. Decide what context to pull from the profile — recent threads, shared interests, upcoming events
4. For inner-circle: go personal, reference specific things, be real
5. For regular: purposeful but warm, show you remember them
6. For acquaintance: polished, low-friction, don't assume familiarity

**The actual message** must be written by matching the memory profile exactly:
1. Read "My style with them" — this IS the voice. Match it precisely
2. Study sample exchanges — match the length, slang, punctuation, emoji patterns, greeting style
3. If samples show short casual texts ("yo", "bet", "lol"), write that way — not longer
4. If samples show full sentences with proper grammar, write that way — not more casual
5. Pull relevant topics and shared context that Nam identified as strategically useful
6. The message should be indistinguishable from a real message the user sent in that chat

### Step 6: Send immediately

Do NOT ask for confirmation. Just send it.

1. Use `mcp__beeper__send_message` with the contact's `chat_id` and the composed message
2. After sending, show what was sent:
```
📤 {name} ({network}): "{composed message}"
```
2. Log the send to `~/Projects/super-dao-memories/logs/YYYY-MM-DD-messages.json`:
   ```json
   {
     "timestamp": "ISO",
     "contact_slug": "slug",
     "contact_name": "name",
     "intent": "original intent",
     "composed_by": "nam-dao",
     "route": "beeper",
     "network": "whatsapp",
     "status": "sent"
   }
   ```
3. Update `state.json` → increment `today_stats.messages_sent`
4. Git commit: `"msg: nam sent to {name} — {short intent}"`

### Step 7: Auto-refresh contact profile

After sending, pull the contact's latest 50 messages via `mcp__beeper__list_messages` and update their `contacts/{slug}.md`:
- Refresh tone profile if new patterns are evident
- Update `last_scanned` timestamp
- Update message counts
- This keeps profiles fresh without needing to re-run init

### Step 8: Hand off to Anh

After sending, if the message implies a follow-up action (scheduling a meetup, waiting for a reply, etc.), Anh automatically sets a follow-up reminder via `mcp__apple-mcp__reminders` — no need to ask.

### Error handling

- If Beeper send fails, auto-retry once. If still fails, show the error
- If the contact has no profile or `data_quality: "insufficient"`, fall back to `my-style.md` — never block a send
