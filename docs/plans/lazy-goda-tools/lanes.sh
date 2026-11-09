#!/usr/bin/env bash
# Usage: lanes.sh <config dir> <run dir> [lane...]
# Drives a real Neovim TUI in tmux with isolated XDG directories and prints PASS or FAIL per lane.
set -u
CFG=$(cd "$1" && pwd); RUN=$2; shift 2
LANES=("$@"); [ ${#LANES[@]} -eq 0 ] && LANES=(1 2 3 4 5 6 7 8 9)
mkdir -p "$RUN/xdg/config" "$RUN/out" "$RUN/proj/.git"
RUN=$(cd "$RUN" && pwd)
ln -sfn "$CFG" "$RUN/xdg/config/nvim"
export XDG_CONFIG_HOME=$RUN/xdg/config XDG_DATA_HOME=$RUN/xdg/data XDG_STATE_HOME=$RUN/xdg/state XDG_CACHE_HOME=$RUN/xdg/cache
export DENO_DIR=${DENO_DIR:-$HOME/Library/Caches/deno}
SOCK=$RUN/nvim.sock; TM=(tmux -L "lanes$$" -f /dev/null)
start() {
  "${TM[@]}" kill-server 2>/dev/null; rm -f "$SOCK"
  "${TM[@]}" new-session -d -x 130 -y 40 -c "$RUN/proj" \
    "env XDG_CONFIG_HOME=$XDG_CONFIG_HOME XDG_DATA_HOME=$XDG_DATA_HOME XDG_STATE_HOME=$XDG_STATE_HOME XDG_CACHE_HOME=$XDG_CACHE_HOME DENO_DIR=$DENO_DIR PATH=$PATH nvim -i NONE --listen $SOCK $*"
  for _ in $(seq 100); do [ -S "$SOCK" ] && break; sleep 0.1; done
  sleep "${BOOT_WAIT:-4}"
}
keys() { "${TM[@]}" send-keys "$@"; }
type_slow() { local s=$1 i; for ((i = 0; i < ${#s}; i++)); do "${TM[@]}" send-keys -l "${s:i:1}"; sleep 0.12; done; }
screen() { "${TM[@]}" capture-pane -p; }
expr_() { nvim --server "$SOCK" --remote-expr "$1" 2>/dev/null; }
wait_screen() { local pat=$1 n=${2:-60} i; for ((i = 0; i < n; i++)); do screen | grep -qE "$pat" && return 0; sleep 0.25; done; return 1; }
wait_expr() { local e=$1 want=$2 n=${3:-60} i; for ((i = 0; i < n; i++)); do [ "$(expr_ "$e")" = "$want" ] && return 0; sleep 0.25; done; return 1; }
result() { local lane=$1 ok=$2 note=${3:-}; screen > "$RUN/out/lane$lane.txt" 2>/dev/null; [ "$ok" = 0 ] && echo "PASS lane$lane $note" || echo "FAIL lane$lane $note"; }

lane1() { printf 'local alphabetical = 1\nlocal alphanumeric = 2\n\n' > "$RUN/proj/c.lua"; start c.lua; keys G; keys i; sleep 1; type_slow alph
  wait_screen 'alphanumeric.*' 40; local a=$?; screen | grep -c 'alphabetical' | grep -qE '^[2-9]'; local b=$?; [ $a = 0 ] && [ $b = 0 ]; result 1 $? "completion"; }
lane2() { start c.lua; sleep 2; local m; m=$(expr_ 'execute("messages")'); printf '%s\n' "$m" > "$RUN/out/lane2-messages.txt"
  ! printf '%s' "$m" | grep -qE 'E[0-9]+:|Error|error'; local a=$?
  [ "$(expr_ 'luaeval("#vim.tbl_filter(function(p) return not p._.installed end, require([[lazy]]).plugins())")')" = 0 ]; local b=$?; [ $a = 0 ] && [ $b = 0 ]; result 2 $? "startup"; }
lane3() { printf 'local x = 1\n\n' > "$RUN/proj/l.lua"; BOOT_WAIT=2 start l.lua
  wait_expr 'luaeval("#vim.lsp.get_clients{bufnr=0}")' 1 80; sleep 6; keys G; keys i; sleep 1; type_slow string.up; wait_screen 'upper' 60; result 3 $? "lsp"; }
lane4() { start c.lua; keys Escape; type_slow ":let g:lane4 = 42"; sleep 1; local p; p=$(expr_ "pum#visible()"); keys Enter; sleep 0.5; [ "$(expr_ "get(g:, 'lane4', 0)")" = 42 ]; result 4 $? "cmdline pum=$p"; }
lane5() { start c.lua; keys Space f f; wait_screen 'Smart Open|Files|c\.lua' 40; local a=$?; keys Escape Escape q; sleep 0.5; keys Space f g; sleep 1; type_slow alpha; wait_screen 'alphabetical = 1' 40; local b=$?; keys Escape Escape q; [ $a = 0 ] && [ $b = 0 ]; result 5 $? "telescope"; }
lane6() { printf 'local t = { a = 1, b = 2 }\nprint(1)\n' > "$RUN/proj/k.lua"; start k.lua; keys Space /; sleep 1; local c; c=$(expr_ 'getline(1)'); [[ "$c" == --* ]]; local a=$?
  keys Space /; sleep 0.5; keys 0 f '{'; sleep 0.2; keys g S; sleep 1; [ "$(expr_ 'line("$")')" -gt 2 ]; local b=$?; [ $a = 0 ] && [ $b = 0 ]; result 6 $? "lazy keys"; }
lane7() { printf '# Title\n\nbody\n' > "$RUN/proj/m.md"; start m.md; lane7_check; result 7 $? "preview"; }
lane7_check() { [ "$(expr_ 'exists(":PreviewMarkdown")')" = 2 ]; }
lane8() { printf 'first\nasdf\n日本語のテキスト\n' > "$RUN/proj/j.txt"; start j.txt; keys gg; keys /; sleep 1; type_slow nihongo; sleep 1; keys Enter; sleep 1.5; wait_expr 'line(".")' 3 12; result 8 $? "kensaku"; }
lane9() { start c.lua; keys Escape; type_slow ':Aibo cat'; keys Enter; wait_expr 'luaeval("vim.bo.filetype:find([[aibo%-prompt]]) ~= nil and 1 or 0")' 1 30; local a=$?
  if [ $a != 0 ]; then keys Escape; sleep 1; fi; [ $a = 0 ]; result 9 $? "aibo prompt"; }
for l in "${LANES[@]}"; do "lane$l"; done
"${TM[@]}" kill-server 2>/dev/null
