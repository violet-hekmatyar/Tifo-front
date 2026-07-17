import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final skeletonStatusProvider = Provider<String>(
  (ref) => 'Flutter mobile initialized',
);

class SkeletonPage extends ConsumerWidget {
  const SkeletonPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(skeletonStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('南看台')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('南看台', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(status),
            const SizedBox(height: 8),
            const Text('F01 基础骨架'),
          ],
        ),
      ),
    );
  }
}
