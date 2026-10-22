package media.membrana.adwall.demo.compose

import android.graphics.Color
import android.graphics.Typeface
import media.membrana.adwall.AdWallAppearance

/** Shared visual specification; validate-demo-copies.sh checks the two app-owned copies. */
object DemoDesign {
    const val heading = "Choose a scenario"
    val scenarios = listOf(
        "Whole page" to "Protect the complete article from the first frame",
        "Part of screen" to "Keep the introduction visible and gate the remaining article",
        "Branded styling" to "Same whole-page coverage, restyled with publisher colors and fonts",
    )
    val brandedAppearance = AdWallAppearance(
        buttonBackgroundColor = Color.rgb(216, 27, 96),
        titleTypeface = Typeface.create("sans-serif", Typeface.BOLD),
        descriptionTypeface = Typeface.create("sans-serif", Typeface.NORMAL),
        buttonTypeface = Typeface.create("sans-serif", Typeface.BOLD),
    )
    const val pageInset = 24
    const val articleTop = 20
    const val articleBottom = 48
    const val labelTop = 8
    const val labelBottom = 10
    const val categorySize = 14
    const val titleSize = 30
    const val summarySize = 20
    const val bodySize = 18
    const val heroHeight = 180
    const val hero = "▤"
}
