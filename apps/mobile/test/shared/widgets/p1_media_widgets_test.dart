import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/shared/widgets/app_content_image.dart';
import 'package:tifo/shared/widgets/app_entity_avatar.dart';
import 'package:tifo/shared/widgets/app_player_avatar.dart';
import 'package:tifo/shared/widgets/app_team_logo.dart';

void main() {
  testWidgets('media widgets keep a visible fallback when no URL exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SingleChildScrollView(
          child: Column(
            children: [
              AppPlayerAvatar(identity: 'player:1', name: '林远航'),
              AppTeamLogo(identity: 'team:1', name: '尤文图斯'),
              AppEntityAvatar(
                identity: 'user:1',
                semanticLabel: '用户头像',
                fallbackIcon: Icons.person,
              ),
              AppContentImage(),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('林远航 球员头像'), findsOneWidget);
    expect(find.bySemanticsLabel('尤文图斯 球队标识'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/ui/football/neutral-player-avatar.png',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/ui/home/neutral-team-crest.png',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.sports_soccer_rounded), findsOneWidget);
  });

  testWidgets('media widgets use Image.network for resolved URLs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SingleChildScrollView(
          child: Column(
            children: [
              AppPlayerAvatar(
                identity: 'player:1',
                name: '林远航',
                imageUrl: 'http://localhost/demo/p1-media/player-flagship.png',
              ),
              AppTeamLogo(
                identity: 'team:1',
                name: '尤文图斯',
                imageUrl:
                    'http://localhost/demo/p1-media/team-crest-cobalt.png',
              ),
              AppContentImage(
                imageUrl: 'http://localhost/demo/p1-media/cover-stadium.png',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    final networkImages = tester.widgetList<Image>(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is NetworkImage,
      ),
    );
    expect(
      networkImages.map((image) => (image.image as NetworkImage).url).toSet(),
      {
        'http://localhost/demo/p1-media/player-flagship.png',
        'http://localhost/demo/p1-media/team-crest-cobalt.png',
        'http://localhost/demo/p1-media/cover-stadium.png',
      },
    );
    expect(find.byIcon(Icons.sports_soccer_rounded), findsOneWidget);
  });

  testWidgets('SVG covers load through SvgPicture and retain fallback', (
    tester,
  ) async {
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: AppContentImage(
              imageUrl: 'http://localhost/demo/contents/cover.svg?rev=2',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }, createHttpClient: (_) => _SvgHttpClient());

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byIcon(Icons.sports_soccer_rounded), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/ui/home/neutral-football-cover.png',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('SVG HTTP failure leaves the real local cover fallback visible', (
    tester,
  ) async {
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: AppContentImage(
              imageUrl: 'http://localhost/demo/contents/missing.svg?rev=3',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }, createHttpClient: (_) => _SvgHttpClient(fail: true));

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byIcon(Icons.sports_soccer_rounded), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/ui/home/neutral-football-cover.png',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('SVG media URL detection handles path and query strings', () {
    expect(
      isSvgMediaUrl('http://localhost/demo/contents/cover-05.svg?rev=1'),
      isTrue,
    );
    expect(
      isSvgMediaUrl('http://localhost/demo/p1-media/cover-stadium.png'),
      isFalse,
    );
  });
}

class _SvgHttpClient implements HttpClient {
  _SvgHttpClient({this.fail = false});

  final bool fail;

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _SvgHttpRequest(method: method, fail: fail);

  @override
  void close({bool force = false}) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SvgHttpRequest implements HttpClientRequest {
  _SvgHttpRequest({this.method = 'GET', this.fail = false});

  final bool fail;
  @override
  final HttpHeaders headers = _SvgHttpHeaders();

  @override
  final String method;
  int _contentLength = -1;

  @override
  int get contentLength => _contentLength;

  @override
  set contentLength(int value) => _contentLength = value;

  bool _followRedirects = true;

  @override
  bool get followRedirects => _followRedirects;

  @override
  set followRedirects(bool value) => _followRedirects = value;

  @override
  int get maxRedirects => 5;

  @override
  set maxRedirects(int value) {}

  @override
  bool get persistentConnection => false;

  @override
  set persistentConnection(bool value) {}

  @override
  Future<HttpClientResponse> close() async => _SvgHttpResponse(fail: fail);

  @override
  Future<HttpClientResponse> addStream(Stream<List<int>> stream) async {
    await for (final _ in stream) {}
    return close();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SvgHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _values.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = [value.toString()];
  }

  @override
  String? value(String name) => _values[name.toLowerCase()]?.first;

  @override
  List<String>? operator [](String name) => _values[name.toLowerCase()];

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SvgHttpResponse implements HttpClientResponse {
  _SvgHttpResponse({this.fail = false});

  final bool fail;

  static const _svg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12"><rect width="12" height="12" fill="#0f6b53"/></svg>';
  @override
  int get statusCode => fail ? HttpStatus.notFound : HttpStatus.ok;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => _svg.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _SvgHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_svg.codeUnits).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
