# VR13-R2 Execution Record

Date: 2026-09-30

## Scope and restrictions

Only the two VR13 widget tests, test font loader, golden files, evidence compositor, and VR13 reports were changed. Production widgets, routes, API, backend, database, Seed, APK, and Android screenshots were not changed or rebuilt.

## CJK golden result

- Test font: `C:\Windows\Fonts\simhei.ttf`
- Font SHA-256: `9B1959DB3B3ABEB7EFDAEC26EDF7DFE871A6039DE8D614AF7248575207BE629E`
- Font loading is explicit and fails if the file is missing; there is no Ahem fallback path in the test helper.
- Catalog and six fixture goldens contain readable Chinese text with no red Ahem boxes or yellow test baselines.

## Pixel comparison result

- `01_catalog_750x1808.png`: 750x1808px.
- `comparison_01_catalog.png`: 1500x1808px.
- The prototype occupies x=0..749 and the current catalog occupies x=750..1499.
- The compositor clears an opaque white canvas and copies both panels pixel-by-pixel; it does not use DPI-aware image scaling.
- The compositor verifies opaque alpha, rejects red Ahem-like pixels, and checks the prototype panel against the source pixels.

## Verification

- VR13 widget tests: 9 passed after regenerating goldens.
- Full frozen VR13 affected suite: 94 tests passed.
- `flutter analyze --no-pub`: passed.
- Frontend/backend `git diff --check`: no errors; only existing LF/CRLF warnings.
- APK unchanged; SHA-256 remains `25857D58334BA9C356A3C84A9A145F9474C9A630B6B85A37174B89B02D336771`.

## Handoff

VR13-R2 is submitted for Plan-model review. This execution model does not close VR13 and does not enter VR14.
