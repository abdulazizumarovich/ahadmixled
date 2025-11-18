package uz.iportal.axadmixled.presentation.player.components

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Color
import android.util.AttributeSet
import android.view.Gravity
import android.view.animation.LinearInterpolator
import android.widget.FrameLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import timber.log.Timber
import uz.iportal.axadmixled.domain.model.TextAnimation
import uz.iportal.axadmixled.domain.model.TextOverlay
import uz.iportal.axadmixled.domain.model.TextPosition

class TextOverlayView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private val textView: TextView
    private var scrollAnimator: ValueAnimator? = null

    init {
        // Create and configure TextView
        textView = TextView(context).apply {
            textSize = 24f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.BLACK)
            setPadding(
                dpToPx(16),
                dpToPx(8),
                dpToPx(16),
                dpToPx(8)
            )
            gravity = Gravity.CENTER
        }

        addView(textView, LayoutParams(
            LayoutParams.WRAP_CONTENT,
            LayoutParams.WRAP_CONTENT
        ))

        visibility = GONE
    }

    fun show(overlay: TextOverlay) {
        try {
            Timber.d("Showing text overlay: ${overlay.text}")

            // Update text content
            textView.text = overlay.text

            // Update text size
            textView.textSize = overlay.fontSize.toFloat()

            // Update colors
            try {
                textView.setTextColor(Color.parseColor(overlay.textColor))
                textView.setBackgroundColor(Color.parseColor(overlay.backgroundColor))
            } catch (e: Exception) {
                Timber.e(e, "Failed to parse colors, using defaults")
                textView.setTextColor(Color.WHITE)
                textView.setBackgroundColor(Color.BLACK)
            }

            // Update position
            val layoutParams = textView.layoutParams as LayoutParams
            layoutParams.gravity = when (overlay.position) {
                TextPosition.TOP -> Gravity.TOP or Gravity.CENTER_HORIZONTAL
                TextPosition.BOTTOM -> Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
                TextPosition.LEFT -> Gravity.START or Gravity.CENTER_VERTICAL
                TextPosition.RIGHT -> Gravity.END or Gravity.CENTER_VERTICAL
            }
            textView.layoutParams = layoutParams

            // Apply animation
            when (overlay.animation) {
                TextAnimation.SCROLL -> {
                    startScrollAnimation(overlay.speed, overlay.position)
                }
                TextAnimation.STATIC -> {
                    scrollAnimator?.cancel()
                    textView.translationX = 0f
                    textView.translationY = 0f
                }
            }

            visibility = VISIBLE
        } catch (e: Exception) {
            Timber.e(e, "Failed to show text overlay")
        }
    }

    fun hide() {
        Timber.d("Hiding text overlay")
        visibility = GONE
        scrollAnimator?.cancel()
        textView.translationX = 0f
        textView.translationY = 0f
    }

    private fun startScrollAnimation(speed: Float, position: TextPosition) {
        // Cancel any existing animation
        scrollAnimator?.cancel()

        // Measure text view
        textView.measure(
            MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED),
            MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED)
        )

        val textWidth = textView.measuredWidth
        val textHeight = textView.measuredHeight
        val containerWidth = width
        val containerHeight = height

        // Calculate animation based on position
        when (position) {
            TextPosition.TOP, TextPosition.BOTTOM -> {
                // Horizontal scroll
                val startX = containerWidth.toFloat()
                val endX = -textWidth.toFloat()
                val distance = startX - endX
                val duration = ((distance / speed) * 1000).toLong()

                scrollAnimator = ValueAnimator.ofFloat(startX, endX).apply {
                    this.duration = duration
                    repeatCount = ValueAnimator.INFINITE
                    interpolator = LinearInterpolator()

                    addUpdateListener { animation ->
                        textView.translationX = animation.animatedValue as Float
                    }

                    start()
                }

                Timber.d("Started horizontal scroll animation (speed=$speed, duration=$duration)")
            }

            TextPosition.LEFT, TextPosition.RIGHT -> {
                // Vertical scroll
                val startY = containerHeight.toFloat()
                val endY = -textHeight.toFloat()
                val distance = startY - endY
                val duration = ((distance / speed) * 1000).toLong()

                scrollAnimator = ValueAnimator.ofFloat(startY, endY).apply {
                    this.duration = duration
                    repeatCount = ValueAnimator.INFINITE
                    interpolator = LinearInterpolator()

                    addUpdateListener { animation ->
                        textView.translationY = animation.animatedValue as Float
                    }

                    start()
                }

                Timber.d("Started vertical scroll animation (speed=$speed, duration=$duration)")
            }
        }
    }

    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        // Restart animation if view size changed while visible
        if (visibility == VISIBLE && scrollAnimator?.isRunning == true) {
            scrollAnimator?.cancel()
            // Animation will be restarted on next show() call
        }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        scrollAnimator?.cancel()
    }
}
