import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:poker_contract/poker_contract.dart';
import 'package:poker_game/poker_game.dart';
import 'package:web/web.dart' as web;

import 'dart:ui_web' as ui_web;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runWidget(const EmbeddedViews());
}

class EmbeddedViews extends StatefulWidget {
  const EmbeddedViews({super.key});
  @override
  State<EmbeddedViews> createState() => _EmbeddedViewsState();
}

class _EmbeddedViewsState extends State<EmbeddedViews>
    with WidgetsBindingObserver {
  late final SemanticsHandle semantics;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    semantics = SemanticsBinding.instance.ensureSemantics();
  }

  @override
  void didChangeMetrics() => setState(() {});
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    semantics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ViewCollection(
    views: [
      for (final view in WidgetsBinding.instance.platformDispatcher.views)
        View(
          key: ValueKey(view.viewId),
          view: view,
          child: EmbeddedGame(viewId: view.viewId),
        ),
    ],
  );
}

class EmbeddedGame extends StatefulWidget {
  const EmbeddedGame({super.key, required this.viewId});
  final int viewId;
  @override
  State<EmbeddedGame> createState() => _EmbeddedGameState();
}

class _EmbeddedGameState extends State<EmbeddedGame> {
  late final web.HTMLElement host;
  BridgeContext? configuration;
  late final JSFunction listener;
  String? error;

  void accept(Object? value) {
    final next = BridgeContext.parse(value);
    if (configuration != null && next.instance != configuration!.instance) {
      throw const FormatException('Stale embed instance');
    }
    configuration = next;
  }

  void send(String kind) {
    final data = jsonEncode({
      'version': BridgeContext.version,
      'instance': configuration?.instance,
      'viewId': widget.viewId,
      'kind': kind,
      'capabilities': ['preview', 'theme', 'return'],
    });
    host.dispatchEvent(
      web.CustomEvent('poker-event', web.CustomEventInit(detail: data.toJS)),
    );
  }

  @override
  void initState() {
    super.initState();
    host = ui_web.views.getHostElement(widget.viewId)! as web.HTMLElement;
    try {
      accept(ui_web.views.getInitialData(widget.viewId).dartify());
    } on FormatException {
      error = 'Incompatible game context';
    }
    listener = ((web.Event event) {
      if (!identical(event.target, host)) return;
      try {
        accept(
          jsonDecode((event as web.CustomEvent).detail.dartify()! as String),
        );
        setState(() => error = null);
      } on Object {
        setState(() => error = 'Invalid game context');
        send('error');
      }
    }).toJS;
    host.addEventListener('poker-context', listener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) send(error == null ? 'ready' : 'error');
    });
  }

  @override
  void dispose() {
    host.removeEventListener('poker-context', listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    initialRoute: "/",
    locale: Locale(configuration?.locale ?? "en"),
    theme: ThemeData(
      brightness: configuration?.theme == 'dark'
          ? Brightness.dark
          : Brightness.light,
    ),
    home: error != null
        ? Scaffold(body: Center(child: Text(error!)))
        : GameScreen(
            source: configuration!.preview
                ? const PreviewSource()
                : const UnavailableSource(),
            onReturn: () => send('return'),
          ),
  );
}
