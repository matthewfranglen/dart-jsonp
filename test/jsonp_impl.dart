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

test_many () {
  External ext;
  TestData data = new TestData('value');

  {
    JavascriptMock js;
    HtmlMock html;
    StreamController stream;

    js = new JavascriptMock();
    js.when(callsTo('makeManyCallback')).thenCall((_callback, _stream) => stream = _stream, 2);

    html = new HtmlMock();
    html.when(callsTo('request')).thenCall((url) => stream.add(data.toProxy()), 2);

    ext = new External.dynamic(js, html);
  }

  Future makeManyRequest(Type type) {
    Completer completer;

    // The test waits for the future to complete. When using a stream, I don't
    // get a nice future to return, so a completer is used to handle this. Also
    // allows easy tracking for the possibility of extra items being returned.
    completer = new Completer();
    jsonp.fetchMany(ext, "test", uri: "http://example.com/rest/resource/1?format=jsonp&callback=?", type: type)
        .forEach((v) => completer.isCompleted
                      ? completer.completeError(new Exception('Already received value'))
                      : completer.complete(v));
      return completer.future;
  }

  Completer first = new Completer();
  test( 'Test no autoconversion', () =>
      makeManyRequest(null)
        .then((v) => new TestData.fromProxy(v))
        .then((v) { expect(v, equals(data)); first.complete(v); })
    );

  test( 'Test autoconversion', () =>
    first.future
      .then((_) => jsonp.disposeMany("test"))
      .then((_) => makeManyRequest(TestData))
      .then((v) => expect(v, equals(data)))
  );
}

main () {
  group( 'Once callbacks working', test_once );
  group( 'Many callbacks working', test_many );
}
