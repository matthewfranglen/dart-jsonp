library jsonp;

import 'dart:async';
import 'src/jsonp_impl.dart' as impl;
import 'src/external.dart';
import 'src/ext_web.dart';

Future fetch({String uri: null, String uriGenerator(String callback): null}) =>
  impl.fetch(
      const External(const JavascriptImpl(), const HtmlImpl()),
      uri: uri,
      uriGenerator: uriGenerator
    );

Stream fetchMany(String stream, {String uri: null, String uriGenerator(String callback): null}) =>
    impl.fetchMany(
        const External(const JavascriptImpl(), const HtmlImpl()),
        stream,
        uri: uri,
        uriGenerator: uriGenerator
      );

void disposeMany(String stream) => impl.disposeMany(stream);
