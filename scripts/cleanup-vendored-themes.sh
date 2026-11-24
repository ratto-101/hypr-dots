#!/usr/bin/env bash
# =============================================================================
# cleanup-vendored-themes.sh
# -----------------------------------------------------------------------------
# Run this LOCALLY (on your machine, in your clone of the repo) to remove the
# vendored icon and GTK themes from git. These are huge (6000+ files, ~140 MB)
# and should be installed via AUR packages instead (bibata-cursor-theme is
# already in aur-packages.txt).
#
# The GitHub API can't bulk-delete directories, so this must be done locally.
#
# Usage:
#   cd /path/to/hypr-dots
#   bash scripts/cleanup-vendored-themes.sh
#   git commit -m "chore: remove vendored themes and editor cruft"
#   git push
# =============================================================================
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "==> Removing vendored icon theme (Bibata-Modern-Ice)..."
git rm -r --quiet icons/Bibata-Modern-Ice 2>/dev/null || echo "  (already removed or not present)"

echo "==> Removing vendored GTK theme (Waypaper-Gruvbox)..."
git rm -r --quiet themes/Waypaper-Gruvbox 2>/dev/null || echo "  (already removed or not present)"

echo "==> Removing .vscode editor cruft..."
git rm -r --quiet config/hypr/.vscode 2>/dev/null || echo "  (already removed or not present)"

echo
echo "==> Done. Now commit and push:"
echo "    git commit -m \"chore: remove vendored themes and editor cruft\""
echo "    git push"
echo
echo "    The .gitignore already prevents these from being re-added."
echo "    The repo will drop from ~144 MB to ~2 MB."
