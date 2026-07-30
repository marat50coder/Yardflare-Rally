# Gray-Flow Lessons — bugs hit while building from the template

Every item below is a real bug that cost debugging time on the previous
template. The fix is already applied in this codebase — do NOT regress it.

## 1. WKWebView `isForMainFrame` can be null → app "freezes", no-wifi never shows
**Symptom:** internet drops inside the WebView; nothing happens, app looks
frozen; the offline screen never appears.
**Cause:** `onWebResourceError: if (err.isForMainFrame != true) return;` — on
WKWebView `isForMainFrame` is sometimes `null` for the main navigation, so a
real load failure was silently swallowed.
**Fix (`roost_portal.dart`):** treat null as main-frame:
```dart
final mainFrame = error.isForMainFrame ?? true;
if (error.errorCode == -999) return; // cancelled
... if (!mainFrame) return;
```

## 2. Offline must show IMMEDIATELY on connectivity none (no probe first)
**Cause:** a DNS probe hangs for seconds while offline, during which the
WebView renders its own error page.
**Fix:** connectivity `none` → `_goOffline()` directly (no probe). Only
WebView *load errors* (which can be transient) go through a probe first.

## 3. Retry on the offline screen must RE-RUN the pipeline
**Symptom A (crash):** Retry threw "widget unmounted / defunct context".
**Cause:** the offline screen captured the parent's `BuildContext` in an
`onRetry` closure. **Fix:** `EmptyAirPage` takes a `retryBuilder` (WidgetBuilder)
and navigates with its OWN context.
**Symptom B (infinite offline):** Retry kept returning to no-wifi even with
internet. **Cause:** `HatchCoordinator.decide()` cached its future forever, so
Retry replayed the cached `OfflineNest`. **Fix:** cache only de-dupes
*concurrent* startup calls, then clears (`whenComplete`) so a later Retry runs
fresh:
```dart
Future<HatchDestination> decide({...}) =>
    _decideFuture ??= _decide(...).whenComplete(() => _decideFuture = null);
```

## 4. Gate-enable predicate must not depend on optional fields
**Symptom:** whole gray flow silently disabled (no AppsFlyer, no config POST,
white part only). **Cause:** `grayCredentialsReady` required `oneLinkHost`
which was empty. **Fix:** predicate = `endpoint && appsFlyerKey &&
firebaseProjectNumber` ONLY. OneLink and similar are optional.

## 5. AppCheck / Firebase failure must not disable attribution
**Cause:** attribution/gate was tied to `productionServicesReady` which was set
only if Firebase AND AppCheck succeeded. **Fix (`main.dart`):** init Firebase
and AppCheck in separate try/catch; the gate runs on
`EraHatchConfig.grayCredentialsReady`, independent of AppCheck. AppCheck debug
token errors are harmless.

## 6. Cold-start push must open in the phone's ACTUAL orientation
**Symptom:** tapping a push (app killed) opened the link in landscape, then
flipped to portrait. **Cause:** the "stretched WebView" fix used a micro-
rotation to `landscapeLeft` (visible flip). **Fix:** removed the forced
rotation; keep deferred mount + immersive settle, then correct any residual
stretch via post-load `resize` + one `reload()` in the current orientation.

## 7. Rotation jitter — poke reflow several times
**Cause:** WKWebView keeps the pre-rotation viewport width ~1s → site renders
wrong then snaps. **Fix (`didChangeMetrics`):** on orientation change, dispatch
`orientationchange`+`resize` at several delays (40/160/320/560/850ms) and
re-assert inset/zoom, so the page reflows in ~0.3s.

## 8. WebView must feel native — kill zoom, tap-highlight, overscroll
- `enableZoom(false)` is NOT enough on iOS. Inject a viewport lock
  (`maximum-scale=1, user-scalable=no`) + preventDefault on
  `gesturestart/gesturechange` and double-tap (`_installZoomLock`).
- Kill the grey box on tap: `* { -webkit-tap-highlight-color: transparent }`
  (`_installTapPolish`).
- Stop rubber-band into black: `html,body{overscroll-behavior:none}` in the
  inset-guard CSS.

## 9. Safe area
- WebView: pad with `MediaQuery.viewPadding` on ALL sides (top notch + bottom
  home indicator) in both orientations. Cold-start uses `viewPadding`, never
  `EdgeInsets.zero`.
- Permit / no-wifi screens in **landscape**: do NOT wrap buttons in `SafeArea`
  and center them horizontally — the notch inset otherwise shifts the
  horizontal center and the buttons look off. Portrait may keep a bottom gap.

## 10. Permit / offline screens must rotate
`BootScreen` locks portrait right before routing; `FeatherInvitation` and
`EmptyAirPage` re-enable `portraitUp + landscapeLeft/Right` in `initState`,
otherwise they stay portrait-locked.

## 11. GCD lookup uses the numeric App Store id on iOS (not bundle id)
`https://gcdsdk.appsflyer.com/install_data/v5.0/id<iosStoreId>?device_id=...`.
Using the bundle id returns wrong/empty data.

## 12. Credential encoding — always regenerate + verify
Never hand-edit the encoded byte arrays. A single stray/missing byte corrupts
the URL (seen: an extra byte turned the endpoint into garbage → 404s / gate
off). Always `dart run tool/encode_era_values.dart` and confirm the VERIFY
block round-trips exactly.

## 13. Asset quality
- Ship screen art as **webp**, display with `filterQuality: FilterQuality.high`,
  and provide source ≥ the device resolution (a 460px source upscaled looked
  pixelated). Compress large PNGs to webp (chapters went 46MB → 4.7MB).
- Use a real display font (bundled `Baloo2`) — the system serif looked default
  and ugly.

## 14. App icon must be opaque (no alpha) for iOS
Generate all `AppIcon.appiconset` sizes from a 1024² source with alpha
flattened, or App Store review rejects it.
