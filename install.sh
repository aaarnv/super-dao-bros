#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
MEMORIES_DIR="$HOME/Projects/super-dao-memories"

echo "═══ Super DAO Bros — Installer ═══"
echo ""

# 1. Install commands (slash commands)
echo "Installing commands..."
mkdir -p "$CLAUDE_DIR/commands"
if [ -d "$CLAUDE_DIR/commands/super-dao-bros" ]; then
  echo "  Updating existing commands..."
  rm -rf "$CLAUDE_DIR/commands/super-dao-bros"
fi
cp -r "$REPO_DIR/commands/super-dao-bros" "$CLAUDE_DIR/commands/super-dao-bros"
echo "  ✓ Commands installed to $CLAUDE_DIR/commands/super-dao-bros/"

# 2. Install agent definitions
echo "Installing agents..."
mkdir -p "$CLAUDE_DIR/agents"
cp "$REPO_DIR/agents/nam-dao.md" "$CLAUDE_DIR/agents/nam-dao.md"
cp "$REPO_DIR/agents/anh-dao.md" "$CLAUDE_DIR/agents/anh-dao.md"
echo "  ✓ Agents installed to $CLAUDE_DIR/agents/"

# 2b. Install nchook handler (real-time Beeper watcher)
echo "Installing real-time watcher..."
mkdir -p "$HOME/.config/nchook"
cp "$REPO_DIR/agents/nchook_script" "$HOME/.config/nchook/nchook_script"
chmod +x "$HOME/.config/nchook/nchook_script"
cp "$REPO_DIR/scaffold/beeper-watcher-state.template.json" "$CLAUDE_DIR/agents/beeper-watcher-state.json"
echo "  ✓ nchook handler installed to ~/.config/nchook/nchook_script"

# 3. Scaffold memories repo (if it doesn't exist)
if [ ! -d "$MEMORIES_DIR" ]; then
  echo "Creating memories repo..."
  mkdir -p "$MEMORIES_DIR"/{contacts,tasks,logs,digests,agents}
  cp "$REPO_DIR/scaffold/config.template.json" "$MEMORIES_DIR/config.json"
  cp "$REPO_DIR/scaffold/state.template.json" "$MEMORIES_DIR/state.json"
  cp "$REPO_DIR/scaffold/contacts-index.template.json" "$MEMORIES_DIR/contacts-index.json"
  cp "$REPO_DIR/scaffold/inbox.template.md" "$MEMORIES_DIR/tasks/inbox.md"
  cp "$REPO_DIR/scaffold/queue.template.json" "$MEMORIES_DIR/tasks/queue.json"
  cp "$REPO_DIR/scaffold/nam-dao-config.json" "$MEMORIES_DIR/agents/nam-dao-config.json"
  cp "$REPO_DIR/scaffold/anh-dao-config.json" "$MEMORIES_DIR/agents/anh-dao-config.json"
  cd "$MEMORIES_DIR" && git init && git add -A && git commit -m "scaffold: initialize super-dao-memories"
  echo "  ✓ Memories repo created at $MEMORIES_DIR/"
else
  echo "  ⊘ Memories repo already exists at $MEMORIES_DIR/ — skipping"
fi

echo ""
echo "═══ Installation Complete ═══"
echo ""
echo "Available commands:"
echo "  /super-dao-bros:init          Scan contacts + build profiles"
echo "  /super-dao-bros:run           Execute task batch"
echo "  /super-dao-bros:send-message  Send tone-matched message"
echo "  /super-dao-bros:eod           End-of-day digest"
echo "  /super-dao-bros:watch-video   Summarize YouTube video"
echo "  /super-dao-bros:status        Dashboard"
echo "  /super-dao-bros:help          Command reference"
echo ""
echo "Prerequisites:"
echo "  - Beeper Desktop running + Beeper MCP plugin enabled"
echo "  - Apple MCP plugin enabled (for calendar/reminders)"
echo "  - YouTube MCP plugin enabled (for video summaries)"
echo "  - Herobrine skill installed (for scheduled execution)"
echo "  - nchook for real-time watcher: brew install who23/formulae/nchook"
echo ""
echo "To enable real-time message watching:"
echo "  brew install who23/formulae/nchook"
echo "  brew services start nchook"
echo ""
echo "Next step: Run /super-dao-bros:init in Claude Code"
