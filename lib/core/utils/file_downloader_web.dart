import 'dart:convert';
import 'package:web/web.dart' as web;

/// Dispara download no browser via âncora invisible.
Future<void> downloadFile(List<int> bytes, String filename) async {
  final base64str = base64Encode(bytes);
  final dataUri = 'data:text/csv;charset=utf-8;base64,$base64str';
  final anchor =
      web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = dataUri;
  anchor.download = filename;
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
}
