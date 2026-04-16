# Timelapse generator (local macOS) — design spec

**Date:** 2026-04-16  
**Status:** Approved for implementation planning (v0 scope)

## Goal

A **local-only** tool on this Mac that:

1. **Starts and stops** screen recording of the **main display** from the **command line**.
2. After recording ends, **converts** the capture to a **fixed-speedup timelapse**.
3. Writes a **WhatsApp-friendly MP4** (H.264, modest resolution, **small file size** prioritized over fidelity).

**Non-goals for v0:** App Store distribution, cloud upload, multi-user sync, audio capture (unless explicitly added later).

## Distribution and signing

- **Development and daily use:** Run from the terminal; **no App Store** and no App Store–specific constraints.
- **Optional later:** Apple **Developer ID** signing and **notarization** to reduce Gatekeeper friction—still **outside** the App Store.

## v0 scope (approved): ffmpeg-only, full main display

**v0 uses `ffmpeg` only** for capture and transcode. That implies:

- **The recording includes everything visible on the main display**, including Terminal and any other windows. **Per-app exclusion (e.g. Terminal) is explicitly out of scope for v0.**
- **RAM / complexity:** Transcoding with `ffmpeg` is **standard and efficient** for 720p–1080p-class output; capture I/O and encode settings matter more than raw RAM for typical sessions. The **simplest** path is **ffmpeg end-to-end** without a separate native recorder.

**“Ready quickly”:** v0 is intentionally a **small CLI** (shell wrapper and/or minimal script) that shells out to `ffmpeg`. A **literal five-minute** first version is possible in the best case; **first-run permission prompts**, flag tuning, and one validation pass on this machine should be budgeted separately.

## Deferred: v1 (optional follow-up)

| Feature | Approach |
|--------|----------|
| **Exclude Terminal (and later other apps)** | **ScreenCaptureKit** (Swift) with content filters; **not** achievable with display-wide ffmpeg capture alone. |
| **Menu bar Start/Stop** | Small native UI; pairs naturally with v1 if we already ship a Swift helper. **Out of v0** to keep the first deliverable a single CLI + `ffmpeg`. |

## Functional requirements (v0)

### Recording

- Capture the **main display** only (primary screen in a multi-monitor setup is acceptable as “main”; exact device index is chosen at implementation time via `ffmpeg` device listing).
- **Video only** for v0; **no microphone / system audio** unless we add a later flag (default **silent**).

### Timelapse

- **Fixed speedup** (e.g. default **60×**), **configurable** via CLI (e.g. `--speed 60`).
- Applied in post (after stop), not as a vague “faster playback” only in a player—output file must be **actually shortened** on disk.

### Output

- **Container:** MP4.
- **Video:** H.264, **yuv420p**, resolution **capped** (e.g. max **1280×720** or **1920×1080** scaled down) to favor **small files**.
- **Rate control:** CRF and/or max bitrate tuned for **share size** (WhatsApp tolerates varying limits; **≤ ~16 MB** is a reasonable **soft target** for many clips, not a hard guarantee for arbitrarily long recordings).

### CLI

- **`start`:** begins recording; writes **session state** (PID, temp path, start time, speedup, output directory).
- **`stop`:** stops recording, runs transcode pipeline, writes final MP4 to the output directory (default **`<repo>/output/`**, resolved from the `bin/timelapse` install path), **timestamped filename**.
- **Concurrent sessions:** **Reject** a second `start` while an active session exists (v0).

### Permissions

- macOS **Screen Recording** permission for the **terminal / binary** that launches `ffmpeg` (first run may require **System Settings → Privacy & Security → Screen Recording**).

## Data flow (v0)

1. **Start:** Create session staging path (e.g. under **`<repo>/output/.staging/<uuid>/`**), start `ffmpeg` **screen capture** to a **temporary** file (e.g. MOV/MP4 intermediate).
2. **Stop:** Gracefully stop `ffmpeg` (signal handling), then run **second** `ffmpeg` invocation (or filter graph—implementation detail) to apply **`setpts`** for speedup, **`scale`** to max resolution, and **H.264** encode to the **final MP4**.
3. **Success:** Remove or trim staging files; **Failure:** **Retain** staging and print paths for manual recovery.

## Error handling (v0)

| Situation | Behavior |
|-----------|----------|
| Screen Recording denied | Clear message + pointer to System Settings; non-zero exit. |
| Disk full / write failure | Abort; keep partial staging; non-zero exit. |
| `ffmpeg` encode failure | Print **stderr** tail; leave staging; non-zero exit. |
| `stop` with no active session | Clear error; non-zero exit. |
| Stale state file (crash) | Next `start` detects orphan state and **cleans up or warns** (implementation chooses one deterministic behavior). |

## Testing (v0)

- **Manual:** Short clip (e.g. 30s), verify output duration ≈ **input duration / speedup** (within container accuracy).
- **Manual:** Verify MP4 **opens in QuickTime** and **imports to WhatsApp** on this machine.
- **Manual:** Double `start` rejected; `stop` with no session errors cleanly.

## Open parameters (implementation plan will fix defaults)

- Default **speedup** (proposal: **60**).
- Default **max resolution** and **CRF / bitrate** presets (“small / smaller / smallest”).
- Exact **ffmpeg device selection** string for “main display only” on Apple Silicon + current macOS.

## Success criteria

- One-command **start** / **stop** workflow from the terminal.
- Output **MP4** suitable for **casual WhatsApp sharing** from this laptop without App Store packaging.
- **Honest v0 limitation:** no Terminal or app exclusion; **v1** document may add SCK + exclusions + optional menu bar.
