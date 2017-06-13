library jsonp.impl;

import 'dart:async';
import 'handlers.dart';

Future fetch({String uri: null, String uriGenerator(String callback): null}) {
  try {
    final Once once = new Once();

    once.request((String callback) => _generateUrl(uri, uriGenerator, callback));
    return once.future();
  }
  catch (e) {
    return new Future.error(e);
  }
}

Stream fetchMany(String stream, {String uri: null, String uriGenerator(String callback): null}) {
  final Many many = new Many(stream);

  if (uri != null || uriGenerator != null) {
    try {
      many.request((String callback) => _generateUrl(uri, uriGenerator, callback));
    }
    catch (e) {
      many.error(e);
    }
  }
  return many.stream();
}

void disposeMany(String stream) {
  Many.disposeMany(stream);
}

// Transforms the uri, uriGenerator and callback into the callable url.
String _generateUrl(String uri, String uriGenerator(String callback), String callback) {
  if ( uri == null && uriGenerator == null ) {
    throw new ArgumentError("Missing Parameter: uri or uriGenerator required");
  }

  return uri != null ? _addCallbackToUri(uri, callback) : uriGenerator(callback);
}

// Replaces any of the query values that are '?' with the callback name.
String _addCallbackToUri(String uri, String callback) {
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
