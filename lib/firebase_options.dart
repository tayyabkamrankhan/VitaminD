import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform,
TargetPlatform, kIsWeb;
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbW1Adr7tfQ_64v2XwYAlxK-VU7foTSkk',
    appId: '1:124174642820:android:161c35a708032e7f53dcd1',
    messagingSenderId: '124174642820',
    projectId: 'vitamin-d-sensor',
    storageBucket: 'vitamin-d-sensor.appspot.com',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAbW1Adr7tfQ_64v2XwYAlxK-VU7foTSkk',
    appId: '1:124174642820:android:161c35a708032e7f53dcd1',
    messagingSenderId: '124174642820',
    projectId: 'vitamin-d-sensor',
    storageBucket: 'vitamin-d-sensor.appspot.com',
    iosBundleId: 'YOUR_BUNDLE_ID',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAbW1Adr7tfQ_64v2XwYAlxK-VU7foTSkk',
    appId: '1:124174642820:web:161c35a708032e7f53dcd1',
    messagingSenderId: '124174642820',
    projectId: 'vitamin-d-sensor',
    storageBucket: 'vitamin-d-sensor.appspot.com',
  );
}