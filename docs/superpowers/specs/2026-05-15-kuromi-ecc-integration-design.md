# Kuromi `~/.claude/` × ECC × Superpowers 統合 — Design Doc

**Date**: 2026-05-15
**Author**: kuromi (under katsu direction)
**Status**: Draft v1, awaiting katsu approval
**Repo**: `kuromi-config-ecc-poc` (新規 test repo)

---

## §1 Overview

`~/.claude/` を **4 層 stack** で再構成し、katsu の Pro 課金 (`kanto.eco@gmail.com`) で得とる **ECC Tools GitHub App** を **判定者** として使い、a-1 (CLAUDE.md rule-based) vs a-2 (hook-based 物理強制) のどちらが best か **AgentShield-backed review で公式判定させる**。判定結果を本体 `~/.claude/CLAUDE.md` に反映する。

くろみペルソナ (Layer 1) + superpowers (Layer 2) は **絶対 touch せず**、Layer 3 (ECC) を新規追加、Layer 4 (業務 skill) は既存保持。

---

## §2 Goals / Non-Goals

### Goals
- G1: ECC 60 agents / 75 commands / 228 skills / rules / AgentShield / research-pack を `~/.claude/` に統合（full install）
- G2: superpowers (process) + ECC (specialist) の **連携ルール** を確立、a-1 か a-2 を **ECC 自身に review させて判定**
- G3: 判定 + 反映後、他 session の「くろみ挙動アホ」問題を改善（katsu 不満解消）
- G4: rollback 経路を物理的に保証（backup → 即復旧可能）

### Non-Goals
- NG1: くろみペルソナ / 関西弁 / 業務 skill (ebi-* / nemoclaw-*) の置換 や 改変
- NG2: NemoClaw enterprise release path への影響（独立作業）
- NG3: team-config-sync / enterprise-controls（Pro 該当外 + 不要）
- NG4: 他言語 reviewer agents の業務利用（Java/C#/Kotlin/Rust 等、配備はするが trigger 設定はしない）
- NG5: 本体 repo (nemoclaw-enterprise / Claude-Code-Communication) への ECC Tools App install（test repo 完徹後に別判断）

---

## §3 Background

### 現状の `~/.claude/` (= Layer 1 + Layer 2 + Layer 4)

| Layer | 中身 | 状態 |
|------|------|------|
| L1 Persona/Memory | CLAUDE.md (275 行 global) + UserPromptSubmit hook 5 本 + Stop hook 8 本 + memory grep + auto-RAG + persona-linter + kansai-score | 健全、health check PASS |
| L2 Process | `superpowers@claude-plugins-official` v5.0.7 (brainstorming / writing-plans / TDD / debugging / parallel-agents 等) | 健全、enable 済 |
| L3 Specialists | **空** (`~/.claude/agents/` ≒ 空、commands 1 本のみ) | **これから ECC で埋める** |
| L4 Domain | 40 skills (ebi-* / nemoclaw-* / api-* / obsidian-* / sentry-* / 等) + design-docs templates 23 本 | 健全 |

### ECC paid Pro tier 価値
- private repo `/ecc-tools analyze` (= 自動 SKILL.md / instincts.yaml / guardrails.md PR 生成)
- **AgentShield-backed scanning** (config 監査 + 危険 context review) ← **本 design の判定者**
- `security` / `research` install profile アクセス
- Doctor / repair / uninstall
- Priority support

### 判定対象 a-1 vs a-2

| 方式 | 実装 | 制御性 | risk |
|------|------|-------|------|
| **a-1: CLAUDE.md rule-based** | CLAUDE.md に「superpowers:brainstorming 完了後、機能追加なら ECC planner agent invoke」rule 明記 | 柔軟、状況判断可 | rule 無視発生し得る |
| **a-2: hook-based 物理強制** | PostToolUse on Skill 完了で transcript 監視 → 次 prompt に「ECC planner 必須」injection | 強制力 100% | 過剰発火、token 爆発、loop risk |

→ **どっちが best か AgentShield に judge させる**（katsu 提案、本 design の核）

---

## §4 Architecture

### 4 層 stack

```
┌─────────────────────────────────────────────────────┐
│ L4 Domain (keep)                                    │
│  40 skills + design-docs templates + handoff system  │
├─────────────────────────────────────────────────────┤
│ L3 Specialists (NEW = ECC OSS + Pro pack)            │
│  - 60 agents (planner/code-reviewer/tdd-guide/…)     │
│  - 75 commands (/plan, /tdd, /verify, /code-review…)  │
│  - rules/common/ (security/testing/style/git)         │
│  - 228 skills (search-first/verification-loop/…)      │
│  - hooks layer (pre-bash/config-protection/quality)   │
│  - **AgentShield-pack** (Pro: guardrails + scanner)  │
│  - **research-pack** (Pro: research-playbook)         │
├─────────────────────────────────────────────────────┤
│ L2 Process (keep)                                    │
│  superpowers v5.0.7 (brainstorming/plans/TDD/…)      │
├─────────────────────────────────────────────────────┤
│ L1 Persona/Memory (redzone, untouchable)             │
│  SOUL=kuromi + hooks 16 本 + CLAUDE.md persona 部     │
└─────────────────────────────────────────────────────┘
```

### Workflow 連携順序（採用: a-1 or a-2 が **AgentShield 判定で確定**）

```
katsu prompt
  → L1 (memory grep + persona enforce)
  → L2 superpowers (brainstorming / writing-plans)
  → L3 ECC (specialist agent dispatch)
  → L4 Domain skill (業務 fit 時)
  → L1 (persona-linter + kansai-score 最終 verify)
```

---

## §5 Test Repo Setup (`kuromi-config-ecc-poc`)

### Scope: **A (minimal)**（katsu 承認済）

含める:
- `CLAUDE.md` (a-1 ルール追加版 + a-2 比較版を別 branch)
- `agents/` (ECC 由来 selective、業務 fit する分)
- `commands/` (ECC 由来 selective)
- `rules/` (ECC `rules/common/` 全部)
- `docs/superpowers/specs/` (本 design + 後続 plan)

含めない:
- hooks 実体 (実体 js は ECC review でも価値薄、Local で session 単体 test 可)
- settings.json (機微情報多、redact 漏れ risk)
- 業務 skill (ebi-* / nemoclaw-* / api-* 等、敏感)
- handoff / memory / qa-log (機微)
- `.env` / API key 系一切

### Repo 構造（test repo 完成形 = push 直前）

```
kuromi-config-ecc-poc/
├── README.md                         # 目的 + a-1/a-2 比較 + ECC review 結果
├── CLAUDE.md                          # main branch = a-1 版 (rule-based)
├── docs/
│   └── superpowers/
│       └── specs/
│           └── 2026-05-15-kuromi-ecc-integration-design.md  # 本 doc
├── agents/                            # ECC cherry-pick 15-20 体
│   ├── planner.md
│   ├── code-reviewer.md
│   ├── tdd-guide.md
│   ├── security-reviewer.md
│   ├── architect.md
│   └── ...
├── commands/                          # ECC cherry-pick 18
│   ├── plan.md
│   ├── tdd.md
│   ├── code-review.md
│   └── ...
├── rules/
│   └── common/                        # ECC rules/common/ 全部
│       ├── security.md
│       ├── testing.md
│       ├── coding-style.md
│       ├── git-workflow.md
│       └── ...
└── .gitignore
```

### branch 戦略

| branch | 内容 | PR target |
|--------|------|-----------|
| `main` | base setup (CLAUDE.md = persona keep + 空 integration rule) | — |
| `feat/a-1-rule-based` | CLAUDE.md に a-1 ルール追加 | PR #1 → main |
| `feat/a-2-hook-based` | hooks-snippets/ に a-2 hook script + CLAUDE.md 参照追加 | PR #2 → main |

両 PR を ECC Tools App `/ecc-tools analyze` で同時 review、AgentShield-backed feedback で比較判定。

---

## §6 a-1 / a-2 具体実装

### a-1: CLAUDE.md rule-based (branch `feat/a-1-rule-based`)

CLAUDE.md に **新規 section** 追加:

```md
## superpowers × ECC 連携ルール (Layer 2 → L3)

新機能追加 / 大型改修の prompt を katsu から受けた場合、以下 sequence 厳守:

1. superpowers:brainstorming で要件探索
2. brainstorming 完了 (= design doc 書いた) 後、必ず ECC `planner` agent を Agent tool で dispatch
3. planner 出力 = phase 別 implementation plan を superpowers:writing-plans に渡す
4. writing-plans 完了後、ECC `tdd-guide` agent を dispatch して TDD loop
5. 実装完了後、ECC `code-reviewer` + `security-reviewer` agent 並列 dispatch
6. superpowers:verification-before-completion で最終確認

例外（rule skip 可）:
- 単純な typo / 1 行修正 / 既知 file の rename 等、設計判断不要 case
- katsu が明示的に「planner 不要」「skip ECC」と指示した case
```

### a-2: Hook-based 物理強制 (branch `feat/a-2-hook-based`)

`hooks-snippets/superpowers-ecc-bridge.js` 追加:

```js
#!/usr/bin/env node
// PostToolUse on Skill tool、superpowers:brainstorming 完了検出
// → 次の Stop で UserPromptSubmit injection で「ECC planner 必須」
const fs = require('fs');
const input = JSON.parse(fs.readFileSync(0, 'utf8'));
if (input.tool === 'Skill' && input.tool_input?.skill === 'superpowers:brainstorming') {
  // ~/.claude/state/ecc-bridge.flag に flag 立てる
  fs.writeFileSync(`${process.env.HOME}/.claude/state/ecc-bridge.flag`,
    JSON.stringify({pendingPlannerDispatch: true, ts: Date.now()}));
}
process.stdout.write(JSON.stringify(input));
```

+ UserPromptSubmit hook で flag check → injection:

```js
const flag = readFlag();
if (flag.pendingPlannerDispatch) {
  return injectMessage(
    "[ECC-BRIDGE] superpowers:brainstorming 完了検出。次 turn で ECC planner agent dispatch 必須。"
  );
}
```

CLAUDE.md には参照のみ追加 (rule 本体は hook が enforce):
```md
## superpowers × ECC 連携 = hook で物理強制（hooks-snippets/superpowers-ecc-bridge.js）
```

---

## §7 ECC Tools Review 手順

### Pre-condition
- katsu が `ecc.tools/account` で Pro tier active 確認（`kanto.eco@gmail.com`）
- `kuromi-config-ecc-poc` を GitHub に push 済
- ECC Tools GitHub App を **この repo にのみ install**

### Review flow

```
Step 1: PR #1 (a-1) と PR #2 (a-2) を main に対して open
Step 2: 各 PR の issue tab で `/ecc-tools analyze` コメント
Step 3: ~5-15 min で ECC Tools が以下を生成:
  - SKILL.md (repo パターンから抽出)
  - guardrails.md (AgentShield 由来の警告 / 推奨)
  - instincts.yaml (continuous-learning 由来の挙動推奨)
  - PR-triggered config audit 結果（Pro 限定）
Step 4: katsu + くろみ で生成 PR を read、AgentShield コメント比較
Step 5: 比較表作成:
  - a-1 と a-2 で AgentShield 警告数 / 推奨数 / 重要度
  - secret 漏洩 risk / loop risk / persona 干渉 risk の AgentShield 評価
Step 6: 採用案確定（a-1 or a-2 or 折衷）
Step 7: 採用版を `~/.claude/CLAUDE.md` に反映 + (a-2 採用なら) hook 配備
```

### 判定基準（AgentShield 出力 read 時）

| 基準 | a-1 採用シグナル | a-2 採用シグナル |
|------|---------------|---------------|
| AgentShield 警告数 | 少 = a-1 OK | 少 = a-2 OK |
| loop / 過剰発火警告 | a-1 推奨 (= rule なら無視可) | a-2 反対材料 |
| 強制力評価 | 「rule 無視 risk」言及 = a-2 推奨 | — |
| token cost 警告 | a-1 (= 任意 dispatch なので cost 低) | a-2 反対材料 |
| persona 干渉警告 | どっちも要確認 | どっちも要確認 |
| 「最適 practice」言及 | どっちが「ECC-aligned」か言及見る | 同 |

判定不能（両者ほぼ同等）の場合 = **a-1 採用 default**（理由: rollback 容易、token cost 低、katsu 観察可）

---

## §8 Components to Install (full)

### `ecc-universal install --profile developer --add security --add research`

| Component | path | 用途 |
|-----------|------|------|
| runtime-core | `~/.claude/skills/everything-claude-code/SKILL.md` + identity.json + instincts | ECC core |
| 60 agents | `~/.claude/agents/*.md` | planner / code-reviewer / 等 |
| 75 commands | `~/.claude/commands/*.md` | /plan, /tdd, /code-review 等 |
| 228 skills | `~/.claude/skills/*/SKILL.md` | search-first / verification-loop / 等 |
| rules/common/ | `~/.claude/rules/common/` | security / testing / coding-style / git-workflow |
| **agentshield-pack** (Pro) | `~/.claude/rules/everything-claude-code-guardrails.md` + scanner | AgentShield 監査 |
| **research-pack** (Pro) | `~/.claude/research/everything-claude-code-research-playbook.md` | research workflow |
| workflow-pack | `~/.claude/commands/database-migration.md` + feature-development.md + add-language-rules.md | 追加 workflow command |
| ECC hooks layer | settings.json に手動 merge | pre-bash-dispatcher / config-protection / mcp-health-check / post:quality-gate / post:context-monitor / stop:cost-tracker 等 |

### skip するもの
- team-config-sync (Pro 該当外 + 1 person 不要)
- enterprise-controls (Enterprise tier、不要)
- `gateguard-fact-force` hook（find-before-claim と趣旨被り）
- `pre:observe` continuous-learning hook（auto-rag と二重）
- `governance-capture` hook（opt-in only、現時点 disable）

---

## §9 Verification Plan

### Phase 別 verify

| Phase | 検証項目 | PASS 条件 |
|-------|--------|---------|
| Phase 0 backup | backup dir 存在 + 完全 cp | `~/.claude.bak-*` size = orig size ± 10% |
| Phase 1 ecc-universal install | `which ecc-universal` 通る | exit 0 |
| Phase 2 Pro auth | `ecc-universal auth status` で Pro tier 表示 | tier="pro" or "enterprise" |
| Phase 3 dry-run | install plan の change list | くろみ既存 file への overwrite なし |
| Phase 4 install | `~/.claude/agents/` に 60 file + `commands/` 75 file 配備 | file count 一致 |
| Phase 5 動作 | くろみ persona 維持 + /plan invoke OK | kansai-score PASS + persona-linter PASS + planner agent 起動 |
| Phase 6 test repo | `kuromi-config-ecc-poc` push 済 + ECC App install | PR comment で `/ecc-tools analyze` 反応 |
| Phase 7 ECC review | PR #1/#2 で ECC 生成 PR 出る | 5-15 min 内に review PR open |
| Phase 8 採用判定 | a-1 or a-2 確定 | AgentShield 比較表で明確差 |
| Phase 9 本体反映 | `~/.claude/CLAUDE.md` 更新 + persona section untouched | persona/サボり防止 部分 diff = 0 |
| Phase 10 hook 統合 | settings.json で ECC hook 並列追加 | くろみ hooks 17 本 + ECC 追加分 順序維持 |
| Phase 11 最終 | 1 session で具体 prompt test = 「機能 X 追加」 | L2 → L3 → L4 → L1 順序通り発火 |

### おかしくなった時の症状 detection

| 症状 | 検出 file | 重要度 |
|------|---------|-------|
| Loop (agent chain 暴走) | `~/.claude/telemetry/*.jsonl` で同 agent >3 回 / response | ★★★ |
| Token 爆発 | ECC `stop:cost-tracker` 出力で cost > baseline × 3 | ★★★ |
| Process 早送り | transcript で ExitPlanMode 前に Edit/Write | ★★ |
| Persona 衝突 | `kansai-score.js` stderr で 違反 detection | ★★★ |
| 重複 review | transcript で同 file が 2 回 review | ★ |
| memory 不整合 | `memory-grep-enforce.js` stderr で 違反 | ★★ |

---

## §10 Rollback Plan

### Phase 別 rollback 経路

| Phase | rollback 方法 |
|-------|------------|
| Phase 0-4 (install only) | `rm -rf ~/.claude && mv ~/.claude.bak-* ~/.claude` |
| Phase 5-7 (test repo) | test repo 削除 + ECC App uninstall (= GitHub UI) |
| Phase 8-9 (CLAUDE.md 反映後) | `cp ~/.claude.bak-*/CLAUDE.md ~/.claude/CLAUDE.md` |
| Phase 10 (hook 統合後) | `cp ~/.claude.bak-*/settings.json ~/.claude/settings.json` + (a-2 時) hook file 削除 |
| 完全 abort | `~/.claude` 全廃棄 + backup 復元 |

### 緊急 rollback trigger
- persona-linter / kansai-score が response あたり 3 回以上違反
- katsu「すぐ戻して」明示
- 業務 skill (ebi-* / nemoclaw-*) が動作不能（= L4 干渉発生）
- Cost spike >5× baseline

---

## §11 Risks

| Risk | likelihood | impact | mitigation |
|------|----------|-------|----------|
| ECC hooks が くろみ hooks 順序を破壊 | 中 | 高 | hook 統合は **手動 merge**、自動 install 不可、Phase 10 別 session |
| AgentShield review が「persona 強制」を bug 認定 | 低 | 中 | review 結果は参考、katsu 最終判断 |
| ECC 60 agents 配備で `~/.claude/agents/` 重く load 遅延 | 低 | 低 | model selection と connection、起動時間 +1-2 sec 想定 |
| Pro auth 失敗 (`kanto.eco@gmail.com` recovery 不可) | 低 | 中 | `ecc.tools/account` で先に portal 確認 |
| test repo の minimal scope でも secret 漏洩 | 低 | 高 | A scope = CLAUDE.md/agents/commands/rules のみ、`.env` / hook 実体 含めず |
| MEMORY.md 178KB 肥大で session start 遅延 | 既知 | 中 | 本 design とは別 task、後日整理 |

---

## §12 Out of Scope (本 design では扱わない)

- MEMORY.md 圧縮（別 task）
- NemoClaw enterprise release path（独立、影響なし）
- 他言語 reviewer agent の業務利用（Java/C#/Kotlin/Rust/Swift/Dart 等、配備のみで dormant）
- ecc-universal の自動 update 戦略（手動 rerun で対応、別 task）
- Continuous learning v2 の有効化（auto-rag と二重なので保留）

---

## §13 Locked Decisions（katsu 承認 2026-05-15）

1. **test repo visibility = public**
   - A scope = 機微情報なし、validation robust 優先
   - Free tier でも `/ecc-tools analyze` 動く保険

2. **ECC App install 範囲 = `kuromi-config-ecc-poc` のみ**
   - 他 repo (`kk-ben/project` / nemoclaw-enterprise 等) は **install しない**
   - test 完徹後に別判断

3. **a-1 ルール trigger = (a) 機能追加 / 実装全般 + skip 例外明示**
   - rule body: 「新機能追加 / 大型改修 / 実装 prompt」発火
   - 例外: 単純 typo / 1 行修正 / rename / katsu 明示 skip 指示

---

## §14 Success Criteria

- [ ] Phase 0-4 install 完徹、くろみ persona 維持
- [ ] test repo push + ECC App install + `/ecc-tools analyze` PR 生成
- [ ] a-1 / a-2 AgentShield review 取得 + 比較表作成
- [ ] 採用案を `~/.claude/CLAUDE.md` に反映 (persona section 不変)
- [ ] hook 統合後の 1 session test で L2→L3→L4→L1 順序動作
- [ ] 他 session で「くろみ挙動アホ」事案発生せず（katsu 体感判定）

---

**End of Design Doc v1**
