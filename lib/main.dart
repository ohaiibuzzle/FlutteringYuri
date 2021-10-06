import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
        title: "Welcome Home",
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

class RedditPostDisplay extends StatelessWidget {
  const RedditPostDisplay({
    Key? key,
    required this.thumbnailUri,
    required this.postTitle,
    required this.user,
    required this.postUrl,
    required this.ups,
    required this.nsfw,
  }) : super(key: key);

  final String thumbnailUri;
  final String postTitle;
  final String user;
  final String postUrl;
  final int ups;
  final bool nsfw;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchUrl(postUrl),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: 2, child: Image.network(thumbnailUri)),
            Expanded(
                flex: 3,
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(postTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            )),
                        const SizedBox(height: 10),
                        Text(user,
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 12.0,
                            )),
                        Text("Upvotes: $ups",
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 12.0,
                            )),
                        const SizedBox(height: 3),
                        () {
                          if (nsfw) {
                            return const ColoredBox(
                              color: Colors.red,
                              child: Text("NSFW",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10.0)),
                            );
                          } else {
                            return const ColoredBox(
                                color: Colors.grey,
                                child: Text("SFW",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10.0)));
                          }
                        }()
                      ],
                    )))
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class RedditFeed extends StatefulWidget {
  const RedditFeed({Key? key, required this.settings}) : super(key: key);

  final SettingsArguments settings;

  @override
  _RedditFeedState createState() => _RedditFeedState();
}

class _RedditFeedState extends State<RedditFeed> {
  final PagingController<String, RedditPost> _pagingController =
      PagingController(firstPageKey: "");

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      getPostFeed(
          widget.settings.subreddit, widget.settings.allowNSFW, pageKey);
    });
  }

  Future<void> getPostFeed(
      String subreddit, bool allowNSFW, String lastPost) async {
    var _toReturn = <RedditPost>[];
    var url =
        Uri.parse("https://www.reddit.com/r/$subreddit.json?after=$lastPost");
    var response = await http.get(url);

    var postData = jsonDecode(response.body)['data']['children'];
    for (final item in postData) {
      if (!item['data']['url'].endsWith(".png") &
          !item['data']['url'].endsWith(".jpg")) continue;
      if (!allowNSFW && item['data']['over_18']) continue;
      var thisPost = RedditPost(
          "https://reddit.com" + item['data']['permalink'],
          item['data']['title'],
          item['data']['url'],
          item['data']['author'],
          item['data']['ups'],
          item['data']['over_18']);

      _toReturn.add(thisPost);
      lastPost = item['data']['name'];
    }
    _pagingController.appendPage(_toReturn, lastPost);
  }

  Widget _buildRow(RedditPost post) {
    var postName = post.postName;
    if (postName.length > 100) {
      postName = postName.substring(0, 100) + '...';
    }
    return RedditPostDisplay(
      thumbnailUri: post.imageUrl,
      postTitle: postName,
      postUrl: post.postUrl,
      user: post.user,
      ups: post.ups,
      nsfw: post.isNsfw,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        onRefresh: () => Future.sync(
              () => _pagingController.refresh(),
            ),
        child: PagedListView<String, RedditPost>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<RedditPost>(
                itemBuilder: (context, item, index) => _buildRow(item))));
  }
}
