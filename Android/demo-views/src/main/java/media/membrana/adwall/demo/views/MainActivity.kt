package media.membrana.adwall.demo.views

import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ScrollView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.google.android.material.card.MaterialCardView
import com.google.android.material.color.MaterialColors
import com.google.android.material.textview.MaterialTextView

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "AdWall Scenarios"
        val root = android.widget.FrameLayout(this)
        ViewCompat.setOnApplyWindowInsetsListener(root) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
            view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            WindowInsetsCompat.CONSUMED
        }
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(DemoDesign.pageInset), dp(24), dp(DemoDesign.pageInset), dp(24))
        }
        root.addView(ScrollView(this).apply { addView(content) })
        content.addView(label(DemoDesign.heading, 16))
        DemoDesign.scenarios.forEachIndexed { index, (title, detail) ->
            val card = MaterialCardView(this).apply {
                radius = dp(16).toFloat()
                cardElevation = dp(1).toFloat()
                strokeWidth = 0
                setCardBackgroundColor(MaterialColors.getColor(this, com.google.android.material.R.attr.colorSurfaceContainerLow))
                isClickable = true
                isFocusable = true
                setOnClickListener {
                    startActivity(
                        Intent(this@MainActivity, ArticleActivity::class.java)
                            .putExtra("partial", index == 1)
                            .putExtra("branded", index == 2),
                    )
                }
            }
            val row = LinearLayout(this).apply {
                gravity = Gravity.CENTER_VERTICAL
                setPadding(dp(16), dp(16), dp(16), dp(16))
            }
            row.addView(label(DemoDesign.hero, 24), LinearLayout.LayoutParams(dp(24), -2))
            val copy = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                addView(label(title, 18))
                addView(label(detail, 14).apply { setPadding(0, dp(4), 0, 0) })
            }
            row.addView(copy, LinearLayout.LayoutParams(0, -2, 1f).apply { marginStart = dp(16); marginEnd = dp(16) })
            row.addView(label("›", 28).apply { gravity = Gravity.CENTER }, LinearLayout.LayoutParams(dp(24), -2))
            card.addView(row)
            content.addView(card, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(16) })
        }
        setContentView(root)
    }

    private fun label(value: String, size: Int) = MaterialTextView(this).apply {
        text = value
        textSize = size.toFloat()
        setTextColor(MaterialColors.getColor(this, com.google.android.material.R.attr.colorOnSurface))
    }
    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
}
