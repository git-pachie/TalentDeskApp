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
val GreenPrimary        = Color(0xFF2E7D32)   // Forest green
val GreenPrimaryLight   = Color(0xFF4CAF50)   // Lighter interactive green
val GreenOnPrimary      = Color(0xFFFFFFFF)
val GreenContainer      = Color(0xFFC8E6C9)   // Light green container (light mode)
val GreenContainerDark  = Color(0xFF1B5E20)   // Deep green container (dark mode)

// Accent — warm amber for badges, deals, highlights
val AmberAccent         = Color(0xFFF59E0B)   // Warm amber
val RedBadge            = Color(0xFFE53935)   // Crisp red for errors/discount

// ── Light Mode Palette ────────────────────────────────────────────────────────
// Warm off-white background — feels premium, not sterile
val LightBackground     = Color(0xFFF7F7F5)   // Warm white
val LightSurface        = Color(0xFFFFFFFF)   // Pure white cards
val LightSurfaceVariant = Color(0xFFF0F0EE)   // Slightly tinted surface (input bg)
val LightTitle          = Color(0xFF111111)   // Near-black — maximum readability
val LightSubtitle       = Color(0xFF555555)   // Medium grey
val LightMuted          = Color(0xFF999999)   // Muted grey
val LightBorder         = Color(0xFFE8E8E6)   // Warm light border
val LightDivider        = Color(0xFFEEEEEC)   // Subtle divider
val LightBanner         = Color(0xFFE8F5E9)   // Soft green tint banner
val LightPrimaryLight   = Color(0xFFE8F5E9)   // Primary container bg

// ── Dark Mode Palette ─────────────────────────────────────────────────────────
// True layered dark — not just grey, has depth
val DarkBackground      = Color(0xFF0D0D0D)   // Near-black base
val DarkSurface         = Color(0xFF1A1A1A)   // Card surface — first elevation
val DarkSurfaceVariant  = Color(0xFF242424)   // Second elevation (inputs, sheets)
val DarkSurfaceHigh     = Color(0xFF2E2E2E)   // Third elevation (dialogs)
val DarkTitle           = Color(0xFFF5F5F5)   // Warm white text
val DarkSubtitle        = Color(0xFFB0B0B0)   // Medium grey
val DarkMuted           = Color(0xFF707070)   // Muted grey
val DarkBorder          = Color(0xFF2A2A2A)   // Subtle dark border
val DarkDivider         = Color(0xFF222222)   // Dark divider
val DarkBanner          = Color(0xFF1A2E1A)   // Deep green tint banner
val DarkPrimaryLight    = Color(0xFF1B3A1B)   // Primary container bg dark

// ── Material 3 Color Schemes ──────────────────────────────────────────────────
private val LightColorScheme = lightColorScheme(
    primary              = GreenPrimary,
    onPrimary            = GreenOnPrimary,
    primaryContainer     = GreenContainer,
    onPrimaryContainer   = Color(0xFF003300),
    secondary            = Color(0xFF558B2F),
    onSecondary          = Color.White,
    secondaryContainer   = Color(0xFFDCEDC8),
    onSecondaryContainer = Color(0xFF1B3A00),
    tertiary             = AmberAccent,
    onTertiary           = Color.White,
    tertiaryContainer    = Color(0xFFFFF3CD),
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
    inverseSurface       = Color(0xFF1A1A1A),
    inverseOnSurface     = Color(0xFFF5F5F5),
    inversePrimary       = GreenPrimaryLight,
    scrim                = Color(0xFF000000),
)

private val DarkColorScheme = darkColorScheme(
    primary              = GreenPrimaryLight,
    onPrimary            = Color(0xFF003300),
    primaryContainer     = GreenContainerDark,
    onPrimaryContainer   = Color(0xFFC8E6C9),
    secondary            = Color(0xFF8BC34A),
    onSecondary          = Color(0xFF1B3A00),
    secondaryContainer   = Color(0xFF2E4A1A),
    onSecondaryContainer = Color(0xFFDCEDC8),
    tertiary             = Color(0xFFFFCA28),
    onTertiary           = Color(0xFF3E2000),
    tertiaryContainer    = Color(0xFF3E2A00),
    onTertiaryContainer  = Color(0xFFFFF3CD),
    background           = DarkBackground,
    onBackground         = DarkTitle,
    surface              = DarkSurface,
    onSurface            = DarkTitle,
    surfaceVariant       = DarkSurfaceVariant,
    onSurfaceVariant     = DarkSubtitle,
    outline              = DarkBorder,
    outlineVariant       = DarkDivider,
    error                = Color(0xFFFF6B6B),
    onError              = Color(0xFF7F1D1D),
    errorContainer       = Color(0xFF3B1A1A),
    onErrorContainer     = Color(0xFFFFB3B3),
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
