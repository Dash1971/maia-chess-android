package io.flutter

class FlutterInjector {
    companion object { fun instance() = FlutterInjector() }
    fun flutterLoader() = Loader()
}
class Loader { fun getLookupKeyForAsset(path: String) = path }
