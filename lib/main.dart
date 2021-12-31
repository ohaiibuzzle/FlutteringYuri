import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yuri_app/post_imgview.dart';
import 'package:yuri_app/reddit_feed.dart';
import 'package:yuri_app/settings_page.dart';
import 'package:http/http.dart' as http;

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
  late Image header;

  @override
  void initState() {
    super.initState();
    getSettings().then((value) => settingsArgs = value);
  }

  Future<SettingsArguments> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsArguments(
        (prefs.getString("subreddit") ?? "WholesomeYuri"),
        (prefs.getBool("allowNSFW") ?? false),
        (prefs.getBool("loadFullRes") ?? true));
  }

  Future<Image> getSubredditHeading() async {
    final prefs = await SharedPreferences.getInstance();
    final subredditInfo = await http.get(Uri.parse(
        "https://www.reddit.com/r/${prefs.getString("subreddit") ?? "WholesomeYuri"}/about.json"));
    final subredditHeader = await jsonDecode(subredditInfo.body);
    return Image.network(subredditHeader['data']['banner_img']);
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

    var defaultHeader = DrawerHeader(
        decoration: BoxDecoration(color: Theme.of(context).backgroundColor),
        child: const Text("The WholesomeYuri thing"));

    var subredditHeader = FutureBuilder(
        future: getSubredditHeading(),
        builder: (BuildContext context, AsyncSnapshot<Image> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return defaultHeader;
            case ConnectionState.done:
              if (snapshot.hasError) {
                return defaultHeader;
              } else {
                return DrawerHeader(
                  decoration: BoxDecoration(
                      color: Theme.of(context).backgroundColor,
                      image: DecorationImage(
                          image: snapshot.data!.image,
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.4),
                              BlendMode.dstATop))),
                  child: const Text("The WholesomeYuri thing"),
                );
              }
            case ConnectionState.none:
              return DrawerHeader(
                  decoration:
                      BoxDecoration(color: Theme.of(context).backgroundColor),
                  child: const Text("The WholesomeYuri thing"));
            case ConnectionState.active:
              return DrawerHeader(
                  decoration:
                      BoxDecoration(color: Theme.of(context).backgroundColor),
                  child: const Text("The WholesomeYuri thing"));
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
            subredditHeader,
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
