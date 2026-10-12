import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/bottom_nav_bar.dart';
import '../features/cart/providers/deal_cart_provider.dart';

/// Hosts the five bottom-navigation branches.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        cartCount: ref.watch(dealCartCountProvider),
        onTap: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
      ),
    );
  }
}
