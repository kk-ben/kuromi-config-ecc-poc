# a-1 vs a-2 判定結果

**Date**: 2026-05-15
**判定者**: kuromi + katsu
**採用**: **a-1 (CLAUDE.md rule-based)**

---

## 背景

spec §7 で「ECC Tools AgentShield に judge させる」path を想定したが、**ECC Tools `/ecc-tools analyze` の実仕様** = repo 全体 bundle 生成 PR を 1 回作成、PR 内容個別 review **しない** 機能と判明（教訓）。

副次的に CodeRabbit (別 install 済 review tool) が PR #4 で rate limit exceeded、PR #3 は summary のみ = 比較材料不足。

→ **手動判定 (技術論理)** に pivot。

---

## 比較表 (8 観点)

| 観点 | a-1 (CLAUDE.md rule) | a-2 (hook 物理強制) | 勝者 |
|------|---------------------|---------------------|------|
| **強制力** | 中 (rule 無視可) | 100% (hook 必発火) | a-2 |
| **rollback 容易性** | 高 (CLAUDE.md edit のみ) | 中 (hook 削除 + settings.json revert) | a-1 |
| **token cost** | 低 (適用判断時のみ planner) | 高 (毎 brainstorming で planner 強制) | a-1 |
| **loop risk** | 低 (例外明示) | 高 (planner → architect → planner 連鎖可) | a-1 |
| **persona 衝突** | 低 (くろみ文脈調整可) | 高 (機械 injection で関西弁崩れ) | a-1 |
| **柔軟性** | 高 (typo / 局所 fix で skip 可) | 低 (全 brainstorming で発火) | a-1 |
| **ECC 自身の流儀** | rule-based (CLAUDE.md / rules/*) | NA (ECC は hook 強制せず) | a-1 |
| **新規 user 理解性** | 高 (rule 読めば分かる) | 低 (hook script 読まないと挙動不明) | a-1 |
| **score** | **7 勝** | **1 勝** | **a-1** |

---

## 採用 a-1 の主理由

1. **ECC 自身が rule-based 流儀**: CLAUDE.md / AGENTS.md / rules/common/*.md は全部 rule、hook 強制じゃない
2. **既存くろみ hook が「検出系」**: persona-linter / kansai-score は違反検出、ECC bridge は hard force injection = 別流儀
3. **token / loop / persona risk** で a-2 失格
4. **rollback 容易**: CLAUDE.md 戻すだけ

---

## 適用 spec

a-1 rule 本体は本 repo `feat/a-1-rule-based` branch の `CLAUDE.md` に記載済 (= 16 行 append、commit `4837434`)。

本体 `~/.claude/CLAUDE.md` への反映は Phase 12 で実施。persona / サボり防止 / えびルール / 既知のバグ / 協働環境 section は **touch 禁止**、a-1 section のみ append。

---

## 教訓 (= 計画失敗 admit)

spec §7「ECC Tools が judge する」path、ECC Tools 公式 doc を 100% 読まずに推測で組んだ。CLAUDE.md「公式 doc は 100% 読む」ルール違反。

今後: ECC Tools 系 / 新ツール導入時は **公式 doc + 実 trigger 動作を verify** してから spec 起稿する。

## 採用後の追加 fix (= 実 session 動作 verify 後)

a-1 を本体 `~/.claude/CLAUDE.md` 反映 + e2e test (= katsu の新 session で「タスク管理 CLI design して」) 実施後に発見した問題と対策:

### 動作 verify 結果

| step | a-1 v1 期待 | 実動作 | 結果 |
|------|-----------|--------|------|
| 1 brainstorming | ✓ Skill tool invoke | **OK** |
| 2 ECC planner dispatch | Agent tool 0 回 | **FAIL** |
| 3+ | (未到達) | - |

### 根本原因

`superpowers:brainstorming` SKILL.md が「terminal state = writing-plans only、ONLY skill to invoke after」と HARD-GATE 明記、a-1 v1 step 2「planner 強制」と衝突 → くろみが superpowers 後段指示に従って planner skip。

### a-1 revise (= v2 確定)

- **大原則明示**: 「superpowers (= 手順書) + ECC (= 工具) 併用」、二者択一じゃない
- **planner を必須から optional に降格** (= writing-plans 並列 or 大型 architecture 判断時のみ)
- **必須は実装完了後の `code-reviewer` + `security-reviewer` 並列 dispatch** のみ
- **既知衝突明示**: superpowers HARD-GATE 違反しないよう wording 整合

### 追加 fix (= 本 session で実施)

1. CLAUDE.md L297 typo 修正 (`設定書` → `設計書`)
2. settings.json deny list 4 → 26 entries (dd / mkfs / shred / docker prune / docker-compose down -v / git clean -fdx / npm publish 等)
3. VPS hostname / IP 平文除去 + `~/.claude/secrets/ebi.env` (0600 perm) 分離
4. (E) 新規 `block-destructive-bash.js` hook = regex deny で `bash -c 'rm -rf'` / `eval` / pipe-to-shell 等 shell trick 経由も block
5. (F) SessionStart handoff inject に owner check + perm <=644 check + SAFETY warning prefix (= prompt injection 緩和)

### 残 MEDIUM backlog (= 別 task)

- mcp-health-check.js dormant injection (= `ECC_MCP_RECONNECT_<SERVERNAME>` env 未設定で dormant、設定時は要 serverName sanitize)
- config-protection.js extend (= tsconfig.json / .husky / .pre-commit-config.yaml 等追加保護)
- additionalDirectories 整理 (= sub-path redundancy、Claude Code permission 挙動 verify 後)
- MEMORY.md 178KB 肥大整理 (= index 圧縮)
- 1-2 ヶ月後 Pro tier 価値判定 → keep / cancel

## archive 宣言

本 repo `kk-ben/kuromi-config-ecc-poc` は **a-1 採用判定 + e2e verify + revise の経緯 archive**。本体 SSoT は `~/.claude/CLAUDE.md` (= 311→324 行 a-1 revised)。**本 repo は read-only reference**、追加変更予定なし。

---

## 関連 file

- spec: `docs/superpowers/specs/2026-05-15-kuromi-ecc-integration-design.md`
- plan: `docs/superpowers/plans/2026-05-15-kuromi-ecc-integration-plan.md`
- a-1 PR: https://github.com/kk-ben/kuromi-config-ecc-poc/pull/3
- a-2 PR: https://github.com/kk-ben/kuromi-config-ecc-poc/pull/4
- ECC bundle PR (merged): https://github.com/kk-ben/kuromi-config-ecc-poc/pull/2
