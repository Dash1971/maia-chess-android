import android.app.UiAutomation;
import android.graphics.Rect;
import android.os.HandlerThread;
import android.os.Looper;
import android.util.Xml;
import android.view.accessibility.AccessibilityNodeInfo;
import java.lang.reflect.Constructor;
import org.xmlpull.v1.XmlSerializer;

/** Shell-only snapshot for continuously updating analysis/progress screens. */
public final class FastDump {
    static String str(Object value) { return value == null ? "" : value.toString(); }

    static void node(XmlSerializer out, AccessibilityNodeInfo n, int index) throws Exception {
        out.startTag(null, "node");
        out.attribute(null, "index", Integer.toString(index));
        out.attribute(null, "text", str(n.getText()));
        out.attribute(null, "content-desc", str(n.getContentDescription()));
        out.attribute(null, "class", str(n.getClassName()));
        out.attribute(null, "package", str(n.getPackageName()));
        out.attribute(null, "resource-id", str(n.getViewIdResourceName()));
        out.attribute(null, "editable", Boolean.toString(n.isEditable()));
        out.attribute(null, "focused", Boolean.toString(n.isFocused()));
        out.attribute(null, "clickable", Boolean.toString(n.isClickable()));
        out.attribute(null, "checkable", Boolean.toString(n.isCheckable()));
        out.attribute(null, "checked", Boolean.toString(n.isChecked()));
        out.attribute(null, "scrollable", Boolean.toString(n.isScrollable()));
        out.attribute(null, "enabled", Boolean.toString(n.isEnabled()));
        out.attribute(null, "visible-to-user", Boolean.toString(n.isVisibleToUser()));
        Rect bounds = new Rect();
        n.getBoundsInScreen(bounds);
        out.attribute(null, "bounds", "[" + bounds.left + "," + bounds.top + "]["
                + bounds.right + "," + bounds.bottom + "]");
        // A Flutter container may report not visible while its descendants are
        // usable. Preserve visibility as evidence; never drop that entire subtree.
        for (int i = 0; i < n.getChildCount(); i++) {
            AccessibilityNodeInfo child = n.getChild(i);
            if (child != null) node(out, child, i);
        }
        out.endTag(null, "node");
    }

    public static void main(String[] args) throws Exception {
        Looper.prepareMainLooper();
        HandlerThread thread = new HandlerThread("maia-release-ui");
        thread.start();
        Object connection = Class.forName("android.app.UiAutomationConnection")
                .getDeclaredConstructor().newInstance();
        Constructor<?> ctor = UiAutomation.class.getDeclaredConstructor(
                Looper.class, Class.forName("android.app.IUiAutomationConnection"));
        ctor.setAccessible(true);
        UiAutomation ui = (UiAutomation) ctor.newInstance(thread.getLooper(), connection);
        try {
            UiAutomation.class.getDeclaredMethod("connect", int.class).invoke(ui, 1);
            AccessibilityNodeInfo root = null;
            for (int i = 0; i < 30 && root == null; i++) {
                root = ui.getRootInActiveWindow();
                if (root == null) Thread.sleep(20);
            }
            if (root == null) throw new IllegalStateException("No active accessibility root");
            XmlSerializer out = Xml.newSerializer();
            out.setOutput(System.out, "UTF-8");
            out.startDocument("UTF-8", true);
            out.startTag(null, "hierarchy");
            node(out, root, 0);
            out.endTag(null, "hierarchy");
            out.endDocument();
            System.out.flush();
        } finally {
            UiAutomation.class.getDeclaredMethod("disconnect").invoke(ui);
            thread.quitSafely();
        }
        System.exit(0);
    }
}
