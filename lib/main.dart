import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yuri_app/post_imgview.dart';
import 'package:yuri_app/reddit_feed.dart';
import 'package:yuri_app/settings_page.dart';

void main() {
  runApp(MaterialApp(home: const MyApp(), routes: {
    SettingsPage.routeName: (context) => const SettingsPage(),
  }));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SettingsArguments settingsArgs;

  @override
  void initState() {
    super.initState();
    getSettings().then((value) => settingsArgs = value);
  }

  Future<SettingsArguments> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsArguments((prefs.getString("subreddit") ?? "WholesomeYuri"),
        (prefs.getBool("allowNSFW") ?? false));
  }

  @override
  Widget build(BuildContext context) {
    var homeBarFuture = FutureBuilder(
        future: getSettings(),
        builder:
            (BuildContext context, AsyncSnapshot<SettingsArguments> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Text('Loading...');
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const Text("Error!");
              } else {
                return Text(snapshot.data!.subreddit);
              }
            case ConnectionState.none:
              return const Text('Loading...');
            case ConnectionState.active:
              return const Text('Loading...');
          }
        });
    var bodyFuture = FutureBuilder(
        future: getSettings(),
        builder:
            (BuildContext context, AsyncSnapshot<SettingsArguments> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Text('Loading...');
            case ConnectionState.done:
              if (snapshot.hasError) {
                return const Text("Error!");
              } else {
                return RedditFeed(settings: snapshot.data!);
              }
            case ConnectionState.none:
              return const Text('Loading...');
            case ConnectionState.active:
              return const Text('Loading...');
          }
        });

    return MaterialApp(
        routes: {
          PostImageViewer.routeName: (context) => const PostImageViewer(),
        },
        title: "Fluttering Yuri",
        theme: ThemeData(),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(),
        ),
        home: Scaffold(
          appBar: AppBar(title: homeBarFuture),
          body: bodyFuture,
          drawer: Drawer(
              child: ListView(padding: EdgeInsets.zero, children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text("The WholesomeYuri thing",
                  style: TextStyle(fontSize: 16.0)),
            ),
            ListTile(
                title: const Text("Settings"),
                onTap: () {
                  Navigator.pushNamed(context, SettingsPage.routeName,
                          arguments: settingsArgs)
                      .then((value) => setState(() {
                            getSettings();
                          }));
                })
          ])),
        ));
  }
}
