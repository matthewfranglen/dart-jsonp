import 'package:jsonp/src/jsonp_impl.dart' as jsonp;
import 'package:jsonp/src/external.dart';
import 'ext_test.dart';

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';

class TestData {
  var value;

  TestData(this.value);
  TestData.fromProxy(var proxy) : value = proxy['value'];

  String toString() => "TestData(${value})";
  dynamic toProxy() => { 'value': value };

  bool operator ==(var compare) =>
      compare != null && compare is TestData && value == compare.value;
}

test_once () {
  External ext;
  TestData data = new TestData('value');

  {
    JavascriptMock js;
    HtmlMock html;
    Completer completer;

    js = new JavascriptMock();
    js.when(callsTo('makeOnceCallback')).thenCall((_callback, _completer) => completer = _completer, 2);

    html = new HtmlMock();
    html.when(callsTo('request')).thenCall((url) => completer.complete(data.toProxy()), 2);

    ext = new External.dynamic(js, html);
  }

  test( 'Test no autoconversion', () =>
      jsonp.fetch(ext, uri: "http://example.com/rest/resource/1?format=jsonp&callback=?")
        .then((v) => new TestData.fromProxy(v)).then((v) => expect(v, equals(data)))
  );

  test( 'Test autoconversion', () =>
      jsonp.fetch(ext, uri: "http://example.com/rest/resource/1?format=jsonp&callback=?", type: TestData)
        .then((v) => expect(v, equals(data)))
  );
}

main () {
  group( 'Once callbacks working', test_once );
}
