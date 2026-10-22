package media.membrana.adwall.demo.compose

import android.os.Bundle
import android.widget.FrameLayout
import androidx.activity.compose.BackHandler
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.google.android.material.color.MaterialColors
import media.membrana.adwall.*
import media.membrana.adwall.compose.AdWallGate

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The two samples use the same Material action bar. All content here is Compose.
        val root = FrameLayout(this)
        ViewCompat.setOnApplyWindowInsetsListener(root) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            WindowInsetsCompat.CONSUMED
        }
        root.addView(ComposeView(this).apply {
            setContent {
                MaterialTheme {
                    Demo((application as DemoApplication).adWall) { title, subtitle, canGoBack ->
                        supportActionBar?.title = title
                        supportActionBar?.subtitle = subtitle
                        supportActionBar?.setDisplayHomeAsUpEnabled(canGoBack)
                    }
                }
            }
        }, FrameLayout.LayoutParams(-1, -1))
        setContentView(root)
    }

    override fun onSupportNavigateUp(): Boolean {
        onBackPressedDispatcher.onBackPressed()
        return true
    }
}

@Composable
private fun nativeColor(attribute: Int): Color =
    Color(MaterialColors.getColor(LocalContext.current, attribute, "Demo theme"))

/** Match native TextView font metrics, including font padding, rather than different M3 defaults. */
@Composable
private fun Label(text: String, size: Int, modifier: Modifier = Modifier) {
    Text(text, modifier, color = nativeColor(com.google.android.material.R.attr.colorOnSurface),
        style = TextStyle(fontSize = size.sp, platformStyle = PlatformTextStyle(includeFontPadding = true)))
}

@Composable
private fun Demo(adWall: AdWall, updateBar: (String, String?, Boolean) -> Unit) {
    var scenario by rememberSaveable { mutableStateOf<Int?>(null) }
    var status by remember { mutableStateOf<String?>(null) }
    BackHandler(scenario != null) { scenario = null; status = null }
    val barTitle = scenario?.let { DemoDesign.scenarios[it].first } ?: "AdWall Scenarios"
    val barStatus = status
    val canGoBack = scenario != null
    SideEffect { updateBar(barTitle, barStatus, canGoBack) }
    Surface(Modifier.fillMaxSize(), color = nativeColor(com.google.android.material.R.attr.colorSurface)) {
        if (scenario == null) {
            Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(DemoDesign.pageInset.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Label(DemoDesign.heading, 16)
                DemoDesign.scenarios.forEachIndexed { index, (title, detail) ->
                    ElevatedCard(onClick = { status = null; scenario = index }, modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.elevatedCardColors(containerColor = nativeColor(com.google.android.material.R.attr.colorSurfaceContainerLow),
                            contentColor = nativeColor(com.google.android.material.R.attr.colorOnSurface)),
                        elevation = CardDefaults.elevatedCardElevation(defaultElevation = 1.dp)) {
                        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                            Label(DemoDesign.hero, 24, Modifier.width(24.dp).clearAndSetSemantics { })
                            Column(Modifier.weight(1f)) {
                                Label(title, 18)
                                Label(detail, 14, Modifier.padding(top = 4.dp))
                            }
                            Box(Modifier.width(24.dp).clearAndSetSemantics { }, contentAlignment = Alignment.Center) { Label("›", 28) }
                        }
                    }
                }
            }
        } else key(scenario) {
            Article(
                adWall,
                partial = scenario == 1,
                branded = scenario == 2,
                onStatus = { status = it },
            )
        }
    }
}

@Composable
private fun Article(adWall: AdWall, partial: Boolean, branded: Boolean, onStatus: (String) -> Unit) {
    var started by remember { mutableStateOf(false) }
    var failure by remember { mutableStateOf<String?>(null) }
    var unlocked by remember { mutableStateOf(false) }
    val latestStatus by rememberUpdatedState(onStatus)
    fun fail(message: String) { failure = message; latestStatus("Content remains protected") }
    // Publisher integration step 2: after the host app has completed its own privacy/consent flow
    // and permits ad requests, call start(). Every call shares one startup, so a screen may call it
    // to learn when the SDK is ready; it runs asynchronously and never blocks navigation.
    LaunchedEffect(adWall) {
        try { adWall.start(); started = true }
        catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled }
        catch (_: Exception) { fail("Ads are currently unavailable") }
    }
    val listener = remember {
        object : AdWallListener {
            override fun onPresented(adWall: AdWall) { latestStatus("Content is protected") }
            override fun onContentUnlocked(adWall: AdWall) {
                // Publisher integration step 5: grant access only from the SDK's unlock callback.
                unlocked = true
                latestStatus("Content unlocked")
            }
            override fun onContentUnavailable(adWall: AdWall, reason: AdWallUnavailableReason) {
                // Capping and missing rewarded demand leave the article readable.
                @Suppress("DEPRECATION")
                if (reason == AdWallUnavailableReason.NOT_ALLOWED ||
                    reason == AdWallUnavailableReason.REWARDED_AD_NOT_READY ||
                    reason == AdWallUnavailableReason.DEMAND_UNAVAILABLE
                ) {
                    unlocked = true
                    latestStatus("Content available")
                    return
                }
                fail("AdWall unavailable: ${reason.name.lowercase().replace('_', ' ')}")
            }
            override fun onFailure(adWall: AdWall, error: AdWallException) { fail("Ads are currently unavailable") }
        }
    }
    val scroll = rememberScrollState()
    val article: @Composable () -> Unit = {
        Column(Modifier.fillMaxSize().verticalScroll(scroll, enabled = !started || failure != null || unlocked)
            .padding(start = DemoDesign.pageInset.dp, top = DemoDesign.articleTop.dp,
                end = DemoDesign.pageInset.dp, bottom = DemoDesign.articleBottom.dp)) {
            ArticleLabel(DemoArticle.category, DemoDesign.categorySize)
            ArticleLabel(DemoArticle.title, DemoDesign.titleSize)
            ArticleLabel(DemoArticle.summary, DemoDesign.summarySize)
            ArticleLabel(DemoArticle.paragraphs.first(), DemoDesign.bodySize)
            if (partial) {
                ProtectedRegion(adWall, started, failure, listener, branded, Modifier.fillMaxWidth()) { ArticleTail() }
            } else ArticleTail()
        }
    }
    // Publisher integration step 3: lay out the content that must remain protected inside the gate.
    // The partial example keeps the introduction readable above it.
    if (partial) article()
    else ProtectedRegion(adWall, started, failure, listener, branded, Modifier.fillMaxSize(), article)
}

@Composable
private fun ProtectedRegion(adWall: AdWall, started: Boolean, failure: String?, listener: AdWallListener,
                            branded: Boolean, modifier: Modifier, content: @Composable () -> Unit) {
    if (started && failure == null) {
        // Publisher integration step 4: wrap either the complete article or the exact protected
        // region in AdWallGate. It gates once Android has measured the region.
        AdWallGate(
            adWall,
            modifier = modifier,
            appearance = DemoDesign.brandedAppearance.takeIf { branded },
            listener = listener,
            content = content,
        )
    } else {
        Box(modifier) {
            // Preserve article geometry while shielding both pixels and accessibility content.
            Box(Modifier.alpha(0f).clearAndSetSemantics { }) { content() }
            Box(Modifier.matchParentSize().background(nativeColor(com.google.android.material.R.attr.colorSurface)),
                contentAlignment = Alignment.Center) { Label(failure ?: "Preparing ads…", 20) }
        }
    }
}

@Composable
private fun ArticleLabel(text: String, size: Int) =
    Label(text, size, Modifier.fillMaxWidth().padding(top = DemoDesign.labelTop.dp, bottom = DemoDesign.labelBottom.dp))

@Composable
private fun ArticleTail() {
    Column(Modifier.fillMaxWidth()) {
        Box(Modifier.fillMaxWidth().height(DemoDesign.heroHeight.dp)
            .background(nativeColor(com.google.android.material.R.attr.colorSecondaryContainer)), contentAlignment = Alignment.Center) {
            Label(DemoDesign.hero, 60)
        }
        DemoArticle.paragraphs.drop(1).forEach { ArticleLabel(it, DemoDesign.bodySize) }
    }
}
