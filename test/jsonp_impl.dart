import 'package:jsonp/src/jsonp_impl.dart' as jsonp;
import 'package:jsonp/src/external.dart';
import 'ext_test.dart';

import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:unittest/mock.dart';

/**
 * This class just encapsulates some test data which can be passed through the
 * jsonp handling code with ease.
 */
class TestData {
  var value;

  // This allows easy creation in tests
  TestData(this.value);
  // This allows autocompletion
  TestData.fromProxy(var proxy) : value = proxy['value'];

  // The object is stringified when there are comparison failures
  String toString() => "TestData(${value})";
  // Conversion to proxy is useful for passing through the jsonp callback code.
  // This does not return a real js.Proxy, but it is good enough because we are
  // handling the autocompletion code in fromProxy.
  dynamic toProxy() => { 'value': value };

  // Test comparisons depend on equals, which by default tests by reference
  bool operator ==(var compare) =>
      compare != null && compare is TestData && value == compare.value;
}

/**
 * Test the one shot callbacks.
 */
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

/**
 * Test problematic one shot callbacks.
 */
test_once_exception () {
  External ext;

  {
    JavascriptMock js;
    HtmlMock html;

    js = new JavascriptMock();
    js.when(callsTo('makeOnceCallback')).alwaysThrow(new Exception());
    html = new HtmlMock();

    ext = new External.dynamic(js, html);
  }

  test( 'Test exception throwing js', () =>
      jsonp.fetch(ext, uri: "http://example.com/rest/resource/1?format=jsonp&callback=?")
        .then((_) => fail('Exception not passed through Future'), onError: (e) => expect(e, isException)));

  {
    JavascriptMock js;
    HtmlMock html;

    js = new JavascriptMock();
    html = new HtmlMock();
    html.when(callsTo('request')).alwaysThrow(new Exception());

    ext = new External.dynamic(js, html);
  }

  test( 'Test exception throwing html', () =>
      jsonp.fetch(ext, uri: "http://example.com/rest/resource/1?format=jsonp&callback=?")
        .then((_) => fail('Exception not passed through Future'), onError: (e) => expect(e, isException)));
}

/**
 * Test the streamable callbacks.
 */
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

  // The completer here allows the separate tests to be divided while still
  // forcing the disposeMany call to come after the first test.
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

/**
 * Test the problematic streamable callbacks.
 */
test_many_exception () {
  External ext;

  {
    JavascriptMock js;
    HtmlMock html;

    js = new JavascriptMock();
    html = new HtmlMock();
    html.when(callsTo('request')).alwaysThrow(new Exception());

    ext = new External.dynamic(js, html);
  }

  Future makeManyRequest() {
    Completer completer;

    // The test waits for the future to complete. When using a stream, I don't
    // get a nice future to return, so a completer is used to handle this. Also
    // allows easy tracking for the possibility of extra items being returned.
    completer = new Completer();
    jsonp.fetchMany(ext, "exception", uri: "http://example.com/rest/resource/1?format=jsonp&callback=?")
        .handleError((e) => completer.isCompleted
                          ? completer.completeError(new Exception('Already received value'))
                          : completer.complete(e))
        .forEach((v) => fail('Exception not passed through Stream'));
    return completer.future;
  }

  // The completer here allows the separate tests to be divided while still
  // forcing the disposeMany call to come after the first test.
  Completer first = new Completer();

  test( 'Test exception throwing js', () =>
      makeManyRequest()
        .then((e) { expect(e, isException); first.complete(e); }));
}

main () {
  group( 'Once callbacks working', test_once );
  group( 'Once callbacks working', test_once_exception );
  group( 'Many callbacks working', test_many );
  group( 'Many callbacks working', test_many_exception );
}
