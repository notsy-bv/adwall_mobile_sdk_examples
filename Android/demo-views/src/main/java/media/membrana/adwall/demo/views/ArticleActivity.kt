package media.membrana.adwall.demo.views

import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.doOnPreDraw
import com.google.android.material.color.MaterialColors
import com.google.android.material.textview.MaterialTextView
import media.membrana.adwall.*

class ArticleActivity : AppCompatActivity(), AdWallListener {
    private val adWall get() = (application as DemoApplication).adWall
    private lateinit var protectedView: ViewGroup
    private lateinit var fallback: MaterialTextView
    private lateinit var fallbackHost: FrameLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val partial = intent.getBooleanExtra("partial", false)
        val branded = intent.getBooleanExtra("branded", false)
        title = when {
            branded -> "Branded styling"
            partial -> "Part of screen"
            else -> "Whole page"
        }
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        val root = FrameLayout(this).apply {
            // AppCompat includes the action bar in the content's dispatched system-bar insets.
            // Android 15+ lays the window edge to edge, so consume these before laying out the article.
            ViewCompat.setOnApplyWindowInsetsListener(this) { view, insets ->
                val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
                view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
                WindowInsetsCompat.CONSUMED
            }
        }
        val article = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(DemoDesign.pageInset), dp(DemoDesign.articleTop), dp(DemoDesign.pageInset), dp(DemoDesign.articleBottom)) }
        val scroll = ScrollView(this).apply { isFillViewport = true; addView(article) }
        root.addView(scroll, FrameLayout.LayoutParams(-1, -1))
        article.addView(label(DemoArticle.category, DemoDesign.categorySize))
        article.addView(label(DemoArticle.title, DemoDesign.titleSize))
        article.addView(label(DemoArticle.summary, DemoDesign.summarySize))
        article.addView(label(DemoArticle.paragraphs.first(), DemoDesign.bodySize))
        val tail = FrameLayout(this)
        val paragraphs = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(label(DemoDesign.hero, 60).apply {
                gravity = android.view.Gravity.CENTER
                setBackgroundColor(MaterialColors.getColor(this, com.google.android.material.R.attr.colorSecondaryContainer))
            }, LinearLayout.LayoutParams(-1, dp(DemoDesign.heroHeight)))
            DemoArticle.paragraphs.drop(1).forEach { addView(label(it, DemoDesign.bodySize)) }
        }
        tail.addView(paragraphs)
        article.addView(tail)
        // Publisher integration step 3: add and lay out the content that must remain protected
        // before asking the SDK to gate it. The partial example keeps the introduction readable.
        protectedView = if (partial) tail else scroll
        fallbackHost = if (partial) tail else root
        fallback = label("Preparing ads…", 20).apply {
            gravity = android.view.Gravity.CENTER
            isClickable = true
            setBackgroundColor(MaterialColors.getColor(this, com.google.android.material.R.attr.colorSurface))
        }
        fallbackHost.addView(fallback, FrameLayout.LayoutParams(-1, -1))
        paragraphs.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
        setContentView(root)
        // Publisher integration step 2: after the host app has completed its own privacy/consent
        // flow and permits ad requests, call start(). Every call shares one startup, so a screen may
        // call it to learn when the SDK is ready; it runs asynchronously and never blocks navigation.
        JavaGateBridge.start(adWall) { error ->
            if (isDestroyed || isFinishing) return@start
            if (error != null) {
                showFallback("Ads are currently unavailable")
            } else {
                root.doOnPreDraw {
                    if (!isDestroyed && !isFinishing) {
                        // Publisher integration step 4: once Android has measured the host, gate
                        // either the complete article or the exact protected subtree, passing the
                        // Activity and a listener.
                        fallback.visibility = View.GONE
                        paragraphs.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_AUTO
                        JavaGateBridge.gate(
                            adWall,
                            protectedView,
                            this,
                            this,
                            DemoDesign.brandedAppearance.takeIf { branded },
                        )
                    }
                }
                root.requestLayout()
            }
        }
    }

    override fun onSupportNavigateUp(): Boolean { finish(); return true }
    override fun onPresented(adWall: AdWall) { supportActionBar?.subtitle = "Content is protected" }
    override fun onContentUnlocked(adWall: AdWall) {
        // Publisher integration step 5: grant access only from the SDK's unlock callback.
        supportActionBar?.subtitle = "Content unlocked"
        fallbackHost.removeView(fallback)
    }
    override fun onContentUnavailable(adWall: AdWall, reason: AdWallUnavailableReason) {
        Log.i("AdWallViewsDemo", "AdWall unavailable: $reason")
        // Capping and missing rewarded demand skip the wall; the article stays readable.
        @Suppress("DEPRECATION")
        if (reason == AdWallUnavailableReason.NOT_ALLOWED ||
            reason == AdWallUnavailableReason.REWARDED_AD_NOT_READY ||
            reason == AdWallUnavailableReason.DEMAND_UNAVAILABLE
        ) {
            supportActionBar?.subtitle = "Content available"
            fallbackHost.removeView(fallback)
            return
        }
        showFallback("AdWall unavailable: ${reason.name.lowercase().replace('_', ' ')}")
    }
    override fun onFailure(adWall: AdWall, error: AdWallException) { showFallback("Ads are currently unavailable") }
    private fun showFallback(message: String) {
        supportActionBar?.subtitle = "Content remains protected"
        fallback.text = message
        fallback.visibility = View.VISIBLE
        fallback.bringToFront()
        for (index in 0 until fallbackHost.childCount) {
            fallbackHost.getChildAt(index).takeIf { it !== fallback }?.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
        }
    }
    private fun label(value: String, size: Int) = MaterialTextView(this).apply {
        breakStrategy = android.graphics.text.LineBreaker.BREAK_STRATEGY_SIMPLE
        hyphenationFrequency = android.text.Layout.HYPHENATION_FREQUENCY_NONE
        text = value; textSize = size.toFloat(); setTextColor(MaterialColors.getColor(this, com.google.android.material.R.attr.colorOnSurface)); setPadding(0, dp(DemoDesign.labelTop), 0, dp(DemoDesign.labelBottom))
    }
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
}
