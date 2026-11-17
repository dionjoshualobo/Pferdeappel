-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.**

# Keep Flutter classes but exclude Play Store deferred components
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.engine.loader.** { *; }
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.embedding.engine.renderer.** { *; }
-keep class io.flutter.embedding.engine.dart.** { *; }
-keep class io.flutter.embedding.engine.systemchannels.** { *; }
-keep class io.flutter.embedding.android.FlutterActivity { *; }
-keep class io.flutter.embedding.android.FlutterView { *; }
-keep class io.flutter.embedding.android.FlutterSurfaceView { *; }
-keep class io.flutter.embedding.android.FlutterTextureView { *; }
-keep class io.flutter.embedding.android.FlutterImageView { *; }
-keep class io.flutter.plugin.platform.** { *; }

