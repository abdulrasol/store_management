package io.github.abdulrasol.store_mangment

import io.flutter.embedding.android.FlutterFragmentActivity
import androidx.activity.enableEdgeToEdge

class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
