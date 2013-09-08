library json.external;

import 'dart:async';

/**
 * This is used to allow unit testing. The unittest package cannot handle js or html.
 *
 * This library provides singletons for each of the bad libraries which are either backed by the real thing or by a test friendly mock.
 */
abstract class Javascript {

  const Javascript();

  /**
   * Makes a callback that will complete the completer with the resulting data.
   */
  void makeOnceCallback(String name, Completer completer);

  /**
   * Makes a callback that will populate the stream with the resulting data.
   */
  void makeManyCallback(String name, StreamController stream);

  /**
   * Releases the named callback.
   */
  void releaseCallback(String name);

  /**
   * Releases the json data.
   */
  void releaseData(var data);
}

abstract class Html {

  const Html();

  /**
   * This adds a script node with a source of the provided url to the dom.
   */
  void request(String url);
}

class External<J extends Javascript, H extends Html> {
  final J js;
  final H html;

  const External(this.js, this.html);
  External.dynamic(this.js, this.html);
}
