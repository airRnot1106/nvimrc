# dpp.vim から lazy.nvim と goda.vim へ移行する plan

この plan は Neovim 設定の plugin manager を lazy.nvim に変え、denops 製 plugin
を goda.vim 製へ置き換え、最後に Deno を削除する。
利用者は設定の所有者である。保守者は Lua の spec と Go の設定 module
を扱うようになる。 守る規則は 1 つである。各 PR
の完了時点で、普段の補完、検索、preview が trunk と同じように動く。 PR の順序は
M1、M2、G1、G2、G3、G4、G5、G6、G7、G8、Z1 である。

## How to read this

One box is one unit of work. Every box names the evidence that checks it. A
nested box is a sub-step of the box above it. Check a box only when its evidence
exists, a file, a log line, a screenshot, a test run, or a SHA. The body is a
how-to. The appendices explain and record.

The program runs `pstack/skills/poteto-mode/playbooks/autopilot-stack.md`.
operator が全 PR を review して merge する。全 PR は merge-ready で止まる。

Tests alone are not sufficient verification. A PR is verified only when its
unit, live, and perf boxes are all checked.

## Program checklist

### Arm the program

- [ ] State the protocol and this plan to the operator, then stop. Start
      execution only on the operator's explicit go.
- [ ] 開始時と各 tick で次を読み直す。
  - [ ] `git show origin/main:init.lua`
  - [ ] `git show origin/main:lua/plugins/lspconfig.lua`
  - [ ] pstack の `skills/poteto-mode/playbooks/autopilot-stack.md` を plugin
        cache から読む。
  - [ ] pstack の `skills/swarm/SKILL.md` を plugin cache から読む。
  - [ ] pstack の `skills/poteto-mode/playbooks/opening-a-pr.md` を plugin cache
        から読む。
- [ ] On the operator's go, arm the audit tick as `/loop 1h` with the tick
      prompt below. Never leave the cadence to memory.
- [ ] Use this tick prompt, verbatim. "Re-read the execution playbook from
      trunk. Audit the operation against it and fix drift in this tick. Probe
      every active lane and judge progress by side effects only. Stand down a
      stuck lane and dispatch its replacement now. Then post a short status
      message to the operator in chat only when the audit found a tracked change
      that no earlier status message reported, such as a PR opened, a code-ready
      head, a round launched or closed, a verdict, a merge, a stuck agent and
      the action taken, a blocker added or cleared, or a decision only the
      operator can make. Name every such change and nothing else. Do not repeat
      a table, the merged list, or an unchanged blocker. If the audit found
      none, end the turn with no reply text. Either way, log this tick's row in
      your decision trail. The row names the items reported, or none."
- [ ] On the operator's hold or stand-down, send every owner a zero-writes order
      at once.

### Spawn owners

- [ ] Spawn one owner per PR with the full lifecycle the execution playbook
      names.
- [ ] Follow this dependency graph. 依存先の branch を base にする。
  - [ ] M1 は最初に `main` から branch する。
  - [ ] M2 と G1 は M1 の後に始める。互いに独立している。
  - [ ] G2 と G7 は G1 の後に始める。G1 が `lua/plugins/goda.lua` を作る。
  - [ ] G3、G4、G5 は G2 の後に始める。互いに独立している。
  - [ ] G6 は G3、G4、G5 の後に始める。
  - [ ] G8 は G7 の後に始める。
  - [ ] Z1 は G1、G6、G8 の後に始める。
- [ ] Hold the file boundaries. G3、G4、G5 は `goda-cmp/ext/` の別の directory
      だけを編集し、`goda-cmp/main.go` の登録行だけを共有する。
- [ ] Hold the review gate. M1、G1、G6、G7、G8 は操作感を変える。merge の前に
      operator が確認する。

### PR mechanics, for every PR

- [ ] Resolve the forge once. `gh` を使う。
- [ ] Open the PR ready, never draft, per **Opening a PR**. stack の子 PR は親
      branch を base にする。
- [ ] Run `nix flake check` once before the PR-facing push. Push with hooks on.
- [ ] Run `/deslop` before each commit and `/no-comments` before review.
      `cursor-team-kit` がない場合は skip を記録する。
- [ ] Triage every review comment on its merits.
- [ ] Rebase onto current trunk before the code-ready report.

### Verdict and merge, for every PR

- [ ] A full swarm runs once, at the code-ready head. rebase
      や小さな修正は単一の検証で足りる。
- [ ] Clean only when every lane is `PASS`. 指摘は owner へ戻す。新しい head
      には新しい verdict を出す。
- [ ] owner は merge しない。root が stack へ追加し、operator が bottom-up で
      land する。

### Boot recipe, for every live lane

Skipped in Claude Code. Cursor の cloud VM は使わない。各 lane は local の git
worktree と隔離した XDG で動かす。

- [ ] `git fetch origin <head-branch> && git worktree add <dir> <head SHA>`。
- [ ] `XDG_CONFIG_HOME`、`XDG_DATA_HOME`、`XDG_STATE_HOME`、`XDG_CACHE_HOME` を
      lane 専用の directory に設定する。M1 から G6 までは `DENO_DIR` に実環境の
      cache を設定する。
- [ ] `tmux` の pane で Neovim を起動し、入力は `tmux send-keys`
      だけで渡す。診断は `nvim --server` の read-only な expr だけを使う。
- [ ] 画面は `tmux capture-pane -p` で保存する。Save every capture to
      `/tmp/swarm-<pr-id>/worker-<n>/<slug>.txt` and return the paths with the
      report.

## dpp.vim を lazy.nvim へ一度に切り替える (M1)

**Depends on.** None.

**Files.**

- [ ] Edit `init.lua`。
- [ ] Edit `lua/config.lua`。
- [ ] Edit `lua/plugins/*.lua`。
- [ ] Create `lua/plugins/denops.lua`。
- [ ] Create `lazy-lock.json`。
- [ ] Edit `flake.nix`、`flake.lock`、`.github/dependabot.yaml`。
- [ ] Delete
      `dpp.ts`、`lib/`、`lua/dpp-cache.lua`、`nix/dpp/`、`deno.jsonc`、`deno.lock`。

**Build.**

- [ ] `docs/plans/lazy-goda-tools/dpp2lazy.pl` を `lua/plugins/*.lua`
      に適用する。
- [ ] `init.lua` の dpp 起動処理を lazy.nvim の bootstrap と
      `require("lazy").setup` に置き換える。
- [ ] `denops.vim` を `lazy = false` の spec として追加する。
- [ ] `DppUpdate` command を削除する。
- [ ] `telescope-fzf-native` と `bufpreview` の `build`
      が完了することを確認する。

**You see.**

- [ ] `:Lazy` に 72 個の plugin が表示される。
- [ ] `rg -n 'dpp|Dpp' init.lua lua flake.nix` が 0 件を返す。

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Run `nvim --headless "+Lazy! install" +qa`。exit 0 と `not_installed={}`
      を確認する。
- [ ] Run `nix flake check`。hook が全件通る。

**Verify, live.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked. Ten lanes on
`inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. trunk と head で
      `docs/plans/lazy-goda-tools/e2e-completion.lua` を実行する。 Save
      `m1-lane1-completion.txt`. Pass when 両方の pum に `alphabetical` と
      `alphanumeric` が出る。
- [ ] Lane 2. 通常起動して `:messages` と `:checkhealth lazy` を確認する。 Save
      `m1-lane2-startup.txt`. Pass when error が 0 件で、未 install の plugin が
      0 件である。
- [ ] Lane 3. `docs/plans/lazy-goda-tools/e2e-lsp.lua` で `string.up`
      を入力する。 Save `m1-lane3-lsp.txt`. Pass when pum に `upper` が出る。
- [ ] Lane 4. noice を有効にしたまま `:ech` を入力する。 Save
      `m1-lane4-cmdline.txt`. Pass when pum に `echo` が出て、`<C-y>`
      で確定できる。
- [ ] Lane 5. `<Leader>ff` と `<Leader>fg` で telescope を開く。 Save
      `m1-lane5-telescope.txt`. Pass when smart_open と live_grep
      の両方が結果を返す。
- [ ] Lane 6. `<Leader>/`、`gS`、`<Leader>r` を初回押下する。 Save
      `m1-lane6-keys.txt`. Pass when 初回の押下で plugin が load
      され、そのまま操作が実行される。
- [ ] Lane 7. Markdown を開いて preview を起動する。 Save
      `m1-lane7-preview.txt`. Pass when browser
      に本文が表示され、編集が反映される。
- [ ] Lane 8. 日本語の buffer で `/nihongo` を検索する。 Save
      `m1-lane8-kensaku.txt`. Pass when `日本語` に一致する。
- [ ] Lane 9. `<Leader>aq` で aibo prompt を開き、補完と `<C-n>` を試す。 Save
      `m1-lane9-aibo.txt`. Pass when prompt buffer で補完が動き、pum
      がないときは履歴移動になる。
- [ ] Lane 10. 空の XDG で 2 回起動する。 Save `m1-lane10-bootstrap.txt`. Pass
      when 1 回目で install と build が終わり、2 回目は error が 0 件である。

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Metric. `e2e-completion.lua` の最終 key から `pum#visible()`
      が真になるまでの ms。VimEnter で load する plugin の完了までの ms。
- [ ] Probe. trunk と head を交互に 20
      回ずつ実行し、中央値と四分位範囲を記録する。
- [ ] Baseline. trunk の値を先に記録する。`--startuptime` の `NVIM STARTED`
      は使わない。Appendix A の通り、VimEnter で load する plugin を含まない。
- [ ] Rule. head の中央値が trunk の 1.10 倍を超えたら不合格にする。

**Review gate.** The operator reviews before merge.

- [ ] Copy lane の screenshot 相当の capture を `docs/plans/media/m1-review.txt`
      へ保存する。
- [ ] 30 から 60 秒の video を `docs/plans/media/m1-review.mp4` に保存する。
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for
      the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] review comment の triage が終わっている。
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] root が stack へ追加し、operator が bottom-up で land する。

## 7 日の更新 cooldown を lazy-lock.json に移す (M2)

**Depends on.** M1.

**Files.**

- [ ] Create `scripts/lazy-cooldown.lua`。
- [ ] Edit `lazy-lock.json`。

**Build.**

- [ ] 各 plugin の追跡 branch から、7 日以上前の最新 commit を選んで
      `lazy-lock.json` に書く script を作る。
- [ ] 更新手順を script の実行、`:Lazy restore`、差分確認の順に固定する。

**You see.**

- [ ] script の実行後、`lazy-lock.json` の全 commit が 7 日以上前の commit
      になる。

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Run `nvim -l scripts/lazy-cooldown.lua --check`。7 日未満の commit
      があれば exit 1 を返す fixture を含める。

**Verify, live.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked. Ten lanes on
`inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. trunk と head で
      `docs/plans/lazy-goda-tools/e2e-completion.lua` を実行する。 Save
      `m2-lane1-completion.txt`. Pass when 両方の pum に `alphabetical` と
      `alphanumeric` が出る。
- [ ] Lane 2. 通常起動して `:messages` と `:checkhealth lazy` を確認する。 Save
      `m2-lane2-startup.txt`. Pass when error が 0 件で、未 install の plugin が
      0 件である。
- [ ] Lane 3. `docs/plans/lazy-goda-tools/e2e-lsp.lua` で `string.up`
      を入力する。 Save `m2-lane3-lsp.txt`. Pass when pum に `upper` が出る。
- [ ] Lane 4. noice を有効にしたまま `:ech` を入力する。 Save
      `m2-lane4-cmdline.txt`. Pass when pum に `echo` が出て、`<C-y>`
      で確定できる。
- [ ] Lane 5. `<Leader>ff` と `<Leader>fg` で telescope を開く。 Save
      `m2-lane5-telescope.txt`. Pass when smart_open と live_grep
      の両方が結果を返す。
- [ ] Lane 6. `<Leader>/`、`gS`、`<Leader>r` を初回押下する。 Save
      `m2-lane6-keys.txt`. Pass when 初回の押下で plugin が load
      され、そのまま操作が実行される。
- [ ] Lane 7. Markdown を開いて preview を起動する。 Save
      `m2-lane7-preview.txt`. Pass when browser
      に本文が表示され、編集が反映される。
- [ ] Lane 8. 日本語の buffer で `/nihongo` を検索する。 Save
      `m2-lane8-kensaku.txt`. Pass when `日本語` に一致する。
- [ ] Lane 9. `<Leader>aq` で aibo prompt を開き、補完と `<C-n>` を試す。 Save
      `m2-lane9-aibo.txt`. Pass when prompt buffer で補完が動き、pum
      がないときは履歴移動になる。
- [ ] Lane 10. cooldown script の実行後に `:Lazy restore` を実行し、空の XDG
      でも起動する。 Save `m2-lane10-restore.txt`. Pass when lock の commit と
      checkout 先の commit が全 plugin で一致する。

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Metric. `scripts/lazy-cooldown.lua` の完了までの秒数。trunk
      には機能がないため、この処理単体を測る。
- [ ] Probe. 全 plugin の clone がある状態で 5 回実行する。
- [ ] Baseline. trunk にこの機能がないことを記録する。
- [ ] Rule. 中央値が 60 秒を超えたら不合格にする。

**Review gate.** None. M2 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] review comment の triage が終わっている。
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] root が stack へ追加し、operator が bottom-up で land する。

## bufpreview.vim を gmp.vim へ置き換える (G1)

**Depends on.** M1.

**Files.**

- [ ] Create `lua/plugins/gmp.lua`。
- [ ] Create `lua/plugins/goda.lua`。
- [ ] Delete `lua/plugins/bufpreview.lua`。

**Build.**

- [ ] `airRnot1106/gmp.vim` を `build = "nix build"` と `ft = "markdown"`
      で追加する。
- [ ] `Shougo/goda.vim` の spec を追加する。

**You see.**

- [ ] Markdown の preview が Deno なしで起動する。

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Run `nix build` を gmp.vim の clone で実行する。`result/bin/gmp`
      が存在する。

**Verify, live.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked. Ten lanes on
`inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. trunk と head で
      `docs/plans/lazy-goda-tools/e2e-completion.lua` を実行する。 Save
      `g1-lane1-completion.txt`. Pass when 両方の pum に `alphabetical` と
      `alphanumeric` が出る。
- [ ] Lane 2. 通常起動して `:messages` と `:checkhealth lazy` を確認する。 Save
      `g1-lane2-startup.txt`. Pass when error が 0 件で、未 install の plugin が
      0 件である。
- [ ] Lane 3. `docs/plans/lazy-goda-tools/e2e-lsp.lua` で `string.up`
      を入力する。 Save `g1-lane3-lsp.txt`. Pass when pum に `upper` が出る。
- [ ] Lane 4. noice を有効にしたまま `:ech` を入力する。 Save
      `g1-lane4-cmdline.txt`. Pass when pum に `echo` が出て、`<C-y>`
      で確定できる。
- [ ] Lane 5. `<Leader>ff` と `<Leader>fg` で telescope を開く。 Save
      `g1-lane5-telescope.txt`. Pass when smart_open と live_grep
      の両方が結果を返す。
- [ ] Lane 6. `<Leader>/`、`gS`、`<Leader>r` を初回押下する。 Save
      `g1-lane6-keys.txt`. Pass when 初回の押下で plugin が load
      され、そのまま操作が実行される。
- [ ] Lane 7. Markdown を開いて gmp.vim の preview を起動する。Mermaid と KaTeX
      を含む文書を使う。 Save `g1-lane7-gmp.txt`. Pass when browser
      に図と数式が表示され、cursor 追従が動く。
- [ ] Lane 8. 日本語の buffer で `/nihongo` を検索する。 Save
      `g1-lane8-kensaku.txt`. Pass when `日本語` に一致する。
- [ ] Lane 9. `<Leader>aq` で aibo prompt を開き、補完と `<C-n>` を試す。 Save
      `g1-lane9-aibo.txt`. Pass when prompt buffer で補完が動き、pum
      がないときは履歴移動になる。
- [ ] Lane 10. 空の XDG で 2 回起動する。 Save `g1-lane10-bootstrap.txt`. Pass
      when 1 回目で install と build が終わり、2 回目は error が 0 件である。

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Metric. preview command の実行から browser に初回描画されるまでの ms。
- [ ] Probe. bufpreview と gmp.vim を交互に 10 回ずつ起動する。
- [ ] Baseline. trunk の bufpreview の値を先に記録する。
- [ ] Rule. head の中央値が trunk の 1.20 倍を超えたら不合格にする。

**Review gate.** The operator reviews before merge.

- [ ] Copy lane の screenshot 相当の capture を `docs/plans/media/g1-review.txt`
      へ保存する。
- [ ] 30 から 60 秒の video を `docs/plans/media/g1-review.mp4` に保存する。
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for
      the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] review comment の triage が終わっている。
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] root が stack へ追加し、operator が bottom-up で land する。

## goda-cmp の Go module と build 経路を用意する (G2)

**Depends on.** G1.

**Files.**

- [ ] Create `goda-cmp/go.mod`、`goda-cmp/go.sum`、`goda-cmp/main.go`。
- [ ] Create `lua/plugins/goda-cmp.lua`。
- [ ] Edit
      `lua/plugins/goda.lua`、`flake.nix`、`nix/treefmt.nix`、`.github/dependabot.yaml`。

**Build.**

- [ ] `g:goda#workspace` に lazy の `goda.vim` と `goda-cmp.vim` の path
      を設定する。`lazy-lock.json` が版の正本になる。
- [ ] `goda-cmp.vim` に `build = ":call goda_cmp#build()"` を設定する。function
      形式の build は `E117` で失敗する。
- [ ] `goda.vim` の更新でも `goda-cmp` を再 build する。
- [ ] この repository の `flake.nix` の devShell に `go` と `gopls`
      を追加し、treefmt に gofmt を追加する。nix profile には入れない。
- [ ] plugin の install と更新は、この repository で direnv を有効にした Neovim
      から実行する。
- [ ] `lazy = true` のまま `goda_cmp#enable()` は呼ばない。ddc
      が動作中の補完を担当する。

**You see.**

- [ ] `:Lazy build goda-cmp.vim` が `~/.cache/nvim/goda-cmp/goda-cmp` を作る。
- [ ] `go.work` が lazy の clone を指す。

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Run `go vet ./...` と `go test ./...` を `goda-cmp/` で実行する。

**Verify, live.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked. Ten lanes on
`inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. trunk と head で
      `docs/plans/lazy-goda-tools/e2e-completion.lua` を実行する。 Save
      `g2-lane1-completion.txt`. Pass when 両方の pum に `alphabetical` と
      `alphanumeric` が出る。
- [ ] Lane 2. 通常起動して `:messages` と `:checkhealth lazy` を確認する。 Save
      `g2-lane2-startup.txt`. Pass when error が 0 件で、未 install の plugin が
      0 件である。
- [ ] Lane 3. `docs/plans/lazy-goda-tools/e2e-lsp.lua` で `string.up`
      を入力する。 Save `g2-lane3-lsp.txt`. Pass when pum に `upper` が出る。
- [ ] Lane 4. noice を有効にしたまま `:ech` を入力する。 Save
      `g2-lane4-cmdline.txt`. Pass when pum に `echo` が出て、`<C-y>`
      で確定できる。
- [ ] Lane 5. `<Leader>ff` と `<Leader>fg` で telescope を開く。 Save
      `g2-lane5-telescope.txt`. Pass when smart_open と live_grep
      の両方が結果を返す。
- [ ] Lane 6. `<Leader>/`、`gS`、`<Leader>r` を初回押下する。 Save
      `g2-lane6-keys.txt`. Pass when 初回の押下で plugin が load
      され、そのまま操作が実行される。
- [ ] Lane 7. Markdown を開いて preview を起動する。 Save
      `g2-lane7-preview.txt`. Pass when browser
      に本文が表示され、編集が反映される。
- [ ] Lane 8. 日本語の buffer で `/nihongo` を検索する。 Save
      `g2-lane8-kensaku.txt`. Pass when `日本語` に一致する。
- [ ] Lane 9. `<Leader>aq` で aibo prompt を開き、補完と `<C-n>` を試す。 Save
      `g2-lane9-aibo.txt`. Pass when prompt buffer で補完が動き、pum
      がないときは履歴移動になる。
- [ ] Lane 10. 空の XDG で install し、`goda-cmp` の binary
      が作られることを確認する。別の directory の Go
      がない環境でも起動し、`:Lazy update` も実行する。 Save
      `g2-lane10-build.txt`. Pass when Go なしでも起動と補完が動き、build
      の失敗が画面に出る。

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Metric. `goda_cmp#build()` の完了までの秒数。trunk
      には機能がないため、この処理単体を測る。
- [ ] Probe. Go build cache が温かい状態で 5 回実行する。
- [ ] Baseline. trunk にこの機能がないことを記録する。試作は 2.8 秒だった。
- [ ] Rule. 中央値が 30 秒を超えたら不合格にする。

**Review gate.** None. G2 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] review comment の triage が終わっている。
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] root が stack へ追加し、operator が bottom-up で land する。

## rg、emoji、fuzzy filter を Go へ移植する (G3)

**Depends on.** G2.

**Files.**

- [ ] Create `goda-cmp/ext/source/rg/`。
- [ ] Create `goda-cmp/ext/source/emoji/`。
- [ ] Create `goda-cmp/ext/filter/fuzzy/`。
- [ ] Edit `goda-cmp/main.go`。

**Build.**

- [ ] `ddc-source-rg` の 77 行を移植する。
- [ ] `ddc-emoji` の 71 行を移植する。
- [ ] `ddc-fuzzy` の matcher、sorter、converter の 147 行を移植する。
- [ ] `path` source は移植しない。`file` と同じ `keywordPattern` と
      `forceCompletionPattern` を持つため、`file` へ統合する。

**You see.**

- [ ] `goda-cmp/main.go` が各 extension を登録し、`go test` で候補を返す。

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Run `go test ./ext/...`。`cmptest` で rg の非 0 exit、emoji の `:`
      入力、fuzzy の順位を検証する。

**Verify, live.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked. Ten lanes on
`inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. trunk の ddc と head の goda-cmp
      で同じ入力に対する fuzzy の候補順を比べる。goda-cmp は test
      用の設定で起動する。 Save `g3-lane1-fuzzy.txt`. Pass when 上位 5 件のうち
      4 件以上が一致する。
- [ ] Lane 2. 通常起動して `:messages` と `:checkhealth lazy` を確認する。 Save
      `g3-lane2-startup.txt`. Pass when error が 0 件で、未 install の plugin が
      0 件である。
- [ ] Lane 3. `docs/plans/lazy-goda-tools/e2e-lsp.lua` で `string.up`
      を入力する。 Save `g3-lane3-lsp.txt`. Pass when pum に `upper` が出る。
- [ ] Lane 4. noice を有効にしたまま `:ech` を入力する。 Save
      `g3-lane4-cmdline.txt`. Pass when pum に `echo` が出て、`<C-y>`
      で確定できる。
- [ ] Lane 5. `<Leader>ff` と `<Leader>fg` で telescope を開く。 Save
      `g3-lane5-telescope.txt`. Pass when smart_open と live_grep
      の両方が結果を返す。
- [ ] Lane 6. `<Leader>/`、`gS`、`<Leader>r` を初回押下する。 Save
      `g3-lane6-keys.txt`. Pass when 初回の押下で plugin が load
      され、そのまま操作が実行される。
- [ ] Lane 7. Markdown を開いて preview を起動する。 Save
      `g3-lane7-preview.txt`. Pass when browser
      に本文が表示され、編集が反映される。
- [ ] Lane 8. 日本語の buffer で `/nihongo` を検索する。 Save
      `g3-lane8-kensaku.txt`. Pass when `日本語` に一致する。
- [ ] Lane 9. `<Leader>aq` で aibo prompt を開き、補完と `<C-n>` を試す。 Save
      `g3-lane9-aibo.txt`. Pass when prompt buffer で補完が動き、pum
      がないときは履歴移動になる。
- [ ] Lane 10. 空の XDG で 2 回起動する。 Save `g3-lane10-bootstrap.txt`. Pass
      when 1 回目で install と build が終わり、2 回目は error が 0 件である。

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Metric. 10 万語の buffer での fuzzy filter の処理時間。
- [ ] Probe. `go test -bench` と ddc-fuzzy の同一入力を交互に 10
      回ずつ実行する。
- [ ] Baseline. trunk の ddc-fuzzy の値を先に記録する。
- [ ] Rule. head の中央値が trunk の 1.10 倍を超えたら不合格にする。

**Review gate.** None. G3 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] review comment の triage が終わっている。
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] root が stack へ追加し、operator が bottom-up で land する。

## copilot と maccy の source を Go へ移植する (G4)

**Depends on.** G2.

**Files.**

- [ ] Create `goda-cmp/ext/source/copilot/`。
- [ ] Create `goda-cmp/ext/source/maccy/`。
- [ ] Edit `goda-cmp/main.go`。

**Build.**

- [ ] `ddc-source-copilot` の 166 行を移植し、`copilot.lua` の client を Lua
      経由で呼ぶ。
- [ ] `ddc-source-maccy` の 897 行を移植する。SQLite は pure Go driver か
      `sqlite3` command のどちらかを PR 内で計測して選ぶ。

**You see.**

- [ ] copilot の提案と Maccy の直近の clipboard が候補に出る。

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Run `go test ./ext/...`。maccy は fixture DB で
      `recentMs`、`dedupe`、`excludeAfterUse`、`maxUseCount` を検証する。

**Verify, live.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked. Ten lanes on
`inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. trunk の ddc と head の goda-cmp
      で、Maccy に 1 件 copy した直後の候補を比べる。 Save `g4-lane1-maccy.txt`.
      Pass when 両方の候補に同じ clipboard の値が出る。
- [ ] Lane 2. 通常起動して `:messages` と `:checkhealth lazy` を確認する。 Save
      `g4-lane2-startup.txt`. Pass when error が 0 件で、未 install の plugin が
      0 件である。
- [ ] Lane 3. `docs/plans/lazy-goda-tools/e2e-lsp.lua` で `string.up`
      を入力する。 Save `g4-lane3-lsp.txt`. Pass when pum に `upper` が出る。
- [ ] Lane 4. noice を有効にしたまま `:ech` を入力する。 Save
      `g4-lane4-cmdline.txt`. Pass when pum に `echo` が出て、`<C-y>`
      で確定できる。
- [ ] Lane 5. `<Leader>ff` と `<Leader>fg` で telescope を開く。 Save
      `g4-lane5-telescope.txt`. Pass when smart_open と live_grep
      の両方が結果を返す。
- [ ] Lane 6. `<Leader>/`、`gS`、`<Leader>r` を初回押下する。 Save
      `g4-lane6-keys.txt`. Pass when 初回の押下で plugin が load
      され、そのまま操作が実行される。
- [ ] Lane 7. Markdown を開いて preview を起動する。 Save
      `g4-lane7-preview.txt`. Pass when browser
      に本文が表示され、編集が反映される。
- [ ] Lane 8. 日本語の buffer で `/nihongo` を検索する。 Save
      `g4-lane8-kensaku.txt`. Pass when `日本語` に一致する。
- [ ] Lane 9. copilot の認証済み環境で関数の途中を入力する。 Save
      `g4-lane9-copilot.txt`. Pass when `[Copilot]`
      の候補が出て、確定すると本文に入る。
- [ ] Lane 10. 空の XDG で 2 回起動する。 Save `g4-lane10-bootstrap.txt`. Pass
      when 1 回目で install と build が終わり、2 回目は error が 0 件である。

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Metric. maccy source の Gather の ms。
- [ ] Probe. 実 DB の copy を使い、ddc 版と Go 版を交互に 20 回ずつ実行する。
- [ ] Baseline. trunk の ddc-source-maccy の値を先に記録する。
- [ ] Rule. head の中央値が trunk の 1.10 倍を超えたら不合格にする。

**Review gate.** None. G4 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] review comment の triage が終わっている。
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] root が stack へ追加し、operator が bottom-up で land する。

## Neovim の LSP client を使う source を作る (G5)

**Depends on.** G2.

**Files.**

- [ ] Create `goda-cmp/ext/source/nvimlsp/`。
- [ ] Create `lua/goda_cmp_lsp.lua`。
- [ ] Edit `goda-cmp/main.go`。

**Build.**

- [ ] `docs/plans/lazy-goda-tools/goda-cmp-proto/nvimlsp.go` と
      `nvimlsp_spike.lua` を土台にする。Go は `cmp.Source` と
      `cmp.CompleteDoner` を実装し、Lua は `vim.lsp.buf_request_all`
      で起動済みの client に要求する。
- [ ] `textEdit` と `insertReplace`
      の範囲から置換位置を計算する。`Gathered.Start` をこの結果に合わせる。
- [ ] `itemDefaults` と `isIncomplete` を処理する。
- [ ] `cmp.Resolver` を実装し、`completionItem/resolve` の結果を説明文に使う。
- [ ] `ctx` の取り消しで古い request を cancel し、`pending` の table
      に結果を残さない。
- [ ] 複数 client の結果を統合し、client ごとの `offset_encoding` を保つ。
- [ ] `additionalTextEdits` を適用し、snippet は `vim.snippet.expand`
      で展開する。

**You see.**

- [ ] `after/lsp/` と `lua/plugins/lspconfig.lua` の server
      設定を変更しないで補完が動く。
- [ ] language server の process 数が trunk から増えない。
- [ ] snippet の候補を確定すると placeholder へ移動する。

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Run `go test ./ext/source/nvimlsp` を `goda-cmp/`
      で実行する。候補の変換、`ctx` の取り消し、resolve の結果を検証する。
- [ ] Run `nvim -l` で fake client を使う Lua の test
      を実行する。`itemDefaults`、`textEdit` の範囲、複数 client
      の統合を検証する。

**Verify, live.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked. Ten lanes on
`inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. trunk の ddc と head の goda-cmp で
      `string.up` を 1 文字ずつ入力する。 Save `g5-lane1-lsp.txt`. Pass when
      両方の pum に `upper` が出る。
- [ ] Lane 2. 通常起動して `:messages` と `:checkhealth lazy` を確認する。 Save
      `g5-lane2-startup.txt`. Pass when error が 0 件で、未 install の plugin が
      0 件である。
- [ ] Lane 3. `docs/plans/lazy-goda-tools/e2e-lsp.lua` で `string.up`
      を入力する。 Save `g5-lane3-lsp.txt`. Pass when pum に `upper` が出る。
- [ ] Lane 4. noice を有効にしたまま `:ech` を入力する。 Save
      `g5-lane4-cmdline.txt`. Pass when pum に `echo` が出て、`<C-y>`
      で確定できる。
- [ ] Lane 5. `<Leader>ff` と `<Leader>fg` で telescope を開く。 Save
      `g5-lane5-telescope.txt`. Pass when smart_open と live_grep
      の両方が結果を返す。
- [ ] Lane 6. `<Leader>/`、`gS`、`<Leader>r` を初回押下する。 Save
      `g5-lane6-keys.txt`. Pass when 初回の押下で plugin が load
      され、そのまま操作が実行される。
- [ ] Lane 7. `fun` を入力し、`function ()` の候補を確定する。 Save
      `g5-lane7-snippet.txt`. Pass when 本文に展開され、`vim.snippet.active()`
      が真になる。
- [ ] Lane 8. 日本語の buffer で `/nihongo` を検索する。 Save
      `g5-lane8-kensaku.txt`. Pass when `日本語` に一致する。
- [ ] Lane 9. `vtsls` の project で auto import の候補を確定する。 Save
      `g5-lane9-autoimport.txt`. Pass when import 文が追加され、cursor
      位置が保たれる。
- [ ] Lane 10. 同じ project を trunk と head で開き、`ps -axo command` で
      language server を数える。 Save `g5-lane10-lsp-procs.txt`. Pass when head
      の process 数が trunk と同じである。

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Metric. LSP 候補の表示までの ms。入力から pum 表示までを測る。
- [ ] Probe. `docs/plans/lazy-goda-tools/e2e-lsp-compare.lua` を使い、trunk と
      head を交互に 20 回ずつ実行する。`lua_ls` と `vtsls` の project で測る。
- [ ] Baseline. trunk の ddc-source-lsp の値を先に記録する。試作の最小版は
      `lua_ls` で 117 から 125ms だった。
- [ ] Rule. head の中央値が trunk の 1.10 倍を超えるか、process
      数が増えたら不合格にする。

**Review gate.** None. G5 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] review comment の triage が終わっている。
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] root が stack へ追加し、operator が bottom-up で land する。

## ddc.vim を goda-cmp へ切り替えて削除する (G6)

**Depends on.** G3、G4、G5。

**Files.**

- [ ] Edit
      `lua/plugins/goda-cmp.lua`、`lua/plugins/nvim-aibo.lua`、`lua/plugins/lspconfig.lua`、`lua/plugins/noice.lua`、`lua/plugins/nvim-autopairs.lua`。
- [ ] Edit `goda-cmp/main.go`。
- [ ] Delete `lua/plugins/ddc.lua`、`lua/plugins/ddc-*.lua`。

**Build.**

- [ ] `lua/plugins/ddc.lua` の sources、sourceOptions、sourceParams を
      `goda-cmp/main.go` へ移す。
- [ ] `<C-n>`、`<C-p>`、`<CR>`、`<C-e>` と cmdline の key
      設定を移す。`DDCCmdlineLeave` は `GodaCmpCmdlineLeave` に変える。
- [ ] `ddc_source_lsp.make_client_capabilities()` の呼び出しを削除する。Neovim
      の client は既定の capabilities を使う。
- [ ] `ddc#custom#patch_buffer` を `goda_cmp#patch_buffer` に置き換える。
- [ ] `ddc-previewer-floating` を pum.vim の `preview` と
      `goda_cmp#get_previewer` に置き換える。
- [ ] noice の `[ddc-rg]` route を新しい message に合わせる。

**You see.**

- [ ] `rg -n 'ddc' lua goda-cmp` が 0 件を返す。
- [ ] insert mode と cmdline の補完が goda-cmp で動く。

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Run `go test ./...` を `goda-cmp/` で実行する。
- [ ] Run `rg -n 'ddc|denops#callback' lua`。0 件を返す。

**Verify, live.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked. Ten lanes on
`inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. trunk と head で
      `docs/plans/lazy-goda-tools/e2e-completion.lua` を実行する。 Save
      `g6-lane1-completion.txt`. Pass when 両方の pum に `alphabetical` と
      `alphanumeric` が出る。
- [ ] Lane 2. 通常起動して `:messages` と `:checkhealth lazy` を確認する。 Save
      `g6-lane2-startup.txt`. Pass when error が 0 件で、未 install の plugin が
      0 件である。
- [ ] Lane 3. `docs/plans/lazy-goda-tools/e2e-lsp.lua` で `string.up`
      を入力する。 Save `g6-lane3-lsp.txt`. Pass when pum に `upper` が出る。
- [ ] Lane 4. noice を有効にしたまま `:ech` を入力する。 Save
      `g6-lane4-cmdline.txt`. Pass when pum に `echo` が出て、`<C-y>`
      で確定できる。
- [ ] Lane 5. `<Leader>ff` と `<Leader>fg` で telescope を開く。 Save
      `g6-lane5-telescope.txt`. Pass when smart_open と live_grep
      の両方が結果を返す。
- [ ] Lane 6. `<Leader>/`、`gS`、`<Leader>r` を初回押下する。 Save
      `g6-lane6-keys.txt`. Pass when 初回の押下で plugin が load
      され、そのまま操作が実行される。
- [ ] Lane 7. Markdown を開いて preview を起動する。 Save
      `g6-lane7-preview.txt`. Pass when browser
      に本文が表示され、編集が反映される。
- [ ] Lane 8. 日本語の buffer で `/nihongo` を検索する。 Save
      `g6-lane8-kensaku.txt`. Pass when `日本語` に一致する。
- [ ] Lane 9. `<Leader>aq` で aibo prompt を開き、`SpecialBufferCompletion`
      の補完と `<C-n>` を試す。 Save `g6-lane9-aibo.txt`. Pass when prompt
      buffer で補完が動き、pum がないときは履歴移動になる。
- [ ] Lane 10. 空の XDG で 2 回起動する。 Save `g6-lane10-bootstrap.txt`. Pass
      when 1 回目で install と build が終わり、2 回目は error が 0 件である。

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Metric. `e2e-completion.lua` の最終 key から `pum#visible()`
      が真になるまでの ms。VimEnter で load する plugin の完了までの
      ms。候補の選択から確定までの ms も測る。
- [ ] Probe. trunk と head を交互に 20
      回ずつ実行し、中央値と四分位範囲を記録する。
- [ ] Baseline. trunk の値を先に記録する。`--startuptime` の `NVIM STARTED`
      は使わない。Appendix A の通り、VimEnter で load する plugin を含まない。
- [ ] Rule. head の中央値が trunk の 1.10 倍を超えたら不合格にする。

**Review gate.** The operator reviews before merge.

- [ ] Copy lane の screenshot 相当の capture を `docs/plans/media/g6-review.txt`
      へ保存する。
- [ ] 30 から 60 秒の video を `docs/plans/media/g6-review.mp4` に保存する。
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for
      the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] review comment の triage が終わっている。
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] root が stack へ追加し、operator が bottom-up で land する。

## kensaku.vim を goda 製へ移植する (G7)

**Depends on.** G1.

**Files.**

- [ ] Create 新規 repository `airRnot1106/goda-kensaku.vim`。
- [ ] Create `lua/plugins/goda-kensaku.lua`。
- [ ] Edit `lua/plugins/kensaku-search.lua`。
- [ ] Delete `lua/plugins/kensaku.lua`。

**Build.**

- [ ] `koron/gomigemo` を使い、`kensaku#query` 相当の API を Go で実装する。
- [ ] `kensaku-search.vim` の `kensaku#query` 呼び出しを新しい API
      へ向ける。上流の変更が必要なら同じ repository に移す。
- [ ] `<Plug>(kensaku-search-replace)` を維持する。

**You see.**

- [ ] `/nihongo` が `日本語` に一致する。

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Run `go test ./...` を新規 repository で実行する。kensaku.vim と同じ query
      を golden test にする。

**Verify, live.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked. Ten lanes on
`inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. trunk の kensaku と head で 30 語の
      romaji query を比べる。 Save `g7-lane1-kensaku.txt`. Pass when 30
      語すべてで同じ語に一致する。
- [ ] Lane 2. 通常起動して `:messages` と `:checkhealth lazy` を確認する。 Save
      `g7-lane2-startup.txt`. Pass when error が 0 件で、未 install の plugin が
      0 件である。
- [ ] Lane 3. `docs/plans/lazy-goda-tools/e2e-lsp.lua` で `string.up`
      を入力する。 Save `g7-lane3-lsp.txt`. Pass when pum に `upper` が出る。
- [ ] Lane 4. noice を有効にしたまま `:ech` を入力する。 Save
      `g7-lane4-cmdline.txt`. Pass when pum に `echo` が出て、`<C-y>`
      で確定できる。
- [ ] Lane 5. `<Leader>ff` と `<Leader>fg` で telescope を開く。 Save
      `g7-lane5-telescope.txt`. Pass when smart_open と live_grep
      の両方が結果を返す。
- [ ] Lane 6. `<Leader>/`、`gS`、`<Leader>r` を初回押下する。 Save
      `g7-lane6-keys.txt`. Pass when 初回の押下で plugin が load
      され、そのまま操作が実行される。
- [ ] Lane 7. Markdown を開いて preview を起動する。 Save
      `g7-lane7-preview.txt`. Pass when browser
      に本文が表示され、編集が反映される。
- [ ] Lane 8. 日本語の buffer で `/nihongo` を検索する。 Save
      `g7-lane8-kensaku.txt`. Pass when `日本語` に一致する。
- [ ] Lane 9. `<Leader>aq` で aibo prompt を開き、補完と `<C-n>` を試す。 Save
      `g7-lane9-aibo.txt`. Pass when prompt buffer で補完が動き、pum
      がないときは履歴移動になる。
- [ ] Lane 10. 空の XDG で 2 回起動する。 Save `g7-lane10-bootstrap.txt`. Pass
      when 1 回目で install と build が終わり、2 回目は error が 0 件である。

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Metric. 初回 query と 2 回目以降の query の ms。辞書の load 時間を含める。
- [ ] Probe. trunk と head を交互に 20 回ずつ実行する。
- [ ] Baseline. trunk の kensaku.vim の値を先に記録する。
- [ ] Rule. 初回の中央値が 500ms を超えるか、2 回目以降が trunk の 1.10
      倍を超えたら不合格にする。

**Review gate.** The operator reviews before merge.

- [ ] Copy lane の screenshot 相当の capture を `docs/plans/media/g7-review.txt`
      へ保存する。
- [ ] 30 から 60 秒の video を `docs/plans/media/g7-review.mp4` に保存する。
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for
      the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] review comment の triage が終わっている。
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] root が stack へ追加し、operator が bottom-up で land する。

## fuzzy-motion.vim を goda 製へ移植する (G8)

**Depends on.** G7.

**Files.**

- [ ] Create 新規 repository `airRnot1106/goda-fuzzy-motion.vim`。
- [ ] Create `lua/plugins/goda-fuzzy-motion.lua`。
- [ ] Delete `lua/plugins/fuzzy-motion.lua`。

**Build.**

- [ ] `fuzzy-motion.vim` の 525 行を移植する。
- [ ] `kensaku` と fzf の matcher を G7 の API と Go の fuzzy matcher
      で実装する。
- [ ] `<Leader>;` と `:FuzzyMotion` を維持する。

**You see.**

- [ ] `<Leader>;` で label が表示され、romaji で日本語へ移動できる。

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Run `go test ./...` を新規 repository で実行する。label の割り当てと
      matcher の順位を検証する。

**Verify, live.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked. Ten lanes on
`inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. trunk と head で
      `docs/plans/lazy-goda-tools/e2e-completion.lua` を実行する。 Save
      `g8-lane1-completion.txt`. Pass when 両方の pum に `alphabetical` と
      `alphanumeric` が出る。
- [ ] Lane 2. 通常起動して `:messages` と `:checkhealth lazy` を確認する。 Save
      `g8-lane2-startup.txt`. Pass when error が 0 件で、未 install の plugin が
      0 件である。
- [ ] Lane 3. `docs/plans/lazy-goda-tools/e2e-lsp.lua` で `string.up`
      を入力する。 Save `g8-lane3-lsp.txt`. Pass when pum に `upper` が出る。
- [ ] Lane 4. noice を有効にしたまま `:ech` を入力する。 Save
      `g8-lane4-cmdline.txt`. Pass when pum に `echo` が出て、`<C-y>`
      で確定できる。
- [ ] Lane 5. `<Leader>ff` と `<Leader>fg` で telescope を開く。 Save
      `g8-lane5-telescope.txt`. Pass when smart_open と live_grep
      の両方が結果を返す。
- [ ] Lane 6. `<Leader>;` を初回押下し、英語と romaji の両方で移動する。 Save
      `g8-lane6-fuzzy-motion.txt`. Pass when 初回の押下で起動し、選択した位置へ
      cursor が移動する。
- [ ] Lane 7. Markdown を開いて preview を起動する。 Save
      `g8-lane7-preview.txt`. Pass when browser
      に本文が表示され、編集が反映される。
- [ ] Lane 8. 日本語の buffer で `/nihongo` を検索する。 Save
      `g8-lane8-kensaku.txt`. Pass when `日本語` に一致する。
- [ ] Lane 9. `<Leader>aq` で aibo prompt を開き、補完と `<C-n>` を試す。 Save
      `g8-lane9-aibo.txt`. Pass when prompt buffer で補完が動き、pum
      がないときは履歴移動になる。
- [ ] Lane 10. 空の XDG で 2 回起動する。 Save `g8-lane10-bootstrap.txt`. Pass
      when 1 回目で install と build が終わり、2 回目は error が 0 件である。

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Metric. `<Leader>;` の押下から label 表示までの ms。
- [ ] Probe. 10000 行の buffer で trunk と head を交互に 20 回ずつ実行する。
- [ ] Baseline. trunk の fuzzy-motion.vim の値を先に記録する。
- [ ] Rule. head の中央値が trunk の 1.10 倍を超えたら不合格にする。

**Review gate.** The operator reviews before merge.

- [ ] Copy lane の screenshot 相当の capture を `docs/plans/media/g8-review.txt`
      へ保存する。
- [ ] 30 から 60 秒の video を `docs/plans/media/g8-review.mp4` に保存する。
- [ ] Post the screenshots and the video in chat. Stop at merge-ready. Wait for
      the operator's click.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] review comment の triage が終わっている。
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] root が stack へ追加し、operator が bottom-up で land する。

## denops.vim と Deno を削除する (Z1)

**Depends on.** G1、G6、G8。

**Files.**

- [ ] Delete `lua/plugins/denops.lua`。
- [ ] Edit `flake.nix`、`nix/treefmt.nix`、`flake.lock`。
- [ ] Delete `docs/plans/`。移行の記録は git の履歴に残る。
- [ ] Delete `~/.cache/dpp` は operator が確認してから実行する。

**Build.**

- [ ] `deno` を devShell から外す。
- [ ] treefmt の `deno.enable` を外す。TypeScript がなくなったため不要になる。
- [ ] `rg -n -i 'denops|deno' --glob '!flake.lock' .` が 0
      件になるまで参照を消す。LSP の `denols` は別の用途なので残す。

**You see.**

- [ ] Neovim の実行中に `deno` process が 0 個である。
- [ ] `PATH` から Deno を外しても全 lane が通る。

**Verify, unit.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Run `nix flake check`。
- [ ] Run `PATH` から Deno を除いた状態で
      `docs/plans/lazy-goda-tools/e2e-completion.lua`。

**Verify, live.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked. Ten lanes on
`inherit-parent` at the PR head, per the boot recipe.

- [ ] Lane 1. Regression lane against trunk. trunk と head で
      `docs/plans/lazy-goda-tools/e2e-completion.lua` を実行する。 Save
      `z1-lane1-completion.txt`. Pass when 両方の pum に `alphabetical` と
      `alphanumeric` が出る。
- [ ] Lane 2. 通常起動して `:messages` と `:checkhealth lazy` を確認する。 Save
      `z1-lane2-startup.txt`. Pass when error が 0 件で、未 install の plugin が
      0 件である。
- [ ] Lane 3. `docs/plans/lazy-goda-tools/e2e-lsp.lua` で `string.up`
      を入力する。 Save `z1-lane3-lsp.txt`. Pass when pum に `upper` が出る。
- [ ] Lane 4. noice を有効にしたまま `:ech` を入力する。 Save
      `z1-lane4-cmdline.txt`. Pass when pum に `echo` が出て、`<C-y>`
      で確定できる。
- [ ] Lane 5. `<Leader>ff` と `<Leader>fg` で telescope を開く。 Save
      `z1-lane5-telescope.txt`. Pass when smart_open と live_grep
      の両方が結果を返す。
- [ ] Lane 6. `<Leader>/`、`gS`、`<Leader>r` を初回押下する。 Save
      `z1-lane6-keys.txt`. Pass when 初回の押下で plugin が load
      され、そのまま操作が実行される。
- [ ] Lane 7. Markdown を開いて preview を起動する。 Save
      `z1-lane7-preview.txt`. Pass when browser
      に本文が表示され、編集が反映される。
- [ ] Lane 8. 日本語の buffer で `/nihongo` を検索する。 Save
      `z1-lane8-kensaku.txt`. Pass when `日本語` に一致する。
- [ ] Lane 9. `<Leader>aq` で aibo prompt を開き、補完と `<C-n>` を試す。 Save
      `z1-lane9-aibo.txt`. Pass when prompt buffer で補完が動き、pum
      がないときは履歴移動になる。
- [ ] Lane 10. Deno と dpp の cache がない空の XDG で 2 回起動する。 Save
      `z1-lane10-no-deno.txt`. Pass when 全機能が動き、`pgrep deno` が 0
      件である。

**Verify, perf.** Tests alone are not sufficient verification. A PR is verified
only when its unit, live, and perf boxes are all checked.

- [ ] Metric. `e2e-completion.lua` の最終 key から `pum#visible()`
      が真になるまでの ms。VimEnter で load する plugin の完了までの ms。常駐
      process の RSS 合計も測る。
- [ ] Probe. trunk と head を交互に 20
      回ずつ実行し、中央値と四分位範囲を記録する。
- [ ] Baseline. trunk の値を先に記録する。`--startuptime` の `NVIM STARTED`
      は使わない。Appendix A の通り、VimEnter で load する plugin を含まない。
- [ ] Rule. head の中央値が trunk の 1.10 倍を超えたら不合格にする。

**Review gate.** None. Z1 is not review-gated.

**Merge.**

- [ ] Root's clean verdict at the exact head SHA.
- [ ] review comment の triage が終わっている。
- [ ] Rebased onto current trunk after the verdict, patch-id unchanged.
- [ ] root が stack へ追加し、operator が bottom-up で land する。

## Close the program

- [ ] Every box above is checked with its evidence.
- [ ] Reply to the operator with the report the execution playbook names.

## Appendix A. Prototype evidence

試作は 2026-11-07 に scratchpad の隔離 XDG
で実行した。実際の設定は変更していない。検証環境は macOS arm64、Neovim
v0.13.0-nightly+6332ba6、Go 1.26.4 である。

| 問い                                          | 結果                                                                               | 根拠                                                   |
| --------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------ |
| spec を codemod で変換できるか                | できた。72 個すべてが install された。                                             | `docs/plans/lazy-goda-tools/dpp2lazy.pl`               |
| ddc は lazy.nvim 上で動くか                   | 動いた。dpp と同じ入力で pum が出た。                                              | `docs/plans/lazy-goda-tools/e2e-completion.lua`        |
| goda-cmp は lazy.nvim 上で動くか              | 動いた。`alph` で `alphabetical` と `alphanumeric` が出た。                        | `docs/plans/lazy-goda-tools/goda-cmp-proto/`           |
| LSP 補完は動くか                              | 動いた。buffer にない `upper` が `string.up` から出た。                            | `docs/plans/lazy-goda-tools/e2e-lsp.lua`               |
| Neovim の client を Go の source から使えるか | 使えた。143 行の最小版で `upper` が出た。12 回の表示時間は 117 から 125ms だった。 | `docs/plans/lazy-goda-tools/goda-cmp-proto/nvimlsp.go` |
| 自作 source で snippet を展開できるか         | できた。`function ()` が展開され、`vim.snippet.active()` が真になった。            | `docs/plans/lazy-goda-tools/e2e-lsp-compare.lua`       |
| 実行時に Go は必要か                          | 不要だった。Go を PATH から外した起動でも binary は起動した。                      | e2e 実行                                               |
| 版の正本を lazy に寄せられるか                | できた。`go.work` は lazy の clone を参照し、build で `go.mod` は変わらなかった。  | 生成された `go.work`                                   |
| gmp.vim は build できるか                     | できた。`nix build` は成功した。                                                   | Nix store の出力                                       |

未検証の項目は次の通りである。

- 実 terminal での描画と noice との併用は試していない。
- goda-cmp の cmdline 補完は試していない。
- 移植が必要な source と filter は 1 つも動かしていない。
- 自作の LSP source は `lua_ls` の最小版だけを試した。resolve、`textEdit`
  の範囲、`itemDefaults`、複数 client、request の取り消しは未実装である。
- ddc と自作 source の速度は比較していない。
- 同梱 source は一括入力の試験で pum が出ず、遅延を測れなかった。1
  文字ずつの入力では動いた。原因は未確定である。
- 起動時間の比較は判断材料にならない。7 回の `NVIM STARTED` は dpp が 18.8 から
  21.4ms、lazy.nvim が 18.9 から 20.7ms だったが、log に
  telescope、noice、barbar の読み込みが 0 行だった。VimEnter 後の load
  を測っていない。

lazy.nvim 版の pum には、dpp 版の先頭にあった `alphabetical = 1`
が出なかった。隔離環境に Copilot の認証がないためと推測している。M1 の lane 1
で確認する。

## Appendix B. Alternatives rejected

goda-pm.vim は dpp.vim の後継で、`g:goda#workspace` も自動で設定する。しかし
operator は lazy.nvim を指定した。goda-pm.vim の repository は 2026-10-31
に作られたばかりで、lua の spec をそのまま読めない。

goda-cmp 同梱の `ext/source/lsp` は使わない。この source は Neovim の client
とは別に server を起動するため、process が server ごとに増える。snippet
も要求しない。22 server の設定を Go へ複製する必要があり、そのうち 10 個は
`root_dir` が関数で、9 個は `cmd` が関数である。自作の source なら設定は
`after/lsp/` と `lua/plugins/lspconfig.lua` の 1 か所に残る。代償は、実用版で
400 から 600 行と見込むコードの保守である。この行数は試作からの推測である。

Go を nix profile に入れる案も、operator の判断で取らない。Go はこの repository
の `flake.nix` だけで管理する。

dpp.vim のまま goda へ移す順序は取らない。dpp.vim 自体が denops
を必要とするため、Deno を削除できない。

dpp.vim と lazy.nvim を共存させる期間は作らない。`lua/plugins/*.lua`
の形式が異なり、互換層は捨てるコードになる。

## Appendix C. Risks

- **goda の API が変わる。** README は status を early としている。goda-cmp の
  bundled extension は 1.0 で別 repository へ移り、import path が変わる。G2
  以降の owner は tag と `doc/` の差分を確認する。
- **macOS は上流の自動 test の対象外である。** 上流の README が Windows と macOS
  を未確認としている。試作では動いたが、G6 の lane で確認する。
- **source の panic が補完全体を止める。** 全 source は 1 つの binary
  で動く。試作では `lsp.Params{}` の設定誤りで binary が落ち、pum
  が出なくなった。G3 から G5 の owner は panic を test する。
- **`goda.vim` だけの更新で binary が古くなる。** handshake が古い binary
  を拒否する。G2 で両方の更新に再 build を設定する。
- **lazy.nvim の更新が止まっている。** 最新 release は 2025-11-06、最新 commit
  は 2025-12-17 である。試作では nightly で動いた。M1 の owner は起動時の
  deprecation を確認する。
- **lazy.nvim の `git.cooldown` は commit の経過日数を見ない。** これは fetch
  の再実行間隔である。`minCommitDays` の代わりにならないため M2 を置く。
- **`performance.rtp.reset` が `~/.nix-profile/share/nvim/site` を外す。**
  ここには `fzf.vim` だけがある。設定からの利用は見つかっていない。M1 の lane 2
  で確認する。
- **空の `DENO_DIR` では ddc-path の読み込みが失敗した。** Deno は DNS error
  を出し、同じ URL への curl は 404 を返した。原因は未確定である。M1 では
  `DENO_DIR` を維持する。G6 で ddc-path は消える。
- **自作 source は polling で結果を受け取る。** Go は 5ms ごとに Lua
  へ問い合わせる。試作では動いたが、重い server では未確認である。G5 の perf で
  `vtsls` を測る。
- **goda-cmp の Source interface が変わると自作 source も直す。** 上流は early
  である。G5 の owner は `cmp/types.go` の差分を確認する。
- **Go のない環境で更新すると補完が止まる場合がある。** Go は devShell
  にだけある。別の directory で `:Lazy update` を実行すると build
  が失敗する。goda-cmp の Vim script だけが新しくなると、binary
  は版の不一致で拒否される。更新はこの repository で実行する。
- **TUI 用の control skill がない。** `cursor-team-kit` は未導入である。lane は
  `tmux` で駆動し、capture はテキストで保存する。
- **`build` の失敗に気づきにくい。** function 形式の build は `E117`
  を出したが、`Lazy! install` は exit 0 だった。G2 の lane 10 は binary
  の存在を確認する。

## Appendix D. Links and reading list

- [Shougo/goda.vim](https://github.com/Shougo/goda.vim)
- [Shougo/goda-cmp.vim](https://github.com/Shougo/goda-cmp.vim)
- [Shougo/goda-pm.vim](https://github.com/Shougo/goda-pm.vim)
- [airRnot1106/gmp.vim](https://github.com/airRnot1106/gmp.vim)
- [koron/gomigemo](https://github.com/koron/gomigemo)
- [folke/lazy.nvim](https://github.com/folke/lazy.nvim)

G5 と G6 の前に `how` と `interrogate` の skill を使う。decision trail は
`show-me-your-work` の skill に従う。
