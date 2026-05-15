# kuromi-config-ecc-poc

`~/.claude/` 設定の ECC (Everything Claude Code) 統合 PoC repo (= archive)。

> **Status**: archived (read-only). 本体 SSoT は `~/.claude/CLAUDE.md`。

---

## このリポは何か

[everything-claude-code](https://github.com/affaan-m/everything-claude-code) (= 通称 **ECC**) を kuromi (= katsu の AI エンジニア persona) の `~/.claude/` に統合した時の **設計 + 判定 + 検証 archive**。

ECC とは:
- Anthropic Hackathon 優勝の Claude Code 拡張パッケージ
- agents 60+ / skills 228+ / commands 75+ / hooks / rules を含む
- MIT license、OSS layer は無料
- 別途 GitHub App (ECC Tools) を Pro $19/月 で提供

---

## ECC の価値 (= 確定済)

| 層 | 内容 | 価値 | 課金 |
|---|------|------|------|
| **OSS layer** (= 本 repo install 済) | 48 agents + 80 commands + 187 skills + 89 rules + 14 hooks | ★★★★★ 即時、永久 | 無料 |
| **AgentShield CLI** (= `ecc-agentshield`) | ~/.claude/ の自動 security scan / fix / watch / runtime | ★★★★★ 必須 security 層 | 無料 (OSS) |
| **ECC Tools GitHub App** (Pro tier) | 自動 PR scan / baseline 比較 / 履歴管理 / 50 analyses/月 | ★★★★ 「忘れても勝手に守る」自動化 | $19/月 |

---

## AgentShield (= ECC のスキャン) 使い方

### install (= 既に install 済)

```bash
npm install -g ecc-agentshield
agentshield --version  # 1.5.0 確認
```

### 基本 scan (= ~/.claude/ 全体監査)

```bash
agentshield scan
```

出力例:
```
AgentShield Security Report
Grade: F (38/100)
- Secrets:     100 ✓
- Permissions: 0 ✗ (Bash(*) wildcard 問題)
- Hooks:       0 ✗
- MCP:         90 ✓
- Agents:      0 ✗

Findings: 330 total — 1 critical, 36 high, 79 medium, 212 low, 2 info
Auto-fixable: 19 (use --fix)
```

### `--fix` 注意 ⚠️

`agentshield scan --fix` は **context 知らんで「error suppression」と誤検出**して、意図的な `2>/dev/null` / `|| true` を削除する。

**手動 fix 推奨**、`--fix` は使うな。findings を review して selective に apply する。

### 各 subcommand

| command | 用途 |
|---------|------|
| `agentshield scan` | one-shot 全体 scan |
| `agentshield scan --opus` | Opus 4.6 multi-agent deep analysis |
| `agentshield scan --injection` | prompt injection active testing |
| `agentshield scan --sandbox` | hook を sandbox で実行して挙動観察 |
| `agentshield scan --taint` | データフロー追跡 (taint analysis) |
| `agentshield scan --deep` | 上記全部 |
| `agentshield watch` | 継続監視 daemon (= 変更時即 scan) |
| `agentshield runtime` | PreToolUse hook、policy enforcement (= 危険操作を実時間 block) |
| `agentshield init` | secure baseline 設定生成 |
| `agentshield policy` | 組織共通 policy 管理 |
| `agentshield miniclaw` | 最小 secure AI agent runtime |

### 出力 format

```bash
agentshield scan --format json   # 機械可読
agentshield scan --format markdown
agentshield scan --format html
```

### baseline 比較 (= 「前回より悪化したか」)

```bash
# 初回: baseline 保存
agentshield scan --save-baseline ~/.claude/agentshield-baseline.json

# 以降: baseline と比較
agentshield scan --baseline ~/.claude/agentshield-baseline.json --gate
# (--gate = critical/high 新規発見 or grade 低下で exit 1)
```

### 推奨運用

| 頻度 | 内容 |
|------|------|
| **毎日** (= 朝の習慣) | `agentshield scan` を眺める |
| **週 1 回** | baseline と diff、悪化したら原因調査 |
| **常時** (= optional) | `agentshield watch` daemon で即時検出 |
| **PreToolUse 強制** (= optional) | `agentshield runtime` を settings.json hook に組み込み |

---

## 本 repo 設計経緯 (= archive 内容)

### 採用された a-1 rule (= revised)

詳細: [docs/a1-vs-a2-comparison.md](docs/a1-vs-a2-comparison.md) + [docs/superpowers/specs/2026-05-15-kuromi-ecc-integration-design.md](docs/superpowers/specs/2026-05-15-kuromi-ecc-integration-design.md)

「superpowers (= 手順書) + ECC (= 工具) 併用」を `~/.claude/CLAUDE.md` に反映。新機能追加時の sequence:

```
1. superpowers:brainstorming で要件探索
2. superpowers:writing-plans で plan ファイル化 (+ option ECC planner agent)
3. superpowers:executing-plans で実装 (+ option ECC tdd-guide agent)
4. 実装完了後、ECC code-reviewer + security-reviewer 並列 dispatch (必須)
5. superpowers:verification-before-completion で最終 verify
```

### 採用前の判定 (= a-1 vs a-2 比較)

`feat/a-1-rule-based` PR / `feat/a-2-hook-based` PR を作成、ECC Tools `/ecc-tools analyze` で AgentShield 判定させる予定だった → **ECC Tools の analyze は repo bundle 生成のみで PR 内容個別 review しない**仕様判明、手動判定に pivot。

8 観点 7 勝 1 敗で a-1 採用、PR は両方 close、本 repo は archive (= reference)。

### 教訓

1. **superpowers + ECC は併用が正解**、二者択一じゃない
2. 公式 doc は 100% 読む (= ECC Tools `/ecc-tools analyze` 仕様誤解の原因)
3. a-1 v1「ECC planner 強制」= superpowers HARD-GATE 違反、実 session で発覚 → v2 revise
4. AgentShield は **OSS CLI で完全に使える**、Pro $19/月の真価値は「自動化 + baseline + 履歴」のみ

---

## 動作確認 (= `scripts/verify.sh`)

```bash
bash scripts/verify.sh
```

40 項目 check:
- ECC OSS install 健全性 (= agents / commands / skills / rules 数 + 主要 file 存在)
- AgentShield CLI 動作
- a-1 rule (CLAUDE.md 反映)
- settings.json + custom hook (= block-destructive-bash 等)
- 既存 kuromi hook 保持 (= soul-ping / persona-linter / kansai-score 等)
- backup 経路 + secrets dir / perm

---

## File 構造

```
kuromi-config-ecc-poc/
├── README.md                          # 本 file
├── CLAUDE.md                          # PoC 用 subset、a-1 (branch) / a-2 (branch) で差し替え
├── .gitignore
├── agents/                            # ECC cherry-pick 15 体
├── commands/                          # ECC cherry-pick 18 個
├── rules/common/                      # ECC rules/common/* (10 file)
├── hooks-snippets/                    # a-2 branch のみ追加 (= 不採用版の hook)
├── scripts/
│   └── verify.sh                      # 40 項目 動作確認 script
├── docs/
│   ├── a1-vs-a2-comparison.md        # 採用判定経緯 + 教訓 + revise 後追加 fix
│   └── superpowers/
│       ├── specs/2026-05-15-*.md     # 設計 doc
│       └── plans/2026-05-15-*.md     # 実装 plan
├── .claude/                           # ECC Tools 自動生成 bundle (PR #2 merge 済)
│   ├── ecc-tools.json
│   ├── skills/kuromi-config-ecc-poc/SKILL.md
│   ├── identity.json
│   └── homunculus/instincts/
└── .codex/                            # Codex 用 mirror
```

---

## 関連 file (= 本体側)

| 場所 | 内容 |
|------|------|
| `~/.claude/CLAUDE.md` | 本体 SSoT、a-1 rule revised L279-324 |
| `~/.claude/settings.json` | hooks 31 (= ECC adopt 14 + kuromi 既存 17) + deny list 26 entries |
| `~/.claude/scripts/hooks/block-destructive-bash.js` | 新規 kuromi hook (= regex deny for shell trick) |
| `~/.claude/secrets/ebi.env` | VPS hostname/IP env var (0600 perm) |
| `~/.claude/projects/-Users-kkben/memory/session_20260515_ecc_integration_complete.md` | session handoff |

## backup 経路

```
~/.claude.bak-20260515-112238/                       # Phase 0 全体 (3.2GB)
~/.claude/CLAUDE.md.bak-pre-ecc-20260515-112340      # ECC 反映前
~/.claude/CLAUDE.md.bak-pre-a1-20260515-125503       # a-1 反映前
~/.claude/CLAUDE.md.bak-pre-fixes-20260515-133358    # 後続 fix 前
~/.claude/CLAUDE.md.bak-pre-shield-fix-*             # AgentShield --fix 前
~/.claude/settings.json.bak-pre-ecc-*                # ECC 反映前
~/.claude/settings.json.bak-pre-merge-*              # hook merge 前
~/.claude/settings.json.bak-pre-fixes-*              # 後続 fix 前
```

完全 rollback: `~/.claude.bak-20260515-112238/` 戻すだけ。

## License

本 repo の独自 content は MIT 想定 (= ECC 由来 file は ECC OSS の MIT に従う)。

---

## 次の action (= katsu 持ち分)

1. **AgentShield 運用習慣化**: 週 1 回 `agentshield scan` + baseline 比較
2. **Pro tier $19/月** 評価 (1-2 ヶ月): 自動 PR scan / baseline 機能を本番 repo で試す
3. **新 session で a-1 revised rule 動作再 verify**
4. **MEMORY.md 178KB 肥大整理** (= 別 task)

archive 完了、SSoT は `~/.claude/`。
