package media.membrana.adwall.demo.views;

import android.app.Activity;
import android.view.ViewGroup;
import media.membrana.adwall.AdWall;
import media.membrana.adwall.AdWallAppearance;
import media.membrana.adwall.AdWallListener;
import media.membrana.adwall.AdWallStartCallback;

/** Compiled Java consumer: no Kotlin coroutines or SDK internals are needed by Java hosts. */
public final class JavaGateBridge {
    private JavaGateBridge() {}
    public static void start(AdWall adWall, AdWallStartCallback callback) {
        adWall.start(callback);
    }
    public static void gate(AdWall adWall, ViewGroup view, Activity activity, AdWallListener listener,
                            AdWallAppearance appearance) {
        adWall.gate(view, activity, listener, appearance);
    }
}
