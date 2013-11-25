import 'package:polymer/builder.dart';

main() {
  build(entryPoints: ['web/example.html']).then((_) => deploy(entryPoints: ['web/example.html']));
}
