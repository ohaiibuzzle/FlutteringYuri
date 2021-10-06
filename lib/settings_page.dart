import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsArguments {
  String subreddit;
  bool allowNSFW;

  SettingsArguments(this.subreddit, this.allowNSFW);

  @override
  String toString() {
    return "Subreddit $subreddit and nsfw is $allowNSFW";
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);
  static const routeName = "/settings";

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

Future<void> _saveSettings(SettingsArguments args) async {
  final _prefs = await SharedPreferences.getInstance();
  _prefs.setString("subreddit", args.subreddit);
  _prefs.setBool("allowNSFW", args.allowNSFW);
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsArguments args;
  String srValue = '';

  @override
  Widget build(BuildContext context) {
    args = ModalRoute.of(context)!.settings.arguments as SettingsArguments;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(title: const Text("Settings")),
      body: WillPopScope(
          onWillPop: () async {
            await _saveSettings(args);
            Navigator.pop(context, args);
            return false;
          },
          child: buildSettings(context)),
    );
  }

  Widget buildSettings(BuildContext context) {
    return SettingsList(
      sections: [
        CustomSection(child: const SizedBox(height: 10)),
        SettingsSection(title: 'Subreddit Options', tiles: [
          SettingsTile(
            title: 'Subreddit',
            subtitle: args.subreddit,
            onPressed: (BuildContext context) {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text("Subreddit"),
                  content: Row(
                    children: [
                      Expanded(
                          child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                            labelText: "Subreddit", hintText: args.subreddit),
                        onChanged: (value) {
                          srValue = value;
                        },
                      ))
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                        child: const Text("OK"),
                        onPressed: () {
                          setState(() {
                            args.subreddit = srValue;
                            Navigator.pop(context);
                          });
                        })
                  ],
                ),
              );
            },
          ),
          SettingsTile.switchTile(
              title: 'Allow NSFW Content',
              onToggle: (bool newValue) {
                args.allowNSFW = newValue;
                setState(() {});
              },
              switchValue: args.allowNSFW)
        ])
      ],
    );
  }

  @override
  void dispose() {
    _saveSettings(args);
    super.dispose();
  }
}
