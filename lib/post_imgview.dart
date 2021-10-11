import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yuri_app/reddit_feed.dart';

class PostImageViewer extends StatelessWidget {
  const PostImageViewer({Key? key}) : super(key: key);
  static const routeName = "/viewImage";

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as RedditPost;
    return Scaffold(
      appBar: AppBar(
        title: Text(args.postName),
        actions: <Widget>[
          IconButton(
              onPressed: () => _launchUrl(args.postUrl),
              icon: const Icon(Icons.open_in_browser)),
          IconButton(
            onPressed: () => _copyToClipboard(context, args.postUrl),
            icon: const Icon(Icons.copy),
          ),
          IconButton(
              onPressed: () => Share.share(args.postUrl),
              icon: const Icon(Icons.share))
        ],
      ),
      body: Stack(children: <Widget>[
        GestureDetector(
          child: PhotoView(
            imageProvider: Image.network(args.imageUrl).image,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 3.0,
            initialScale: PhotoViewComputedScale.contained,
          ),
        ),
        Container(
          alignment: Alignment.bottomCenter,
          padding:
              EdgeInsets.only(top: MediaQuery.of(context).size.height * .58),
          child: SizedBox(
            height: 40,
            width: MediaQuery.of(context).size.width,
            child: GestureDetector(
              onTap: () => _launchUrl(args.postUrl),
              child: Card(
                  color: Theme.of(context)
                      .colorScheme
                      .background
                      .withOpacity(0.12),
                  child: Text(
                    args.postName,
                    softWrap: true,
                    maxLines: 3,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary),
                  )),
            ),
          ),
        )
      ]),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text)).whenComplete(() => {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Copied URL to clipboard",
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            backgroundColor: Theme.of(context).colorScheme.background,
          ))
        });
  }

  void _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
