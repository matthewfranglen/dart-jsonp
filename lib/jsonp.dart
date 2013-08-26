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
Future get({String uri: null, String uriGenerator(String callback): null, Type type: null}) {
  if ( uri == null && uriGenerator == null ) {
    throw new ArgumentError("Missing Parameter: uri or uriGenerator required");
  }

  Completer<js.Proxy> result = new Completer<js.Proxy>();
  String callback = _get_id();

  js.context[callback] = new js.Callback.once((js.Proxy data) {
    js.retain(data);
    result.complete(data);
  });
  _get(callback, uri: uri, uriGenerator: uriGenerator);

  if ( type == null ) {
    return result.future;
  }
  else {
    return result.future.then((js.Proxy data) => _to_type(data, type));
  }
}

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
Stream getMany(String stream, {String uri: null, String uriGenerator(String callback): null, Type type: null}) {
  if ( uri == null && uriGenerator == null ) {
    throw new ArgumentError("Missing Parameter: uri or uriGenerator required");
  }

  if ( ! _streams.containsKey(stream) ) {
    _streams[stream] = new _ManyWrapper(stream, _get_id());
  }
  _streams[stream].get(uri: uri, uriGenerator: uriGenerator);

  if ( type == null ) {
    return _streams[stream].stream;
  }
  else {
    return _streams[stream].stream.transform(new StreamTransformer<js.Proxy, Object>(
        handleData: (js.Proxy data, EventSink<Object> sink) {
          sink.add(_to_type(data, type));
        }));
  }
}

/**
 * This will release the resources associated with the stream. If you create
 * many short lived streams then you should call this or you will leak memory.
 */
void disposeMany(String stream) {
  if ( _streams.containsKey(stream) ) {
    _streams[stream].dispose();
    _streams[stream] = null;
  }
}

Map<String, _ManyWrapper> _streams = new Map<String, _ManyWrapper>();

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
  void get({String uri: null, String uriGenerator(String callback): null}) => _get(jsCallbackName, uri: uri, uriGenerator: uriGenerator);

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
void _get(String callback, {String uri: null, String uriGenerator(String callback): null}) {
  if ( uri == null && uriGenerator == null ) {
    throw new ArgumentError("Missing Parameter: uri or uriGenerator required");
  }

  document.body.nodes.add(new ScriptElement()..src = uri != null ? _add_callback_to_uri(uri, callback) : uriGenerator(callback));
}

/**
 * Adds a callback=... query parameter to the provided uri.
 */
String _add_callback_to_uri(String uri, String callback) {
  Uri parsed;
  Map<String, String> queryString;

  parsed = Uri.parse(uri);
  parsed.queryParameters["callback"] = callback;

  return parsed.toString();
}

/**
 * Converts the data to the provided type. Also handles releasing the data, so
 * this can be put after the regular stream or future for a fat comma call with
 * no problems.
 */
Object _to_type(js.Proxy data, Type type) {
  Object result = reflectClass(type).invoke(const Symbol('fromProxy'), [data]);
  js.release(data);
  return result;
}
