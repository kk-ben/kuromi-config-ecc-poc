#!/usr/bin/env bash
# 動作確認 script
# Usage: bash scripts/verify.sh
#
# このスクリプトは以下を検証する:
#   1. ECC OSS install 健全性 (= ~/.claude/ の構成)
#   2. AgentShield CLI 動作
#   3. a-1 rule (CLAUDE.md 反映)
#   4. backup 経路存在
#   5. test repo content 整合性

set -uo pipefail

PASS=0
FAIL=0
WARN=0

ok()   { echo "  ✓ $1"; PASS=$((PASS+1)); }
ng()   { echo "  ✗ $1"; FAIL=$((FAIL+1)); }
warn() { echo "  ⚠ $1"; WARN=$((WARN+1)); }

echo "=== 1. ECC OSS install 健全性 ==="

# agents 数
AGENTS_COUNT=$(ls ~/.claude/agents/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$AGENTS_COUNT" -ge 40 ]; then ok "agents/: $AGENTS_COUNT files (expected >= 40)"; else ng "agents/: $AGENTS_COUNT files (expected >= 40)"; fi

# commands 数
COMMANDS_COUNT=$(ls ~/.claude/commands/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$COMMANDS_COUNT" -ge 70 ]; then ok "commands/: $COMMANDS_COUNT files (expected >= 70)"; else ng "commands/: $COMMANDS_COUNT files"; fi

# skills 数
SKILLS_COUNT=$(ls ~/.claude/skills/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$SKILLS_COUNT" -ge 150 ]; then ok "skills/: $SKILLS_COUNT files"; else ng "skills/: $SKILLS_COUNT files (expected >= 150)"; fi

# rules 数
RULES_COUNT=$(find ~/.claude/rules -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$RULES_COUNT" -ge 80 ]; then ok "rules/: $RULES_COUNT files"; else ng "rules/: $RULES_COUNT files (expected >= 80)"; fi

# 主要 agent / command 存在
for f in agents/planner.md agents/code-reviewer.md agents/tdd-guide.md agents/security-reviewer.md \
         commands/plan.md commands/tdd.md commands/code-review.md \
         skills/search-first/SKILL.md skills/prompt-optimizer/SKILL.md; do
  if [ -e ~/.claude/$f ]; then ok "$f exists"; else ng "$f MISSING"; fi
done

echo ""
echo "=== 2. AgentShield CLI 動作 ==="

if command -v agentshield >/dev/null 2>&1; then
  VER=$(agentshield --version 2>/dev/null | head -1)
  ok "agentshield CLI installed (version $VER)"
else
  ng "agentshield CLI MISSING (run: npm install -g ecc-agentshield)"
fi

# scan 起動テスト (= 1 sec で help 表示確認)
if agentshield scan --help >/dev/null 2>&1; then ok "agentshield scan --help OK"; else ng "agentshield scan invoke failed"; fi

echo ""
echo "=== 3. a-1 rule (CLAUDE.md 反映) ==="

if grep -q "superpowers × ECC 連携ルール" ~/.claude/CLAUDE.md; then
  ok "a-1 rule section found in CLAUDE.md"
else
  ng "a-1 rule section MISSING in CLAUDE.md"
fi

if grep -q "手順書.*ECC.*工具" ~/.claude/CLAUDE.md; then
  ok "a-1 revised wording found (= 両方併用)"
else
  warn "a-1 revised wording not found (= may be old v1)"
fi

# redzone section 保持 (= emoji / 修飾語含むため部分一致)
for section in "ペルソナ" "サボり防止" "えび" "セキュリティ" "既知のバグ"; do
  if grep -q "$section" ~/.claude/CLAUDE.md; then
    ok "redzone section $section preserved"
  else
    ng "redzone section $section MISSING"
  fi
done

echo ""
echo "=== 4. settings.json 健全 + custom hooks ==="

if node -e "JSON.parse(require('fs').readFileSync('/Users/kkben/.claude/settings.json'))" 2>/dev/null; then
  ok "settings.json JSON valid"
else
  ng "settings.json JSON BROKEN"
fi

HOOK_COUNT=$(node -e "
const s = JSON.parse(require('fs').readFileSync('/Users/kkben/.claude/settings.json'));
let n = 0;
for (const groups of Object.values(s.hooks || {})) for (const g of groups) n += (g.hooks||[]).length;
console.log(n);
" 2>/dev/null)
if [ "$HOOK_COUNT" -ge 25 ]; then ok "hooks total: $HOOK_COUNT (expected >= 25)"; else warn "hooks total: $HOOK_COUNT"; fi

# 重要 custom hook 存在
for hook in block-destructive-bash mcp-health-check quality-gate cost-tracker desktop-notify; do
  if [ -f ~/.claude/scripts/hooks/$hook.js ]; then ok "hook script $hook.js exists"; else warn "hook script $hook.js not found"; fi
done

# kuromi 既存 hook
for hook in soul-ping persona-linter kansai-score memory-grep-enforce enforce-skill-tool; do
  if [ -f /Users/kkben/Projects/Claude-Code-Communication/.claude/hooks/$hook.js ]; then
    ok "kuromi hook $hook.js preserved"
  else
    ng "kuromi hook $hook.js MISSING"
  fi
done

echo ""
echo "=== 5. backup 経路 (= rollback 可能性) ==="

BAK_COUNT=$(ls -d ~/.claude.bak-* 2>/dev/null | wc -l | tr -d ' ')
if [ "$BAK_COUNT" -ge 1 ]; then ok "~/.claude.bak-* exists ($BAK_COUNT dirs)"; else ng "no backup found"; fi

for pattern in "CLAUDE.md.bak-pre-ecc-*" "CLAUDE.md.bak-pre-a1-*" "settings.json.bak-pre-merge-*"; do
  if ls ~/.claude/$pattern 2>/dev/null >/dev/null; then
    ok "individual backup $pattern exists"
  else
    warn "individual backup $pattern not found"
  fi
done

echo ""
echo "=== 6. secrets dir + perm ==="

if [ -d ~/.claude/secrets ]; then
  PERM=$(stat -f %A ~/.claude/secrets 2>/dev/null || stat -c %a ~/.claude/secrets 2>/dev/null)
  if [ "$PERM" = "700" ]; then ok "~/.claude/secrets/ exists, perm 700"; else warn "~/.claude/secrets/ perm $PERM (expected 700)"; fi
fi

if [ -f ~/.claude/secrets/ebi.env ]; then
  PERM=$(stat -f %A ~/.claude/secrets/ebi.env 2>/dev/null || stat -c %a ~/.claude/secrets/ebi.env 2>/dev/null)
  if [ "$PERM" = "600" ]; then ok "~/.claude/secrets/ebi.env exists, perm 600"; else warn "ebi.env perm $PERM (expected 600)"; fi
fi

echo ""
echo "=== Summary ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"
echo ""

if [ "$FAIL" -eq 0 ]; then
  echo "✓ All critical checks passed"
  exit 0
else
  echo "✗ $FAIL critical failures detected"
  exit 1
fi
