import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:tifo/app/config/app_config.dart';
import 'package:tifo/core/network/api_client.dart';
import 'package:tifo/core/network/network_exceptions.dart';
import 'package:tifo/features/content/data/publish_subject_api.dart';
import 'package:tifo/features/content/data/publish_subject_repository.dart';
import 'package:tifo/features/content/domain/publish_subject.dart';
import 'package:tifo/features/content/presentation/controllers/publish_subject_controller.dart';

void main() {
  test(
    'subject API decodes topic records and preserves typed metadata',
    () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = PublishSubjectApi(
        ApiClient(AppConfig.fromValues(apiBaseUrl: 'https://api.test'), dio),
      );
      adapter.onGet(
        'https://api.test/api/app/publish/subjects',
        (server) => server.reply(200, {
          'code': 0,
          'message': 'success',
          'data': {
            'records': [
              {
                'subjectId': 701,
                'subjectType': 'TOPIC',
                'name': '英超焦点',
                'discussionCount': 12,
                'summary': '联赛讨论',
                'coverUrl': '/demo/topic.png',
              },
            ],
            'total': 1,
            'pageNum': 1,
            'pageSize': 20,
            'pages': 1,
          },
        }),
      );

      final page = await api.list(
        kind: PublishAuxiliaryKind.topic,
        keyword: '英超',
        pageNum: 1,
        pageSize: 20,
      );
      expect(page.records.single.stableKey, 'TOPIC:701');
      expect(page.records.single.name, '英超焦点');
      expect(page.records.single.coverUrl, '/demo/topic.png');
    },
  );

  test(
    'subject controller handles empty, ready pagination and failure states',
    () async {
      final repository = _Subjects();
      final controller = PublishSubjectController(
        repository,
        PublishAuxiliaryKind.hotspot,
      );

      await controller.loadInitial();
      expect(controller.state.status, PublishSubjectStatus.ready);
      expect(
        controller.state.records.single.kind,
        PublishAuxiliaryKind.hotspot,
      );
      expect(controller.state.hasMore, isTrue);

      await controller.loadMore();
      expect(controller.state.records.map((item) => item.id), [1, 2]);
      expect(controller.state.hasMore, isFalse);

      repository.empty = true;
      await controller.retry();
      expect(controller.state.status, PublishSubjectStatus.empty);

      repository.failure = const NetworkException('目录暂不可用');
      await controller.retry();
      expect(controller.state.status, PublishSubjectStatus.failure);
      expect(controller.state.message, '目录暂不可用');
      controller.dispose();
    },
  );
}

final class _Subjects implements PublishSubjectRepositoryContract {
  bool empty = false;
  AppNetworkException? failure;

  @override
  Future<PublishSubjectPage> list({
    required PublishAuxiliaryKind kind,
    required String keyword,
    required int pageNum,
    required int pageSize,
  }) async {
    if (failure case final error?) throw error;
    if (empty) {
      return PublishSubjectPage(
        records: const [],
        total: 0,
        pageNum: 1,
        pageSize: pageSize,
        pages: 0,
      );
    }
    final records = [
      PublishAuxiliaryItem(id: 1, name: '国家队名单', count: 9, kind: kind),
      if (pageNum > 1)
        PublishAuxiliaryItem(id: 2, name: '欧冠焦点', count: 8, kind: kind),
    ];
    return PublishSubjectPage(
      records: records,
      total: 2,
      pageNum: pageNum,
      pageSize: pageSize,
      pages: 2,
    );
  }
}
