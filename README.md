Dart JSONP
==========

JSONP handler for Dartlang. Allows you to make individual and multiple requests, as well as providing some support for automatically converting the responses to Dart classes.

Examples
--------

When you use _fetch_ to request a url a future will be returned. This future will complete with the raw jsonp response:

    import "package:js/js.dart" as js;
    import "dart:async";
    import "package:jsonp/jsonp.dart" as jsonp;

    // In this example the returned json data would be: { "data": "some text" }
    Future<js.Proxy> result = jsonp.fetch( uri: "http://example.com/rest/object/1" );

    result.then((js.Proxy proxy) {
      print(proxy.data);

      // It is important to release the data!
      js.release(proxy);
    });

The proxy objects can be time consuming to handle, as you don't get things like autocompletion for proxy fields. Automatically converting the proxy objects to classes is quite easy, but depends on the class having a _fromProxy_ method:

    class ExampleData {
      var data;

      // The js library can make unit testing difficult, you can just use var
      // as the js.Proxy object in your method.
      static fromProxy(var proxy) {
        this.data = proxy.data;
      }
    }

    jsonp.fetch( uri: "http://example.com/rest/object/1", Type: ExampleData )
      .then((ExampleData object) => print(object.data));

If you want to request many objects and deal with them as they come in, use _fetchMany_ to make requests to a stream.

    Stream<js.Proxy> object_stream = jsonp.fetchMany( "object", uri: "http://example.com/rest/object/1" );
    Stream<js.Proxy> user_stream = jsonp.fetchMany( "user", uri: "http://example.com/rest/user/1" );

    object_stream.forEach( (js.Proxy data) => print("Received object!") );
    user_stream.forEach( (js.Proxy data) => print("Received user!") );

    // You just need to refer to the stream by name to make further requests
    jsonp.fetchMany( "object", uri: "http://example.com/rest/object/2" );
    jsonp.fetchMany( "object", uri: "http://example.com/rest/object/3" );
    jsonp.fetchMany( "object", uri: "http://example.com/rest/object/4" );

The automatic type conversion is also available. Each call to _fetchMany_ can choose to set a type which will alter the returned stream (basically, you don't need to specify the type unless you actually use the stream).

    Stream<ExampleData> example_stream = jsonp.fetchMany( "object", uri: "http://example.com/rest/object/1", type: ExampleData );

    example_stream.forEach( (ExampleData object) => print("Received ${object.data}") );

    // No need for the type when you don't use the returned stream
    jsonp.fetchMany( "object", uri: "http://example.com/rest/object/2" );
    jsonp.fetchMany( "object", uri: "http://example.com/rest/object/3" );
    jsonp.fetchMany( "object", uri: "http://example.com/rest/object/4" );
