package com.sanshare.groceryapp.ui.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.sanshare.groceryapp.data.remote.ProductDto
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.RedBadge
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.CartNotice
import com.sanshare.groceryapp.ui.viewmodel.CartViewModel
import kotlinx.coroutines.delay

// ── Grocery App Icon ──────────────────────────────────────────────────────────

@Composable
fun GroceryIconView(size: Int = 44) {
    Box(
        modifier = Modifier
            .size(size.dp)
            .clip(RoundedCornerShape((size * 0.26).dp))
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF388E3C),  // rich green top
                        Color(0xFF2E7D32),  // forest green bottom
                    )
                )
            ),
        contentAlignment = Alignment.Center,
    ) {
        Text(text = "🛒", fontSize = (size * 0.44).sp)
    }
}

@Composable
fun ScreenHeader(
    title: String,
    subtitle: String? = null,
    modifier: Modifier = Modifier,
    trailing: (@Composable RowScope.() -> Unit)? = null,
) {
    val colors = MaterialTheme.grocery
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.Top,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.headlineMedium,
                color = colors.title,
            )
            if (!subtitle.isNullOrBlank()) {
                Spacer(Modifier.height(4.dp))
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.muted,
                )
            }
        }
        if (trailing != null) {
            Spacer(Modifier.width(12.dp))
            Row(content = trailing)
        }
    }
}

@Composable
fun AppSurfaceCard(
    modifier: Modifier = Modifier,
    contentPadding: PaddingValues = PaddingValues(16.dp),
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = MaterialTheme.grocery
    Card(
        modifier = modifier,
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = colors.card),
        border = androidx.compose.foundation.BorderStroke(1.dp, colors.cardBorder.copy(alpha = if (colors.isDark) 1f else 0.82f)),
        elevation = CardDefaults.cardElevation(defaultElevation = if (colors.isDark) 0.dp else 2.dp),
    ) {
        Column(modifier = Modifier.padding(contentPadding), content = content)
    }
}

// ── Product Card ──────────────────────────────────────────────────────────────

@Composable
fun ProductCard(
    product: ProductDto,
    isFavorite: Boolean = false,
    onFavoriteClick: () -> Unit = {},
    onAddToCart: () -> Unit = {},
    onClick: () -> Unit = {},
    modifier: Modifier = Modifier,
) {
    val colors = MaterialTheme.grocery
    val imageUrl = product.primaryImageUrl

    Card(
        modifier = modifier
            .fillMaxWidth()
            .height(292.dp)
            .shadow(
                elevation = if (colors.isDark) 0.dp else 6.dp,
                shape = RoundedCornerShape(20.dp),
                ambientColor = Color.Black.copy(alpha = 0.06f),
                spotColor = Color.Black.copy(alpha = 0.08f),
            )
            .clickable { onClick() },
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = colors.card),
        border = androidx.compose.foundation.BorderStroke(
            width = if (colors.isDark) 1.dp else 0.5.dp,
            color = colors.cardBorder,
        ),
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // ── Image area ────────────────────────────────────────────────────
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(152.dp)
                    .clip(RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp))
                    .background(if (colors.isDark) Color(0xFF1E1E1E) else Color.White),
                contentAlignment = Alignment.Center,
            ) {
                if (imageUrl != null) {
                    AsyncImage(
                        model = imageUrl,
                        contentDescription = product.name,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize(),
                    )
                } else {
                    Text(text = emojiForCategory(product.categoryName), fontSize = 42.sp)
                }

                // Discount badge — top left
                product.discountPercent?.let { pct ->
                    Box(
                        modifier = Modifier
                            .padding(10.dp)
                            .align(Alignment.TopStart)
                            .background(colors.badge, RoundedCornerShape(6.dp))
                            .padding(horizontal = 7.dp, vertical = 3.dp),
                    ) {
                        Text(
                            text = "-$pct%",
                            color = Color.White,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                        )
                    }
                }

                // Favorite button — top right, semi-transparent
                IconButton(
                    onClick = onFavoriteClick,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(8.dp)
                        .size(36.dp)
                        .background(
                            color = if (colors.isDark)
                                Color(0xFF000000).copy(alpha = 0.45f)
                            else
                                Color(0xFFFFFFFF).copy(alpha = 0.5f),
                            shape = CircleShape,
                        ),
                ) {
                    Icon(
                        imageVector = if (isFavorite) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                        contentDescription = "Favorite",
                        tint = if (isFavorite) colors.badge else colors.muted,
                        modifier = Modifier.size(18.dp),
                    )
                }
            }

            // ── Info area ─────────────────────────────────────────────────────
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .padding(horizontal = 14.dp)
                    .padding(top = 12.dp, bottom = 12.dp),
            ) {
                Text(
                    text = product.name,
                    style = MaterialTheme.typography.titleSmall,
                    fontWeight = FontWeight.SemiBold,
                    color = colors.title,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    lineHeight = 19.sp,
                )
                Spacer(Modifier.height(5.dp))
                Text(
                    text = product.categoryName,
                    style = MaterialTheme.typography.labelMedium,
                    color = colors.muted,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(Modifier.weight(1f))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Column {
                        Text(
                            text = formatPeso(product.displayPrice),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = colors.primary,
                        )
                        if (product.discountPrice != null) {
                            Text(
                                text = formatPeso(product.price),
                                style = MaterialTheme.typography.labelSmall,
                                color = colors.muted,
                                textDecoration = TextDecoration.LineThrough,
                            )
                        }
                    }
                    // Add to cart button
                    Box(
                        modifier = Modifier
                            .size(38.dp)
                            .background(colors.primary, CircleShape)
                            .clickable { onAddToCart() },
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            imageVector = Icons.Filled.ShoppingCart,
                            contentDescription = "Add to cart",
                            tint = Color.White,
                            modifier = Modifier.size(16.dp),
                        )
                    }
                }
            }
        }
    }
}

// ── Section Header ────────────────────────────────────────────────────────────

@Composable
fun SectionHeader(
    title: String,
    actionLabel: String = "See All",
    onAction: (() -> Unit)? = null,
) {
    val colors = MaterialTheme.grocery
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
            color = colors.title,
        )
        if (onAction != null) {
            TextButton(onClick = onAction) {
                Text(text = actionLabel, color = colors.primary, style = MaterialTheme.typography.labelLarge)
            }
        }
    }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

@Composable
fun OrderStatusBadge(status: String) {
    val colors = MaterialTheme.grocery
    val (bg, fg) = when (status.lowercase()) {
        "pending"        -> colors.warning.copy(alpha = 0.16f) to colors.warning
        "paid"           -> Color(0xFF1D8CA8).copy(alpha = 0.18f) to Color(0xFF7FD8F2)
        "processing"     -> Color(0xFF4F7CFF).copy(alpha = 0.16f) to Color(0xFF7FA1FF)
        "outfordelivery" -> Color(0xFF8B5CF6).copy(alpha = 0.16f) to Color(0xFFC3B0FF)
        "delivered"      -> colors.success.copy(alpha = 0.16f) to colors.success
        "cancelled"      -> colors.badge.copy(alpha = 0.16f) to colors.badge
        else             -> colors.muted.copy(alpha = 0.18f) to colors.subtitle
    }
    val label = when (status.lowercase()) {
        "outfordelivery" -> "Out for Delivery"
        else -> status
    }
    Box(
        modifier = Modifier
            .background(bg, RoundedCornerShape(999.dp))
            .padding(horizontal = 10.dp, vertical = 5.dp)
    ) {
        Text(text = label, color = fg, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold)
    }
}

// ── Loading Indicator ─────────────────────────────────────────────────────────

@Composable
fun LoadingBox(modifier: Modifier = Modifier) {
    val colors = MaterialTheme.grocery
    Box(modifier = modifier.fillMaxSize().padding(24.dp), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            CircularProgressIndicator(color = GreenPrimary, strokeWidth = 2.5.dp)
            Spacer(Modifier.height(12.dp))
            Text("Loading…", style = MaterialTheme.typography.bodySmall, color = colors.muted)
        }
    }
}

@Composable
fun CartNoticeHost(
    cartViewModel: CartViewModel,
    modifier: Modifier = Modifier,
) {
    var activeNotice by remember { mutableStateOf<CartNotice?>(null) }

    LaunchedEffect(cartViewModel) {
        cartViewModel.notices.collect { notice ->
            activeNotice = notice
            delay(2200)
            if (activeNotice == notice) activeNotice = null
        }
    }

    Box(modifier = modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
        AnimatedVisibility(
            visible = activeNotice != null,
            enter = slideInVertically(initialOffsetY = { -it }) + fadeIn(),
            exit = slideOutVertically(targetOffsetY = { -it }) + fadeOut(),
        ) {
            activeNotice?.let { notice ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 10.dp)
                        .clip(RoundedCornerShape(16.dp))
                        .background(if (notice.isError) RedBadge else GreenPrimary)
                        .padding(horizontal = 14.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(
                        imageVector = if (notice.isError) Icons.Default.ErrorOutline else Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(Modifier.width(10.dp))
                    Text(
                        text = notice.message,
                        color = Color.White,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.weight(1f),
                    )
                    IconButton(
                        onClick = { activeNotice = null },
                        modifier = Modifier.size(22.dp)
                    ) {
                        Icon(Icons.Default.Close, contentDescription = "Dismiss", tint = Color.White, modifier = Modifier.size(16.dp))
                    }
                }
            }
        }
    }
}

// ── Empty State ───────────────────────────────────────────────────────────────

@Composable
fun EmptyState(emoji: String, title: String, subtitle: String = "") {
    val colors = MaterialTheme.grocery
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(40.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(88.dp)
                .clip(CircleShape)
                .background(colors.primaryLight.copy(alpha = if (colors.isDark) 0.65f else 1f)),
            contentAlignment = Alignment.Center
        ) {
            Text(text = emoji, fontSize = 38.sp)
        }
        Spacer(Modifier.height(18.dp))
        Text(text = title, style = MaterialTheme.typography.titleLarge, color = colors.title, fontWeight = FontWeight.Bold)
        if (subtitle.isNotBlank()) {
            Spacer(Modifier.height(8.dp))
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium,
                color = colors.muted,
                maxLines = 3
            )
        }
    }
}

// ── Price Row ─────────────────────────────────────────────────────────────────

@Composable
fun PriceRow(label: String, value: String, isTotal: Boolean = false, valueColor: Color? = null) {
    val colors = MaterialTheme.grocery
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 3.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(
            text = label,
            style = if (isTotal) MaterialTheme.typography.titleSmall else MaterialTheme.typography.bodySmall,
            fontWeight = if (isTotal) FontWeight.Bold else FontWeight.Normal,
            color = if (isTotal) colors.title else colors.subtitle,
        )
        Text(
            text = value,
            style = if (isTotal) MaterialTheme.typography.titleMedium else MaterialTheme.typography.bodySmall,
            fontWeight = if (isTotal) FontWeight.Bold else FontWeight.Medium,
            color = valueColor ?: if (isTotal) colors.primary else colors.title,
        )
    }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

fun emojiForCategory(name: String): String {
    val map = mapOf(
        "fruits" to "🍎", "vegetables" to "🥕", "veggie" to "🥕",
        "meats" to "🥩", "meat" to "🥩", "snacks" to "🍿",
        "drinks" to "🥤", "beverages" to "🥤", "dairy" to "🧀",
        "bakery" to "🍞", "bread" to "🍞", "seafood" to "🦐",
        "frozen" to "🧊", "organic" to "🌿", "condiments" to "🧂",
        "household" to "🧹", "personal" to "🧴", "pantry" to "🥫",
    )
    return map[name.lowercase()] ?: "🛒"
}

fun formatPeso(amount: Double): String = "₱${String.format("%,.2f", amount)}"
fun formatPesoInt(amount: Double): String = "₱${amount.toInt()}"
