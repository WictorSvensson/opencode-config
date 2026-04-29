#!/usr/bin/env bash
# setup.sh — Install shared OpenCode agents, skills, and plugins
# Repo: https://github.com/WictorSvensson/opencode-config
#
# Run once to install, re-run anytime to pick up new files after a git pull.
# This script is idempotent — it never overwrites existing non-symlink files.

set -euo pipefail

REPO_URL="https://github.com/WictorSvensson/opencode-config.git"
CLONE_DIR="$HOME/.config/opencode-config"
OPENCODE_DIR="$HOME/.config/opencode"

# ── Colours ────────────────────────────────────────────────────────────────────
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

info()  { echo -e "${GREEN}✔${RESET}  $*"; }
warn()  { echo -e "${YELLOW}⚠${RESET}  $*"; }
error() { echo -e "${RED}✖${RESET}  $*"; exit 1; }

# ── Prerequisites ──────────────────────────────────────────────────────────────
command -v git >/dev/null 2>&1 || error "git is required but not found."

# ── Clone or update the repo ───────────────────────────────────────────────────
if [ -d "$CLONE_DIR/.git" ]; then
  echo "Updating existing clone at $CLONE_DIR …"
  git -C "$CLONE_DIR" pull --ff-only
  info "Repository up to date"
else
  echo "Cloning $REPO_URL → $CLONE_DIR …"
  git clone "$REPO_URL" "$CLONE_DIR"
  info "Repository cloned"
fi

# ── Ensure target directories exist ───────────────────────────────────────────
mkdir -p "$OPENCODE_DIR/agents"
mkdir -p "$OPENCODE_DIR/skills"
mkdir -p "$OPENCODE_DIR/plugins"

# ── Helper: create a symlink safely ───────────────────────────────────────────
# Usage: link_item <source> <target>
link_item() {
  local src="$1"
  local tgt="$2"

  if [ -L "$tgt" ]; then
    # Already a symlink — update it to point to the current source
    ln -sf "$src" "$tgt"
    info "Updated symlink: $tgt"
  elif [ -e "$tgt" ]; then
    # Exists but is not a symlink (manually created / personal file)
    warn "Skipped (non-symlink already exists): $tgt"
  else
    ln -s "$src" "$tgt"
    info "Linked: $tgt"
  fi
}

# ── Agents ─────────────────────────────────────────────────────────────────────
echo ""
echo "── Agents ────────────────────────────────────────────────────────────────"
for src in "$CLONE_DIR/agents/"*.md; do
  name="$(basename "$src")"
  link_item "$src" "$OPENCODE_DIR/agents/$name"
done

# ── Skills ─────────────────────────────────────────────────────────────────────
echo ""
echo "── Skills ────────────────────────────────────────────────────────────────"
for src in "$CLONE_DIR/skills/"/*/; do
  name="$(basename "$src")"
  link_item "$src" "$OPENCODE_DIR/skills/$name"
done

# ── Plugins ────────────────────────────────────────────────────────────────────
echo ""
echo "── Plugins ───────────────────────────────────────────────────────────────"
for src in "$CLONE_DIR/plugins/"*; do
  name="$(basename "$src")"
  link_item "$src" "$OPENCODE_DIR/plugins/$name"
done

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
info "Setup complete. OpenCode will pick up the new agents and skills next time you start it."
echo ""
echo "  To update in the future, run:"
echo "    cd $CLONE_DIR && git pull"
echo ""
