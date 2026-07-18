import 'package:flutter_test/flutter_test.dart';
import 'package:tifo/features/football/domain/football_models.dart';
import 'package:tifo/features/football/domain/match_display_sort.dart';

void main() {
  test('orders live upcoming finished and exceptional groups', () {
    final sorted = sortMatchesForDisplay([
      _match(1, 'FINISHED', DateTime(2026, 7, 10)),
      _match(2, 'UNKNOWN', DateTime(2026, 7, 20)),
      _match(3, 'SCHEDULED', DateTime(2026, 7, 15)),
      _match(4, 'LIVE', DateTime(2026, 7, 13)),
    ]);
    expect(sorted.map((item) => item.id), [4, 3, 1, 2]);
  });

  test('upcoming is ascending and finished is descending', () {
    final sorted = sortMatchesForDisplay([
      _match(1, 'SCHEDULED', DateTime(2026, 7, 20)),
      _match(2, 'FINISHED', DateTime(2026, 7, 8)),
      _match(3, 'SCHEDULED', DateTime(2026, 7, 14)),
      _match(4, 'FINISHED', DateTime(2026, 7, 10)),
    ]);
    expect(sorted.map((item) => item.id), [3, 1, 4, 2]);
  });

  test('live and unknown groups retain backend relative order', () {
    final sorted = sortMatchesForDisplay([
      _match(1, 'PLAYING', DateTime(2026, 7, 20)),
      _match(2, 'HALF_TIME', DateTime(2026, 7, 10)),
      _match(3, 'SUSPENDED', DateTime(2026, 7, 30)),
      _match(4, 'POSTPONED', DateTime(2026, 7, 1)),
    ]);
    expect(sorted.map((item) => item.id), [1, 2, 3, 4]);
  });

  test('missing time is stable and follows valid time inside timed groups', () {
    final sorted = sortMatchesForDisplay([
      _match(1, 'SCHEDULED', null),
      _match(2, 'SCHEDULED', DateTime(2026, 7, 10)),
      _match(3, 'FINISHED', null),
      _match(4, 'FINISHED', DateTime(2026, 7, 8)),
    ]);
    expect(sorted.map((item) => item.id), [2, 1, 4, 3]);
  });

  test('does not infer status from score', () {
    final scoredUpcoming = _match(
      1,
      'SCHEDULED',
      DateTime(2026, 7, 10),
      score: 2,
    );
    final scorelessLive = _match(2, 'LIVE', DateTime(2026, 7, 11));
    expect(
      sortMatchesForDisplay([
        scoredUpcoming,
        scorelessLive,
      ]).map((item) => item.id),
      [2, 1],
    );
  });
}

FootballMatch _match(int id, String status, DateTime? time, {int? score}) =>
    FootballMatch(
      id: id,
      leagueId: 1,
      leagueName: '联赛',
      homeTeam: FootballTeam(id: 10, name: '主队', score: score),
      awayTeam: FootballTeam(id: 11, name: '客队', score: score),
      status: status,
      matchTime: time,
    );
