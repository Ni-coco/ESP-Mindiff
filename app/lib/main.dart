import 'package:flutter/material.dart';
import 'dart:ui';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindiff',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _NavDestinationData {
  const _NavDestinationData({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<_NavDestinationData> _destinations = <_NavDestinationData>[
    const _NavDestinationData(
      title: 'Accueil',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      page: _HomePage(),
    ),
    const _NavDestinationData(
      title: 'Programme',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      page: _ProgrammePage(),
    ),
    const _NavDestinationData(
      title: 'Caméra',
      icon: Icons.camera_alt_outlined,
      selectedIcon: Icons.camera_alt,
      page: _CameraPage(),
    ),
    const _NavDestinationData(
      title: 'Profil',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      page: _ProfilePage(),
    ),
  ];

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index.clamp(0, _destinations.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int safeIndex = _currentIndex.clamp(0, _destinations.length - 1);
    final _NavDestinationData current = _destinations[safeIndex];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        title: Text(current.title),
      ),
      body: current.page,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1.0,
              ),
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorColor: theme.colorScheme.primary.withOpacity(0.12),
                overlayColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.hovered) ||
                      states.contains(MaterialState.focused) ||
                      states.contains(MaterialState.pressed)) {
                    return Colors.transparent; // pas d'overlay hover/focus/pressed
                  }
                  return null; // par défaut sinon
                }),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashFactory: NoSplash.splashFactory,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
                child: _SquareIndicatorNavigationBar(
                  destinations: _destinations,
                  selectedIndex: safeIndex,
                  onDestinationSelected: _onItemTapped,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget personnalisé qui force un indicateur carré centré sous l'icône
class _SquareIndicatorNavigationBar extends StatelessWidget {
  const _SquareIndicatorNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<_NavDestinationData> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 64,
      backgroundColor: Colors.transparent,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      indicatorColor: Colors.transparent, // retirée pour custom indicator
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: List.generate(destinations.length, (i) {
        final selected = i == selectedIndex;
        return NavigationDestination(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              if (selected)
                IgnorePointer(
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.14),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              Icon(
                selected ? destinations[i].selectedIcon : destinations[i].icon,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).iconTheme.color,
                grade: 0.0,
                opticalSize: 24,
              ),
            ],
          ),
          label: '',
        );
      }),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Bienvenue sur Accueil'),
    );
  }
}

class _ProgrammePage extends StatelessWidget {
  const _ProgrammePage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Programme à venir'),
    );
  }
}

class _CameraPage extends StatelessWidget {
  const _CameraPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Caméra (à implémenter)'),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profil utilisateur'),
    );
  }
}
