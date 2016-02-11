import 'package:jsonp/jsonp.dart';

var brokenUrl = 'https://twitter.com/1.1/status/user_timeline.json?user=sethladd&format=json&callback=?';
var workingUrl = 'http://en.wikipedia.org/w/api.php?search=brazil&action=opensearch&format=json&callback=?';
var streamCallback = 'jsonp_stream_callback';

main () {
  fetchMany(streamCallback)
    ..forEach(prefixCallback('Stream received: '))
    ..handleError(prefixCallback('Stream error: '));

  fetch(uri: brokenUrl)
    .then(
      prefixCallback('Future received: '),
      onError: prefixCallback('Future error: ')
    );

  fetch(uri: workingUrl)
    .then(
      prefixCallback('Future received: '),
      onError: prefixCallback('Future error: ')
    );

  // fetchMany(streamCallback, uri: brokenUrl);
  // fetchMany(streamCallback, uri: workingUrl);
}

dynamic prefixCallback(var preamble) {
  return (value) {
    print(preamble);
    print(value);
  };
}
