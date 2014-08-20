library app_bootstrap;

import 'package:polymer/polymer.dart';

import 'my-tweets.dart' as i0;
import 'example.dart' as i1;
import 'package:smoke/smoke.dart' show Declaration, PROPERTY, METHOD;
import 'package:smoke/static.dart' show useGeneratedCode, StaticConfiguration;
import 'my-tweets.dart' as smoke_0;
import 'package:polymer/polymer.dart' as smoke_1;
import 'package:observe/src/metadata.dart' as smoke_2;
abstract class _M0 {} // PolymerElement & ChangeNotifier

void main() {
  useGeneratedCode(new StaticConfiguration(
      checkedMode: false,
      getters: {
        #imageUrl: (o) => o.imageUrl,
        #name: (o) => o.name,
        #tweet: (o) => o.tweet,
        #tweets: (o) => o.tweets,
        #user: (o) => o.user,
      },
      setters: {
        #tweets: (o, v) { o.tweets = v; },
      },
      parents: {
        smoke_0.MyTweetsElement: _M0,
        _M0: smoke_1.PolymerElement,
      },
      declarations: {
        smoke_0.MyTweetsElement: {
          #tweets: const Declaration(#tweets, List, kind: PROPERTY, annotations: const [smoke_2.reflectable, smoke_2.observable]),
        },
      },
      names: {
        #imageUrl: r'imageUrl',
        #name: r'name',
        #tweet: r'tweet',
        #tweets: r'tweets',
        #user: r'user',
      }));
  configureForDeployment([
      () => Polymer.register('my-tweets', i0.MyTweetsElement),
    ]);
  i1.main();
}
