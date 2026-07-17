import '../../../core/network/network_exceptions.dart';

final class TeamOption {
  const TeamOption({
    required this.id,
    required this.name,
    required this.followed,
    this.logoUrl,
    this.leagueName,
    this.country,
  });

  factory TeamOption.fromJson(Object? raw) {
    if (raw is! Map || raw['teamId'] is! num || raw['teamName'] is! String) {
      throw const ParseException('Invalid team option.');
    }
    return TeamOption(
      id: (raw['teamId'] as num).toInt(),
      name: raw['teamName'] as String,
      logoUrl: raw['logoUrl'] as String?,
      leagueName: raw['leagueName'] as String?,
      country: raw['country'] as String?,
      followed: raw['followed'] == true,
    );
  }

  final int id;
  final String name;
  final String? logoUrl;
  final String? leagueName;
  final String? country;
  final bool followed;
}

final class PlayerOption {
  const PlayerOption({
    required this.id,
    required this.name,
    required this.followed,
    this.avatarUrl,
    this.position,
    this.teamId,
    this.teamName,
  });

  factory PlayerOption.fromJson(Object? raw) {
    if (raw is! Map ||
        raw['playerId'] is! num ||
        raw['playerName'] is! String) {
      throw const ParseException('Invalid player option.');
    }
    return PlayerOption(
      id: (raw['playerId'] as num).toInt(),
      name: raw['playerName'] as String,
      avatarUrl: raw['avatarUrl'] as String?,
      position: raw['position'] as String?,
      teamId: (raw['teamId'] as num?)?.toInt(),
      teamName: raw['teamName'] as String?,
      followed: raw['followed'] == true,
    );
  }

  final int id;
  final String name;
  final String? avatarUrl;
  final String? position;
  final int? teamId;
  final String? teamName;
  final bool followed;
}

final class OnboardingOptions {
  const OnboardingOptions({required this.teams, required this.players});

  factory OnboardingOptions.fromJson(Object? raw) {
    if (raw is! Map) throw const ParseException('Invalid onboarding options.');
    final teams = <int, TeamOption>{};
    final players = <int, PlayerOption>{};
    for (final key in ['recommendedTeams', 'hotTeams']) {
      final values = raw[key];
      if (values is! List) throw const ParseException('Invalid team options.');
      for (final value in values) {
        final option = TeamOption.fromJson(value);
        teams[option.id] = option;
      }
    }
    for (final key in ['recommendedPlayers', 'hotPlayers']) {
      final values = raw[key];
      if (values is! List) {
        throw const ParseException('Invalid player options.');
      }
      for (final value in values) {
        final option = PlayerOption.fromJson(value);
        players[option.id] = option;
      }
    }
    return OnboardingOptions(
      teams: List.unmodifiable(teams.values),
      players: List.unmodifiable(players.values),
    );
  }

  final List<TeamOption> teams;
  final List<PlayerOption> players;
  bool get isEmpty => teams.isEmpty && players.isEmpty;
}

final class SavedPreferences {
  const SavedPreferences({
    required this.completed,
    required this.mainTeamId,
    required this.followTeamCount,
    required this.followPlayerCount,
  });

  factory SavedPreferences.fromJson(Object? raw) {
    if (raw is! Map ||
        raw['completed'] is! bool ||
        raw['mainTeamId'] is! num ||
        raw['followTeamCount'] is! num ||
        raw['followPlayerCount'] is! num) {
      throw const ParseException('Invalid preferences response.');
    }
    return SavedPreferences(
      completed: raw['completed'] as bool,
      mainTeamId: (raw['mainTeamId'] as num).toInt(),
      followTeamCount: (raw['followTeamCount'] as num).toInt(),
      followPlayerCount: (raw['followPlayerCount'] as num).toInt(),
    );
  }

  final bool completed;
  final int mainTeamId;
  final int followTeamCount;
  final int followPlayerCount;
}
