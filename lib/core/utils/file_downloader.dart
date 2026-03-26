// Exporta 'downloadFile' correto para cada plataforma:
// - Web  → download via âncora HTML
// - Mobile/Desktop → share sheet nativo (share_plus)
export 'file_downloader_stub.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart';
