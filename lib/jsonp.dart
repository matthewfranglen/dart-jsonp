library jsonp;
import "package:js/js.dart" as js;
import 'dart:async';
import "dart:html";
import "dart:mirrors";

Map<Object, StreamController<js.Proxy>> stream = new Map<Object, StreamController<js.Proxy>>();

var id = 1;

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

  // TODO: race condition
  String callback = "jsonp_receive_" + id;
  id++;

  js.context[callback] = new js.Callback.once((js.Proxy data) {
    js.retain(data);
    result.complete(data);
  });
  document.body.nodes.add(new ScriptElement()..src = urlGenerator(callback));

  return result.future;
}

/**
 * This will load the json data from the remote server and automatically
 * transform it into the appropriate class. This requires that the provided
 * type have a 'fromProxy' method.
 */
Future getAs(String urlGenerator(String callback), Type type) =>
    get(urlGenerator).then((js.Proxy data) {
      var result = reflectClass(type).invoke(const Symbol('fromProxy'), [data]);
      js.release(data);
      return result;
    });

