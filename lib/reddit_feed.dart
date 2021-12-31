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
  final List<String> imageUrl;
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
    String thumbnailUri = post.imageUrl[0];
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
                        }(),
                        const SizedBox(height: 3),
                        () {
                          if (post.imageUrl.length > 1) {
                            return ColoredBox(
                                color: Colors.orange,
                                child: Text(
                                    "Gallery: ${post.imageUrl.length} images",
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10.0)));
                          } else {
                            return const SizedBox();
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
          !item['data']['url'].endsWith(".jpg") &
          !(item['data']['url'].contains("gallery"))) continue;
      if (!allowNSFW && item['data']['over_18']) continue;
      if (item['data']['url'].endsWith(".jpg") ||
          item['data']['url'].endsWith(".png")) {
        _toReturn.add(RedditPost(
            item['data']['permalink'],
            item['data']['title'],
            [item['data']['url']],
            item['data']['author'],
            item['data']['thumbnail'],
            item['data']['ups'],
            item['data']['over_18']));
      } else if (item['data']['url'].contains("gallery")) {
        var itemids = item['data']['gallery_data']?['items'];
        List<String> imageitems = [];
        if (itemids == null) {
          if (item['data']['crosspost_parent_list'] != null) {
            itemids = item['data']['crosspost_parent_list'][0]['gallery_data']
                ?['items'];
            for (final itemid in itemids) {
              imageitems.add(
                  "https://i.redd.it/${(item['data']['crosspost_parent_list'][0]['media_metadata'][itemid['media_id']]['id'])}.${(item['data']['crosspost_parent_list'][0]['media_metadata'][itemid['media_id']]['m'].toString().split("/")[1])}");
            }
          } else {
            continue;
          }
        } else {
          for (final itemid in itemids) {
            imageitems.add(
                "https://i.redd.it/${(item['data']['media_metadata'][itemid['media_id']]['id'])}.${(item['data']['media_metadata'][itemid['media_id']]['m'].toString().split("/")[1])}");
          }
        }

        _toReturn.add(RedditPost(
            item['data']['permalink'],
            item['data']['title'],
            imageitems,
            item['data']['author'],
            item['data']['thumbnail'],
            item['data']['ups'],
            item['data']['over_18']));
      }
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
