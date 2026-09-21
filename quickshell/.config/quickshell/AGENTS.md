# Agent Guide (Quickshell QML — niri port)

This is a Quickshell configuration written in QML, ported from Hyprland to the
**niri** compositor. Entry point: `shell.qml`.

Compositor integration lives in `services/NiriData.qml`, a singleton that reads
niri's IPC event stream (`$NIRI_SOCKET`) and exposes workspaces, windows,
focused window/output and keyboard layouts. Actions are sent with
`niri msg action`. There are no `Quickshell.Hyprland` dependencies.

## Documentation

- QtQuick QML modules (official Qt docs): https://doc.qt.io/qt-6/qtquick-qmlmodule.html
- Quickshell type reference (v0.3.1): https://quickshell.org/docs/v0.3.1/types/
- niri IPC (event stream): https://niri-wm.github.io/niri/IPC.html
- Official examples repository: https://git.outfoxxed.me/quickshell/quickshell-examples

## Common Commands

### Run / Smoke Test

- Run this config from the repo root:
  - `quickshell -p . --verbose`
- Avoid starting a duplicate instance:
  - `quickshell -p . --no-duplicate --verbose`
- Stop a running instance of this config:
  - `quickshell kill -p .`
- List running Quickshell instances (useful when multiple configs run):
  - `quickshell list`
- Lockscreen (separate Quickshell config — do not run while locked):
  - `quickshell -c modules/lockscreen/`

### Logs / Debug

- Tail logs for this config:
  - `quickshell log -p . -t 200`
- Follow logs live:
  - `quickshell log -p . -f`
- IPC help / discover targets:
  - `quickshell ipc --help`
  - `quickshell ipc show -p .`

### Lint / Format

This repo currently has no enforced formatter/linter in-tree.

- If you have Qt tools installed:
  - `qmllint **/*.qml`
  - `qmlformat -i **/*.qml`

Notes:
- `qmlformat` may not be installed by default.
- Keep changes minimal and consistent with existing style even without auto-format.

### Tests (Automated)

There is no automated unit/integration test suite in this repository.
Treat “running the shell” as the primary test.

Recommended manual checks after UI changes:
- Open/close the launcher (Apps / Wallpapers / Web modes) and popups.
- Verify animations (Behaviors) still trigger.
- Check for null-safety issues when services are not ready.

## Project Structure

- `shell.qml`: `ShellRoot` that loads `ThemeLoader`, one `Bar` per screen
  (`Variants` over `Quickshell.screens`) and a single `UnifiedLauncher`.
- `modules/`: UI modules
  - `bar/` (Bar + `widgets/`: pills, logo, resource meters)
  - `launcher/` (UnifiedLauncher, AppsView, WebView, WallpaperGrid)
  - `notifications/`, `network/`, `date/`, `music/`, `tray/`, `assistant/`
  - `focused-window/`
  - `lockscreen/`: a **separate** Quickshell config (`shell.qml` + `qmldir`)
    with its own `Theme` singleton (`LockTheme.qml`). It is launched by
    `scripts/session-lock.sh` and is not part of the main shell root.
- `components/`: reusable UI (`SvgIcon`, `PillBase`, `ScrollingText`, `shell/*`).
- `services/`: stateful integrations (`NiriData`, `AudioService`,
  `NetworkStatusService`, `SystemMonitorService`, `SessionService`, etc.).
- `core/`: singletons and loaders (`Theme` → `ThemeManager.qml`, `AppPaths`,
  `ThemeLoader`).
- `utils/`: helper singletons (`ColorUtils`, `TimeUtils`, `IconResolver`, `Fuzzy`).
- `scripts/`: shell helpers (`apply_wallpaper.sh`, `session-lock.sh`,
  `network_status.sh`, `sysmon.sh`).
- `assets/`: icons and images.

Repo notes:
- Generated files (matugen outputs) are gitignored: `Theme.qml`, `colors.css`,
  `gtk.css`, `niri/colors.kdl`, `swayosd/style.css`.
- Runtime state is gitignored: `alarms.json`, `notes.json`, `launcher_usage.json`.
- `AppPaths` resolves `$HOME` at runtime; never hardcode `/home/<user>`.

## Code Style Guidelines

### QML Imports

Sort `import ...` lines alphabetically.

- Prefer explicit local module paths instead of broad imports.
- Only import what you use.

### Formatting

- Indentation: 4 spaces.
- Braces: K&R style (opening brace on same line).
- Prefer `anchors.fill: parent` over verbose anchor blocks when equivalent.
- Prefer `readonly property` for computed values used as bindings.

### Naming

- Components: `PascalCase` filenames and type names.
- IDs: `lowerCamelCase` and descriptive (`background`, `notificationsPane`).
- Properties/functions/signals: `lowerCamelCase`.
- Prefer explicit property types (`bool`, `int`, `real`, `string`) over `var`.

### Types and Null-Safety

- Use optional chaining and nullish coalescing where data can be missing:
  - `modelData?.summary ?? ""`
  - `activeNode?.audio?.volume ?? 0`
- Guard side-effectful calls:
  - `if (!root.initialized) return;`
- Clamp normalized values when converting or writing:
  - `Math.max(0, Math.min(1, v))`

### Error Handling & Logging

- Prefer graceful fallbacks in UI bindings instead of throwing.
- In services, log actionable errors (e.g. missing device paths) and keep running.
- Avoid spamming logs in high-frequency bindings; use timers/signals when needed.

### Binding vs. Imperative Code

- Avoid side effects inside property bindings.
- Put side effects in signal handlers (`onClicked`, `onTriggered`, `onLoaded`).
- When you need animations, prefer `Behavior on <prop>` with
  `NumberAnimation`/`ColorAnimation`.

### Reuse and Componentization

- Extract repeated delegates/blocks into `components/` or the module folder.
- For utility computations used in multiple places, add a documented function
  to `utils/`.

### Configuration and Theme

- The `Theme` singleton lives in `core/ThemeManager.qml` and exposes **flat**
  color properties (`Theme.primary`, `Theme.inkSurf`, `Theme.outline`,
  `Theme.alpha(...)`). There is no `Theme.color.*` / `Config` / `GlobalStates`.
- `ThemeLoader` parses the matugen-generated `Theme.qml` and calls
  `Theme.applyFromParsed(colors)`. Keep the property names in
  `matugen/templates/quickshell.qml` in sync with `ThemeManager.applyFromParsed`
  and `modules/lockscreen/LockTheme.qml`.
- `AppPaths` is the source of truth for `$HOME`-relative paths.

### External Commands

When using `Quickshell.Io.Process`:

- Use `command: ["bash", "-c", "..."]` only when necessary; prefer direct argv arrays.
- Treat user-provided values carefully (avoid injection via string concatenation).
- Session actions (lock/logout/suspend/poweroff) go through `SessionService`.
  Locking always uses `scripts/session-lock.sh` (single direct invocation).

## Git / Hygiene (Agent Expectations)

### Commit Messages

Use Conventional Commits: https://www.conventionalcommits.org/

- Format: `type(scope): Summary` (imperative, sentence case, no trailing period).
  - Examples:
    - `feat(quickSettings): Add output device selector`
    - `fix(dateMenu): Prevent crash when notifications are empty`
    - `refactor(components): Extract NotificationRow delegate`
- Use a scope that matches the area (`bar`, `launcher`, `services`, `core`,
  `utils`, `lockscreen`, etc.).

- Do not commit generated or runtime files (see `.gitignore`).
- Keep diffs focused; avoid large reformat-only changes.
- Do not introduce secrets/credentials.
