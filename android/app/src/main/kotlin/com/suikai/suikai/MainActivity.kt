package com.suikai.suikai

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		Log.d("SuikaiAuth", "MAIN_ACTIVITY onCreate data=${intent?.dataString}")
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
		Log.d("SuikaiAuth", "MAIN_ACTIVITY onNewIntent data=${intent.dataString}")
	}

	override fun onResume() {
		super.onResume()
		Log.d("SuikaiAuth", "MAIN_ACTIVITY onResume data=${intent?.dataString}")
	}
}
