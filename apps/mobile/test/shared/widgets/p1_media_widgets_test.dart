import 'package:flutter/material.dart';
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

    expect(find.text('林'), findsOneWidget);
    expect(find.text('尤'), findsOneWidget);
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
    expect(find.byType(Image), findsNWidgets(4));
    expect(find.byIcon(Icons.sports_soccer_rounded), findsOneWidget);
  });
}
