library jsonp.handlers;

import 'dart:async';
import 'dart:html';
import 'dart:js' as js;

static int _count = 0;

// Each call to this will return a different id. The return value can be used as the callback name.
String _generateId() {
  return "jsonp_receive_${_count++}";
}

abstract class CallbackHandler {

  final String callback;

  CallbackHandler(this.callback);

  void request(String generator(String callback));

  void complete(js.JsObject result);

  void error(var error);

  void dispose() {
    js.context.deleteProperty(callback);
  }

}

/**
 * This provides a one shot request as a Future.
 */
class Once extends CallbackHandler {

  final Completer _completer = new Completer();
  final ScriptElement script = new ScriptElement();

  Once() : super(_generateId()) {
    js.context[callback] = this.complete;
    script.onError.listen(this.error);
  }

  Future future() => _completer.future;

  void request(String generator(String callback)) {
    script.src = generator(callback);
    document.body.nodes.add(script);
  }

  void dispose() {
    super.dispose();
    script.remove();
  }

  void complete(js.JsObject result) {
    dispose();
    completer.complete(result);
  }

  void error(e) {
    dispose();
    completer.completeError(e);
  }

}

/**
 * This provides a repeatable callback as a Stream.
 */
class Many extends CallbackHandler {
  // All created streams are in this map.
  static final Map<String, Many> _streams = new Map<String, Many>();

  factory Many(String callback) {
    if (! _streams.containsKey(callback)) {
      _streams[callback] = new Many._Impl(callback);
    }
    return _streams[callback];
  }

  static dispose(String callback) {
    if (_streams.containsKey(callback)) {
      _streams[callback]._dispose();
      _streams.remove(callback);
    }
  }

  StreamController _stream = new StreamController();

  Many._Impl(this.callback) : super(callback) {
    js.context[callback] = this.complete;
  }

  Stream stream() => _stream.stream;

  void request(String generator(String callback)) {
    // This adds scripts which build up in the dom, but cannot be effectively
    // removed while having a single callback. Could have multiple callbacks.

    ScriptElement script = new ScriptElement();
    script.src = generator(callback);
    script.onError.listen(this.error);
    document.body.nodes.add(script);
  }

  void complete(js.JsObject result) {
    _stream.add(result);
  }

  void error(e) {
    _stream.addError(e);
  }

  void dispose() {
    super.dispose();
    _stream.close();
  }

}
