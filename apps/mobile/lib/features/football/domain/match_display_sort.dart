import 'football_models.dart';

const _liveStatuses = {
  'LIVE',
  'IN_PROGRESS',
  'PLAYING',
  'HALF_TIME',
  'SECOND_HALF',
  'EXTRA_TIME',
};
const _upcomingStatuses = {'SCHEDULED', 'NOT_STARTED', 'UPCOMING'};
const _finishedStatuses = {'FINISHED', 'ENDED', 'COMPLETED'};

List<FootballMatch> sortMatchesForDisplay(Iterable<FootballMatch> matches) {
  final indexed = matches.indexed.toList(growable: false);
  indexed.sort((a, b) {
    final groupCompare = _group(a.$2.status).compareTo(_group(b.$2.status));
    if (groupCompare != 0) return groupCompare;
    final group = _group(a.$2.status);
    final timeCompare = switch (group) {
      1 => _compareTime(a.$2.matchTime, b.$2.matchTime),
      2 => _compareTimeDescending(a.$2.matchTime, b.$2.matchTime),
      _ => 0,
    };
    return timeCompare != 0 ? timeCompare : a.$1.compareTo(b.$1);
  });
  return List.unmodifiable(indexed.map((entry) => entry.$2));
}

int _group(String status) {
  final normalized = status.trim().toUpperCase();
  if (_liveStatuses.contains(normalized)) return 0;
  if (_upcomingStatuses.contains(normalized)) return 1;
  if (_finishedStatuses.contains(normalized)) return 2;
  return 3;
}

int _compareTime(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

int _compareTimeDescending(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}
