package com.sanshare.groceryapp.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

// ── Brand Colors ──────────────────────────────────────────────────────────────
val GreenPrimary    = Color(0xFF54B050)   // rgb(84,176,80)
val GreenLight      = Color(0x1F54B050)   // 12% opacity
val RedBadge        = Color(0xFFD93838)   // rgb(217,56,56)

// Light palette
val LightBackground = Color(0xFFFAFAFA)
val LightCard       = Color(0xFFFFFFFF)
val LightTitle      = Color(0xFF1C1C1C)
val LightSubtitle   = Color(0xFF727272)
val LightMuted      = Color(0xFFA6A6A6)
val LightBorder     = Color(0x0F000000)   // Black 6%
val LightBanner     = Color(0xFFD9F2D8)   // Light green tint

// Dark palette
val DarkBackground  = Color(0xFF121218)
val DarkCard        = Color(0xFF1F1F23)
val DarkTitle       = Color(0xFFFFFFFF)
val DarkSubtitle    = Color(0x99FFFFFF)   // White 60%
val DarkMuted       = Color(0x66FFFFFF)   // White 40%
val DarkBorder      = Color(0x0FFFFFFF)   // White 6%
val DarkBanner      = Color(0xFF2E472E)   // Dark green tint

private val LightColorScheme = lightColorScheme(
    primary = GreenPrimary,
    onPrimary = Color.White,
    primaryContainer = GreenLight,
    background = LightBackground,
    surface = LightCard,
    onBackground = LightTitle,
    onSurface = LightTitle,
    error = RedBadge,
)

private val DarkColorScheme = darkColorScheme(
    primary = GreenPrimary,
    onPrimary = Color.White,
    primaryContainer = GreenLight,
    background = DarkBackground,
    surface = DarkCard,
    onBackground = DarkTitle,
    onSurface = DarkTitle,
    error = RedBadge,
)

// ── Custom theme tokens ───────────────────────────────────────────────────────
data class GroceryColors(
    val primary: Color,
    val primaryLight: Color,
    val title: Color,
    val subtitle: Color,
    val muted: Color,
    val background: Color,
    val card: Color,
    val cardBorder: Color,
    val banner: Color,
    val badge: Color,
    val isDark: Boolean,
)

val LocalGroceryColors = staticCompositionLocalOf {
    GroceryColors(
        primary = GreenPrimary,
        primaryLight = GreenLight,
        title = LightTitle,
        subtitle = LightSubtitle,
        muted = LightMuted,
        background = LightBackground,
        card = LightCard,
        cardBorder = LightBorder,
        banner = LightBanner,
        badge = RedBadge,
        isDark = false,
    )
}

@Composable
fun GroceryAppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme
    val groceryColors = if (darkTheme) {
        GroceryColors(
            primary = GreenPrimary,
            primaryLight = GreenLight,
            title = DarkTitle,
            subtitle = DarkSubtitle,
            muted = DarkMuted,
            background = DarkBackground,
            card = DarkCard,
            cardBorder = DarkBorder,
            banner = DarkBanner,
            badge = RedBadge,
            isDark = true,
        )
    } else {
        GroceryColors(
            primary = GreenPrimary,
            primaryLight = GreenLight,
            title = LightTitle,
            subtitle = LightSubtitle,
            muted = LightMuted,
            background = LightBackground,
            card = LightCard,
            cardBorder = LightBorder,
            banner = LightBanner,
            badge = RedBadge,
            isDark = false,
        )
    }

    CompositionLocalProvider(LocalGroceryColors provides groceryColors) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = GroceryTypography,
            content = content
        )
    }
}

// Convenience accessor
val MaterialTheme.grocery: GroceryColors
    @Composable get() = LocalGroceryColors.current
