# Installing the app on an iPhone (no Mac needed)

Every release has two files under **Assets**: `app-release.apk` for
Android and `NarrativeApp-<version>.ipa` for iPhone. The Android file
installs as it is. The iPhone file doesn't, because an iPhone only runs
apps signed for it by Apple. The `.ipa` is unsigned: whoever installs it
signs it with their own **free Apple ID**, using one of the tools below.
None of them needs a Mac; the first two need a Windows (or Mac) computer.

## What a free Apple ID allows

- **An app works for 7 days.** After that, sign it again (the same way
  as installing it). Re-signing the same app normally keeps your saved
  game.
- At most **3 sideloaded apps** at a time on the phone.
- A paid Apple Developer account ($99/year) would remove the 7-day limit
  and allow TestFlight. It isn't needed to install the app.

## Option 1: Sideloadly (Windows or Mac)

1. Download the `.ipa` from the latest release on GitHub.
2. Install [Sideloadly](https://sideloadly.io) on the computer. On
   Windows it also needs iTunes and iCloud from Apple's website, not the
   Microsoft Store versions (its site explains this).
3. Plug the iPhone in with a cable and accept "Trust this computer".
4. In Sideloadly, pick the `.ipa`, enter your Apple ID and press Start.
5. On the iPhone, the first time only:
   - **Settings → General → VPN & Device Management**: trust your Apple
     ID's developer app.
   - **Settings → Privacy & Security → Developer Mode**: turn it on and
     restart (iOS 16 and later).

To renew it after 7 days, or to install a new version, do steps 1, 3 and 4
again.

## Option 2: SideStore (updates on the phone itself)

[SideStore](https://sidestore.io) is installed once with a computer,
following its own guide. After that it re-signs apps on the phone over
Wi-Fi every 7 days, with no computer.

- **To install or update the app**, open the `.ipa` in SideStore: from
  Files, or with **Share → SideStore**.
- **Or from the app:** Settings → Check for Updates → Download & Open,
  then Share → SideStore. As on Android, this needs the GitHub token
  (Settings, in Edit mode), because the repository is private.

[AltStore](https://altstore.io) works the same way, except that renewing
the signature needs AltServer running on a computer on the same Wi-Fi.

## Sharing the app with someone else

Send them the `.ipa` file. They install it with their own Apple ID, in
one of the ways above. They don't need access to the GitHub repository.

## Where the `.ipa` comes from

- **Releases:** `.github/workflows/build_apk.yml` publishes a release on
  each push to `main`. Its `ios-release` job then builds the app on a
  macOS runner (`.github/actions/build-ios`) and adds the `.ipa` to that
  release.
- **By hand, any branch:** Actions → **Build iOS** → Run workflow. The
  `.ipa` is in the run's artifacts.
