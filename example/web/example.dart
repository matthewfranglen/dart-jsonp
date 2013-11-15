import 'package:polymer/polymer.dart';
import 'package:jsonp/jsonp.dart' as jsonp;
import 'dart:html';

// The twitter feed to follow. Try out different ones (you can check them in
// your browser).
var _seth_ladd = 'https://twitter.com/status/user_timeline/sethladd?format=json&callback=?';

// Current page, which assumes a count of 1, so really this is the current
// tweet.
var page = 1;

/**
 * Makes a request for a single tweet using a one time request.
 */
void request(tweets) {
  jsonp.fetch(uri: "${_seth_ladd}&count=1&page=${page}")
    .then(tweets.handle);
  page += 1;
}

var stream = 'tweet';

/**
 * Requests 10 tweets at once. The stream handler is set up in [main()] and
 * will just add each tweet to the list as it is received.
 */
void request10() {
  for (int i = 0;i < 10;i++) {
    jsonp.fetchMany(stream, uri: "${_seth_ladd}&count=1&page=${page}");
    page += 1;
  }
}

/**
 * Configures the stream handler which is triggered by the [request10] method.
 * Each stream should be configured in this way one time only, otherwise you
 * will have methods being invoked multiple times.
 */
void main () {
  initPolymer();

  var tweets = querySelector('#tweets').xtag;

  jsonp.fetchMany(stream).forEach(tweets.handle);
  querySelector('#read').onClick.forEach((_) => request(tweets));
  querySelector('#read_10').onClick.forEach((_) => request10());
}
