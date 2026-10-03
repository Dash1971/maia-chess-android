@file:Suppress("UNUSED_PARAMETER")
package io.flutter.plugin.common

class BinaryMessenger { fun makeBackgroundTaskQueue() = Any() }
class StandardMethodCodec {
    companion object { val INSTANCE = StandardMethodCodec() }
}
class MethodCall(val method: String, private val args: Map<String, Any>) {
    @Suppress("UNCHECKED_CAST")
    fun <T> argument(key: String): T? = args[key] as T?
}
class MethodChannel(
    messenger: BinaryMessenger,
    name: String,
    codec: StandardMethodCodec,
    queue: Any,
) {
    companion object { val callbacks = java.util.concurrent.atomic.AtomicInteger() }
    interface MethodCallHandler { fun onMethodCall(call: MethodCall, result: Result) }
    interface Result {
        fun success(value: Any?)
        fun error(code: String, message: String?, details: Any?)
        fun notImplemented()
    }
    fun setMethodCallHandler(handler: MethodCallHandler?) {}
    fun invokeMethod(method: String, args: Any?) { callbacks.incrementAndGet() }
}
