@file:Suppress("UNUSED_PARAMETER")
package android.content

class Context { val assets = Assets() }
class Assets { fun openFd(path: String) = Descriptor() }
class Descriptor : java.io.Closeable { override fun close() {} }
