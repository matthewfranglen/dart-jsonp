library jsonp;

import 'dart:async';
import 'src/jsonp_impl.dart' as impl;

/**
 * Returns a future that will complete with the data from the jsonp endpoint.
 * This will return a JsObject.
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
Future fetch({String uri: null, String uriGenerator(String callback): null}) =>
  impl.fetch(
      uri: uri,
      uriGenerator: uriGenerator
    );

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
Stream fetchMany(String stream, {String uri: null, String uriGenerator(String callback): null}) =>
    impl.fetchMany(
        stream,
        uri: uri,
        uriGenerator: uriGenerator
      );

/**
 * This will release the resources associated with the stream. If you create
 * many short lived streams then you should call this or you will leak memory.
 */
void disposeMany(String stream) => impl.disposeMany(stream);
