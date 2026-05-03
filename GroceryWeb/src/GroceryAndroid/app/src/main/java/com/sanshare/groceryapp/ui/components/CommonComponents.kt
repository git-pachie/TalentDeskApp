package com.sanshare.groceryapp.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
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

// ── Grocery App Icon ──────────────────────────────────────────────────────────

@Composable
fun GroceryIconView(size: Int = 44) {
    Box(
        modifier = Modifier
            .size(size.dp)
            .clip(RoundedCornerShape((size * 0.22).dp))
            .background(
                Brush.linearGradient(
                    colors = listOf(GreenPrimary, GreenPrimary.copy(alpha = 0.75f))
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(text = "🛒", fontSize = (size * 0.5).sp)
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
    Card(
        modifier = modifier
            .fillMaxWidth()
            .shadow(4.dp, RoundedCornerShape(14.dp))
            .clickable { onClick() },
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = colors.card),
    ) {
        Column {
            // Image
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(140.dp)
                    .background(Color(0xFFF5F5F5))
            ) {
                val imageUrl = product.primaryImageUrl
                if (imageUrl != null) {
                    AsyncImage(
                        model = imageUrl,
                        contentDescription = product.name,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.fillMaxSize(),
                    )
                } else {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text(text = emojiForCategory(product.categoryName), fontSize = 40.sp)
                    }
                }

                // Discount badge
                product.discountPercent?.let { pct ->
                    Box(
                        modifier = Modifier
                            .padding(8.dp)
                            .align(Alignment.TopStart)
                            .background(RedBadge, RoundedCornerShape(6.dp))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(text = "$pct% off", color = Color.White, fontSize = 10.sp, fontWeight = FontWeight.Bold)
                    }
                }

                // Favorite button
                IconButton(
                    onClick = onFavoriteClick,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .size(36.dp)
                ) {
                    Icon(
                        imageVector = if (isFavorite) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                        contentDescription = "Favorite",
                        tint = if (isFavorite) RedBadge else colors.muted,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            // Info
            Column(modifier = Modifier.padding(10.dp)) {
                Text(
                    text = product.name,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = colors.title,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(Modifier.height(2.dp))
                Text(
                    text = product.categoryName,
                    style = MaterialTheme.typography.labelSmall,
                    color = colors.muted,
                )
                Spacer(Modifier.height(6.dp))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column {
                        Text(
                            text = "₱${product.displayPrice.toInt()}",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold,
                            color = colors.primary,
                        )
                        if (product.discountPrice != null) {
                            Text(
                                text = "₱${product.price.toInt()}",
                                style = MaterialTheme.typography.labelSmall,
                                color = colors.muted,
                                textDecoration = TextDecoration.LineThrough,
                            )
                        }
                    }
                    // Add to cart button
                    Box(
                        modifier = Modifier
                            .size(32.dp)
                            .background(colors.primary, CircleShape)
                            .clickable { onAddToCart() },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Filled.ShoppingCart,
                            contentDescription = "Add to cart",
                            tint = Color.White,
                            modifier = Modifier.size(16.dp)
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
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = colors.title,
        )
        if (onAction != null) {
            TextButton(onClick = onAction) {
                Text(text = actionLabel, color = colors.primary, fontSize = 13.sp)
            }
        }
    }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

@Composable
fun OrderStatusBadge(status: String) {
    val (bg, fg) = when (status.lowercase()) {
        "pending"        -> Color(0xFFFFF3CD) to Color(0xFF856404)
        "paid"           -> Color(0xFFCFF4FC) to Color(0xFF055160)
        "processing"     -> Color(0xFFCFE2FF) to Color(0xFF084298)
        "outfordelivery" -> Color(0xFFEDE9FE) to Color(0xFF5B21B6)
        "delivered"      -> Color(0xFFD1FAE5) to Color(0xFF065F46)
        "cancelled"      -> Color(0xFFFEE2E2) to Color(0xFF991B1B)
        else             -> Color(0xFFE5E7EB) to Color(0xFF374151)
    }
    val label = when (status.lowercase()) {
        "outfordelivery" -> "Out for Delivery"
        else -> status
    }
    Box(
        modifier = Modifier
            .background(bg, RoundedCornerShape(20.dp))
            .padding(horizontal = 10.dp, vertical = 4.dp)
    ) {
        Text(text = label, color = fg, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
    }
}

// ── Loading Indicator ─────────────────────────────────────────────────────────

@Composable
fun LoadingBox(modifier: Modifier = Modifier) {
    Box(modifier = modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(color = GreenPrimary)
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
        Text(text = emoji, fontSize = 56.sp)
        Spacer(Modifier.height(12.dp))
        Text(text = title, style = MaterialTheme.typography.titleMedium, color = colors.title)
        if (subtitle.isNotBlank()) {
            Spacer(Modifier.height(4.dp))
            Text(text = subtitle, style = MaterialTheme.typography.bodySmall, color = colors.muted)
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
