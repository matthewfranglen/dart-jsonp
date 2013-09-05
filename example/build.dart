import 'package:web_ui/component_build.dart';
import 'dart:io';

// Ref: http://www.dartlang.org/articles/dart-web-components/tools.html
main() {
    build(new Options().arguments, ['example.html']);
}
