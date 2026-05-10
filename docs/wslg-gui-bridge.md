# WSLg GUI bridge on Arch WSL

This WSL instance already exposes the Windows WSLg bridge:

- X11 display: `DISPLAY=:0`
- Wayland display: `WAYLAND_DISPLAY=wayland-0`
- Audio bridge: `PULSE_SERVER=unix:/mnt/wslg/PulseServer`
- WSLg sockets: `/tmp/.X11-unix/X0` and `/mnt/wslg/runtime-dir/wayland-0`
- GPU bridge device: `/dev/dxg`

WSLg is the preferred mechanism on Windows 11 and recent WSL builds. X11 apps run through WSLg's XWayland server, while Wayland-native apps connect to the Wayland socket directly.

## Install test tools

```bash
pacman -Syu --needed xorg-xclock xorg-xeyes xorg-xauth xorg-fonts-misc ttf-dejavu mesa-utils vulkan-tools
```

## Run `xclock`

From inside Arch WSL:

```bash
/root/work/scripts/wslg-run.sh xclock
```

To start it and return to the shell:

```bash
/root/work/scripts/wslg-run.sh --detach xclock
```

The `xclock` window should appear as a normal Windows desktop window.

## Run another GUI app

Install the app with `pacman`, then run it through the same launcher:

```bash
pacman -S --needed firefox
/root/work/scripts/wslg-run.sh firefox
```

For a one-off command without the launcher, this is the minimum environment:

```bash
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export PULSE_SERVER=unix:/mnt/wslg/PulseServer
xclock
```

## What the launcher does

`scripts/wslg-run.sh` checks that WSLg's X11 socket exists, sets `DISPLAY`, connects Wayland and PulseAudio when available, prepends `/usr/lib/wsl/lib` for Windows-provided GPU libraries, and then starts the requested GUI command.

## Diagnostics

Check the bridge:

```bash
ls -l /tmp/.X11-unix/X0 /mnt/wslg/runtime-dir/wayland-0 /mnt/wslg/PulseServer /dev/dxg
```

Check OpenGL:

```bash
glxinfo -B
```

Check Vulkan:

```bash
vulkaninfo --summary
```

Vulkan over D3D12 also needs a Vulkan driver such as Arch's `vulkan-dzn`:

```bash
pacman -S --needed vulkan-dzn
```

If `glxinfo -B` reports `llvmpipe`, OpenGL is using software rendering. That does not affect simple X11 apps such as `xclock`, but it matters for 3D workloads.

If GUI windows stop appearing, restart WSL from Windows PowerShell:

```powershell
wsl --shutdown
```

Then start Arch WSL again and rerun the launcher.
