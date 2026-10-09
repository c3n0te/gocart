import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:gocart/main.dart';
import 'package:gocart/globals/pocketbase.dart';
import 'package:gocart/globals/logger.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _notifications = true; // load from and save to your store


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettingsList(
        lightTheme: SettingsThemeData(
          settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          settingsSectionBackground: Colors.white,
        ),
        sections: [
          SettingsSection(
            title: const Text('General', style: TextStyle(color: Colors.black)),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                value: const Text('English'),
                onPressed: (context) {/* open a language picker */},
              ),
              SettingsTile.switchTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                activeSwitchColor: Colors.black,
                initialValue: _notifications,
                onToggle: (value) => setState(() => _notifications = value),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Account', style: TextStyle(color: Colors.black),),
            tiles: [
              SettingsTile(
                title: const Text('Password'), 
                description: const Text('Update your credentials'),
              ),
              SettingsTile(
                title: const Text('Sign out', style: TextStyle(color: Colors.red),),
                onPressed: (context) { 
                  pb.authStore.clear();
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HomeLayout()));
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('About', style: TextStyle(color: Colors.black)),
            tiles: [
              SettingsTile(
                title: const Text('Version'),
                value: const Text('0.1.0'),
              ),
              SettingsTile.navigation(
                title: const Text('Open-source licenses'),
                onPressed: (context) => showLicensePage(context: context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}