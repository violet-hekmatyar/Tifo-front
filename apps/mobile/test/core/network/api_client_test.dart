import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart' hide Matcher;
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/api_response.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/core/network/network_providers.dart';
import 'package:tifo/core/network/page_result.dart';

void main() {
  const baseUrl = 'https://api.example.test';
  late Dio dio;
  late DioAdapter adapter;
  late ApiClient client;

  setUp(() {
    dio = Dio();
    adapter = DioAdapter(dio: dio);
    client = ApiClient(AppConfig.fromValues(apiBaseUrl: baseUrl), dio);
  });

  test('decodes an object response without exposing dynamic', () async {
    adapter.onGet(
      '$baseUrl/user',
      (server) => server.reply(200, {
        'code': 0,
        'message': 'success',
        'data': {'id': 7, 'name': 'Tifo'},
        'traceId': 'trace-1',
      }),
    );

    final user = await client.get<_User>('/user', decode: _User.fromJson);
    expect(user, const _User(7, 'Tifo'));
  });

  test('decodes void, list, and page response shapes', () async {
    adapter
      ..onDelete(
        '$baseUrl/item/1',
        (server) => server.reply(200, {
          'code': 0,
          'message': 'success',
          'data': null,
          'traceId': null,
        }),
      )
      ..onGet(
        '$baseUrl/items',
        (server) => server.reply(200, {
          'code': 0,
          'message': 'success',
          'data': [
            {'id': 1, 'name': 'One'},
          ],
          'traceId': 'trace-list',
        }),
      )
      ..onGet(
        '$baseUrl/page',
        (server) => server.reply(200, {
          'code': 0,
          'message': 'success',
          'data': {
            'records': [
              {'id': 2, 'name': 'Two'},
            ],
            'total': 1,
            'pageNum': 1,
            'pageSize': 10,
            'pages': 1,
          },
          'traceId': 'trace-page',
        }),
      );

    await client.delete<void>('/item/1', decode: decodeVoid);
    final list = await client.get<List<_User>>(
      '/items',
      decode: (raw) => decodeList(raw, _User.fromJson),
    );
    final page = await client.get<PageResult<_User>>(
      '/page',
      decode: (raw) => PageResult.fromRaw(raw, _User.fromJson),
    );

    expect(list.single.name, 'One');
    expect(page.records.single.name, 'Two');
    expect(page.total, 1);
  });

  test('maps business failure and malformed responses', () async {
    adapter
      ..onGet(
        '$baseUrl/business',
        (server) => server.reply(200, {
          'code': 40001,
          'message': 'bad input',
          'data': null,
          'traceId': 'trace-business',
        }),
      )
      ..onGet(
        '$baseUrl/malformed',
        (server) => server.reply(200, {'unexpected': true}),
      );

    await expectLater(
      client.get<void>('/business', decode: decodeVoid),
      throwsA(
        isA<BusinessException>()
            .having((e) => e.code, 'code', 40001)
            .having((e) => e.traceId, 'traceId', 'trace-business'),
      ),
    );
    await expectLater(
      client.get<void>('/malformed', decode: decodeVoid),
      throwsA(isA<ParseException>()),
    );
  });

  test('maps HTTP 401 and 403 without authentication side effects', () async {
    for (final status in [401, 403]) {
      final path = '$baseUrl/http-$status';
      adapter.onGet(
        path,
        (server) => server.reply(status, {
          'code': status == 401 ? 40101 : 40301,
          'message': 'denied',
          'data': null,
          'traceId': 'trace-$status',
        }),
      );
      await expectLater(
        client.get<void>('/http-$status', decode: decodeVoid),
        throwsA(
          isA<HttpException>()
              .having((e) => e.statusCode, 'statusCode', status)
              .having((e) => e.traceId, 'traceId', 'trace-$status'),
        ),
      );
    }
  });

  test(
    'maps connection, timeout, cancellation, and unknown failures',
    () async {
      final cases = <(String, DioExceptionType, Matcher)>[
        (
          'connection',
          DioExceptionType.connectionError,
          isA<NetworkException>(),
        ),
        ('timeout', DioExceptionType.receiveTimeout, isA<TimeoutException>()),
        ('cancel', DioExceptionType.cancel, isA<CancelledException>()),
        ('unknown', DioExceptionType.unknown, isA<UnknownException>()),
      ];
      for (final (name, type, matcher) in cases) {
        final path = '$baseUrl/$name';
        adapter.onGet(
          path,
          (server) => server.throws(
            0,
            DioException(
              requestOptions: RequestOptions(path: path),
              type: type,
            ),
          ),
        );
        await expectLater(
          client.get<void>('/$name', decode: decodeVoid),
          throwsA(matcher),
        );
      }
    },
  );

  test('missing base URL fails before any network request', () async {
    final missingConfigClient = ApiClient(AppConfig.fromValues(), dio);
    await expectLater(
      missingConfigClient.get<void>('/never-sent', decode: decodeVoid),
      throwsA(isA<ConfigException>()),
    );
  });

  test('Riverpod providers can replace config, Dio, and headers', () async {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.fromValues(appEnv: 'test', apiBaseUrl: baseUrl),
        ),
        dioProvider.overrideWithValue(dio),
        requestHeadersProvider.overrideWithValue(
          () => const {'X-Test-Header': 'replaced'},
        ),
      ],
    );
    addTearDown(container.dispose);
    adapter.onGet(
      '$baseUrl/provider',
      (server) => server.reply(200, {
        'code': 0,
        'message': 'success',
        'data': null,
        'traceId': 'provider',
      }),
    );

    await container
        .read(apiClientProvider)
        .get<void>('/provider', decode: decodeVoid);
    final headers = await container.read(requestHeadersProvider)();
    expect(headers['X-Test-Header'], 'replaced');
  });
}

final class _User {
  const _User(this.id, this.name);

  factory _User.fromJson(Object? raw) {
    if (raw case {'id': final int id, 'name': final String name}) {
      return _User(id, name);
    }
    throw const FormatException('Invalid user JSON.');
  }

  final int id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is _User && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
