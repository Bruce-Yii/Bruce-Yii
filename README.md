<div align="center">

# 👋 Hi, I'm Bruce Yi

**AI Product · Agent Systems · Open Source**

I fix agent systems upstream: CLI reliability, RAG fidelity, eval correctness, OAuth edge cases. Small, verifiable patches — merged, not claimed.

<p>
  <img alt="Profile views" src="https://komarev.com/ghpvc/?username=Bruce-Yii" />
  <img alt="Open Source" src="https://img.shields.io/badge/Open_Source-merged_upstream-blue" />
  <img alt="AI Product" src="https://img.shields.io/badge/AI_Product-agent_systems-8A2BE2" />
  <img alt="Agent Systems" src="https://img.shields.io/badge/Agent_Systems-reliability-green" />
</p>

</div>

- Focus: agent CLIs & gateways (OpenClaw), RAG pipelines (Dify), eval harnesses (ModelScope EvalScope), console & auth flows (QwenPaw, OpenCodex), install reliability (dsh-market)
- Method: reproduce first, keep the diff minimal, verify against current `main`
- Profile: [github.com/Bruce-Yii](https://github.com/Bruce-Yii)

## Upstream contributions (merged, verifiable)

Every entry links to a merged upstream PR — no claims without a link.

| Area | Merged PR | What changed |
|------|-----------|--------------|
| OpenClaw · gateway reliability | [openclaw/openclaw#145220](https://github.com/openclaw/openclaw/pull/145220) | `doctor --fix` no longer leaves the systemd-user gateway stopped after repair |
| EvalScope · eval correctness | [modelscope/evalscope#1729](https://github.com/modelscope/evalscope/pull/1729) | Real multi-image MMMU dataset mode (perf) |
| Dify · data fidelity | [langgenius/dify#42221](https://github.com/langgenius/dify/pull/42221) | Preserve literal `NA` in annotation CSV imports |
| Dify · RAG fidelity | [langgenius/dify#42171](https://github.com/langgenius/dify/pull/42171) | Preserve Notion mention and equation text in RAG ingestion |
| OpenClaw · CLI output contract | [openclaw/openclaw#144579](https://github.com/openclaw/openclaw/pull/144579) | Keep transcript output free of startup notes |
| QwenPaw · console UX | [agentscope-ai/QwenPaw#7593](https://github.com/agentscope-ai/QwenPaw/pull/7593) | Restore session direct-path input alongside picker |
| dsh-market · install reliability | [dsh-market/dsh-market#119](https://github.com/dsh-market/dsh-market/pull/119) | Reclaim orphaned pnpm store staging dirs after failed runs |
| OpenCodex · auth robustness | [lidge-jun/opencodex#1418](https://github.com/lidge-jun/opencodex/pull/1418) | Guard `expires_in` parsing against NaN across token responses |

More merged work (same author, live on GitHub): [search `author:Bruce-Yii is:pr is:merged`](https://github.com/search?q=author%3ABruce-Yii+is%3Apr+is%3Amerged&type=pullrequests) — e.g. Dify #42212, OpenClaw #141569 / #140531, EvalScope #1720, dsh-market #117 / #115.

## Focus

- Agent reliability: startup/transcript contracts, gateway repair paths, session handling
- RAG & data: CSV/Notion ingestion fidelity, annotation correctness
- Eval: dataset modes that reflect real multimodal inputs
- Auth & install: token-expiry guards, retry/timeout semantics, store recovery

## Recent OSS activity

<!-- OSS-ACTIVITY:START -->
- 2026-09-20 — `langgenius/dify#42171` merged — fix(rag): preserve Notion mention and equation text
- 2026-09-17 — `modelscope/evalscope#1729` merged — feat(perf): add real multi-image MMMU dataset mode
- 2026-09-12 — `langgenius/dify#42221` merged — fix(api): preserve literal NA in annotation CSV imports
- 2026-09-12 — `langgenius/dify#42212` merged — fix: ignore blank keyword rows in moderation limit
- 2026-09-11 — `openclaw/openclaw#145220` merged — fix(doctor): doctor --fix leaves systemd-user gateway stopped after repair
- 2026-09-11 — `modelscope/evalscope#1720` merged — fix(utils): narrow check_import exception handling
- 2026-09-11 — `openclaw/openclaw#144579` merged — fix(cli): keep transcript output free of startup notes
<!-- OSS-ACTIVITY:END -->

> Auto-updated weekly from the GitHub API. Handwritten sections are preserved via markers; the updater never erases content on API failure and never commits when there is no change.

## Contributions

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/Bruce-Yii/Bruce-Yii/main/dist/github-snake-dark.svg" />
  <img alt="Contribution grid snake" src="https://raw.githubusercontent.com/Bruce-Yii/Bruce-Yii/main/dist/github-snake.svg" />
</picture>
