library json.ext_web;

import 'dart:async';
import 'dart:html';
import 'package:js/js.dart' as js;
import 'external.dart';

class JavascriptImpl extends Javascript {

  const JavascriptImpl();

  /**
   * Makes a callback that will complete the completer with the resulting data.
   */
  void makeOnceCallback(String name, Completer completer) {
    js.context[name] = (js.Proxy data) {
      completer.complete(data);
    };
  }

  /**
   * Makes a callback that will populate the stream with the resulting data.
   */
  void makeManyCallback(String name, StreamController stream) {
    js.context[name] = (js.Proxy data) {
      stream.add(data);
    };
  }

  /**
   * Releases the named callback.
   */
  void releaseCallback(String name) {
    js.context[name] = null;
  }

  /**
   * Releases the json data.
   */
  // No longer performs any function as of library revision for dart 0.8.7.0.
  // This used to release the js.Proxy data which was explicitly retained to
  // allow other methods to operate on it. It appears that is no longer needed.
  // If I am incorrect in this assumption then this will be useful, as well as
  // not breaking code that uses this on an impulse.
  void releaseData(js.Proxy data) { }
}

class HtmlImpl extends Html {

  const HtmlImpl();

  /**
   * This adds a script node with a source of the provided url to the dom.
   */
  void request(String url) {
    document.body.nodes.add(new ScriptElement()..src = url);
  }
}
