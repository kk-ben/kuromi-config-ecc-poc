# Kuromi `~/.claude/` × ECC × Superpowers 統合 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ECC OSS full stack を `~/.claude/` に install し、test repo `kuromi-config-ecc-poc` に a-1 (CLAUDE.md rule-based) と a-2 (hook-based 物理強制) を branch 切って push、ECC Tools GitHub App AgentShield review で判定、勝者を本体 `~/.claude/CLAUDE.md` に反映。

**Architecture:** 4 層 stack (L1 Persona keep / L2 superpowers keep / **L3 ECC NEW** / L4 Domain keep)。test repo は public、ECC App は test repo のみ install、AgentShield-backed PR review を判定者とする。

**Tech Stack:** Node.js + npm (ecc-universal) / git + gh CLI / bash / Claude Code hooks / GitHub PR

**Source spec:** `docs/superpowers/specs/2026-05-15-kuromi-ecc-integration-design.md`

---

## File Structure

新規 file (本 plan で作成):
- `/Users/kkben/Projects/kuromi-config-ecc-poc/` 配下 test repo 全体
  - `README.md` — 目的 + a-1/a-2 比較表 placeholder
  - `CLAUDE.md` — main = base、`feat/a-1-rule-based` で rule 追加、`feat/a-2-hook-based` で参照のみ追加
  - `agents/` — ECC cherry-pick 15 体
  - `commands/` — ECC cherry-pick 18 個
  - `rules/common/` — ECC `rules/common/` 全部
  - `hooks-snippets/superpowers-ecc-bridge.js` — a-2 branch のみ追加
  - `.gitignore`
- `~/.claude.bak-YYYYMMDD-HHMMSS/` — backup (= 全 `~/.claude/` 全 cp)

変更 file:
- `~/.claude/agents/` — ECC 由来 60 file 配備
- `~/.claude/commands/` — ECC 由来 75 file 配備
- `~/.claude/skills/` — ECC 由来 ~200 skill 配備 (既存 40 keep)
- `~/.claude/rules/common/` — ECC 由来 配備（新規 dir）
- `~/.claude/research/` — ECC research-pack（新規 dir）
- `~/.claude/CLAUDE.md` — Phase 12 で判定結果 append（persona section untouched）
- `~/.claude/settings.json` — Phase 13 で ECC hooks 並列 merge

絶対 touch しない (redzone):
- `~/.claude/CLAUDE.md` の persona / サボり防止 / えびルール / 既知のバグ section
- `/Users/kkben/Projects/Claude-Code-Communication/.claude/hooks/*.js` (くろみ既存 hook 26+)
- `~/.claude/hooks/stop-hook-task-diary.sh`
- `~/.claude/skills/{ebi-*,nemoclaw-*,api-*,obsidian-*,sentry-*,defuddle,baoyu-imagine,ppt-generation,video-editing,document-skills,task-diary,...}`
- `~/.claude/templates/design-docs/`
- `~/.claude/projects/-Users-kkben/memory/`
- superpowers plugin (`~/.claude/plugins/cache/claude-plugins-official/superpowers/`)

---

## Phase 0: Backup + Pre-flight (10 min)

### Task 0.1: timestamped backup 作成

**Files:**
- Create: `~/.claude.bak-<timestamp>/` (cp -r で全コピー)

- [ ] **Step 1: backup 実行**

```bash
TS=$(date +%Y%m%d-%H%M%S)
cp -r ~/.claude ~/.claude.bak-${TS}
echo "backup: ~/.claude.bak-${TS}"
```

- [ ] **Step 2: size + file count verify**

```bash
ORIG_SIZE=$(du -sk ~/.claude | awk '{print $1}')
BAK_SIZE=$(du -sk ~/.claude.bak-${TS} | awk '{print $1}')
ORIG_COUNT=$(find ~/.claude -type f | wc -l)
BAK_COUNT=$(find ~/.claude.bak-${TS} -type f | wc -l)
echo "orig: ${ORIG_SIZE}KB / ${ORIG_COUNT} files"
echo "bak:  ${BAK_SIZE}KB / ${BAK_COUNT} files"
```

Expected: size 差 ±10% 以内、file count 完全一致

### Task 0.2: settings.json + CLAUDE.md 個別 backup（即 rollback 用）

- [ ] **Step 1: 個別 backup**

```bash
TS=$(date +%Y%m%d-%H%M%S)
cp ~/.claude/settings.json ~/.claude/settings.json.bak-pre-ecc-${TS}
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak-pre-ecc-${TS}
ls -la ~/.claude/*.bak-pre-ecc-${TS}
```

Expected: 2 file 存在、size 元 file と一致

### Task 0.3: 前提環境 verify

- [ ] **Step 1: 必須コマンド存在**

```bash
which node npm git gh
node --version
npm --version
gh --version | head -1
```

Expected: 全 exit 0、Node >=18

- [ ] **Step 2: gh auth status**

```bash
gh auth status 2>&1 | head -5
```

Expected: `Logged in to github.com as kk-ben` 表示

- [ ] **Step 3: GitHub user の repo 作成権限**

```bash
gh api user --jq .login
```

Expected: `kk-ben`

---

## Phase 1: ecc-universal install (5 min)

### Task 1.1: ecc-universal global install

**Files:** npm global、`/opt/homebrew/lib/node_modules/ecc-universal/`

- [ ] **Step 1: install**

```bash
npm install -g ecc-universal 2>&1 | tail -10
```

Expected: `added N packages` 表示、error なし

- [ ] **Step 2: verify**

```bash
which ecc-universal
ecc-universal --version
```

Expected: `/opt/homebrew/bin/ecc-universal`、version 番号表示

- [ ] **Step 3: help 確認**

```bash
ecc-universal --help 2>&1 | head -30
```

Expected: install / auth / doctor / uninstall 等 subcommand 表示

### Task 1.2: install 失敗時の fallback path 検討

- [ ] **Step 1: もし npm install -g 失敗 → clone 経由 install**

```bash
# fallback (npm 失敗時のみ)
cd /tmp/everything-claude-code
node scripts/install-plan.js --help 2>&1 | head
```

Expected: `--profile` `--add` `--remove` `--dry-run` 等 flag 表示

---

## Phase 2: Pro auth (5 min)

### Task 2.1: ecc.tools/account で Pro tier 状態 verify (katsu 操作)

- [ ] **Step 1: katsu 手動 verify**

→ katsu に `https://ecc.tools/account` を開いてもらう
→ `kanto.eco@gmail.com` でログイン
→ Pro plan active 確認
→ subscription status: active / canceled / expired のどれか報告

Expected: status=`active`

### Task 2.2: ecc-universal auth login

- [ ] **Step 1: interactive auth**

```bash
ecc-universal auth login
# → email 入力: kanto.eco@gmail.com
# → device code or browser auth (CLI が指示)
```

Expected: `Logged in as kanto.eco@gmail.com (tier: pro)` 等の表示

- [ ] **Step 2: tier verify**

```bash
ecc-universal auth status
```

Expected: `tier=pro` または `enterprise` 含む出力

---

## Phase 3: Dry-run review (10 min)

### Task 3.1: developer + security + research profile dry-run

**Files:** dry-run、`~/.claude/` 実 file 変更なし

- [ ] **Step 1: dry-run 実行**

```bash
cd /tmp/everything-claude-code
node scripts/install-plan.js --profile developer --add security --add research --dry-run 2>&1 | tee /tmp/ecc-dryrun-output.txt
wc -l /tmp/ecc-dryrun-output.txt
```

Expected: 出力 200+ 行、変更予定 file 一覧 + 衝突なし表示

- [ ] **Step 2: 衝突 file 抽出**

```bash
grep -i "conflict\|overwrite\|exists" /tmp/ecc-dryrun-output.txt | head -30
```

Expected: 衝突 0 件、または既存 skill (ebi-* / nemoclaw-* 等) との重複 0 件

### Task 3.2: 配備予定 file 一覧化

- [ ] **Step 1: agents / commands / skills / rules 数 count**

```bash
grep -E "^\s+(create|add|install).*\.claude/agents/" /tmp/ecc-dryrun-output.txt | wc -l
grep -E "^\s+(create|add|install).*\.claude/commands/" /tmp/ecc-dryrun-output.txt | wc -l
grep -E "^\s+(create|add|install).*\.claude/skills/" /tmp/ecc-dryrun-output.txt | wc -l
grep -E "^\s+(create|add|install).*\.claude/rules/" /tmp/ecc-dryrun-output.txt | wc -l
```

Expected: agents ~60, commands ~75, skills ~228, rules ~10+

### Task 3.3: 衝突 / 警告あれば katsu に判断仰ぐ (gate)

- [ ] **Step 1: 警告 0 → Phase 4 へ続行**
- [ ] **Step 1 (alt): 警告 >0 → 各警告を katsu に提示、対応決定**

Decision tree:
- 衝突 file が ECC 公式 SKILL.md と既存 ebi-* SKILL.md の場合 → 既存 keep 優先
- 衝突なし → 続行

---

## Phase 4: Full install (15 min)

### Task 4.1: developer profile install

- [ ] **Step 1: 本 install**

```bash
cd /tmp/everything-claude-code
node scripts/install-plan.js --profile developer
node scripts/install-apply.js 2>&1 | tail -30
```

Expected: `Successfully installed` 表示、error 0

- [ ] **Step 2: agents 配備 verify**

```bash
ls ~/.claude/agents/ | wc -l
ls ~/.claude/agents/planner.md ~/.claude/agents/code-reviewer.md ~/.claude/agents/tdd-guide.md
```

Expected: file count >= 25、3 file 存在

- [ ] **Step 3: commands 配備 verify**

```bash
ls ~/.claude/commands/ | wc -l
ls ~/.claude/commands/plan.md ~/.claude/commands/tdd.md ~/.claude/commands/code-review.md
```

Expected: file count >= 50、3 file 存在

### Task 4.2: security profile 追加 install

- [ ] **Step 1: AgentShield-pack 追加**

```bash
node scripts/install-plan.js --add security-audits
node scripts/install-apply.js 2>&1 | tail -10
```

Expected: `everything-claude-code-guardrails.md` 配備表示

- [ ] **Step 2: AgentShield 配置 verify**

```bash
ls ~/.claude/rules/everything-claude-code-guardrails.md
head -20 ~/.claude/rules/everything-claude-code-guardrails.md
```

Expected: file 存在、AgentShield 由来の guardrails 内容表示

### Task 4.3: research profile 追加 install

- [ ] **Step 1: research-pack 追加**

```bash
node scripts/install-plan.js --add research-tooling
node scripts/install-apply.js 2>&1 | tail -10
```

Expected: `everything-claude-code-research-playbook.md` 配備表示

- [ ] **Step 2: research playbook verify**

```bash
ls ~/.claude/research/everything-claude-code-research-playbook.md
wc -l ~/.claude/research/everything-claude-code-research-playbook.md
```

Expected: file 存在、>=50 行

### Task 4.4: rules/common/ verify

- [ ] **Step 1: rules dir 確認**

```bash
ls ~/.claude/rules/common/ 2>/dev/null
# or wherever ECC places rules
find ~/.claude/rules -type f 2>/dev/null | head -20
```

Expected: security.md / testing.md / coding-style.md / git-workflow.md / patterns.md / performance.md 等

### Task 4.5: 既存くろみ asset の生存 verify

- [ ] **Step 1: ebi-* / nemoclaw-* skill 残ってる確認**

```bash
ls ~/.claude/skills/ | grep -E "^(ebi-|nemoclaw-)" | wc -l
ls ~/.claude/skills/nemoclaw-skills-guide/
ls ~/.claude/skills/ebi-architecture/
```

Expected: count >= 15、ebi-* と nemoclaw-* dir 健在

- [ ] **Step 2: hooks path 健全**

```bash
ls /Users/kkben/Projects/Claude-Code-Communication/.claude/hooks/ | wc -l
test -f /Users/kkben/Projects/Claude-Code-Communication/.claude/hooks/soul-ping.js && echo "OK"
```

Expected: file count >= 30、soul-ping.js 存在

- [ ] **Step 3: settings.json JSON 構文**

```bash
node -e "JSON.parse(require('fs').readFileSync('/Users/kkben/.claude/settings.json'))" && echo "JSON OK"
```

Expected: `JSON OK`

### Task 4.6: 配備 final count

- [ ] **Step 1: 最終 count**

```bash
echo "=== After full install ==="
echo "agents: $(ls ~/.claude/agents/ 2>/dev/null | wc -l)"
echo "commands: $(ls ~/.claude/commands/ 2>/dev/null | wc -l)"
echo "skills: $(ls ~/.claude/skills/ 2>/dev/null | wc -l)"
echo "rules: $(find ~/.claude/rules -type f 2>/dev/null | wc -l)"
echo "research: $(find ~/.claude/research -type f 2>/dev/null | wc -l)"
```

Expected: agents=60, commands=75, skills=268 (228 ECC + 40 既存), rules>=10, research>=1

---

## Phase 5: Local kuromi persona 整合性 verify (10 min)

### Task 5.1: 新規 session 起動 test

- [ ] **Step 1: katsu に新規 Claude Code session を開いてもらう**

→ 別 terminal で `claude` 起動 (or 別 session start)
→ プロンプト「health check」と入力
→ Response 観察

Expected:
- soul-ping hook 発動 (= 関西弁 reminder 表示)
- くろみペルソナで応答（「くろみ」一人称、関西弁、絵文字なし）
- ECC agents / commands が `~/.claude/agents/` / `~/.claude/commands/` で load される（list で見える）

### Task 5.2: persona-linter / kansai-score 正常動作

- [ ] **Step 1: Stop hook log 確認**

```bash
tail -20 ~/.claude/logs/*.log 2>/dev/null | head -30
# or check telemetry
ls ~/.claude/telemetry/ 2>/dev/null | tail -3
```

Expected: persona-linter / kansai-score の log entry 存在、違反 0

### Task 5.3: /plan command 動作 test

- [ ] **Step 1: katsu に新 session で `/plan test feature` 試してもらう**

Expected:
- `/plan` slash command が認識される
- planner agent dispatch される
- ECC planner agent output 表示（くろみペルソナ的修正ありで）
- persona-linter PASS

- [ ] **Step 2: 異常時 rollback 判断**

If 異常 (persona 崩壊 / planner 暴走 / hook 失敗):
```bash
TS_BAK=$(ls -td ~/.claude.bak-* | head -1 | sed 's|.*\.bak-||')
mv ~/.claude ~/.claude.broken-${TS_BAK}
mv ~/.claude.bak-${TS_BAK} ~/.claude
```
→ Phase 0 backup へ巻き戻し、Phase 4 やり直し

---

## Phase 6: Test repo content 作成 (15 min)

### Task 6.1: git init + branch 設計

**Files:**
- Create: `/Users/kkben/Projects/kuromi-config-ecc-poc/.git/`

- [ ] **Step 1: git init**

```bash
cd /Users/kkben/Projects/kuromi-config-ecc-poc
git init -b main
git config user.email "kanto.eco@gmail.com"
git config user.name "kk-ben"
```

Expected: `Initialized empty Git repository in ...`

### Task 6.2: README.md 起稿

**Files:** Create `kuromi-config-ecc-poc/README.md`

- [ ] **Step 1: README 書く**

Write `README.md`:

```markdown
# kuromi-config-ecc-poc

`~/.claude/` 設定の ECC 統合 PoC repo。

## 目的

ECC Tools GitHub App AgentShield review に **a-1 (CLAUDE.md rule-based)** vs **a-2 (hook-based 物理強制)** のどちらが best か判定させる。

## scope (A minimal)

- `CLAUDE.md` (a-1 branch で rule 追加 / a-2 branch で hook 参照のみ追加)
- `agents/` ECC cherry-pick 15 体
- `commands/` ECC cherry-pick 18
- `rules/common/` ECC `rules/common/` 全部
- `hooks-snippets/` (a-2 branch のみ) hook script

含めない: hook 実体 js / settings.json / 業務 skill / `.env` / handoff / memory

## branch

| branch | 内容 |
|--------|------|
| `main` | base (CLAUDE.md = persona + 空 integration rule) |
| `feat/a-1-rule-based` | CLAUDE.md に a-1 ルール追加 |
| `feat/a-2-hook-based` | hooks-snippets/ + CLAUDE.md 参照追加 |

## ECC Tools review

PR を main に対して open → `/ecc-tools analyze` コメント → AgentShield-backed PR 自動生成。

## design + plan

- spec: `docs/superpowers/specs/2026-05-15-kuromi-ecc-integration-design.md`
- plan: `docs/superpowers/plans/2026-05-15-kuromi-ecc-integration-plan.md`
```

- [ ] **Step 2: 書いた verify**

```bash
ls /Users/kkben/Projects/kuromi-config-ecc-poc/README.md
wc -l /Users/kkben/Projects/kuromi-config-ecc-poc/README.md
```

Expected: 行数 ~30

### Task 6.3: agents/ cherry-pick 15 体

**Files:** Copy from `~/.claude/agents/` to `kuromi-config-ecc-poc/agents/`

- [ ] **Step 1: 15 agent cp**

```bash
cd /Users/kkben/Projects/kuromi-config-ecc-poc
for a in planner code-reviewer tdd-guide security-reviewer architect \
         build-error-resolver refactor-cleaner doc-updater \
         silent-failure-hunter performance-optimizer type-design-analyzer \
         database-reviewer docs-lookup harness-optimizer loop-operator; do
  cp ~/.claude/agents/${a}.md agents/ 2>&1 | head
done
ls agents/ | wc -l
```

Expected: 15 file

### Task 6.4: commands/ cherry-pick 18

- [ ] **Step 1: 18 command cp**

```bash
for c in plan tdd code-review build-fix quality-gate test-coverage \
         learn learn-eval promote skill-create skill-health \
         harness-audit aside checkpoint resume-session save-session sessions \
         verify; do
  cp ~/.claude/commands/${c}.md commands/ 2>&1 | head
done
ls commands/ | wc -l
```

Expected: 18 file

### Task 6.5: rules/common/ 全部 cp

- [ ] **Step 1: rules 全部 cp**

```bash
mkdir -p rules/common
# ECC install 時の path 確認
find ~/.claude/rules -name "common" -type d 2>/dev/null
# 見つかった source から cp
cp -r ~/.claude/rules/common/* rules/common/ 2>&1 | head
ls rules/common/
```

Expected: security.md / testing.md / coding-style.md / git-workflow.md 等 8+ file

### Task 6.6: main branch 用 CLAUDE.md 起稿 (= base、persona keep + 空 rule)

**Files:** Create `kuromi-config-ecc-poc/CLAUDE.md`

- [ ] **Step 1: CLAUDE.md base 版 write**

Write:

```markdown
# kuromi `~/.claude/` config — Test PoC

これは PoC test repo です。本体 `~/.claude/CLAUDE.md` の subset を含みます (機微情報除く)。

## ペルソナ (絶対 redzone、touch 禁止)

くろみ = 関西弁エンジニア、技術真面目、絵文字なし、katsu にタメ口。
一人称「くろみ」、「〜やねん」「ええやん」「せやな」「やろ」「しとる」等使用。

## superpowers × ECC 連携ルール

このセクションは **branch ごとに差し替え**:
- `main` = 空（base）
- `feat/a-1-rule-based` = a-1 rule (CLAUDE.md に明示)
- `feat/a-2-hook-based` = a-2 hook 参照のみ

## 基本原則 (= 本体 CLAUDE.md からの subset)

1. 完全自動実行 — 危険操作以外は確認せず即座実行
2. 動いているものを壊さない
3. 単純を複雑にしない
4. 必要最小限で最大の結果

## サボり防止 (subset)

- 公式 doc は 100% 読む
- CLI コマンドある時は使う、設定 file 直接編集禁止
- 失敗は正直に認める、バックアップから即復旧
- 認証パターン: `sk-/api-key` = API key、`oauth/auth-profiles` = OAuth (サブスク = OAuth 必須)

## 既知のバグ (subset)

Claude Code TUI scrollback duplication — `~/.claude/settings.json` の env で `CLAUDE_CODE_NO_FLICKER=1` 永続化済。
```

- [ ] **Step 2: 書いた verify**

```bash
ls /Users/kkben/Projects/kuromi-config-ecc-poc/CLAUDE.md
wc -l /Users/kkben/Projects/kuromi-config-ecc-poc/CLAUDE.md
```

Expected: 行数 ~40

### Task 6.7: .gitignore 起稿

**Files:** Create `kuromi-config-ecc-poc/.gitignore`

- [ ] **Step 1: gitignore write**

```bash
cat > /Users/kkben/Projects/kuromi-config-ecc-poc/.gitignore <<'EOF'
# Sensitive
.env
.env.*
!.env.example
*.key
*.pem
secrets/

# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/

# Local cache
node_modules/
*.log
EOF
cat /Users/kkben/Projects/kuromi-config-ecc-poc/.gitignore
```

Expected: 16 行

### Task 6.8: spec + plan を docs/ に既存配備 verify

- [ ] **Step 1: spec / plan 配置済確認**

```bash
ls /Users/kkben/Projects/kuromi-config-ecc-poc/docs/superpowers/specs/
ls /Users/kkben/Projects/kuromi-config-ecc-poc/docs/superpowers/plans/
```

Expected: 各 1 file 存在 (本 doc + spec)

### Task 6.9: initial commit

- [ ] **Step 1: stage + commit**

```bash
cd /Users/kkben/Projects/kuromi-config-ecc-poc
git add -A
git status
```

Expected: README.md / CLAUDE.md / .gitignore / agents/* / commands/* / rules/common/* / docs/* 全部 staged

- [ ] **Step 2: commit**

```bash
git commit -m "$(cat <<'EOF'
feat: initial kuromi-config-ecc-poc structure

- README + CLAUDE.md base + .gitignore
- ECC cherry-pick: 15 agents + 18 commands + rules/common
- docs/superpowers/{specs,plans}/2026-05-15-* design + plan

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
git log --oneline | head -3
```

Expected: commit hash 表示

---

## Phase 7: GitHub repo + push (10 min)

### Task 7.1: GitHub repo 作成

- [ ] **Step 1: gh で public repo 作成**

```bash
cd /Users/kkben/Projects/kuromi-config-ecc-poc
gh repo create kk-ben/kuromi-config-ecc-poc --public \
  --description "Kuromi ~/.claude/ × ECC × Superpowers integration PoC — AgentShield review judge for a-1 vs a-2" \
  --source=. --remote=origin --push 2>&1 | tail -10
```

Expected: `Created repository kk-ben/kuromi-config-ecc-poc on GitHub`

- [ ] **Step 2: remote 確認**

```bash
git remote -v
```

Expected: `origin https://github.com/kk-ben/kuromi-config-ecc-poc.git (fetch)` 表示

- [ ] **Step 3: web で reachable verify**

```bash
gh repo view kk-ben/kuromi-config-ecc-poc --json url,visibility,isPrivate
```

Expected: visibility=PUBLIC、isPrivate=false

---

## Phase 8: ECC Tools GitHub App install (5 min、katsu 操作)

### Task 8.1: ECC App install (katsu 手動)

- [ ] **Step 1: katsu に install してもらう**

→ katsu に `https://github.com/apps/ecc-tools` を開いてもらう
→ "Install" or "Configure" クリック
→ Account = `kk-ben` 選択
→ Repository access = "Only select repositories" → `kuromi-config-ecc-poc` のみ選択
→ Install 実行

Expected: GitHub から install 完了通知

### Task 8.2: install verify

- [ ] **Step 1: install 確認**

```bash
gh api /repos/kk-ben/kuromi-config-ecc-poc/installation 2>&1 | head -20
```

Expected: app_id / app_slug=`ecc-tools` 表示、または 404 でも install 完了 ack 確認

- [ ] **Step 2: 既知の test = issue 1 つ作って `/ecc-tools` コメント反応**

```bash
ISSUE_URL=$(gh issue create --title "test: ECC Tools App reachability" \
  --body "Checking ECC Tools App responds to commands.")
ISSUE_NUM=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
gh issue comment $ISSUE_NUM --body "/ecc-tools help"
```

Expected: 1-2 min 内に App から bot reply

---

## Phase 9: a-1 branch + PR (10 min + AgentShield 待機 5-15 min)

### Task 9.1: feat/a-1-rule-based branch 切り

- [ ] **Step 1: branch 切り替え**

```bash
cd /Users/kkben/Projects/kuromi-config-ecc-poc
git checkout -b feat/a-1-rule-based
```

Expected: `Switched to a new branch 'feat/a-1-rule-based'`

### Task 9.2: CLAUDE.md に a-1 ルール section 追加

**Files:** Modify `kuromi-config-ecc-poc/CLAUDE.md`

- [ ] **Step 1: rule section 追加**

末尾に append:

```markdown

## superpowers × ECC 連携ルール (a-1: CLAUDE.md rule-based)

新機能追加 / 大型改修 / 実装 prompt を katsu から受けた場合、以下 sequence 厳守:

1. **superpowers:brainstorming** で要件探索
2. brainstorming 完了 (= design doc commit) 後、**必ず Agent tool で ECC `planner` agent dispatch**
3. planner 出力 (= phase 別 implementation plan) を **superpowers:writing-plans** に渡す
4. writing-plans 完了後、**ECC `tdd-guide` agent を Agent tool で dispatch** して TDD loop
5. 実装完了後、**ECC `code-reviewer` + `security-reviewer` agent を並列 dispatch**
6. **superpowers:verification-before-completion** で最終確認

例外 (rule skip 可):
- 単純な typo / 1 行修正 / 既知 file の rename
- katsu が明示的に「planner 不要」「skip ECC」と指示
- bug fix で root cause が明確かつ局所的な case
```

具体 edit command:

```bash
cat >> CLAUDE.md <<'EOF'

## superpowers × ECC 連携ルール (a-1: CLAUDE.md rule-based)

新機能追加 / 大型改修 / 実装 prompt を katsu から受けた場合、以下 sequence 厳守:

1. **superpowers:brainstorming** で要件探索
2. brainstorming 完了 (= design doc commit) 後、**必ず Agent tool で ECC `planner` agent dispatch**
3. planner 出力 (= phase 別 implementation plan) を **superpowers:writing-plans** に渡す
4. writing-plans 完了後、**ECC `tdd-guide` agent を Agent tool で dispatch** して TDD loop
5. 実装完了後、**ECC `code-reviewer` + `security-reviewer` agent を並列 dispatch**
6. **superpowers:verification-before-completion** で最終確認

例外 (rule skip 可):
- 単純な typo / 1 行修正 / 既知 file の rename
- katsu が明示的に「planner 不要」「skip ECC」と指示
- bug fix で root cause が明確かつ局所的な case
EOF
```

- [ ] **Step 2: diff verify**

```bash
git diff CLAUDE.md | head -40
```

Expected: 上記 section が +added 表示

### Task 9.3: commit + push

- [ ] **Step 1: commit**

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
feat(a-1): add CLAUDE.md rule-based ECC integration

superpowers:brainstorming → ECC planner → writing-plans →
tdd-guide → code-reviewer + security-reviewer →
verification-before-completion の 6 step sequence を rule 化。

例外: typo / rename / 局所 bug fix / katsu 明示 skip。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Expected: commit hash 表示

- [ ] **Step 2: push**

```bash
git push -u origin feat/a-1-rule-based
```

Expected: `Branch 'feat/a-1-rule-based' set up to track 'origin/feat/a-1-rule-based'`

### Task 9.4: PR #1 open

- [ ] **Step 1: PR 作成**

```bash
gh pr create --base main --head feat/a-1-rule-based \
  --title "feat(a-1): CLAUDE.md rule-based ECC integration" \
  --body "$(cat <<'EOF'
## Summary

a-1 implementation: superpowers × ECC 連携を **CLAUDE.md の rule** として明示記述。

## sequence

1. superpowers:brainstorming
2. ECC planner agent
3. superpowers:writing-plans
4. ECC tdd-guide agent
5. ECC code-reviewer + security-reviewer (並列)
6. superpowers:verification-before-completion

## 例外

- typo / 1 行修正 / rename
- katsu 明示 skip
- 局所 bug fix

## ECC Tools review

`/ecc-tools analyze` で AgentShield-backed review 取得予定。
b ranch `feat/a-2-hook-based` の PR #2 と比較判定する。

🤖 Generated with Claude Code
EOF
)"
```

Expected: PR URL 出力

### Task 9.5: `/ecc-tools analyze` トリガー

- [ ] **Step 1: PR コメント追加**

```bash
PR_NUM=$(gh pr list --head feat/a-1-rule-based --json number --jq '.[0].number')
gh pr comment $PR_NUM --body "/ecc-tools analyze"
echo "PR #${PR_NUM} comment posted, waiting AgentShield review..."
```

Expected: comment 投稿成功

### Task 9.6: AgentShield review 待機 + 取得

- [ ] **Step 1: 5-15 min 待機 (poll)**

```bash
# 30 sec interval で poll、最大 15 min
PR_NUM=$(gh pr list --head feat/a-1-rule-based --json number --jq '.[0].number')
for i in $(seq 1 30); do
  REVIEWS=$(gh pr view $PR_NUM --json comments --jq '.comments | map(select(.author.login | contains("ecc")))')
  if [ "$(echo $REVIEWS | jq '. | length')" -gt 0 ]; then
    echo "ECC review arrived (poll #$i)"
    break
  fi
  echo "poll #$i: no ECC review yet"
  sleep 30
done
```

Expected: 5-15 min 内に ECC bot からの comment / PR 出る

- [ ] **Step 2: 生成された PR (もしあれば) を fetch**

```bash
# ECC Tools が別 PR (= proposed-skills 系) を open するパターン
gh pr list --search "ecc-tools in:title" --json number,title,headRefName
# or comment 内 link 取得
gh pr view $PR_NUM --json comments --jq '.comments[].body' | head -50
```

Expected: ECC 生成の SKILL.md / guardrails.md / instincts.yaml の link、または PR 自体に直接コメント

---

## Phase 10: a-2 branch + PR (10 min + AgentShield 待機 5-15 min)

### Task 10.1: feat/a-2-hook-based branch 切り

- [ ] **Step 1: main に戻ってから新 branch**

```bash
cd /Users/kkben/Projects/kuromi-config-ecc-poc
git checkout main
git checkout -b feat/a-2-hook-based
```

Expected: `Switched to a new branch 'feat/a-2-hook-based'`

### Task 10.2: hooks-snippets/superpowers-ecc-bridge.js 起稿

**Files:** Create `kuromi-config-ecc-poc/hooks-snippets/superpowers-ecc-bridge.js`

- [ ] **Step 1: PostToolUse hook (Skill 完了監視) 書く**

```bash
mkdir -p hooks-snippets
cat > hooks-snippets/superpowers-ecc-bridge.js <<'EOF'
#!/usr/bin/env node
/**
 * a-2: hook-based 物理強制 ECC bridge
 *
 * PostToolUse on Skill tool:
 *   superpowers:brainstorming 完了検出 → ~/.claude/state/ecc-bridge.flag に flag 立てる
 *
 * UserPromptSubmit:
 *   flag check → 「ECC planner agent dispatch 必須」を additionalContext として injection
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const FLAG_PATH = path.join(os.homedir(), '.claude', 'state', 'ecc-bridge.flag');
const STATE_DIR = path.dirname(FLAG_PATH);

function ensureStateDir() {
  if (!fs.existsSync(STATE_DIR)) {
    fs.mkdirSync(STATE_DIR, { recursive: true });
  }
}

function main() {
  let rawInput = '';
  try {
    rawInput = fs.readFileSync(0, 'utf8');
  } catch (e) {
    process.stdout.write(JSON.stringify({}));
    return;
  }

  let input;
  try {
    input = JSON.parse(rawInput);
  } catch (e) {
    process.stdout.write(rawInput);
    return;
  }

  const hookEvent = input.hookEventName || input.hook_event_name;

  // Mode A: PostToolUse on Skill
  if (hookEvent === 'PostToolUse' && input.tool === 'Skill') {
    const skillName = input.tool_input?.skill || input.tool_input?.args?.skill;
    if (skillName === 'superpowers:brainstorming') {
      ensureStateDir();
      fs.writeFileSync(FLAG_PATH, JSON.stringify({
        pendingPlannerDispatch: true,
        ts: Date.now(),
        triggeredBy: 'superpowers:brainstorming',
      }));
    }
  }

  // Mode B: UserPromptSubmit (flag check + injection)
  if (hookEvent === 'UserPromptSubmit') {
    if (fs.existsSync(FLAG_PATH)) {
      let flag;
      try {
        flag = JSON.parse(fs.readFileSync(FLAG_PATH, 'utf8'));
      } catch (e) {
        flag = null;
      }
      if (flag?.pendingPlannerDispatch) {
        // Consume flag
        fs.unlinkSync(FLAG_PATH);
        // Inject
        process.stdout.write(JSON.stringify({
          hookSpecificOutput: {
            hookEventName: 'UserPromptSubmit',
            additionalContext: '[ECC-BRIDGE] superpowers:brainstorming 完了検出。' +
              '次 turn で **Agent tool で ECC `planner` agent dispatch 必須** ' +
              '(spec → impl 移行前の plan 生成のため)。skip 不可。',
          },
        }));
        return;
      }
    }
  }

  // pass-through
  process.stdout.write(rawInput);
}

main();
EOF
chmod +x hooks-snippets/superpowers-ecc-bridge.js
wc -l hooks-snippets/superpowers-ecc-bridge.js
node --check hooks-snippets/superpowers-ecc-bridge.js && echo "syntax OK"
```

Expected: ~75 行、syntax OK

### Task 10.3: CLAUDE.md に hook 参照 section 追加

**Files:** Modify `kuromi-config-ecc-poc/CLAUDE.md`

- [ ] **Step 1: section append**

```bash
cat >> CLAUDE.md <<'EOF'

## superpowers × ECC 連携 (a-2: hook-based 物理強制)

`hooks-snippets/superpowers-ecc-bridge.js` で物理強制:

- **PostToolUse on Skill**: superpowers:brainstorming 完了検出 → flag 立てる
- **UserPromptSubmit**: flag check → 「ECC planner dispatch 必須」injection

settings.json への hook 登録例:

```json
{
  "hooks": {
    "PostToolUse": [
      {"matcher": "Skill", "hooks": [{
        "type": "command",
        "command": "node /path/to/hooks-snippets/superpowers-ecc-bridge.js"
      }]}
    ],
    "UserPromptSubmit": [
      {"matcher": "", "hooks": [{
        "type": "command",
        "command": "node /path/to/hooks-snippets/superpowers-ecc-bridge.js"
      }]}
    ]
  }
}
```

例外なし、物理強制 100%。bypass = hook script を無効化する必要。
EOF
```

- [ ] **Step 2: diff verify**

```bash
git diff CLAUDE.md hooks-snippets/ | head -100
```

Expected: hook script + CLAUDE.md addition が表示

### Task 10.4: commit + push + PR

- [ ] **Step 1: commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
feat(a-2): hook-based physical enforcement ECC bridge

PostToolUse on Skill で superpowers:brainstorming 完了検出、
UserPromptSubmit で次 turn に ECC planner dispatch 必須を injection。

hook script: hooks-snippets/superpowers-ecc-bridge.js (~75 行)
CLAUDE.md は参照のみ、rule 本体は hook が enforce。

物理強制 100%、bypass 不可（hook 無効化要）。

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
git push -u origin feat/a-2-hook-based
```

Expected: push 成功

- [ ] **Step 2: PR open**

```bash
gh pr create --base main --head feat/a-2-hook-based \
  --title "feat(a-2): hook-based physical enforcement ECC bridge" \
  --body "$(cat <<'EOF'
## Summary

a-2 implementation: superpowers × ECC 連携を **hook で物理強制**。

## mechanism

- PostToolUse on Skill: superpowers:brainstorming 完了検出 → `~/.claude/state/ecc-bridge.flag` に flag
- UserPromptSubmit: flag check → 「ECC planner dispatch 必須」を additionalContext で injection

## file

- `hooks-snippets/superpowers-ecc-bridge.js` (~75 行)
- `CLAUDE.md` 参照のみ追加 (rule 本体は hook)

## 強制力

100% (hook 無効化要、bypass 不可)。

## risk

- loop (planner → architect → planner)
- token 爆発 (毎 brainstorming で planner 強制)
- persona 干渉
- 過剰発火

## ECC Tools review

`/ecc-tools analyze` で AgentShield-backed review 取得、PR #1 (a-1) と比較判定。

🤖 Generated with Claude Code
EOF
)"
```

Expected: PR URL

### Task 10.5: `/ecc-tools analyze` トリガー + 待機

- [ ] **Step 1: コメント**

```bash
PR_NUM=$(gh pr list --head feat/a-2-hook-based --json number --jq '.[0].number')
gh pr comment $PR_NUM --body "/ecc-tools analyze"
```

- [ ] **Step 2: 5-15 min poll**

```bash
PR_NUM=$(gh pr list --head feat/a-2-hook-based --json number --jq '.[0].number')
for i in $(seq 1 30); do
  REVIEWS=$(gh pr view $PR_NUM --json comments --jq '.comments | map(select(.author.login | contains("ecc")))')
  if [ "$(echo $REVIEWS | jq '. | length')" -gt 0 ]; then
    echo "ECC review arrived (poll #$i)"
    break
  fi
  sleep 30
done
```

Expected: 5-15 min 内に review arrive

---

## Phase 11: AgentShield 比較 + 判定 (15 min)

### Task 11.1: a-1 review 抽出

- [ ] **Step 1: PR #1 の ECC bot comment 全 dump**

```bash
PR1_NUM=$(gh pr list --head feat/a-1-rule-based --json number --jq '.[0].number')
gh pr view $PR1_NUM --json comments --jq '.comments[] | select(.author.login | contains("ecc")) | .body' > /tmp/ecc-review-a1.md
wc -l /tmp/ecc-review-a1.md
head -50 /tmp/ecc-review-a1.md
```

Expected: ECC bot comment 内容 (AgentShield 警告 / 推奨 / scan 結果) 取得

### Task 11.2: a-2 review 抽出

- [ ] **Step 1: PR #2 の ECC bot comment dump**

```bash
PR2_NUM=$(gh pr list --head feat/a-2-hook-based --json number --jq '.[0].number')
gh pr view $PR2_NUM --json comments --jq '.comments[] | select(.author.login | contains("ecc")) | .body' > /tmp/ecc-review-a2.md
wc -l /tmp/ecc-review-a2.md
head -50 /tmp/ecc-review-a2.md
```

Expected: 同様

### Task 11.3: 比較表作成

**Files:** Create `kuromi-config-ecc-poc/docs/a1-vs-a2-comparison.md`

- [ ] **Step 1: 比較 table 起稿 (main branch)**

```bash
cd /Users/kkben/Projects/kuromi-config-ecc-poc
git checkout main

# 比較項目別 grep + count
cat > docs/a1-vs-a2-comparison.md <<'EOF'
# a-1 vs a-2 AgentShield Review 比較

## 出力 raw

- a-1 review: `/tmp/ecc-review-a1.md`
- a-2 review: `/tmp/ecc-review-a2.md`

## 比較 table (= 各項目 count)

| 項目 | a-1 | a-2 | 解釈 |
|------|-----|-----|------|
| AgentShield critical warning | TBD | TBD | 少ない方優位 |
| AgentShield medium warning | TBD | TBD | 少ない方優位 |
| AgentShield info / suggestion | TBD | TBD | — |
| persona 干渉警告 | TBD | TBD | — |
| loop / 過剰発火警告 | TBD | TBD | a-2 反対材料 |
| token cost 警告 | TBD | TBD | a-2 反対材料 |
| 強制力 / robustness 言及 | TBD | TBD | a-2 推奨材料 |
| 「ECC-aligned」言及 | TBD | TBD | どっち寄りか |

## 判定

(TBD: AgentShield 結果見てから埋める)

## 採用案

(TBD)
EOF
```

- [ ] **Step 2: 比較項目 count (実行)**

```bash
for keyword in "critical" "warning" "error" "loop" "cost" "token" "persona" "force" "physical" "rule"; do
  A1_CNT=$(grep -ic "$keyword" /tmp/ecc-review-a1.md || echo 0)
  A2_CNT=$(grep -ic "$keyword" /tmp/ecc-review-a2.md || echo 0)
  echo "$keyword: a-1=$A1_CNT, a-2=$A2_CNT"
done
```

Expected: 各 keyword count 出力、TBD 部分を実値で埋める

### Task 11.4: katsu と一緒に判定

- [ ] **Step 1: 比較表を katsu に提示**

→ 数値表 + AgentShield 全文を katsu に show
→ katsu の判断仰ぐ
→ 判定不能なら default = **a-1**

Decision tree:
- a-1 critical warnings > a-2 → a-2 採用
- a-1 critical warnings <= a-2 → a-1 採用
- AgentShield が「rule 無視 risk」を強く言及 → a-2 採用
- AgentShield が「過剰発火」「loop」「cost」警告 → a-1 採用
- 同等 → **a-1 default**

- [ ] **Step 2: 判定結果 commit**

```bash
# docs/a1-vs-a2-comparison.md の TBD 部分を埋めて commit
git add docs/a1-vs-a2-comparison.md
git commit -m "docs: a-1 vs a-2 AgentShield review comparison + final decision"
git push origin main
```

---

## Phase 12: 採用案を本体 `~/.claude/CLAUDE.md` に反映 (10 min)

### Task 12.1: 反映前 backup (再)

- [ ] **Step 1: 直前 backup**

```bash
TS=$(date +%Y%m%d-%H%M%S)
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak-pre-a1a2-${TS}
```

Expected: backup file 存在

### Task 12.2: 採用案を CLAUDE.md に append

- [ ] **Step 1 (a-1 採用時): rule section append**

```bash
cat >> ~/.claude/CLAUDE.md <<'EOF'

## superpowers × ECC 連携ルール (a-1: AgentShield 判定済)

新機能追加 / 大型改修 / 実装 prompt を katsu から受けた場合、以下 sequence 厳守:

1. superpowers:brainstorming で要件探索
2. brainstorming 完了後、必ず Agent tool で ECC planner agent dispatch
3. planner 出力を superpowers:writing-plans に渡す
4. writing-plans 完了後、ECC tdd-guide agent dispatch で TDD loop
5. 実装完了後、ECC code-reviewer + security-reviewer 並列 dispatch
6. superpowers:verification-before-completion で最終確認

例外:
- 単純な typo / 1 行修正 / rename
- katsu 明示 skip 指示
- 局所 bug fix で root cause 明確
EOF
```

- [ ] **Step 1 (a-2 採用時、代替): hook 配備 + CLAUDE.md 参照**

```bash
# hook script を ~/.claude/hooks/ に配備
mkdir -p ~/.claude/state
cp /Users/kkben/Projects/kuromi-config-ecc-poc/hooks-snippets/superpowers-ecc-bridge.js \
   /Users/kkben/Projects/Claude-Code-Communication/.claude/hooks/superpowers-ecc-bridge.js
node --check /Users/kkben/Projects/Claude-Code-Communication/.claude/hooks/superpowers-ecc-bridge.js

# CLAUDE.md 参照のみ
cat >> ~/.claude/CLAUDE.md <<'EOF'

## superpowers × ECC 連携 (a-2: hook 物理強制)

`/Users/kkben/Projects/Claude-Code-Communication/.claude/hooks/superpowers-ecc-bridge.js` で物理強制。
- PostToolUse on Skill (superpowers:brainstorming 完了検出)
- UserPromptSubmit (flag check + planner dispatch 必須 injection)
EOF
```

### Task 12.3: persona section diff = 0 verify

- [ ] **Step 1: persona 部分 diff**

```bash
TS_BAK=$(ls -t ~/.claude/CLAUDE.md.bak-pre-a1a2-* | head -1)
diff <(grep -A 50 "## ペルソナ" $TS_BAK | head -60) \
     <(grep -A 50 "## ペルソナ" ~/.claude/CLAUDE.md | head -60)
```

Expected: diff 0 行 (= persona section 完全保持)

- [ ] **Step 2: サボり防止 / えびルール / 既知のバグ section 同 verify**

```bash
for section in "サボり防止" "えび" "既知のバグ" "協働環境"; do
  echo "=== $section diff ==="
  diff <(grep -A 30 "## $section" $TS_BAK) \
       <(grep -A 30 "## $section" ~/.claude/CLAUDE.md) | head -20
done
```

Expected: 全 section diff 0

### Task 12.4: 1 session 動作 test

- [ ] **Step 1: katsu に新 session で test prompt 投入してもらう**

→ test prompt: 「test の機能追加 design して」
→ Expected sequence (a-1 採用時):
  - superpowers:brainstorming 起動
  - design doc 提示
  - katsu 承認後、ECC planner agent dispatch
  - implementation plan 出力
  - persona-linter / kansai-score PASS

Expected: a-1 rule 通りに発火、persona 違反 0

---

## Phase 13: hook 統合 (30 min、別 session 推奨)

### Task 13.1: 現 settings.json の hook section 再確認

- [ ] **Step 1: 現状 hooks count**

```bash
node -e "
const s = JSON.parse(require('fs').readFileSync('/Users/kkben/.claude/settings.json'));
for (const [event, hooks] of Object.entries(s.hooks)) {
  console.log(event + ': ' + hooks.length + ' matcher group, ' +
    hooks.reduce((a,h) => a + (h.hooks?.length || 0), 0) + ' total commands');
}
"
```

Expected: PreToolUse / UserPromptSubmit / Stop / SessionStart / PreCompact / SessionEnd / PostToolUse の event 別 count

### Task 13.2: ECC hooks 取得 + redact

**Files:** Create `~/.claude/settings.json.ecc-merge-draft-<ts>`

- [ ] **Step 1: ECC `hooks/hooks.json` を base に redact**

```bash
TS=$(date +%Y%m%d-%H%M%S)
cp ~/.claude/settings.json ~/.claude/settings.json.bak-pre-hooks-${TS}

# ECC hook の一部 (cost-tracker / desktop-notify / quality-gate / context-monitor) を抽出
node -e "
const ecc = JSON.parse(require('fs').readFileSync('/tmp/everything-claude-code/hooks/hooks.json'));
const adopt_ids = [
  'pre:bash:dispatcher',
  'pre:config-protection',
  'pre:mcp-health-check',
  'post:bash:dispatcher',
  'post:quality-gate',
  'post:edit:console-warn',
  'post:edit:accumulator',
  'post:ecc-context-monitor',
  'stop:format-typecheck',
  'stop:check-console-log',
  'stop:cost-tracker',
  'stop:desktop-notify',
];
const skip_ids = [
  'pre:edit-write:gateguard-fact-force',  // find-before-claim と被り
  'pre:observe:continuous-learning',       // auto-rag と二重
  'post:observe:continuous-learning',
  'pre:governance-capture',                 // opt-in
  'post:governance-capture',
  'stop:session-end',                       // task-diary と二重
  'stop:evaluate-session',                  // 不要
  'session:end:marker',                     // task-diary と二重
];
// adopt のみ抽出して出力
const adopted = {};
for (const [event, groups] of Object.entries(ecc.hooks)) {
  for (const g of groups) {
    for (const h of (g.hooks || [])) {
      // id 判定は g.id or 個別マッチ
    }
  }
}
console.log('ECC adopt 候補: ' + adopt_ids.length);
console.log('ECC skip:      ' + skip_ids.length);
"
```

→ 採用候補と skip 候補を明示

### Task 13.3: 統合版 settings.json 起稿

- [ ] **Step 1: 手動 merge (脚本にせず、慎重に編集)**

→ katsu と一緒に `~/.claude/settings.json` を edit:
1. 既存 hooks の **順序維持** (くろみ hook が先頭、ECC が並列追加)
2. ECC adopt 候補 (`pre:bash:dispatcher` 等) を該当 event の **末尾** に追加
3. ECC skip 候補は完全に除外

→ 完成版を `~/.claude/settings.json.ecc-merge-draft-${TS}` として保存

- [ ] **Step 2: JSON 構文 verify**

```bash
node -e "JSON.parse(require('fs').readFileSync('/Users/kkben/.claude/settings.json.ecc-merge-draft-${TS}'))" && echo "OK"
```

Expected: `OK`

- [ ] **Step 3: 既存 hook path 全保持 verify**

```bash
# 既存 hook path が draft でも全部参照されとる verify
for f in $(grep -oE '/Users/kkben/[^"]+\.(js|sh)' ~/.claude/settings.json | sort -u); do
  grep -q "$f" ~/.claude/settings.json.ecc-merge-draft-${TS} && echo "✓ $f" || echo "✗ LOST: $f"
done
```

Expected: 全 16 ✓、LOST 0

### Task 13.4: draft → live 切替

- [ ] **Step 1: apply**

```bash
mv ~/.claude/settings.json.ecc-merge-draft-${TS} ~/.claude/settings.json
node -e "JSON.parse(require('fs').readFileSync('/Users/kkben/.claude/settings.json'))" && echo "JSON OK"
```

Expected: `JSON OK`

- [ ] **Step 2: 新 session 起動 + hook 発火 test**

→ katsu に新 session 開いてもらう
→ プロンプト: 「test: hook 発火確認」
→ Stop hook 終了時に各 hook log 出力確認

Expected: persona-linter / kansai-score / ECC stop:cost-tracker 等全て発火

### Task 13.5: 異常時 rollback

If hook 統合後に異常 (= persona 崩壊 / agent loop / cost spike):

```bash
mv ~/.claude/settings.json ~/.claude/settings.json.broken-$(date +%Y%m%d-%H%M%S)
cp ~/.claude/settings.json.bak-pre-hooks-${TS} ~/.claude/settings.json
```

---

## Phase 14: 最終 verification (10 min)

### Task 14.1: 全 layer 動作 e2e test

- [ ] **Step 1: katsu に「機能 X 設計して」prompt 投入してもらう**

Expected sequence:
1. L1: memory-grep-enforce 発火、persona enforce
2. L2: superpowers:brainstorming 起動
3. brainstorming 完了 (design doc 書く)
4. L3: ECC planner agent dispatch (a-1 rule 由来 or a-2 hook 由来)
5. plan 出力
6. L2: superpowers:writing-plans 起動
7. L3: ECC tdd-guide agent dispatch
8. 実装 phase
9. L3: ECC code-reviewer + security-reviewer 並列
10. L2: superpowers:verification-before-completion
11. L1: persona-linter / kansai-score PASS

### Task 14.2: cost / token 比較 (baseline vs new)

- [ ] **Step 1: ECC stop:cost-tracker 出力確認**

```bash
ls ~/.claude/telemetry/ | tail -3
# 最新 telemetry の cost confirm
tail -20 ~/.claude/telemetry/<latest>.jsonl 2>/dev/null
```

Expected: cost spike ない (= baseline × 3 未満)

### Task 14.3: 「アホ挙動」検出 + 是正

- [ ] **Step 1: katsu 体感判定**

→ katsu に 1-2 週間 各 session で挙動観察してもらう
→ 「アホ挙動」発生 = 即報告
→ 報告内容に応じて hook / rule 調整 (= a-1 採用時は rule 文言追加、a-2 採用時は hook injection 文言調整)

---

## Self-Review (本 plan 起稿後)

**1. Spec coverage:**
- §1 Overview → Phase 0-14 全 cover
- §2 Goals G1-G4 → Phase 4 (G1) / Phase 11 (G2) / Phase 12-14 (G3) / Phase 0+全 Phase rollback (G4)
- §3 Background → Pre-flight (Task 0.3) で再 verify
- §4 Architecture 4 layer → Phase 12 で本体に反映、Phase 14 で e2e
- §5 Test repo scope A → Phase 6 task 6.3-6.7
- §6 a-1 / a-2 実装 → Phase 9 (a-1) + Phase 10 (a-2)
- §7 ECC review 手順 → Phase 8-11
- §8 install components → Phase 4
- §9 verification → Phase 5 + Phase 14
- §10 rollback → Phase 0 backup + Task 5.3 / 12.1 / 13.5 個別
- §11 risks → 各 Phase に mitigation 組込み
- §13 locked decisions → Phase 6-10 で反映済

**2. Placeholder scan:**
- Phase 11.3 / 11.4 で「TBD: AgentShield 結果見てから埋める」 → 動的 content、許容（出力結果次第）
- Phase 12.4 / 14.1 で「Expected sequence」 → 動作期待値、placeholder じゃない

**3. Type consistency:**
- branch 名 `feat/a-1-rule-based` / `feat/a-2-hook-based` 全 Phase で統一
- file path `kuromi-config-ecc-poc` 全 Phase で統一
- env var `${TS}` / `${TS_BAK}` 用法一貫

修正点: なし、plan 完成。

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-15-kuromi-ecc-integration-plan.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration. Phase 単位で subagent 渡し、Phase 完了ごとに katsu review checkpoint。最大の concurrency 取れる。

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints for review. 本 session 内で順次実行、katsu interactive 確認多い段階 (auth / GitHub UI / katsu 判定) で必ず止まる。

**くろみ推奨 = 2 (Inline)** — 理由:
- Phase 2 (Pro auth) / Phase 8 (App install) / Phase 11.4 (判定) は **katsu interactive** 必須
- subagent 経由だと katsu との dialogue が分断される
- Phase 0-4 (install) は副作用大 = くろみが直接見届けたい
- ただし Phase 9-10 (a-1 / a-2 PR push) は subagent 並列もアリ

**Which approach?**
