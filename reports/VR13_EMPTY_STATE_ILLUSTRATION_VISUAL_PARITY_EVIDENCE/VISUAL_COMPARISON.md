# VR13-R3 Visual Comparison

`comparison_01_catalog.png` contains two pixel-copied panels: the prototype at x=0..749 and the current catalog at x=750..1499. Both panels are 750x1808px. The current catalog is rendered from the logical 375x904dp test viewport at DPR 2. The comparison canvas is opaque and has no DPI-driven black/transparent gap.

The current catalog contains nine distinct semantic variants: search empty, network error, no following, no followed teams, no history, no comments, no favorites, no data, and no messages. The back arrow is a vector path and is not dependent on a font glyph. Labels use 15sp; the measured first-row centers are 221.5px and 528.5px. Prototype row starts are 245, 547, 850, 1153, 1460px; current row starts are 244, 548, 852, 1156, 1462px.

The six `fixture_*.png` files are controlled production-component evidence for the six mapped empty-state categories. They are intentionally classified as fixtures because the current DEMO account has non-empty data for several of those categories. All fixture text is rendered with the explicit CJK test font; no Ahem/tofu output is accepted. The two standard Android files are real logged-in API pages; the width and font files are the corresponding responsive evidence.
