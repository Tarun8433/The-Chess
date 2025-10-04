import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/theme_service.dart';

class ThemeToggleWidget extends StatelessWidget {
  final bool showLabel;
  final IconData? lightIcon;
  final IconData? darkIcon;
  final double iconSize;
  
  const ThemeToggleWidget({
    Key? key,
    this.showLabel = true,
    this.lightIcon,
    this.darkIcon,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        return InkWell(
          onTap: () => themeService.toggleTheme(),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  themeService.isDarkMode 
                      ? (lightIcon ?? Icons.light_mode)
                      : (darkIcon ?? Icons.dark_mode),
                  size: iconSize,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    themeService.isDarkMode ? 'Light Mode' : 'Dark Mode',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class ThemeSelectionDialog extends StatelessWidget {
  const ThemeSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ThemeOption(
                title: 'Light',
                subtitle: 'Light theme',
                icon: Icons.light_mode,
                isSelected: themeService.themeMode == ThemeMode.light,
                onTap: () {
                  themeService.switchToLightTheme();
                  Navigator.of(context).pop();
                },
              ),
              _ThemeOption(
                title: 'Dark',
                subtitle: 'Dark theme',
                icon: Icons.dark_mode,
                isSelected: themeService.themeMode == ThemeMode.dark,
                onTap: () {
                  themeService.switchToDarkTheme();
                  Navigator.of(context).pop();
                },
              ),
              _ThemeOption(
                title: 'System',
                subtitle: 'Follow system setting',
                icon: Icons.settings_system_daydream,
                isSelected: themeService.themeMode == ThemeMode.system,
                onTap: () {
                  themeService.switchToSystemTheme();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected 
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// Floating Action Button for theme toggle
class ThemeToggleFAB extends StatelessWidget {
  const ThemeToggleFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        return FloatingActionButton(
          mini: true,
          onPressed: () => themeService.toggleTheme(),
          tooltip: 'Toggle Theme',
          child: Icon(
            themeService.isDarkMode 
                ? Icons.light_mode 
                : Icons.dark_mode,
          ),
        );
      },
    );
  }
}

// App Bar action for theme selection
class ThemeSelectionAction extends StatelessWidget {
  const ThemeSelectionAction({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeService>(
      builder: (themeService) {
        return PopupMenuButton<String>(
          icon: Icon(
            themeService.isDarkMode 
                ? Icons.dark_mode 
                : Icons.light_mode,
          ),
          onSelected: (value) {
            switch (value) {
              case 'light':
                themeService.switchToLightTheme();
                break;
              case 'dark':
                themeService.switchToDarkTheme();
                break;
              case 'system':
                themeService.switchToSystemTheme();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'light',
              child: Row(
                children: [
                  const Icon(Icons.light_mode),
                  const SizedBox(width: 8),
                  const Text('Light'),
                  if (themeService.themeMode == ThemeMode.light)
                    const Spacer(),
                  if (themeService.themeMode == ThemeMode.light)
                    const Icon(Icons.check),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'dark',
              child: Row(
                children: [
                  const Icon(Icons.dark_mode),
                  const SizedBox(width: 8),
                  const Text('Dark'),
                  if (themeService.themeMode == ThemeMode.dark)
                    const Spacer(),
                  if (themeService.themeMode == ThemeMode.dark)
                    const Icon(Icons.check),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'system',
              child: Row(
                children: [
                  const Icon(Icons.settings_system_daydream),
                  const SizedBox(width: 8),
                  const Text('System'),
                  if (themeService.themeMode == ThemeMode.system)
                    const Spacer(),
                  if (themeService.themeMode == ThemeMode.system)
                    const Icon(Icons.check),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}