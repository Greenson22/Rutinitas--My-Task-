import 'package:flutter/material.dart';

class DrawerMenu extends StatelessWidget {
  final String selectedBaseDir;
  final String fullJsonPath;
  final VoidCallback onOpenSettings;

  const DrawerMenu({
    super.key,
    required this.selectedBaseDir,
    required this.fullJsonPath,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              children: const [
                Icon(
                  Icons.format_list_bulleted,
                  color: Colors.indigo,
                  size: 30,
                ),
                SizedBox(width: 20),
                Text(
                  'Task Master',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            Icons.format_list_bulleted,
            'Task Master',
            isSelected: true,
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            Icons.wb_sunny_outlined,
            'Daily',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            Icons.calendar_today,
            'Weekly',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            Icons.calendar_month,
            'Monthly',
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          _buildDrawerItem(
            Icons.settings,
            'Settings',
            subtitle: '~/$selectedBaseDir/mytask/',
            onTap: () {
              Navigator.pop(context);
              onOpenSettings();
            },
          ),
          const Divider(),
          _buildDrawerItem(
            Icons.info_outline,
            'About',
            subtitle: 'Path: $fullJsonPath',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title, {
    String? subtitle,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.indigo : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.indigo : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            )
          : null,
      onTap: onTap,
    );
  }
}
