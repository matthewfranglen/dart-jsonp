Dart JSONP
==========

JSONP handler for Dartlang. Allows you to make individual and multiple requests, as well as providing some support for automatically converting the responses to Dart classes.

Usage
------

This library allows you to call a method with a URL and receive JSON data back. The URL can be provided as a simple string, or as a function. When using the string, the URL must include a query parameter which has a value of _?_. The function will take a string indicating the callback method name, and must return a valid URL.

When you use _fetch_ to request a URL a future will be returned. This future will complete with the raw JSON response (a js.Proxy object):

    import "package:js/js.dart" as js;
    import "dart:async";
    import "package:jsonp/jsonp.dart" as jsonp;

    // In this example the returned json data would be:
    // { "data": "some text" }
    Future<js.Proxy> result = jsonp.fetch(
        uri: "http://example.com/rest/object/1?callback=?"
      );

    result.then((js.Proxy proxy) {
      print(proxy.data);

      // It is important to release the data!
      js.release(proxy);
    });

The proxy objects can be time consuming to handle, as you don't get things like autocompletion for proxy fields. Automatically converting the proxy objects to classes is quite easy, but depends on the class having a _fromProxy_ method:

    class ExampleData {
      var data;

      // The js library can make unit testing difficult, you can just
      // use var as the js.Proxy object in your method.
      static fromProxy(var proxy) {
        this.data = proxy.data;
      }
    }

    jsonp.fetch(
        uri: "http://example.com/rest/object/1?callback=?",
        Type: ExampleData
      )
      .then((ExampleData object) => print(object.data));

If you want to request many objects and deal with them as they come in, use _fetchMany_ to make requests to a stream.

    Stream<js.Proxy> object_stream = jsonp.fetchMany(
        "object", uri: "http://example.com/rest/object/1?callback=?"
      );
    Stream<js.Proxy> user_stream = jsonp.fetchMany(
        "user", uri: "http://example.com/rest/user/1?callback=?"
      );

    object_stream.forEach(
        (js.Proxy data) => print("Received object!")
      );
    user_stream.forEach(
        (js.Proxy data) => print("Received user!")
      );

    // You just need to refer to the stream by name to make further requests
    jsonp.fetchMany(
        "object", uri: "http://example.com/rest/object/2?callback=?"
      );
    jsonp.fetchMany(
        "object", uri: "http://example.com/rest/object/3?callback=?"
      );
    jsonp.fetchMany(
        "object", uri: "http://example.com/rest/object/4?callback=?"
      );

The automatic type conversion is also available. Each call to _fetchMany_ can choose to set a type which will alter the returned stream (basically, you don't need to specify the type unless you actually use the stream).

    Stream<ExampleData> example_stream = jsonp.fetchMany(
        "object",
        uri: "http://example.com/rest/object/1?callback=?",
        type: ExampleData
      );

    example_stream.forEach(
        (ExampleData object) => print("Received ${object.data}")
      );

    // No need for the type when you don't use the returned stream
    jsonp.fetchMany(
        "object", uri: "http://example.com/rest/object/2?callback=?"
      );
    jsonp.fetchMany(
        "object", uri: "http://example.com/rest/object/3?callback=?"
      );
    jsonp.fetchMany(
        "object", uri: "http://example.com/rest/object/4?callback=?"
      );

Examples
--------

A pre built version of the example can be viewed [here](http://matthewfranglen.github.io/dart-jsonp/example/out/example.html). It has been converted to javascript.

An example of using the library can be found in the examples folder. This example uses the web_ui package to handle displaying the returned content. **This means it must be compiled**.

To get the required packages you may have to run _pub install_ in the root of the library. Once you have the packages installed, you can then run the build script _from within the example folder_ (right click run in the editor is fine).

After building you can view the example at _out/example.html_ in Dartium.
