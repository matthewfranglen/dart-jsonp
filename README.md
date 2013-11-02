Dart JSONP
==========

JSONP handler for Dartlang. Allows you to make individual and multiple requests, as well as providing some support for automatically converting the responses to Dart classes.

Usage
------

This library handles requesting a URL and handling the subsequent callback. To achieve this a URL must be provided which can be updated with a callback method name which is determined by the library. There are two ways to do this.

The easiest way is to provide a complete URL which includes a callback query parameter. The query parameter value which can be replaced by the callback name has the placeholder value ?. The library is not smart about this, and will replace _all_ query parameters which have that value.

    jsonp.fetch( uri: "http://example.com/rest/object/1?callback=?" );

If you need more control over the creation of the URL, then you can take the more advanced approach. This means providing a function which takes a String (the callback method name) and returns a string (the request URL including the callback parameter). As you define the function, this approach allows total control over the constructed URL.

    jsonp.fetch( uriGenerator: (String callback) =>
        "http://example.com/rest/object/1?callback=$callback" );

### Single Requests

The _fetch_ method can be used to make a single request.

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
    });

#### Type Conversion

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

### Many Requests

The _fetchMany_ and _disposeMany_ methods can be used to handle many requests.

The _fetchMany_ method will return a named Stream which receives individual results. This Stream is identified by the _name_ parameter in the request, sharing single Streams across multiple requests. This means you only need to set up result handling code once, as all results will be handled by the same Stream.

By default the Stream provides js.Proxy objects:

    Stream<js.Proxy> object_stream = jsonp.fetchMany(
        "object", uri: "http://example.com/rest/object/1?callback=?"
      );

    // The uri is optional when making a fetchMany request
    // as you may just want to configure the Stream
    Stream<js.Proxy> user_stream = jsonp.fetchMany("user");

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
    jsonp.fetchMany(
        "user", uri: "http://example.com/rest/user/1?callback=?"
      );

    // Release the stream if you don't need it any more
    jsonp.disposeMany("object");

#### Type Conversion

The automatic type conversion is also available. Each call to _fetchMany_ can choose to set a type which will alter the returned stream (basically, you don't need to specify the type unless you actually use the stream).

    Stream<ExampleData> example_stream = jsonp.fetchMany(
        "object", type: ExampleData
      );

    example_stream.forEach(
        (ExampleData object) => print("Received ${object.data}")
      );

    // No need for the type when you don't use the returned stream
    jsonp.fetchMany(
        "object", uri: "http://example.com/rest/object/1?callback=?"
      );
    jsonp.fetchMany(
        "object", uri: "http://example.com/rest/object/2?callback=?"
      );
    jsonp.fetchMany(
        "object", uri: "http://example.com/rest/object/3?callback=?"
      );

Examples
--------

A pre built version of the example can be viewed [here](http://matthewfranglen.github.io/dart-jsonp/example/out/example.html). It has been converted to javascript.

### Compiling

An example of using the library can be found in the examples folder. This example uses the web_ui package to handle displaying the returned content. **This means it must be compiled**.

To get the required packages you may have to run pub install in the root of the library. Once you have the packages installed, you can then run the build script from within the example folder (right click run in the editor is fine).

After building you can view the example at _out/example.html_ in Dartium.
