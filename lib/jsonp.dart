library jsonp;
import "package:js/js.dart" as js;
import 'dart:async';
import "dart:html";
import "dart:mirrors";

/**
 * Returns a future that will complete with the data from the jsonp endpoint.
 * This will return the js.Proxy object, which will be like a map. It is
 * important that you call js.release() on the returned js.Proxy object once
 * you have finished handling it, otherwise you will leak memory.
 *
 * This takes a function that when called with the name of the jsonp callback
 * will return the full url to request. This may seem a bit clumsy, but the
 * callback name is encapsulated by this library, while the urls of interest
 * come from the calling code.
 *
 * Usually something like the following is sufficient (assuming you have
 * defined $url):
 * (callback) => "$url?callback=$callback"
 *
 * The js.Proxy object is best described with an example. When the jsonp
 * endpoint returns the data:
 * { "one": "1" }
 *
 * The js.Proxy object can access the value of "one" like so:
 * data.one
 *
 * It's simple, but you need to know the shape of the data in advance.
 */
Future<js.Proxy> get(String urlGenerator(String callback)) {
  Completer<js.Proxy> result = new Completer<js.Proxy>();
  String callback = _get_id();

  js.context[callback] = new js.Callback.once((js.Proxy data) {
    js.retain(data);
    result.complete(data);
  });
  _get(urlGenerator, callback);

  return result.future;
}

/**
 * This will load the json data from the remote server and automatically
 * transform it into the appropriate class. This requires that the provided
 * type have a 'fromProxy' method.
 *
 * This will handle releasing the js.Proxy object.
 */
Future getAs(String urlGenerator(String callback), Type type) =>
    get(urlGenerator).then((js.Proxy data) {
      var result = _get_as(data, type);
      js.release(data);
      return result;
    });

/**
 * This will allow you to make repeated requests and have all of the responses
 * come back down the same stream. The order of the responses is not
 * guaranteed, and as the js.Proxy object can be difficult to work with it is
 * recommended that you only use this for one specific type of data.
 *
 * As this is a long running operation, the stream should be disposed of
 * properly when you are finished working with it, otherwise you will leak
 * memory. You can release a stream using the disposeMany(stream) method.
 *
 * The stream that is returned by this operates in the same way as the get(...)
 * Futures and their values. The js.Proxy object that this returns must be
 * released once you are finished working with it, otherwise you will leak
 * memory.
 */
Stream<js.Proxy> getMany(String urlGenerator(String callback), String stream) {
  if ( ! streams.containsKey(stream) ) {
    streams[stream] = new _ManyWrapper(stream, _get_id());
  }
  streams[stream].get(urlGenerator);
  return streams[stream].stream;
}

/**
 * This will transform the stream so that all js.Proxy objects returned are
 * transformed into the specified type.
 *
 * This will handle releasing the js.Proxy object.
 */
Stream getManyAs(String urlGenerator(String callback), String stream, Type type) =>
    getMany(urlGenerator, stream).transform(
      new StreamTransformer<js.Proxy, Object>(
          handleData: (js.Proxy data, EventSink<Object> sink) {
            sink.add(_get_as(data, type));
            js.release(data);
          }
        ));

/**
 * This will release the resources associated with the stream. If you create
 * many short lived streams then you should call this or you will leak memory.
 */
void disposeMany(String stream) {
  if ( streams.containsKey(stream) ) {
    streams[stream].dispose();
    streams[stream] = null;
  }
}

Map<String, _ManyWrapper> streams = new Map<String, _ManyWrapper>();

/**
 * This collects together the different parts that make up the getMany stream.
 */
class _ManyWrapper {
  // The name of the stream.
  // Currently unused, as the key of the map is also the name of the stream.
  String name;

  // The stream controller for the stream that is returned by the getMany
  // method.
  StreamController<js.Proxy> _stream;

  // The js callback object that is invoked by the jsonp responses. This must
  // be released when the stream is destroyed.
  js.Callback jsCallback;

  // The name that the jsCallback is bound to. Required for constructing urls
  // for jsonp resources.
  String jsCallbackName;

  /**
   * Creates and configures the _ManyWrapper. You must call dispose before
   * dropping all references to this, or you will lose memory.
   */
  _ManyWrapper(this.name, this.jsCallbackName) {
    _stream = new StreamController<js.Proxy>();
    js.context[jsCallbackName] = jsCallback = new js.Callback.many((js.Proxy data) {
      js.retain(data);
      _stream.add(data);
    });
  }

  /**
   * The stream is the primary value of this, make it easy to get.
   */
  Stream<js.Proxy> get stream => _stream.stream;

  /**
   * Issues a get that will be received by the stream.
   */
  void get(String urlGenerator(String callback)) => _get(urlGenerator, jsCallbackName);

  /**
   * Releases all resources associated with the stream. Don't forget to call
   * this!
   */
  void dispose() {
    _stream.close();
    jsCallback.dispose();
  }
}

// Crummy name generator. Needs work.
var id = 1;

String _get_id() {
  // TODO: race condition
  String result = "jsonp_receive_" + id;
  id++;

  return result;
}

// Called in two different places, so put here. Also needs work.
void _get(String urlGenerator(String callback), String callback) =>
  document.body.nodes.add(new ScriptElement()..src = urlGenerator(callback));

Object _get_as(js.Proxy data, Type type) =>
  reflectClass(type).invoke(const Symbol('fromProxy'), [data]);
