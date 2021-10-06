class RedditPost {
  final String postUrl;
  final String postName;
  final String imageUrl;
  final String user;
  final int ups;
  final bool isNsfw;

  RedditPost(this.postUrl, this.postName, this.imageUrl, this.user,
      [this.ups = 0, this.isNsfw = false]);

  @override
  String toString() {
    return "Post $postName : $imageUrl permalink : $postUrl";
  }
}
