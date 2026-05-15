# kuromi-config-ecc-poc

`~/.claude/` 設定の ECC 統合 PoC repo。

## 目的

ECC Tools GitHub App AgentShield review に **a-1 (CLAUDE.md rule-based)** vs **a-2 (hook-based 物理強制)** のどちらが best か判定させる。

## scope (A minimal)

含める:
- `CLAUDE.md` (main = base、`feat/a-1-rule-based` で rule 追加、`feat/a-2-hook-based` で参照のみ追加)
- `agents/` ECC cherry-pick 15 体
- `commands/` ECC cherry-pick 18
- `rules/common/` ECC `rules/common/` 全部
- `hooks-snippets/` (a-2 branch のみ) hook script
- `docs/superpowers/{specs,plans}/` design + plan

含めない:
- hook 実体 js / settings.json / 業務 skill (ebi-* / nemoclaw-* / api-*)
- `.env` / handoff / memory / qa-log

## branch 戦略

| branch | 内容 |
|--------|------|
| `main` | base (CLAUDE.md = persona keep + 空 integration rule) |
| `feat/a-1-rule-based` | CLAUDE.md に a-1 ルール追加 |
| `feat/a-2-hook-based` | hooks-snippets/ 追加 + CLAUDE.md 参照のみ追加 |

## ECC Tools review

PR を main に対して open → `/ecc-tools analyze` コメント → AgentShield-backed PR 自動生成。

## design + plan

- spec: `docs/superpowers/specs/2026-05-15-kuromi-ecc-integration-design.md`
- plan: `docs/superpowers/plans/2026-05-15-kuromi-ecc-integration-plan.md`

## license

MIT (設定 file のみ、業務 logic 含まず)
