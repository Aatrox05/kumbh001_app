import 'package:flutter/material.dart';
import 'package:kumbh_app/l10n/app_localizations.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  static const Color _activeColor = Color(0xFFFF7A00);
  static const Color _inactiveColor = Color(0xFF9E9E9E);
  static const Color _backgroundColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: l10n?.home ?? 'Home',
                index: 0,
                currentIndex: currentIndex,
                onTap: onItemSelected,
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: l10n?.explore ?? 'Explore',
                index: 1,
                currentIndex: currentIndex,
                onTap: onItemSelected,
              ),

              // CENTER SOS
              Center(
                child: _SOSButton(
                  onPressed: () => onItemSelected(2),
                  isSelected: currentIndex == 2,
                  label: l10n?.sos ?? 'SOS',
                ),
              ),

              _NavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: l10n?.map ?? 'Map',
                index: 3,
                currentIndex: currentIndex,
                onTap: onItemSelected,
              ),
              _NavItem(
                icon: Icons.more_horiz_outlined,
                activeIcon: Icons.more_horiz,
                label: l10n?.more ?? 'More',
                index: 4,
                currentIndex: currentIndex,
                onTap: onItemSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- PRIVATE NAV ITEM ---------------- */

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  bool get _isActive => currentIndex == index;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                _isActive ? activeIcon : icon,
                key: ValueKey<bool>(_isActive),
                size: 24,
                color: _isActive
                    ? AppBottomNavBar._activeColor
                    : AppBottomNavBar._inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: _isActive ? FontWeight.w600 : FontWeight.w500,
                color: _isActive
                    ? AppBottomNavBar._activeColor
                    : AppBottomNavBar._inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- SOS BUTTON ---------------- */

class _SOSButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isSelected;
  final String label;

  const _SOSButton({
    required this.onPressed,
    required this.isSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: isSelected ? 1.1 : 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Material(
          color: const Color(0xFFFF1744), // Vibrant Red
          shape: const CircleBorder(),
          elevation: 8,
          shadowColor: const Color(0xFFFF1744).withValues(alpha: 0.4),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
