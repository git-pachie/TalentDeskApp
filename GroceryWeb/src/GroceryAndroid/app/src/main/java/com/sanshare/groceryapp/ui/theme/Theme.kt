package com.sanshare.groceryapp.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

// ── Brand ─────────────────────────────────────────────────────────────────────
// Primary green — rich forest green, confident and fresh
val GreenPrimary        = Color(0xFF2D6A4F)   // Rich evergreen
val GreenPrimaryLight   = Color(0xFF40916C)   // Elevated/interactive green
val GreenOnPrimary      = Color(0xFFFFFFFF)
val GreenContainer      = Color(0xFFD9F2E4)   // Light green container (light mode)
val GreenContainerDark  = Color(0xFF18392D)   // Deep green container (dark mode)

// Accent — warm amber for badges, deals, highlights
val AmberAccent         = Color(0xFFF4B740)   // Warm amber
val RedBadge            = Color(0xFFD94C3D)   // Softer warm red

// ── Light Mode Palette ────────────────────────────────────────────────────────
// Warm off-white background — feels premium, not sterile
val LightBackground     = Color(0xFFF5F7F3)
val LightSurface        = Color(0xFFFFFFFF)
val LightSurfaceVariant = Color(0xFFF0F3EE)
val LightTitle          = Color(0xFF142018)
val LightSubtitle       = Color(0xFF526056)
val LightMuted          = Color(0xFF7E8B82)
val LightBorder         = Color(0xFFDDE5DD)
val LightDivider        = Color(0xFFE8EEE8)
val LightBanner         = Color(0xFFEAF7EF)
val LightPrimaryLight   = Color(0xFFE4F2EA)

// ── Dark Mode Palette ─────────────────────────────────────────────────────────
// True layered dark — not just grey, has depth
val DarkBackground      = Color(0xFF08110C)
val DarkSurface         = Color(0xFF121C16)
val DarkSurfaceVariant  = Color(0xFF18241D)
val DarkSurfaceHigh     = Color(0xFF203027)
val DarkTitle           = Color(0xFFF2F6F1)
val DarkSubtitle        = Color(0xFFB8C4BC)
val DarkMuted           = Color(0xFF7F8D84)
val DarkBorder          = Color(0xFF233229)
val DarkDivider         = Color(0xFF1C2A22)
val DarkBanner          = Color(0xFF153126)
val DarkPrimaryLight    = Color(0xFF193126)

// ── Material 3 Color Schemes ──────────────────────────────────────────────────
private val LightColorScheme = lightColorScheme(
    primary              = GreenPrimary,
    onPrimary            = GreenOnPrimary,
    primaryContainer     = GreenContainer,
    onPrimaryContainer   = Color(0xFF003300),
    secondary            = Color(0xFF5A8F6C),
    onSecondary          = Color.White,
    secondaryContainer   = Color(0xFFDCEDC8),
    onSecondaryContainer = Color(0xFF1B3A00),
    tertiary             = AmberAccent,
    onTertiary           = Color.White,
    tertiaryContainer    = Color(0xFFFFF1D9),
    onTertiaryContainer  = Color(0xFF3E2000),
    background           = LightBackground,
    onBackground         = LightTitle,
    surface              = LightSurface,
    onSurface            = LightTitle,
    surfaceVariant       = LightSurfaceVariant,
    onSurfaceVariant     = LightSubtitle,
    outline              = LightBorder,
    outlineVariant       = LightDivider,
    error                = RedBadge,
    onError              = Color.White,
    errorContainer       = Color(0xFFFFEDED),
    onErrorContainer     = Color(0xFF7F1D1D),
    inverseSurface       = Color(0xFF142018),
    inverseOnSurface     = Color(0xFFF5F7F3),
    inversePrimary       = GreenPrimaryLight,
    scrim                = Color(0xFF000000),
)

private val DarkColorScheme = darkColorScheme(
    primary              = GreenPrimaryLight,
    onPrimary            = Color.White,
    primaryContainer     = GreenContainerDark,
    onPrimaryContainer   = Color(0xFFC8E6C9),
    secondary            = Color(0xFF8FD1A8),
    onSecondary          = Color(0xFF0D1F17),
    secondaryContainer   = Color(0xFF264234),
    onSecondaryContainer = Color(0xFFD9F2E4),
    tertiary             = Color(0xFFF3C969),
    onTertiary           = Color(0xFF3E2000),
    tertiaryContainer    = Color(0xFF3F3112),
    onTertiaryContainer  = Color(0xFFFFF1D9),
    background           = DarkBackground,
    onBackground         = DarkTitle,
    surface              = DarkSurface,
    onSurface            = DarkTitle,
    surfaceVariant       = DarkSurfaceVariant,
    onSurfaceVariant     = DarkSubtitle,
    outline              = DarkBorder,
    outlineVariant       = DarkDivider,
    error                = Color(0xFFFF8B7E),
    onError              = Color(0xFF4A120E),
    errorContainer       = Color(0xFF41201C),
    onErrorContainer     = Color(0xFFFFCEC8),
    inverseSurface       = LightSurface,
    inverseOnSurface     = LightTitle,
    inversePrimary       = GreenPrimary,
    scrim                = Color(0xFF000000),
)

// ── Custom Grocery Color Tokens ───────────────────────────────────────────────
data class GroceryColors(
    val primary: Color,
    val primaryLight: Color,       // primary container / icon bg
    val title: Color,              // primary text
    val subtitle: Color,           // secondary text
    val muted: Color,              // tertiary / placeholder text
    val background: Color,         // screen background
    val card: Color,               // card / surface
    val cardElevated: Color,       // elevated card (sheets, dialogs)
    val cardBorder: Color,         // card border / divider
    val banner: Color,             // success/info banner background
    val badge: Color,              // error / discount badge
    val divider: Color,            // list dividers
    val inputBackground: Color,    // text field background
    val topBar: Color,
    val navBar: Color,
    val success: Color,
    val warning: Color,
    val isDark: Boolean,
)

val LocalGroceryColors = staticCompositionLocalOf {
    GroceryColors(
        primary        = GreenPrimary,
        primaryLight   = LightPrimaryLight,
        title          = LightTitle,
        subtitle       = LightSubtitle,
        muted          = LightMuted,
        background     = LightBackground,
        card           = LightSurface,
        cardElevated   = LightSurface,
        cardBorder     = LightBorder,
        banner         = LightBanner,
        badge          = RedBadge,
        divider        = LightDivider,
        inputBackground = LightSurfaceVariant,
        topBar         = LightBackground,
        navBar         = LightSurface.copy(alpha = 0.96f),
        success        = Color(0xFF2F9E59),
        warning        = Color(0xFFB7791F),
        isDark         = false,
    )
}

@Composable
fun GroceryAppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    val groceryColors = if (darkTheme) {
        GroceryColors(
            primary        = GreenPrimaryLight,
            primaryLight   = DarkPrimaryLight,
            title          = DarkTitle,
            subtitle       = DarkSubtitle,
            muted          = DarkMuted,
            background     = DarkBackground,
            card           = DarkSurface,
            cardElevated   = DarkSurfaceVariant,
            cardBorder     = DarkBorder,
            banner         = DarkBanner,
            badge          = Color(0xFFFF6B6B),
            divider        = DarkDivider,
            inputBackground = DarkSurfaceVariant,
            topBar         = DarkBackground,
            navBar         = DarkSurfaceHigh.copy(alpha = 0.96f),
            success        = Color(0xFF5CC98A),
            warning        = Color(0xFFF4C76B),
            isDark         = true,
        )
    } else {
        GroceryColors(
            primary        = GreenPrimary,
            primaryLight   = LightPrimaryLight,
            title          = LightTitle,
            subtitle       = LightSubtitle,
            muted          = LightMuted,
            background     = LightBackground,
            card           = LightSurface,
            cardElevated   = LightSurface,
            cardBorder     = LightBorder,
            banner         = LightBanner,
            badge          = RedBadge,
            divider        = LightDivider,
            inputBackground = LightSurfaceVariant,
            topBar         = LightBackground,
            navBar         = LightSurface.copy(alpha = 0.96f),
            success        = Color(0xFF2F9E59),
            warning        = Color(0xFFB7791F),
            isDark         = false,
        )
    }

    CompositionLocalProvider(LocalGroceryColors provides groceryColors) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography  = GroceryTypography,
            content     = content,
        )
    }
}

// Convenience accessor
val MaterialTheme.grocery: GroceryColors
    @Composable get() = LocalGroceryColors.current
