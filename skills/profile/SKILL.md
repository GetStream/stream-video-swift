---
name: profile
description: >-
  Measure Stream Video Swift performance, binary size, hangs, memory, or thermal behavior.
  Use for profiling investigations and comparisons before and after a change.
---

# Profile

Apply [shared rules](../../AGENTS.md).
Keep an investigation read-only unless the user requests implementation.

## Workflow

1. Define the symptom, scenario, and metric before recording.
   Choose a capture duration that covers the event.
   Record the revision, device, OS, configuration, launch method, and
   attached diagnostics. Check that the target runs the intended build.
2. Check capture permissions and available Instruments, `xctrace`, or equivalent capabilities.
   Inspect supported templates and options.
   If capture is unavailable, analyze supplied traces and state the limit.
3. Reproduce the exact scenario. Mark the event time in the trace.
   Match launch conditions, debugger settings, diagnostics, call roles, network, media settings, and workload.
   Record initial thermal state when relevant.
   Check that the recording contains the event and usable symbols.
4. Follow measured stacks and timing to the responsible component.
   Follow evidence into native media, shared code, or servers through [related repositories](../../AGENTS.md#related-repositories).
   Correlate trace events with logs without treating log severity as proof
   of a crash or hang. Report missing symbols, dropped events, and overhead.
   Separate observed behavior from a proposed cause.
5. If the user authorizes a fix, change the measured cause with the
   [development skill](../development/SKILL.md).
   Repeat the same capture conditions. Compare equivalent intervals and
   repeated runs when variation affects the conclusion.

## Select evidence

| Symptom | Evidence to collect when supported |
| --- | --- |
| UI hang or slow join | Main-thread stacks, Time Profiler, Hangs, Thread Activity, SwiftUI updates, and unified logs (`os_log`). |
| CPU or thermal load | CPU samples, thermal state, media settings, call workload, and capture duration. |
| Memory growth | Allocations, retained objects, memory graphs, and repeated join/leave cycles after teardown. |
| Media degradation | Call timing, frame rate, bitrate, audio routing, and relevant WebRTC statistics. |
| Binary growth | Equivalent Release binaries, bundled resource sizes, and linker maps when available. |

For binary growth, follow the [size comparison procedure](../development/SKILL.md#binary-size).
For WebRTC investigations, read [media performance guidance](../development/references/webrtc.md).
Use a physical device for claims about device thermals or hardware media.
Disclose unmatched captures and their limits without claiming a measured speedup.

## Result

Link the sanitized trace or report outside tracked source directories.
Include the measured interval, baseline, candidate, units, and uncertainty.
State whether the symptom reproduced and whether you retested the final build.
Name the next measurement if the evidence does not establish a cause.
