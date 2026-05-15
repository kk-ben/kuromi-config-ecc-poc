#!/usr/bin/env node
/**
 * a-2: hook-based 物理強制 ECC bridge
 *
 * PostToolUse on Skill tool:
 *   superpowers:brainstorming 完了検出 → ~/.claude/state/ecc-bridge.flag に flag 立てる
 *
 * UserPromptSubmit:
 *   flag check → 「ECC planner agent dispatch 必須」を additionalContext として injection
 *
 * settings.json への登録例 (両 event に同 script):
 *   PostToolUse: matcher="Skill", command="node hooks-snippets/superpowers-ecc-bridge.js"
 *   UserPromptSubmit: matcher="", command="node hooks-snippets/superpowers-ecc-bridge.js"
 *
 * 物理強制: hook 無効化以外で bypass 不可。
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

  const hookEvent = input.hookEventName || input.hook_event_name || '';

  // Mode A: PostToolUse on Skill (brainstorming 完了検出)
  if (hookEvent === 'PostToolUse' && input.tool === 'Skill') {
    const skillName =
      input.tool_input?.skill ||
      input.tool_input?.args?.skill ||
      input.tool_input?.name ||
      '';
    if (skillName === 'superpowers:brainstorming') {
      ensureStateDir();
      fs.writeFileSync(
        FLAG_PATH,
        JSON.stringify({
          pendingPlannerDispatch: true,
          ts: Date.now(),
          triggeredBy: 'superpowers:brainstorming',
        })
      );
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
        process.stdout.write(
          JSON.stringify({
            hookSpecificOutput: {
              hookEventName: 'UserPromptSubmit',
              additionalContext:
                '[ECC-BRIDGE] superpowers:brainstorming 完了検出。' +
                '次 turn で **Agent tool で ECC `planner` agent dispatch 必須** ' +
                '(spec → impl 移行前の plan 生成のため)。skip 不可。',
            },
          })
        );
        return;
      }
    }
  }

  // pass-through
  process.stdout.write(rawInput);
}

main();
