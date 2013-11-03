library jsonp;

import 'dart:async';
import 'src/jsonp_impl.dart' as impl;
import 'src/external.dart';
import 'src/ext_web.dart';

Future fetch({String uri: null, String uriGenerator(String callback): null, Type type: null}) =>
  impl.fetch(
      const External(const JavascriptImpl(), const HtmlImpl()),
      uri: uri, uriGenerator: uriGenerator, type: type
    );

Stream fetchMany(String stream, {String uri: null, String uriGenerator(String callback): null, Type type: null}) =>
    impl.fetchMany(
        const External(const JavascriptImpl(), const HtmlImpl()),
        stream, uri: uri, uriGenerator: uriGenerator, type: type
      );

void disposeMany(String stream) => impl.disposeMany(stream);
