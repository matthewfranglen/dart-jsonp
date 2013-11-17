import 'package:polymer/polymer.dart';
import 'package:js/js.dart' as js;

@CustomTag('my-tweets')
class MyTweetsElement extends PolymerElement {
  // This lets the Bootstrap CSS "bleed through" into the Shadow DOM
  // of this element.
  bool get applyAuthorStyles => true;

  @observable List<Tweet> tweets = toObservable([]);

  MyTweetsElement.created() : super.created();

  /**
   * Every response from the Twitter JSONP API is a list, because usually you
   * would want multiple tweets at once. If it returned one at a time, then the
   * Tweet class could be directly created by the jsonp library.
   */
  void handle(js.Proxy data) {
    // Unfortunately, the proxy object is unable to be correctly inspected,
    // leading to warnings about non existant properties. This is because the
    // content of it is determined by the javascript code.
    for (var i = 0;i < data.length;i++) {
      tweets.add(new Tweet.fromProxy(data[i]));
    }
  }

  void add(Tweet tweet) {
    tweets.add(tweet);
  }
}

/**
 * Wraps up the user details in a nice class. For the moment only the name and
 * image are displayed.
 */
class User {
  final String imageUrl;
  final String name;

  User(this.imageUrl, this.name);
  User.fromProxy(var data) :
    imageUrl = data.profile_image_url,
    name = data.name;
}

/**
 * An individual tweet. The tweet tracks the user that made it, so this could
 * handle conversations.
 */
class Tweet {
  final User user;
  final String tweet;
  final String timestamp;

  Tweet(this.user, this.tweet, this.timestamp);
  Tweet.fromProxy(var data) :
    user = new User.fromProxy(data.user),
    tweet = data.text,
    timestamp = data.created_at;
}
