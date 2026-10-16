# BatteryMenubar

[English](#batterymenubar) | [한국어](#한국어-설명)

Show the macOS menu bar battery indicator (with percentage) **only while on battery power**.
When the power adapter is plugged in, the battery icon disappears from the menu bar.

macOS only lets you choose "always show" or "never show" the battery item.
This tiny menu bar app adds the missing third option.

- No polling: it reacts to IOKit power-source change notifications.
- No `killall ControlCenter`: the preference change is picked up live, so the menu bar does not flicker.
- Restores your original setting when you quit.
- No dependencies: plain Swift, built with the system toolchain.

Requires macOS 13 or later. Tested on macOS 27 (Apple Silicon).

## Install

1. Download `BatteryMenubar.zip` from the [latest release](https://github.com/ewanshin/battery_menubar/releases/latest) and unzip it.
2. Move `BatteryMenubar.app` to `/Applications`.
3. Open it. The app is not notarized, so on first launch macOS will refuse. Either
   **right-click the app > Open**, or clear the quarantine flag:

   ```bash
   xattr -d com.apple.quarantine /Applications/BatteryMenubar.app
   ```

4. Unplug the adapter. The battery item appears together with a small slashed-bolt icon;
   open that icon's menu and turn on **Launch at Login**.

Replug the adapter and both icons disappear.

### Build it yourself

Requires Xcode or the Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/ewanshin/battery_menubar.git
cd battery_menubar
./build.sh            # -> build/BatteryMenubar.app
./build.sh --zip      # also writes build/BatteryMenubar.zip
```

## Use

While on the power adapter nothing is shown. While on battery, the system battery item
(with percentage) appears together with a small slashed-bolt icon that opens the app's menu:
**Launch at Login** and **Quit**. Quitting puts the battery menu bar item back exactly as it
was before the app first ran.

## Uninstall

```bash
./uninstall.sh
```

This quits the app (restoring your original setting), removes the login item, deletes
`/Applications/BatteryMenubar.app`, and cleans up the pre-1.0 LaunchAgent install if present.

## How it works

Control Center stores the battery menu bar item's visibility in the **per-host** domain
of `com.apple.controlcenter`:

| Key                     | Value | Meaning                 |
| ----------------------- | ----- | ----------------------- |
| `Battery`               | `18`  | Show in Menu Bar        |
| `Battery`               | `25`  | Don't Show in Menu Bar  |
| `BatteryShowPercentage` | `1`   | Show percentage         |

The app watches `IOPSNotificationCreateRunLoopSource` and, whenever the providing
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

On first launch the app records your current `Battery` value and keeps it in its own
preferences until you quit, when it writes that value back. If the app is killed without
quitting, the recorded value survives and is used on the next launch instead of whatever
the app had written.

The "hide" value is your original value (or `25` if it was already `18`). Override it with

```bash
defaults write io.github.ewanshin.battery-menubar hideValue -int 25
```

or the `BATTERY_MENUBAR_HIDE_VALUE` environment variable.

## Troubleshooting

```bash
log stream --predicate 'subsystem == "io.github.ewanshin.battery-menubar"' --info
defaults -currentHost read com.apple.controlcenter Battery
```

## Development

```bash
swift test
```

Decision logic lives in `Sources/BatteryMenubarCore` and is unit-tested. The AppKit
shell is in `Sources/BatteryMenubar`.

## License

MIT

---

## 한국어 설명

macOS 메뉴 막대의 배터리 아이콘(퍼센트 포함)을 **배터리로 동작 중일 때만** 표시합니다.
전원 어댑터를 꽂으면 배터리 아이콘이 메뉴 막대에서 사라집니다.

macOS 기본 설정은 배터리 항목을 "항상 표시"하거나 "항상 숨김"만 가능합니다.
이 작은 메뉴 막대 앱이 그 사이에 빠져 있는 세 번째 옵션을 추가해 줍니다.

- 폴링 없음: IOKit 전원 소스 변경 알림에 즉시 반응합니다.
- `killall ControlCenter` 불필요: 설정 변경이 바로 반영되어 메뉴 막대가 깜빡이지 않습니다.
- 종료하면 원래 설정으로 되돌립니다.
- 외부 의존성 없음: 순수 Swift, 시스템 툴체인으로 빌드합니다.

macOS 13 이상이 필요합니다. macOS 27 (Apple Silicon)에서 테스트했습니다.

### 설치

1. [최신 릴리스](https://github.com/ewanshin/battery_menubar/releases/latest)에서 `BatteryMenubar.zip`을 내려받아 풉니다.
2. `BatteryMenubar.app`을 `/Applications`로 옮깁니다.
3. 실행합니다. 공증(notarize)되지 않은 앱이라 첫 실행 시 macOS가 막습니다.
   **앱을 우클릭 > 열기**로 열거나, 격리 플래그를 제거하세요:

   ```bash
   xattr -d com.apple.quarantine /Applications/BatteryMenubar.app
   ```

4. 어댑터를 뽑으면 배터리 항목과 함께 작은 빗금 번개 아이콘이 나타납니다.
   그 아이콘의 메뉴를 열어 **Launch at Login**을 켜 두세요.

어댑터를 다시 꽂으면 두 아이콘 모두 사라집니다.

#### 직접 빌드

Xcode 또는 Command Line Tools(`xcode-select --install`)가 필요합니다.

```bash
git clone https://github.com/ewanshin/battery_menubar.git
cd battery_menubar
./build.sh            # -> build/BatteryMenubar.app
./build.sh --zip      # build/BatteryMenubar.zip도 생성
```

### 사용

어댑터 연결 중에는 아무것도 표시하지 않습니다. 배터리 사용 중에는 시스템 배터리 항목(퍼센트 포함)과
함께 작은 빗금 번개 아이콘이 나타나며, 이 아이콘의 메뉴에 **Launch at Login**(로그인 시 실행)과
**Quit**(종료)이 있습니다. 종료하면 배터리 메뉴 막대 항목이 앱을 처음 실행하기 전 상태로 정확히 돌아갑니다.

### 삭제

```bash
./uninstall.sh
```

앱을 종료(원래 설정 복원)하고, 로그인 항목을 해제하고, `/Applications/BatteryMenubar.app`을
삭제하며, 1.0 이전의 LaunchAgent 설치가 남아 있으면 함께 정리합니다.

### 동작 원리

제어 센터는 배터리 메뉴 막대 항목의 표시 여부를 `com.apple.controlcenter`의
**per-host** 도메인에 저장합니다:

| 키                      | 값    | 의미                   |
| ----------------------- | ----- | ---------------------- |
| `Battery`               | `18`  | 메뉴 막대에 표시       |
| `Battery`               | `25`  | 메뉴 막대에 표시 안 함 |
| `BatteryShowPercentage` | `1`   | 퍼센트 표시            |

앱은 `IOPSNotificationCreateRunLoopSource`로 전원 소스 변경을 감시하다가
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

앱은 첫 실행 시 현재 `Battery` 값을 자체 설정에 기록해 두고, 종료할 때 그 값을 다시 씁니다.
정상 종료 없이 강제 종료되더라도 기록해 둔 값은 남아 있으므로, 다음 실행 때는
앱이 써 둔 값이 아니라 기록된 원본 값을 사용합니다.

"숨김" 값은 원본 값(이미 `18`이면 `25`)입니다. 바꾸려면:

```bash
defaults write io.github.ewanshin.battery-menubar hideValue -int 25
```

또는 `BATTERY_MENUBAR_HIDE_VALUE` 환경 변수를 사용하세요.

### 문제 해결

```bash
log stream --predicate 'subsystem == "io.github.ewanshin.battery-menubar"' --info
defaults -currentHost read com.apple.controlcenter Battery
```

### 개발

```bash
swift test
```

판단 로직은 `Sources/BatteryMenubarCore`에 있고 단위 테스트가 있습니다.
AppKit 셸은 `Sources/BatteryMenubar`에 있습니다.
