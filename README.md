# timelapse-generator

Local **macOS** screen recorder → **fixed-speedup** timelapse (**ffmpeg**), output as **H.264 MP4** (no audio), sized for casual sharing.

Design: [docs/superpowers/specs/2026-04-16-timelapse-generator-design.md](docs/superpowers/specs/2026-04-16-timelapse-generator-design.md).

## Requirements

- macOS with **ffmpeg** built with AVFoundation (e.g. `brew install ffmpeg`)
- **Screen Recording** for the app that **hosts the shell** you run `timelapse` from (not necessarily Terminal.app).

### Screen Recording from Cursor

If you run commands in **Cursor’s integrated terminal**, macOS attributes `ffmpeg` to **Cursor**. In **System Settings → Privacy & Security → Screen Recording**, turn on **Cursor** (and restart Cursor if macOS asks). Enabling only **Terminal** does nothing for Cursor’s terminal.

The script prints the same hint when a capture fails immediately.

## Run from a terminal (no PATH changes)

From a checkout of this repo:

```bash
cd /path/to/timelapse-generator
chmod +x timelapse.sh bin/timelapse
./timelapse.sh start
./timelapse.sh stop
```

*(First line: run once per clone. In **zsh**, do not put `# …` on the same line as `chmod` unless `setopt interactivecomments` is on, or the shell will treat `#` as a filename.)*

Or call the implementation directly:

```bash
/path/to/timelapse-generator/bin/timelapse start
/path/to/timelapse-generator/bin/timelapse stop
```

## Optional: add `bin` to PATH

```bash
chmod +x bin/timelapse
export PATH="/path/to/timelapse-generator/bin:$PATH"
timelapse start
timelapse stop
```

## Where files go (default)

Finished clips and staging live under the **repo**:

- **`output/`** — final `timelapse-*.mp4` files and **`output/.staging/`** while recording  
- That folder is **gitignored** so videos are not committed.

Override with **`--out-dir`** on `start` if you want another location.

## Usage (same flags for `timelapse.sh` and `bin/timelapse`)

```bash
./timelapse.sh start
./timelapse.sh stop

./timelapse.sh start --speed 30 --out-dir ~/Desktop
./timelapse.sh stop --crf 32 --max-width 960
```

Defaults: **60×** speedup, files under **`<repo>/output/`** (see section above).

Override ffmpeg path: `FFMPEG=/opt/homebrew/bin/ffmpeg ./timelapse.sh start`.

## Timelapse math (`--speed`)

Capture uses **`framestep`** (keep every Nth frame) **and** **`setpts=PTS/N`** so the **file duration** is ~recording_length÷N. Without `setpts`, you’d get a long file with sparse frames (looks like “full video”).

## Empty `raw.ts` / “0 bytes” after `stop`

Wait **a few seconds** after `start` before `stop`, especially with **high `--speed`** (fewer frames written per second of wall clock). If it still fails, check **`output/.staging/.../ffmpeg-capture.log`** (Screen Recording permission, odd display size, etc.).

## Other tools (vs ffmpeg)

For **scriptable** screen capture + encode on the Mac, **ffmpeg** is still the usual default: one binary, lots of filters, good community answers.

If you want **fewer AVFoundation quirks** and are OK writing a small app: **ScreenCaptureKit** (Swift) is the native API (smooth start/stop, content filters in v1 of our spec). **OBS Studio** is strong for interactive recording, less so for a tiny CLI. **GStreamer** is another pipeline toolkit (similar tradeoffs to ffmpeg).

## v0 limits

Records the **entire main display** shown by AVFoundation’s **first “Capture screen”** device (override with `--screen-index`). **No per-app exclusion** (see design doc for a possible v1).

## If `stop` hangs (old sessions / stuck ffmpeg)

Capture runs `ffmpeg` with **`-nostdin`**. The raw file is **MPEG-TS** (`.ts`). **`stop`** waits **~20s on SIGINT** (with extra SIGINT nudges), then **~12s on SIGTERM**, then **SIGKILL** only as a last resort—**SIGKILL often corrupts the `.ts`**, so patience on the first phases avoids a failed remux.

If something is still wedged, in another terminal:

```bash
kill -9 PID_SHOWN_BY_timelapse_start
rm -f ~/.timelapse-generator/session.env
```

Example: `kill -9 48585` (use the pid printed when you ran `start`).

You may have partial **`raw.ts`** under **`<repo>/output/.staging/…`** (or your `--out-dir`); safe to delete that folder if you do not need it.