import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:yuri_app/post_imgview.dart';
import 'package:yuri_app/settings_page.dart';
import 'package:html_unescape/html_unescape.dart';

class RedditPost {
  final String postUrl;
  late final String postName;
  final String imageUrl;
  final String user;
  final String thumbnailUrl;
  final int ups;
  final bool isNsfw;

  RedditPost(
      this.postUrl, postName, this.imageUrl, this.user, this.thumbnailUrl,
      [this.ups = 0, this.isNsfw = false]) {
    var unescaper = HtmlUnescape();
    this.postName = unescaper.convert(postName);
  }

  @override
  String toString() {
    return "Post $postName : $imageUrl permalink : $postUrl";
  }
}

class RedditPostDisplay extends StatelessWidget {
  const RedditPostDisplay({
    Key? key,
    required this.post,
  }) : super(key: key);

  final RedditPost post;

  @override
  Widget build(BuildContext context) {
    String thumbnailUri = post.imageUrl;
    String postTitle = post.postName;
    String user = post.user;
    String postUrl = post.postUrl;
    int ups = post.ups;
    bool nsfw = post.isNsfw;
    if (postTitle.length > 100) {
      postTitle = postTitle.substring(0, 100) + '...';
    }

    return GestureDetector(
      onTap: () => {
        Navigator.of(context)
            .pushNamed(PostImageViewer.routeName, arguments: post)
      },
      onLongPress: () => {
        Clipboard.setData(ClipboardData(text: postUrl)).whenComplete(() => {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Copied URL to clipboard",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
                backgroundColor: Theme.of(context).colorScheme.background,
              ))
            })
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
                flex: 2,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250.0),
                  child: Image.network(thumbnailUri,
                      fit: BoxFit.fitWidth, alignment: Alignment.topCenter),
                )),
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
          item['data']['thumbnail'],
          item['data']['ups'],
          item['data']['over_18']);

      _toReturn.add(thisPost);
      lastPost = item['data']['name'];
    }
    _pagingController.appendPage(_toReturn, lastPost);
  }

  Widget _buildRow(RedditPost post) {
    return RedditPostDisplay(
      post: post,
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
