library jsonp.impl;

import 'dart:async';
import 'handlers.dart';
import 'external.dart';

/**
 * Returns a future that will complete with the data from the jsonp endpoint.
 * This will return Map, List, or simple values.
 *
 * This takes a url which includes a query parameter that has a value of [?].
 * This value will be replaced with the callback method name. There must be at
 * least one such parameter in the url.
 *
 * If you require a url of a different form then you can use the url generator
 * parameter. This allows you to pass a function which will be called with the
 * callback name. Use this to create and return the url according to any rules
 * or requirements.
 *
 * Usually something like the following is sufficient (assuming you have
 * defined $url):
 * (callback) => "$url?callback=$callback"
 */
Future fetch(External external, {String uri: null, String uriGenerator(String callback): null, Type type: null}) {
  try {
    final Once once = new Once(external);

    once.request((String callback) => _generate_url(uri, uriGenerator, callback));
    return once.future(type: type);
  }
  catch (e) {
    return new Future.error(e);
  }
}

/**
 * This will allow you to make repeated requests and have all of the responses
 * come back down the same stream. The order of the responses is not
 * guaranteed.
 *
 * As this is a long running operation, the stream should be disposed of
 * properly when you are finished working with it, otherwise you will leak
 * memory. You can release a stream using the disposeMany(stream) method.
 *
 * The stream that is returned by this operates in the same way as the get(...)
 * Futures and their values.
 *
 * You can get the named stream without making an associated request by just
 * asking without indicating a url to retrieve.
 */
Stream fetchMany(External external, String stream, {String uri: null, String uriGenerator(String callback): null, Type type: null}) {
  final Many many = new Many(external, stream);

  if (uri != null || uriGenerator != null) {
    try {
      many.request((String callback) => _generate_url(uri, uriGenerator, callback));
    }
    catch (e) {
      many.error(e);
    }
  }
  return many.stream(type: type);
}

/**
 * This will release the resources associated with the stream. If you create
 * many short lived streams then you should call this or you will leak memory.
 */
void disposeMany(String stream) {
  Many.dispose(stream);
}

/**
 * Transforms the uri, uriGenerator and callback into the callable url.
 */
String _generate_url(String uri, String uriGenerator(String callback), String callback) {
  if ( uri == null && uriGenerator == null ) {
    throw new ArgumentError("Missing Parameter: uri or uriGenerator required");
  }

  return uri != null ? _add_callback_to_uri(uri, callback) : uriGenerator(callback);
}

/**
 * Replaces any of the query values that are '?' with the callback name.
 */
String _add_callback_to_uri(String uri, String callback) {
  Uri parsed, updated;
  Map<String, String> query;
  int count = 0;

  parsed = Uri.parse(uri);
  query = new Map<String, String>();
  parsed.queryParameters.forEach((String key, String value) {
    if (value == '?') {
      query[key] = callback;
      count++;
    } else {
      query[key] = value;
    }
  });
  if (count == 0) {
    throw new ArgumentError("Missing Callback Placeholder: when providing a uri, at least one query parameter must have the ? value");
  }

  updated = new Uri(
      scheme: parsed.scheme,
      userInfo: parsed.userInfo,
      host: parsed.host,
      port: parsed.port,
      path: parsed.path,
      fragment: parsed.fragment,
      queryParameters: query
    );

  return updated.toString();
}
