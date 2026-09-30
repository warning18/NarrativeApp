# Recorded narration

The story's read-aloud voice, recorded with ElevenLabs and shipped inside the app.

Layout: `<en|fr>/<clip id>.mp3`. Each clip is one paragraph, and a `.txt` beside it holds the words it speaks. The clip ID is a hash of the ElevenLabs model, the voice ID and the paragraph's exact text (see `narrationClipId` in `lib/data/narration_clips.dart`). So:

- one folder per language holds every voice's recordings side by side;
- if a paragraph's wording changes, it simply stops matching its old clip. It needs a new recording, and the old file can be deleted.

These files are not edited by hand. In the app, in Edit Mode, record scenes from Settings → Read-Aloud Voice → *Choose scenes to record…*, or with the microphone button on the story screen. Then use *Push recordings to GitHub*. That pushes every recording on the device that isn't here yet to a new branch, in one commit. Merge a pull request from that branch, and the next build plays those scenes with no API key and no download.
