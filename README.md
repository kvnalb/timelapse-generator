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
chmod +x timelapse.sh bin/timelapse    # once
./timelapse.sh start
./timelapse.sh stop
```

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

## Usage (same flags for `timelapse.sh` and `bin/timelapse`)

```bash
./timelapse.sh start                 # default 60×, raw under ~/Movies/Timelapse/.staging/…
./timelapse.sh stop                  # → ~/Movies/Timelapse/timelapse-YYYYMMDD-HHMMSS.mp4

./timelapse.sh start --speed 30 --out-dir ~/Desktop
./timelapse.sh stop --crf 32 --max-width 960
```

Override ffmpeg path: `FFMPEG=/opt/homebrew/bin/ffmpeg ./timelapse.sh start`.

## v0 limits

Records the **entire main display** shown by AVFoundation’s **first “Capture screen”** device (override with `--screen-index`). **No per-app exclusion** (see design doc for a possible v1).