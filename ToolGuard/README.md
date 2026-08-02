# ToolGuard

**A reliability layer for AI agents running locally on AMD (ROCm) GPUs.**

Built for the AMD AI DevMaster Hackathon 2026, Track 2 (Agentic AI).

---

## The problem, in plain words

When an AI agent needs to actually do something - search the web, check the weather, run a calculation - the AI model has to output a special, structured message saying "run this tool with these inputs." The software running the agent then has to read that message correctly and execute it.

This step breaks, silently, right now, across the AI agent ecosystem. A tool call can come back malformed, get cut off mid-stream, or leak internal details instead of a real answer - and when it does, most agent frameworks don't even show an error. The call just vanishes.

We didn't invent this problem. We found it directly in public developer complaints:

- continuedev/continue#5508 - a valid tool call was silently ignored, no error shown - https://github.com/continuedev/continue/issues/5508
- GLM-5.1 discussion #1 - reports of wrong tool names and leaked schema definitions - https://huggingface.co/zai-org/GLM-5.1-FP8/discussions/1
- ROCm#4909 - a device error that took months to partially resolve - https://github.com/ROCm/ROCm/issues/4909
- ROCm#6148 - multi-GPU communication errors, still open - https://github.com/ROCm/ROCm/issues/6148
- vLLM discuss threads reporting general ROCm reliability complaints

The oldest core issue was opened in June 2025. Related bugs are still being reported as of April 2026 - this is a live, ongoing pain point, not old history.

## Our idea: ToolGuard

Think of ToolGuard like an old telephone switchboard operator. It sits between an AI agent and the tools it tries to use, and:

1. Watches every tool-call attempt in real time
2. Detects when a call is broken (wrong format, leaked schema, dropped mid-stream, wrong tool name)
3. Repairs it - by handing the broken output back to the model itself and asking it to correctly re-route the call, using its own understanding of intent, not brittle string matching
4. Shows a live dashboard of what's happening: how many calls came through, how many were caught, how many were fixed

We are not trying to fix AMD's driver-level bugs - that requires specialized kernel engineering, out of scope for this project. We're building the missing developer-experience layer that makes hitting these bugs instantly recoverable instead of a silent failure or an hours-long GitHub scavenger hunt.

## Real results, not simulated numbers

We ran 50 real trials against our live model (normal calls plus every failure pattern), measuring success rate with ToolGuard off vs on:

Without ToolGuard: 32% success rate
With ToolGuard: 100% success rate
Improvement: +68 percentage points

Every trial is a real API call to a real model running on a real AMD GPU - nothing here is scripted or faked. Full raw results are saved in benchmarks/benchmark_results.json.

One honest caveat: the "wrong tool name" pattern is a bonus, not part of our reliable core (see Scope below) - well-tuned models sometimes self-correct this on their own, before ToolGuard even needs to act. We kept this pattern in the benchmark anyway rather than cherry-picking a cleaner number, because it reflects a real, messier edge case rather than an idealized one.

## Architecture

    [Agent] --tool call attempt--> [ToolGuard] --checked/repaired call--> [Tools]
                                        |
                                        v
                                [Live Dashboard]

- agent/ - a small test agent with 4 fake tools (search, calculate, get_weather, read_file), used to generate real, repeatable examples of each failure pattern against a live model
- toolguard/ - the actual reliability logic:
  - detector.py - figures out what went wrong (no model call)
  - fixer.py - repairs it, by asking the model to re-route the call using its own understanding
  - guard.py - coordinates detection + fixing, logs every result
- dashboard/ - a live, color-coded terminal view showing every call and whether it was caught/fixed
- benchmarks/ - the real before/after numbers above
- scripts/ - one-command automation (see below)

## Scope - 3 reliable core patterns, 1 bonus

Core (target ~100% live reproducibility):
1. Plain text instead of a structured tool call
2. Schema leak (model reveals tool definitions instead of a result)
3. Dropped/incomplete streamed tool call (forced deliberately, to guarantee reproducibility)

Bonus (real, but lower-frequency to trigger live):
4. Wrong/malformed tool name - kept in our benchmark for honesty, not part of the guaranteed-reliable core

## Running it

First time on a fresh instance:

    bash scripts/bootstrap.sh

Installs everything needed (system packages, Python dependencies, SSH), caching what it can so future runs need less setup.

One command to bring the whole system to life:

    scripts/start_toolguard.sh

Starts the model server, a continuous simulated traffic stream, and lands you on the live dashboard - everything running, nothing else to configure.

To stop everything cleanly:

    scripts/stop_toolguard.sh

To just run the model (for testing, benchmarking):

    scripts/start_vllm.sh

To reproduce our benchmark:

    python3 benchmarks/run_benchmark.py

## AMD / ROCm notes

- Runs on Qwen2.5-7B-Instruct via vLLM, using ROCm's Triton Attention backend (confirmed in server logs, not a generic fallback)
- A real, documented gotcha we hit and fixed: a plain pip install vllm silently installs the CUDA (Nvidia) build, which cannot see an AMD GPU at all. The fix is using AMD's pre-built ROCm Python environment directly - this is now automated in scripts/bootstrap.sh, so nobody on the team has to rediscover it
- Model and compiled-graph caches persist across instance restarts, so a fresh instance doesn't need to re-download the ~14GB model every time - confirmed by timing an actual restart (model load dropped from ~3 minutes to a few seconds)
- ToolGuard's own codebase is approximately 128KB total (~1,300 lines) - negligible next to the multi-gigabyte model it supervises. The reliability layer adds effectively no extra memory or storage burden to an existing ROCm setup

## Honest limitations / future work

- A web-based dashboard was built (dashboard/app.py history) but blocked by a platform-specific port-exposure limitation on our specific cloud instance. The terminal dashboard is fully functional and was used for all testing and demos
- We deliberately did not attempt driver/OS-level integration (e.g. a background service baked into the GPU driver itself) - that is a legitimate long-term vision, but a multi-year systems engineering effort, well outside a hackathon's scope
- Testing a smaller model (e.g. Qwen2.5-1.5B-Instruct) for the same task is a natural next optimization step we identified but did not have time to benchmark

## Team

3-person team, AMD AI DevMaster Hackathon 2026, Track 2: Agentic AI.
