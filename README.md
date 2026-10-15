# battery-menubar

[English](#battery-menubar) | [한국어](#한국어-설명)

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

---

## 한국어 설명

macOS 메뉴 막대의 배터리 아이콘(퍼센트 포함)을 **배터리로 동작 중일 때만** 표시합니다.
전원 어댑터를 꽂으면 배터리 아이콘이 메뉴 막대에서 사라집니다.

macOS 기본 설정은 배터리 항목을 "항상 표시"하거나 "항상 숨김"만 가능합니다.
이 작은 백그라운드 프로그램이 그 사이에 빠져 있는 세 번째 옵션을 추가해 줍니다.

- 폴링 없음: IOKit 전원 소스 변경 알림에 즉시 반응합니다.
- `killall ControlCenter` 불필요: 설정 변경이 바로 반영되어 메뉴 막대가 깜빡이지 않습니다.
- 외부 의존성 없음: Swift 파일 하나를 시스템 `swiftc`로 컴파일합니다.

macOS 27 (Apple Silicon)에서 테스트했습니다.

### 설치

`swiftc`가 필요하므로 Xcode Command Line Tools를 먼저 설치하세요 (`xcode-select --install`).

```bash
git clone https://github.com/ewanshin/battery_menubar.git
cd battery_menubar
./install.sh
```

`install.sh`는 바이너리를 `~/.local/bin/battery-menubar`에 빌드하고,
LaunchAgent(`~/Library/LaunchAgents/local.battery-menubar.plist`)를 등록해
로그인 시 자동 실행되고 종료되더라도 자동으로 다시 시작되게 합니다.

어댑터를 뺐다 꽂아 보면 배터리 아이콘이 나타났다 사라지는 것을 확인할 수 있습니다.

### 실행

따로 할 일은 없습니다. 설치하면 LaunchAgent가 백그라운드에서 실행하고 로그인할 때마다 다시 시작합니다.
테스트 등을 위해 포그라운드에서 직접 실행하려면:

```bash
swiftc -O -o battery-menubar Sources/main.swift
./battery-menubar        # Ctrl-C로 종료, 로그는 stderr로 출력
```

백그라운드 서비스는 `launchctl`로 관리합니다:

```bash
launchctl print gui/$(id -u)/local.battery-menubar | grep state   # 상태 확인
launchctl kickstart -k gui/$(id -u)/local.battery-menubar         # 재시작
```

### 삭제

```bash
./uninstall.sh
```

서비스를 중지하고 바이너리와 plist를 삭제하며, 배터리 항목은 숨김 상태로 둡니다.
다시 항상 표시하고 싶다면 시스템 설정 > 제어 센터 > 배터리에서 켜면 됩니다.

### 동작 원리

제어 센터는 배터리 메뉴 막대 항목의 표시 여부를 `com.apple.controlcenter`의
**per-host** 도메인에 저장합니다:

| 키                      | 값    | 의미                   |
| ----------------------- | ----- | ---------------------- |
| `Battery`               | `18`  | 메뉴 막대에 표시       |
| `Battery`               | `25`  | 메뉴 막대에 표시 안 함 |
| `BatteryShowPercentage` | `1`   | 퍼센트 표시            |

프로그램은 `IOPSNotificationCreateRunLoopSource`로 전원 소스 변경을 감시하다가
바뀔 때마다 다음을 기록합니다:

```bash
# 배터리일 때
defaults -currentHost write com.apple.controlcenter Battery -int 18
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
# 어댑터 연결 시
defaults -currentHost write com.apple.controlcenter Battery -int 25
```

인터넷에 많이 돌아다니는 `-currentHost` 없는 `defaults write com.apple.controlcenter ...`
방식은 최신 macOS에서는 아무 효과가 없습니다.

"숨김" 값은 프로그램 시작 시점의 `Battery` 키 값을 그대로 사용합니다
(이미 `18`이면 `25`). 필요하면 `BATTERY_MENUBAR_HIDE_VALUE` 환경 변수로 바꿀 수 있습니다.

### 문제 해결

```bash
launchctl print gui/$(id -u)/local.battery-menubar | grep -E 'state|pid'
cat /tmp/battery-menubar.log
```
