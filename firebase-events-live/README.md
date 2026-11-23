# Firebase Events Live

See, live, the Firebase Analytics events (with all parameters) fired by an Android
app, next to a mirror of the phone screen. Like DebugView, but local and instant.

## Requirements
- Node 18+ and `adb` (Android platform-tools) on your computer.
- Android phone with Developer options. Staging/debug build of the app using Firebase.

## Run
```
node server.js        # then open http://localhost:4455
```
No `npm install` needed. Everything stays on your computer.

## Use
1. Connect the phone by USB, or click **Connect over Wi-Fi** (Wireless debugging: pair, then connect).
2. Pick the device, type or pick the **target package**, click **Start capture**.
3. Use the app: events and parameters appear live. Click an event to see its parameters.
   Filter, pause, export JSON/CSV.

## How it works
No traffic interception or certificates. It sets
`debug.firebase.analytics.app=<package>` and verbose `FA` / `FA-SVC` log tags, then parses
`adb logcat` lines ("Logging event (FE): name(_x), Bundle[{...}]"). Stop resets the property.
The mirror polls `adb screencap` (~3-4 fps). Android only.
