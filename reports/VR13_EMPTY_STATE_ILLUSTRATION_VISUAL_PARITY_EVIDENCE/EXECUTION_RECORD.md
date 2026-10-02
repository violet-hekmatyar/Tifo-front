# VR13-R3 Evidence Record

## Catalog and comparison

- `01_catalog_750x1808.png`: current test catalog at 750x1808px, representing 375x904dp at DPR 2. Labels use 15sp and the measured column/row geometry is aligned to the prototype. Chinese text is rendered with the explicitly loaded test font.
- `comparison_01_catalog.png`: direct side-by-side composition, left prototype 750x1808px and right current catalog 750x1808px, final size 1500x1808px. Both panels are copied pixel-by-pixel onto an opaque canvas.

## Six empty-state fixture files

- `fixture_noFollowing.png`
- `fixture_noFollowingTeams.png`
- `fixture_noComments.png`
- `fixture_noFavorites.png`
- `fixture_noData.png`
- `fixture_noMessages.png`

Each is a deterministic Flutter fixture rendering the production `AppStateView` and `AppStateIllustration` component inside a Scaffold at 750x1600px. Each contains both title and message text. Chinese text is rendered with `C:\Windows\Fonts\simhei.ttf` (SHA-256 `9B1959DB3B3ABEB7EFDAEC26EDF7DFE871A6039DE8D614AF7248575207BE629E`). These files are explicitly fixture evidence; they are not real API screenshots and do not write database data.

## Android files

- `android_messages_entry.png`: real logged-in message entry from the current APK.
- `android_interaction_standard.png`: real logged-in interaction empty state from the current APK.
- `width_360dp.png`: 945x2400px, density 420, font scale 1.0; 945 / 420 * 160 = 360dp.
- `font_140.png`: 1080x2400px, density 420, font scale 1.4.

All four Android files use APK SHA-256 `25857D58334BA9C356A3C84A9A145F9474C9A630B6B85A37174B89B02D336771`. The evidence files have no green capture border at the corner pixel. The emulator was restored to 1080x2400, density 420, font scale 1.0 after capture.

No account password, token, or other authentication secret is recorded here.
