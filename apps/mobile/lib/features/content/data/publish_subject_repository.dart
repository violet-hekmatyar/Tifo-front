import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/publish_subject.dart';
import 'publish_subject_api.dart';

abstract interface class PublishSubjectRepositoryContract {
  Future<PublishSubjectPage> list({
    required PublishAuxiliaryKind kind,
    required String keyword,
    required int pageNum,
    required int pageSize,
  });
}

final publishSubjectRepositoryProvider =
    Provider<PublishSubjectRepositoryContract>(
      (ref) => PublishSubjectRepository(
        PublishSubjectApi(ref.watch(apiClientProvider)),
      ),
    );

final class PublishSubjectRepository
    implements PublishSubjectRepositoryContract {
  const PublishSubjectRepository(this._api);
  final PublishSubjectApi _api;

  @override
  Future<PublishSubjectPage> list({
    required PublishAuxiliaryKind kind,
    required String keyword,
    required int pageNum,
    required int pageSize,
  }) => _api.list(
    kind: kind,
    keyword: keyword,
    pageNum: pageNum,
    pageSize: pageSize,
  );
}
