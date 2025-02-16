import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationView extends StatelessWidget {
  const NavigationView({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width > 800) {
      return Center(
        child: SizedBox(
          width: 1000,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Scaffold(
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'ZapCall',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        NavigationRail(
                          selectedIndex: navigationShell.currentIndex,
                          onDestinationSelected: _onTabChange,
                          extended: width > 1000,
                          labelType:
                              width > 1000 ? null : NavigationRailLabelType.all,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.person),
                              label: Text('Users'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.video_call),
                              label: Text('Rooms'),
                              disabled: true,
                            ),
                          ],
                        ),
                        Expanded(child: navigationShell),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTabChange,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_call),
            label: 'Rooms',
            enabled: false,
          ),
        ],
      ),
    );
  }

  void _onTabChange(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
