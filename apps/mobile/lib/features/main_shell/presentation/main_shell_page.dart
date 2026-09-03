import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../notification/data/notification_repository.dart';
import 'shell_destination.dart';

class MainShellPage extends ConsumerWidget {
  const MainShellPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationUnreadCountProvider).value ?? 0;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('main_navigation'),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final destination in ShellDestination.values)
            NavigationDestination(
              icon: _destinationIcon(destination.icon, destination, unread),
              selectedIcon: _destinationIcon(
                destination.selectedIcon,
                destination,
                unread,
              ),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

Widget _destinationIcon(
  IconData icon,
  ShellDestination destination,
  int unread,
) => destination == ShellDestination.messages && unread > 0
    ? Badge.count(count: unread, child: Icon(icon))
    : Icon(icon);
