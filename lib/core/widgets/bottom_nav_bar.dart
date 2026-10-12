import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.currentIndex, required this.onTap, this.cartCount = 0});

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    Widget cartIcon(IconData icon) => Badge(
      isLabelVisible: cartCount > 0,
      backgroundColor: AppColors.danger,
      label: Text('$cartCount'),
      child: Icon(icon),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: AppShadows.bottomBar,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            const NavigationDestination(
              icon: Icon(Icons.search_rounded),
              selectedIcon: Icon(Icons.manage_search_rounded),
              label: 'Tìm kiếm',
            ),
            NavigationDestination(
              icon: cartIcon(Icons.shopping_cart_outlined),
              selectedIcon: cartIcon(Icons.shopping_cart_rounded),
              label: 'Giỏ hời',
            ),
            const NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded),
              label: 'Đã lưu',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
