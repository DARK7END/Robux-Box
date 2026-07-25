# Flutter / Firebase / Play Core keep rules.
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Play Core (deferred components) referenced by Flutter embedding.
-dontwarn com.google.android.play.core.**

# Keep model classes used by JSON/Firestore reflection if any are added later.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
