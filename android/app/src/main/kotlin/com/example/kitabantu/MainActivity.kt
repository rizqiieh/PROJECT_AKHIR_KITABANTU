package com.example.kitabantu

import io.flutter.embedding.android.FlutterFragmentActivity

// Menggunakan FlutterFragmentActivity (bukan FlutterActivity)
// agar plugin local_auth (biometrik) berfungsi dengan benar.
// local_auth membutuhkan FragmentActivity untuk menampilkan
// BiometricPrompt dialog bawaan Android.
class MainActivity : FlutterFragmentActivity()
