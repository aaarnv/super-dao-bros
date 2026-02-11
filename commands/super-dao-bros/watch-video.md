# Super DAO Bros — Watch Video

Summarize a YouTube video from its transcript.

**Arguments:** $ARGUMENTS (a YouTube URL or video description to search for)

## Instructions

### Step 1: Extract video URL

Parse `$ARGUMENTS` for a YouTube URL. Accepted formats:
- `https://www.youtube.com/watch?v=XXXXX`
- `https://youtu.be/XXXXX`
- `https://youtube.com/watch?v=XXXXX`

If no URL is found, tell the user to provide a direct YouTube link.

### Step 2: Get transcript

Use the `mcp__youtube__get_transcript` tool with the video URL to fetch the transcript.

If the transcript is unavailable (private video, no captions), tell the user and stop.

### Step 3: Analyze and summarize

From the transcript, produce:

**Title & Metadata:**
- Video title (from transcript metadata if available, or ask user)
- Estimated length based on transcript timestamps

**Summary (3 sections):**

1. **Key Points** (5-8 bullet points)
   - The most important ideas, claims, or insights
   - Ordered by importance, not chronologically

2. **Main Argument / Thesis**
   - 2-3 sentences capturing the core message
   - Note if the video is educational, opinion, tutorial, interview, etc.

3. **Action Items** (if applicable)
   - Anything the viewer is encouraged to do
   - Tools, resources, or links mentioned
   - "None" if it's purely informational

**Notable Quotes** (2-3 max):
- Direct quotes that are particularly insightful or memorable
- Include approximate timestamp if available

### Step 4: Output and log

1. Display the full summary to the user in a clean format
2. Update `state.json` → increment `today_stats.videos_summarized`
3. Log to `~/Projects/super-dao-memories/logs/YYYY-MM-DD-messages.json`:
   ```json
   {
     "timestamp": "ISO",
     "type": "video_summary",
     "url": "youtube url",
     "title": "video title",
     "route": "youtube",
     "status": "summarized"
   }
   ```
4. Git commit: `"video: summarized — {short title}"`

### Step 5: Offer follow-up

Ask the user if they want to:
- Send the summary to someone (→ route to send-message)
- Add any action items to the inbox
- Save the full summary to a specific location
