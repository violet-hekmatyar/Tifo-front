import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../notification/data/notification_repository.dart';
import '../../../shared/design_system/app_design_tokens.dart';
import 'shell_destination.dart';

class MainShellPage extends ConsumerWidget {
  const MainShellPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notificationUnreadCountProvider).value ?? 0;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Container(
          key: const ValueKey('main_navigation'),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppShadows.floatingNavigation,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: NavigationBar(
              height: 74,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: [
                for (final destination in ShellDestination.values)
                  NavigationDestination(
                    icon: _destinationIcon(
                      destination.icon,
                      destination,
                      unread,
                    ),
                    selectedIcon: _destinationIcon(
                      destination.selectedIcon,
                      destination,
                      unread,
                    ),
                    label: destination.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _destinationIcon(
  IconData icon,
  ShellDestination destination,
  int unread,
) => destination == ShellDestination.messages && unread > 0
    ? Badge(label: Text(unread > 99 ? '99+' : '$unread'), child: Icon(icon))
    : Icon(icon);
