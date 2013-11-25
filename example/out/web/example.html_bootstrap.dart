library app_bootstrap;

import 'package:polymer/polymer.dart';

import 'my-tweets.dart' as i0;
import 'example.dart' as i1;

void main() {
  configureForDeployment([
      'my-tweets.dart',
      'example.dart',
    ]);
  i1.main();
}
