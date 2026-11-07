#!/usr/bin/env bash
set -eu
script=$(cd "$(dirname "$0")" && pwd)/lazy-cooldown.lua
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
commit_at() { GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2" git -C "$1" commit -q --allow-empty -m "$3"; }
ago() { echo "$(($(date +%s) - $1 * 86400)) +0000"; }
make_plugin() {
  git init -q -b main "$tmp/up/$1"
  git -C "$tmp/up/$1" config user.email t@t; git -C "$tmp/up/$1" config user.name t
  commit_at "$tmp/up/$1" "$(ago 30)" old
  commit_at "$tmp/up/$1" "$(ago 10)" allowed
  commit_at "$tmp/up/$1" "$(ago 1)" fresh
  git clone -q "$tmp/up/$1" "$tmp/root/$1"
}
mkdir -p "$tmp/up" "$tmp/root"
make_plugin other
make_plugin mine
git -C "$tmp/root/mine" remote set-url origin "$tmp/up/airRnot1106/mine"
mkdir -p "$tmp/up/airRnot1106"; mv "$tmp/up/mine" "$tmp/up/airRnot1106/mine"
old=$(git -C "$tmp/up/other" rev-parse HEAD~2); allowed=$(git -C "$tmp/up/other" rev-parse HEAD~1); fresh=$(git -C "$tmp/up/other" rev-parse HEAD)
mine_old=$(git -C "$tmp/up/airRnot1106/mine" rev-parse HEAD~2); mine_head=$(git -C "$tmp/up/airRnot1106/mine" rev-parse HEAD)
lock() { printf '{\n  "mine": { "branch": "main", "commit": "%s" },\n  "other": { "branch": "main", "commit": "%s" }\n}\n' "$1" "$2" > "$tmp/lock.json"; }
run() { nvim -l "$script" "$@" --lock "$tmp/lock.json" --root "$tmp/root"; }

lock "$mine_old" "$old"; run
grep -q "$allowed" "$tmp/lock.json" || { echo "FAIL: a 7-day-old commit replaces the older one"; exit 1; }
grep -q "$fresh" "$tmp/lock.json" && { echo "FAIL: a 1-day-old commit stays out of the lock"; exit 1; }
grep -q "$mine_head" "$tmp/lock.json" || { echo "FAIL: the owner's plugin moves to its newest commit"; exit 1; }

lock "$mine_old" "$fresh"; run
grep -q "$fresh" "$tmp/lock.json" || { echo "FAIL: a locked commit newer than the allowed one stays"; exit 1; }

lock "$mine_head" "$allowed"; run --check || { echo "FAIL: --check accepts old commits"; exit 1; }
lock "$mine_head" "$fresh"; if run --check 2>/dev/null; then echo "FAIL: --check rejects a 1-day-old commit"; exit 1; fi
echo ok
