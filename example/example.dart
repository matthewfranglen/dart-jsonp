import 'package:web_ui/web_ui.dart';
import 'package:jsonp/jsonp.dart' as jsonp;
import "package:js/js.dart" as js;

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

/**
 * Every response from the Twitter JSONP API is a list, because usually you
 * would want multiple tweets at once. If it returned one at a time, then the
 * Tweet class could be directly created by the jsonp library.
 */
List<Tweet> listFromProxy(js.Proxy data) {
  List<Tweet> result;

  result = new List<Tweet>();

  // Unfortunately, the proxy object is unable to be correctly inspected,
  // leading to warnings about non existant properties. This is because the
  // content of it is determined by the javascript code.
  for (var i = 0;i < data.length;i++) {
    result.add(new Tweet.fromProxy(data[i]));
  }

  // Don't forget to release the data!
  js.release(data);

  return result;
}

/**
 * Could do a lot of things, but just adds the tweet to the observable list.
 */
void handleTweet(Tweet tweet) {
  tweets.add(tweet);
}

// The twitter feed to follow. Try out different ones (you can check them in
// your browser).
var _seth_ladd = 'https://twitter.com/status/user_timeline/sethladd?format=json';

// The list of tweets to display.
@observable
List<Tweet> tweets = toObservable([]);

// Current page, which assumes a count of 1, so really this is the current
// tweet.
var page = 1;

/**
 * Makes a request for a single tweet using a one time request.
 */
void request() {
  jsonp.fetch(uri: "${_seth_ladd}&count=1&page=${page}")
    .then((js.Proxy data) => listFromProxy(data).forEach(handleTweet));
  page += 1;
}

var stream = 'tweet';

/**
 * Requests 10 tweets at once. The stream handler is set up in [main()] and
 * will just add each tweet to the list as it is received.
 */
void request10() {
  jsonp.fetchMany(stream, uri: "${_seth_ladd}&count=10&page=${(page / 10).toInt()}");
  page += 10;
}

/**
 * Configures the stream handler which is triggered by the [request10] method.
 * Each stream should be configured in this way one time only, otherwise you
 * will have methods being invoked multiple times.
 */
void main () {
  jsonp.fetchMany(stream).expand(listFromProxy).forEach(handleTweet);
}
