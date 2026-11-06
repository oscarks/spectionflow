#!/bin/sh
# Spectionflow installer: copies the skills into a project (or your user directory).
# Usage:
#   ./install.sh                      # into ./.claude/skills of the current directory
#   ./install.sh /path/to/project     # into /path/to/project/.claude/skills
#   ./install.sh --user               # into ~/.claude/skills
#   ./install.sh --dir some/skills    # into an explicit skills directory
#   ./install.sh --only "proposal review"   # install a subset
set -eu

src="$(cd "$(dirname "$0")" && pwd)/skills"
dest=""
only=""

while [ $# -gt 0 ]; do
  case "$1" in
    --user) dest="$HOME/.claude/skills" ;;
    --dir)  shift; dest="${1:?--dir needs a path}" ;;
    --only) shift; only="${1:?--only needs a list}" ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *)  dest="$1/.claude/skills" ;;
  esac
  shift
done
[ -n "$dest" ] || dest="$(pwd)/.claude/skills"

mkdir -p "$dest"
for d in "$src"/*/; do
  name="$(basename "$d")"
  if [ -n "$only" ]; then
    case " $only " in *" $name "*) ;; *) continue ;; esac
  fi
  if [ -e "$dest/$name" ]; then
    echo "skip   $name (already exists in $dest — remove it to reinstall)"
    continue
  fi
  cp -R "$d" "$dest/$name"
  echo "added  $name -> $dest/$name"
done
