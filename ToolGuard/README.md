# ToolGuard

A local watchdog that sits between an AI agent and its tools, catches
broken tool calls in real time, auto-fixes/retries them, and shows a
live before/after reliability dashboard. Runs fully local via vLLM on
an AMD Radeon GPU instance.

Built for AMD AI DevMaster Hackathon 2026, Track 2 (Agentic AI).

## The problem

Agent frameworks calling tools through local LLMs regularly hit these
real, documented failures (see docs/failure_patterns.md for sources):

1. Model outputs a tool call as plain text instead of a structured call
2. Model calls the right tool with a slightly wrong/malformed name
3. Model leaks the tool's schema instead of returning a result

ToolGuard detects these as they happen and fixes what it can, instead
of the agent just silently failing.

## Architecture

```
[Test Agent] --tool call attempt--> [ToolGuard] --checked/fixed call--> [Fake Tools]
                                         |
                                         v
                                 [Live Dashboard]
```

- `agent/` — test agent + fake tools + on-demand failure triggers (Person A)
- `toolguard/` — detection + auto-fix core (Person B)
- `dashboard/` — live before/after reliability view (Person C)
- `benchmarks/` — failure-rate results, ToolGuard OFF vs ON
- `docs/` — spec document source, failure pattern write-up with sources

## Running it locally

1. Launch a Radeon Cloud GPU instance.
2. `source /workspace/setup_env.sh` (see Run.txt for full startup sequence)
3. Start vLLM serving `Qwen/Qwen2.5-7B-Instruct` with tool-calling enabled.
4. `pip install -r requirements.txt`
5. `python agent/test_agent.py` — runs the agent against the fake tools
   with ToolGuard sitting in the middle.
6. Open `dashboard/` in a browser to watch it live.

## ROCm / AMD-specific notes

(Fill in during Day 4-5: exact vLLM flags used, any quantization applied,
tokens/sec numbers, anything that broke and how it was worked around.
This section is part of the 40% GPU-optimization scoring — don't skip it.)

## Team

- Person A — test agent & fake tools
- Person B — detection & auto-fix logic
- Person C — ROCm/vLLM setup, benchmarking, dashboard
