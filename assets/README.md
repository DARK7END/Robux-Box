# Assets structure

Declared in `pubspec.yaml`. Directories are tracked via placeholder files so the
build resolves them even before real assets are added.

```
assets/
├─ images/       # illustrations, reward art, empty-state graphics (PNG/WebP @1x,2x,3x)
├─ icons/        # custom SVG/PNG icons not covered by Material Icons
├─ animations/   # Lottie JSON (reward celebration, loading, confetti)
└─ fonts/        # optional bundled fonts (Sora, Plus Jakarta Sans) — see pubspec
```

## Conventions
- **Images:** prefer WebP; provide `2.0x/` and `3.0x/` variants for raster assets.
- **Icons:** use `flutter_svg`-compatible SVGs; keep a 24×24 viewbox.
- **Animations:** Lottie files consumed via the `lottie` package; keep < 200 KB.
- Reward/offer/banner artwork is served from Cloud Storage at runtime (see
  `docs/FIRESTORE_SCHEMA.md`), not bundled here.

## App icon & splash
Generate launcher icons and the splash with `flutter_launcher_icons` /
`flutter_native_splash` from a 1024×1024 master in `assets/images/`.
