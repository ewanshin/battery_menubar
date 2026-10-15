# battery-menubar

Show the macOS menu bar battery indicator (with percentage) **only while on battery power**.
When the power adapter is plugged in, the battery icon disappears from the menu bar.

macOS only lets you choose "always show" or "never show" the battery item.
This tiny background program adds the missing third option.

- No polling: it reacts to IOKit power-source change notifications.
- No `killall ControlCenter`: the preference change is picked up live, so the menu bar does not flicker.
- No dependencies: a single Swift file, compiled with the system `swiftc`.

Tested on macOS 27 (Apple Silicon).

## Install

Requires Xcode Command Line Tools (`xcode-select --install`) for `swiftc`.

```bash
git clone https://github.com/ewanshin/battery_menubar.git
cd battery_menubar
./install.sh
```

`install.sh` builds the binary into `~/.local/bin/battery-menubar` and registers a
LaunchAgent (`~/Library/LaunchAgents/local.battery-menubar.plist`) so it starts at login
and restarts automatically if it ever exits.

Unplug and replug the adapter to see the battery icon disappear and reappear.

## Run

Nothing to do: once installed, the LaunchAgent runs it in the background and starts it
again at every login. To run it manually in the foreground instead (e.g. for testing):

```bash
swiftc -O -o battery-menubar Sources/main.swift
./battery-menubar        # Ctrl-C to stop; logs go to stderr
```

Manage the background service with `launchctl`:

```bash
launchctl print gui/$(id -u)/local.battery-menubar | grep state   # status
launchctl kickstart -k gui/$(id -u)/local.battery-menubar         # restart
```

## Uninstall

```bash
./uninstall.sh
```

This stops the agent, removes the binary and the plist, and leaves the battery item hidden.
To show it again permanently, use System Settings > Control Center > Battery.

## How it works

Control Center stores the battery menu bar item's visibility in the **per-host** domain
of `com.apple.controlcenter`:

| Key                     | Value | Meaning                 |
| ----------------------- | ----- | ----------------------- |
| `Battery`               | `18`  | Show in Menu Bar        |
| `Battery`               | `25`  | Don't Show in Menu Bar  |
| `BatteryShowPercentage` | `1`   | Show percentage         |

The program watches `IOPSNotificationCreateRunLoopSource` and, whenever the providing
power source changes, writes:

```bash
# on battery
defaults -currentHost write com.apple.controlcenter Battery -int 18
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
# on AC
defaults -currentHost write com.apple.controlcenter Battery -int 25
```

Note that the non-host domain (`defaults write com.apple.controlcenter ...` without
`-currentHost`), which most online guides mention, has no effect on recent macOS versions.

The "hide" value defaults to whatever your `Battery` key was set to when the program
started (or `25` if it was already `18`). Override it with the
`BATTERY_MENUBAR_HIDE_VALUE` environment variable if needed.

## Troubleshooting

```bash
launchctl print gui/$(id -u)/local.battery-menubar | grep -E 'state|pid'
cat /tmp/battery-menubar.log
```

## License

MIT
