# SideButtonControl

SideButtonControl is a macOS menu bar utility for remapping mouse side buttons to system-wide Back and Forward navigation.

The app runs quietly in the background, watches side-button mouse events, and turns the default button 3 / button 4 behavior into navigation commands. It is built for a setup where mouse side buttons should feel like native browser-style navigation across apps, without keeping a full application window open.

## What it does

- Maps mouse button 3 to Back and mouse button 4 to Forward by default.
- Lets the user change each side-button command from the settings window.
- Runs as an `LSUIElement` menu bar app instead of a Dock app.
- Starts and stops detection from the menu bar.
- Hides the menu bar icon until relaunch when requested.
- Provides a diagnostics window for observed side-button events.
- Automatically suspends detection and hides interactive windows when no external display is available.

## How it works

The project keeps the remapping flow split across clear layers:

- `Domain` owns button IDs, command choices, and remap decisions.
- `Application` owns detection use cases, permission snapshots, storage contracts, and monitor contracts.
- `Infrastructure` owns AppKit, CoreGraphics, persistence, event tap monitoring, and action dispatching.
- `Presentation` owns SwiftUI settings, diagnostics, and command display.
- `App` wires the runtime dependencies, menu bar controller, and display-driven lifecycle.

At runtime, `AppContainer` builds the dependency graph. `SideButtonDetectionUseCase` coordinates permission checks, button binding persistence, and event monitoring. `CGEventTapMouseEventMonitor` installs a CoreGraphics event tap for `otherMouseDown` / `otherMouseUp`, evaluates the current `ButtonBindingSet`, consumes mapped events, and dispatches navigation actions.

Most apps receive discrete navigation swipe gestures through `GestureSwipeActionDispatcher`. Apps that need keyboard navigation can be routed through `CGKeyboardShortcutActionDispatcher`; the current runtime route keeps Spotify on Command-Option-Arrow shortcuts.

## Permissions

SideButtonControl needs macOS input-related permissions before it can listen for and remap side-button events. If permissions are missing, the menu bar status shows that access is required and the app can open the relevant settings flow.

Because the app posts navigation gestures or keyboard events, permission behavior depends on the current macOS security settings for the built app bundle.

## Project details

- Platform: macOS
- Language: Swift 6, with a small C bridge for low-level navigation gesture event serialization
- UI: SwiftUI settings and diagnostics hosted from AppKit windows
- Runtime shell: AppKit menu bar app
- Bundle identifier: `com.hamzatufekci.SideButtonControl`

## Build

Open `SideButtonControl.xcodeproj` in Xcode and build the `SideButtonControl` scheme.

From the command line:

```sh
xcodebuild -project SideButtonControl.xcodeproj -scheme SideButtonControl -configuration Debug build
```

Run tests:

```sh
xcodebuild -project SideButtonControl.xcodeproj -scheme SideButtonControl -configuration Debug test
```

## Notes

The low-level navigation gesture path is intentionally isolated behind `NavigationSwipe.h` / `NavigationSwipe.c` and called from Swift through `GestureSwipeActionDispatcher`. That keeps byte-level CoreGraphics event construction out of the domain, application, and presentation layers.
