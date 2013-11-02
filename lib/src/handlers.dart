library jsonp.handlers;

import 'dart:async';
import 'dart:mirrors';
import 'external.dart' show External;

class CallbackHandler {
  // Each Once instance needs a unique id, this is used to distinguish them
  static int _count = 0;

  /**
   * Each call to this will return a different id. The return value can be used as the callback name.
   */
  static String _get_id() {
    return "jsonp_receive_${_count++}";
  }

  final External external;
  final String callback = _get_id();

  CallbackHandler(this.external);

  /**
   * Adds the javascript to the page which will trigger the request.
   */
  void request(String generator(String callback)) => external.html.request(generator(callback));

  /**
   * Converts the data to the provided type. Also handles releasing the data, so
   * this can be put after the regular stream or future for a fat comma call with
   * no problems.
   */
  Object convert(Type type, var data) {
    InstanceMirror result = reflectClass(type).newInstance(const Symbol('fromProxy'), [data]);
    external.js.releaseData(data);
    return result.reflectee;
  }
}

/**
 * This provides a one shot request as a Future.
 */
class Once extends CallbackHandler {
  // This handles the callback from the JSONP request, allowing this class to present the result as a Future
  final Completer _completer = new Completer();

  Once(External external) : super(external) {
    external.js.makeOnceCallback(callback, _completer);
  }

  Future future({Type type: null}) => type == null
                                    ? _completer.future
                                    : _completer.future.then((var data) => convert(type, data));
}

/**
 * This collects together the different parts that make up the getMany stream.
 */
class Many extends CallbackHandler {
  // All created streams are in this map.
  static final Map<String, Many> _streams = new Map<String, Many>();

  /**
   * Returns the ManyWrapper associated with the name provided. Will create it if required.
   */
  factory Many(External external, String name) {
    if (! _streams.containsKey(name)) {
      _streams[name] = new Many._Impl(external, name);
    }
    return _streams[name];
  }

  static dispose(String name) {
    if (_streams.containsKey(name)) {
      _streams[name]._dispose();
      _streams.remove(name);
    }
  }

  // The name of the stream.
  // Currently unused, as the key of the map is also the name of the stream.
  String name;

  // The stream controller for the stream that is returned by the getMany
  // method.
  StreamController _stream = new StreamController();

  /**
   * Private constructor for use by the factory.
   */
  Many._Impl(External external, this.name) : super(external) {
    external.js.makeManyCallback(callback, _stream);
  }

  /**
   * The stream is the primary value of this, make it easy to get.
   */
  Stream stream({Type type: null}) => type == null
                                    ? _stream.stream
                                    : _stream.stream.transform(new StreamTransformer<dynamic, Object>.fromHandlers(
                                        handleData: (var data, EventSink<Object> sink) => sink.add(convert(type, data))
                                      ));

  /**
   * Adds an error to the stream.
   */
  void error(Object error, [Object stackTrace]) => _stream.addError(error, stackTrace);

  /**
   * Releases all resources associated with the stream. Don't forget to call
   * this!
   *
   * Any future call to [new ManyWrapper(name)] will result in the creation of a new stream.
   */
  void _dispose() {
    _stream.close();
    external.js.releaseCallback(name);
  }
}
