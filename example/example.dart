import 'dart:html';
import 'package:web_ui/web_ui.dart';
import 'package:jsonp/jsonp.dart' as jsonp;

class User {
  final String imageUrl;
  final String name;

  User(this.imageUrl, this.name);
  User.fromProxy(var data) :
    imageUrl = data.profile_image_url,
    name = data.name;
}

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

List<Tweet> listFromProxy(var data) {
  List<Tweet> result;

  result = new List<Tweet>();
  for (var i = 0;i < data.length;i++) {
    result.add(new Tweet.fromProxy(data[i]));
  }

  return result;
}

void handleTweet(Tweet tweet) {
  tweets.add(tweet);
}

var _seth_ladd = 'https://twitter.com/status/user_timeline/sethladd?format=json';

@observable
List<Tweet> tweets = toObservable([]);

var page = 1;

void request(_) {
  jsonp.fetch(uri: "${_seth_ladd}&count=1&page=${page}")
    .then((var data) => listFromProxy(data).forEach(handleTweet));
  page += 1;
}

var stream = 'tweet';
void request10(_) {
  jsonp.fetchMany(stream, uri: "${_seth_ladd}&count=10&page=${page / 10}");
  page += 10;
}

void main () {
  jsonp.fetchMany(stream).expand(listFromProxy).forEach(handleTweet);
}
