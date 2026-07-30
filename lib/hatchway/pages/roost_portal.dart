import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../infra/airway_probe.dart';
import '../infra/egg_signal_hub.dart';
import '../infra/nest_vault.dart';
import '../infra/roost_agent.dart';
import 'empty_air_page.dart';

/// Full-screen WKWebView shell used for the gray flow. Handles the
/// cold-start viewport dance, the offline fallback, JS shims that make
/// the partner site feel native (zoom lock, tap polish, keyboard lift),
/// and the redirect-loop recovery.
class LanternPortal extends StatefulWidget {
  const LanternPortal({
    super.key,
    required this.url,
    required this.safe,
    required this.scout,
    required this.torches,
    required this.agent,
    this.coldLaunch = false,
  });

  final String url;
  final CoopSafe safe;
  final PastureScout scout;
  final TorchRelay torches;
  final HerderAgent agent;
  final bool coldLaunch;

  @override
  State<LanternPortal> createState() => _LanternPortalState();
}

class _LanternPortalState extends State<LanternPortal>
    with WidgetsBindingObserver {
  late final WebViewController _webCtl;
  StreamSubscription<List<ConnectivityResult>>? _linkChanges;
  bool _viewportReady = false;
  bool _coldReloadDone = false;
  bool _offlineShown = false;
  int _redirectAttempts = 0;
  String? _lastMainUrl;
  Timer? _reflowDebounce;
  Size? _lastPhysicalSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enterImmersive();
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final params = Platform.isIOS
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();
    _webCtl = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (request) => request.grant(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(widget.agent.userAgent)
      ..enableZoom(false)
      ..setNavigationDelegate(_delegate());
    if (_webCtl.platform is WebKitWebViewController) {
      (_webCtl.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }

    widget.torches.onDestination = (raw) {
      final uri = Uri.tryParse(raw);
      if (mounted && uri != null && uri.hasScheme) {
        _webCtl.loadRequest(uri);
      }
    };
    _linkChanges = widget.scout.changes.listen((states) {
      if (states.every((state) => state == ConnectivityResult.none)) {
        // Connectivity is definitively gone — go to offline immediately.
        // No DNS probe here (a probe blocks for seconds while offline and
        // lets the WebView render its own error page first).
        _goOffline();
      }
    });

    if (widget.coldLaunch) {
      _settleColdViewport();
    } else {
      _viewportReady = true;
      _webCtl.loadRequest(Uri.parse(widget.url));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainPending());
  }

  void _enterImmersive() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _settleColdViewport() async {
    _enterImmersive();
    // Let immersive mode settle in the phone's CURRENT orientation before
    // mounting the WebView so WKWebView measures the correct viewport. No
    // rotation nudge — that once caused a visible sideways flip. Any
    // residual stretch is fixed post-load by resize + one reload.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() => _viewportReady = true);
    await _webCtl.loadRequest(Uri.parse(widget.url));
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    setState(() {});
    // Detect a real rotation (physicalSize orientation flipped). We only
    // poke the page then; other metrics changes (keyboard, focus) leave
    // WKWebView's viewport alone.
    final view = View.of(context);
    final size = view.physicalSize;
    final rotated = _lastPhysicalSize != null &&
        ((_lastPhysicalSize!.width < _lastPhysicalSize!.height) !=
            (size.width < size.height));
    _lastPhysicalSize = size;
    if (!rotated) return;
    _enterImmersive();
    _reflowDebounce?.cancel();
    _pokeReflow(const <int>[40, 160, 320, 560, 850]);
  }

  void _pokeReflow(List<int> delaysMs) {
    for (final ms in delaysMs) {
      Timer(Duration(milliseconds: ms), () {
        if (!mounted) return;
        _webCtl.runJavaScript(
          'window.dispatchEvent(new Event("orientationchange"));'
          'window.dispatchEvent(new Event("resize"));'
          'if(window.visualViewport)'
          '  window.visualViewport.dispatchEvent(new Event("resize"));',
        ).catchError((_) {});
      });
    }
    _reflowDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      _stitchViewportShim();
      _pinPageScale();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enterImmersive();
      _drainPending();
    }
  }

  Future<void> _drainPending() async {
    final value = await widget.safe.consumePushUrl();
    final uri = value == null ? null : Uri.tryParse(value);
    if (mounted && uri != null && uri.hasScheme) {
      await _webCtl.loadRequest(uri);
    }
  }

  NavigationDelegate _delegate() {
    return NavigationDelegate(
      onPageStarted: (url) => _lastMainUrl = url,
      onPageFinished: (_) {
        _redirectAttempts = 0;
        _stitchViewportShim();
        _pinPageScale();
        _dampTapGlow();
        _liftFocusIntoView();
        _pinInputFont();
        _greenlightMedia();
        Future<void>.delayed(const Duration(milliseconds: 800), () async {
          if (!mounted) return;
          setState(() {});
          await _webCtl.runJavaScript(
            'window.dispatchEvent(new Event("resize"));'
            'window.visualViewport?.dispatchEvent(new Event("resize"));',
          );
          _stitchViewportShim();
          if (widget.coldLaunch && !_coldReloadDone) {
            _coldReloadDone = true;
            await _webCtl.reload();
          }
        });
      },
      onWebResourceError: (error) {
        // -999 = cancelled by a newer navigation.
        if (error.errorCode == -999) return;
        // WKWebView sometimes reports `isForMainFrame` as null for the
        // main navigation — treat null as main-frame so a real load
        // failure is never silently swallowed (leaves the app frozen).
        final mainFrame = error.isForMainFrame ?? true;
        final desc = error.description.toLowerCase();
        final redirectLoop = error.errorCode == -1007 ||
            desc.contains('too_many_redirects') ||
            desc.contains('too many redirects');
        if (redirectLoop && _lastMainUrl != null && _redirectAttempts < 3) {
          _redirectAttempts++;
          _webCtl.loadRequest(Uri.parse(_lastMainUrl!));
          return;
        }
        if (!mainFrame) return;
        _showOfflineAfterProbe();
      },
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);
        if (uri == null) return NavigationDecision.prevent;
        const inline = <String>{'http', 'https', 'about', 'data', 'blob'};
        if (inline.contains(uri.scheme)) {
          if (request.isMainFrame) _lastMainUrl = request.url;
          return NavigationDecision.navigate;
        }
        launchUrl(uri, mode: LaunchMode.externalApplication);
        return NavigationDecision.prevent;
      },
    );
  }

  /// Confirms the outage with a real reachability probe (used for WebView
  /// load errors — many are transient) before routing to the offline
  /// screen.
  Future<void> _showOfflineAfterProbe() async {
    if (_offlineShown) return;
    var online = true;
    try {
      online = await widget.scout.canReachNetwork();
    } catch (_) {
      online = false;
    }
    if (online) return;
    _goOffline();
  }

  Future<void> _goOffline() async {
    if (_offlineShown || !mounted) return;
    _offlineShown = true;
    String currentUrl;
    try {
      currentUrl = await _webCtl.currentUrl() ?? widget.url;
    } catch (_) {
      currentUrl = widget.url;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SilentCoopPage(
          scout: widget.scout,
          retryBuilder: (_) => LanternPortal(
            url: currentUrl,
            safe: widget.safe,
            scout: widget.scout,
            torches: widget.torches,
            agent: widget.agent,
          ),
        ),
      ),
    );
  }

  // ─── JS shims ────────────────────────────────────────────────────────
  // All idempotent. Each writes its guard flag into a per-app hub object
  // (window.___lbr) instead of a top-level window boolean. Style tag ids
  // and shim names are unique to Yardflare Rally — do NOT copy 1:1 to a
  // sibling app.

  static const String _shimHub = 'window.___lbr = window.___lbr || {};';

  void _stitchViewportShim() {
    _webCtl.runJavaScript('''
(() => {
  $_shimHub
  const bag = window.___lbr;
  if (bag.viewportShim) return;
  bag.viewportShim = 1;
  const styleId = 'lbr-safe-inset';
  const cssBody =
    ':root{' +
      '--safe-area-inset-top:0px!important;' +
      '--safe-area-inset-right:0px!important;' +
      '--safe-area-inset-bottom:0px!important;' +
      '--safe-area-inset-left:0px!important;' +
      '--sat:0px!important;--sar:0px!important;' +
      '--sab:0px!important;--sal:0px!important;' +
      '--safe-top:0px!important;--safe-right:0px!important;' +
      '--safe-bottom:0px!important;--safe-left:0px!important;' +
    '}' +
    'html,body{' +
      'overscroll-behavior:none!important;' +
      'overscroll-behavior-y:none!important;' +
    '}';
  const kbOpen = () => {
    const vv = window.visualViewport;
    return !!vv && vv.height < window.innerHeight * 0.75;
  };
  const apply = () => {
    if (kbOpen()) return;
    const host = document.head || document.documentElement;
    if (!host) return;
    let meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.name = 'viewport';
      meta.content =
        'width=device-width, initial-scale=1, viewport-fit=contain';
      host.appendChild(meta);
    } else {
      const scrub = (meta.content || '')
        .replace(/,?\\s*viewport-fit\\s*=\\s*\\w+/ig, '')
        .trim();
      meta.content =
        scrub + (scrub ? ', ' : '') + 'viewport-fit=contain';
    }
    let tag = document.getElementById(styleId);
    if (!tag) {
      tag = document.createElement('style');
      tag.id = styleId;
      host.appendChild(tag);
    }
    tag.textContent = cssBody;
  };
  const queue = () => {
    window.setTimeout(apply, 170);
    window.setTimeout(apply, 640);
  };
  for (const kind of ['pushState', 'replaceState']) {
    const original = history[kind];
    history[kind] = function () {
      const outcome = original.apply(this, arguments);
      queue();
      return outcome;
    };
  }
  window.addEventListener('popstate', queue);
  apply();
  window.setInterval(apply, 2900);
})();
''');
  }

  /// Locks the page at 1× scale — no pinch, no double-tap, no gesture
  /// zoom — so the partner site behaves like a native screen. Re-asserts
  /// the viewport on SPA navigations.
  void _pinPageScale() {
    _webCtl.runJavaScript('''
(() => {
  $_shimHub
  const bag = window.___lbr;
  if (bag.pinScale) return;
  bag.pinScale = 1;
  const setViewport = () => {
    const host = document.head || document.documentElement;
    if (!host) return;
    let meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.setAttribute('name', 'viewport');
      host.appendChild(meta);
    }
    meta.setAttribute(
      'content',
      'width=device-width, initial-scale=1.0, ' +
      'maximum-scale=1.0, minimum-scale=1.0, ' +
      'user-scalable=no, viewport-fit=contain',
    );
  };
  setViewport();
  const swallow = (e) => e.preventDefault();
  for (const evt of ['gesturestart', 'gesturechange', 'gestureend']) {
    document.addEventListener(evt, swallow, {passive: false});
  }
  document.addEventListener('touchmove', (e) => {
    if (e.scale !== undefined && e.scale !== 1) e.preventDefault();
  }, {passive: false});
  let lastTouchAt = 0;
  document.addEventListener('touchend', (e) => {
    const now = Date.now();
    if (now - lastTouchAt <= 300) e.preventDefault();
    lastTouchAt = now;
  }, {passive: false});
  for (const kind of ['pushState', 'replaceState']) {
    const original = history[kind];
    history[kind] = function () {
      const outcome = original.apply(this, arguments);
      setTimeout(setViewport, 150);
      return outcome;
    };
  }
  window.addEventListener('popstate', () => setTimeout(setViewport, 150));
})();
''');
  }

  /// Kills the translucent grey box WKWebView paints on every tap (the
  /// default `-webkit-tap-highlight-color`) and the long-press callout so
  /// tapping feels native. Inputs stay selectable via the `:not()` filter.
  void _dampTapGlow() {
    _webCtl.runJavaScript('''
(() => {
  $_shimHub
  const bag = window.___lbr;
  if (bag.tapGlow) return;
  bag.tapGlow = 1;
  const sheet = document.createElement('style');
  sheet.id = 'lbr-quiet-tap';
  sheet.textContent =
    '*{-webkit-tap-highlight-color:transparent!important;}' +
    '*:not(input):not(textarea):not([contenteditable="true"]){' +
      '-webkit-touch-callout:none!important;' +
    '}';
  (document.head || document.documentElement).appendChild(sheet);
})();
''');
  }

  void _liftFocusIntoView() {
    _webCtl.runJavaScript('''
(() => {
  $_shimHub
  const bag = window.___lbr;
  if (bag.focusLift) return;
  bag.focusLift = 1;
  const isEditable = (node) =>
    !!node &&
    !!node.matches &&
    node.matches('input, textarea, select, [contenteditable="true"]');
  const bring = () => {
    const active = document.activeElement;
    if (!isEditable(active)) return;
    active.scrollIntoView({behavior: 'auto', block: 'nearest'});
  };
  document.addEventListener('focusin', (event) => {
    if (isEditable(event.target)) window.setTimeout(bring, 350);
  }, true);
})();
''');
  }

  void _pinInputFont() {
    if (!Platform.isIOS) return;
    _webCtl.runJavaScript('''
(() => {
  $_shimHub
  const bag = window.___lbr;
  if (bag.inputFont) return;
  bag.inputFont = 1;
  const rule = document.createElement('style');
  rule.id = 'lbr-input-font';
  rule.textContent =
    'input,textarea,select,[contenteditable="true"]{' +
      'font-size:max(16px,1em)!important;' +
    '}';
  (document.head || document.documentElement).appendChild(rule);
})();
''');
  }

  void _greenlightMedia() {
    _webCtl.runJavaScript('''
(() => {
  $_shimHub
  const bag = window.___lbr;
  if (bag.inlineMedia) return;
  bag.inlineMedia = 1;
  const arm = (video) => {
    if (!(video instanceof HTMLVideoElement)) return;
    video.setAttribute('playsinline', '');
    video.setAttribute('webkit-playsinline', '');
    video.playsInline = true;
    video.autoplay = true;
    const attempt = video.play();
    if (attempt && attempt.catch) attempt.catch(() => {});
  };
  const walk = (node) => {
    if (node instanceof HTMLVideoElement) arm(node);
    if (node && node.querySelectorAll) {
      node.querySelectorAll('video').forEach(arm);
    }
  };
  walk(document);
  new MutationObserver((records) => {
    for (const record of records) {
      for (const added of record.addedNodes) walk(added);
    }
  }).observe(document.documentElement, {childList: true, subtree: true});
})();
''');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reflowDebounce?.cancel();
    _linkChanges?.cancel();
    widget.torches.onDestination = null;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).viewPadding;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _webCtl.canGoBack()) {
          await _webCtl.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: _viewportReady
            ? Padding(
                // Respect the notch / Dynamic Island (top + sides) AND
                // the home indicator (bottom) in BOTH orientations. Never
                // use EdgeInsets.zero for cold-start — the bottom inset
                // would vanish before immersive mode settles.
                padding: EdgeInsets.only(
                  top: safe.top,
                  bottom: safe.bottom,
                  left: safe.left,
                  right: safe.right,
                ),
                child: WebViewWidget(controller: _webCtl),
              )
            : const ColoredBox(color: Colors.black),
      ),
    );
  }
}
