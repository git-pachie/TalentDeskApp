package com.sanshare.groceryapp.ui.screens.home

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.graphics.ColorUtils
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import coil.compose.SubcomposeAsyncImage
import com.sanshare.groceryapp.data.remote.ProductDto
import com.sanshare.groceryapp.data.remote.SpecialOfferDto
import com.sanshare.groceryapp.ui.components.*
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.CartViewModel
import com.sanshare.groceryapp.ui.viewmodel.FavoritesViewModel
import com.sanshare.groceryapp.ui.viewmodel.HomeViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    cartViewModel: CartViewModel,
    favoritesViewModel: FavoritesViewModel,
    onProductClick: (String) -> Unit,
    onSearchClick: () -> Unit,
    onCategoryClick: (String?) -> Unit,
    viewModel: HomeViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsState()
    val favState by favoritesViewModel.state.collectAsState()
    val colors = MaterialTheme.grocery
    val pagerState = rememberPagerState { maxOf(state.specialOffers.size, 1) }
    var showAddressSheet by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.loadHome()
    }

    // Auto-scroll banners
    LaunchedEffect(state.specialOffers.size) {
        if (state.specialOffers.size > 1) {
            while (true) {
                delay(3500)
                val next = (pagerState.currentPage + 1) % state.specialOffers.size
                pagerState.animateScrollToPage(next)
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
        ) {
        val addr = state.addresses.getOrNull(state.selectedAddressIndex)
        AppSurfaceCard(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            contentPadding = PaddingValues(16.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                GroceryIconView(size = 40)
                Spacer(Modifier.width(12.dp))
                Column(
                    modifier = Modifier
                        .weight(1f)
                        .clickable { showAddressSheet = true }
                ) {
                    Text("Delivered to", style = MaterialTheme.typography.labelMedium, color = colors.muted)
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = addr?.label ?: "Set address",
                            style = MaterialTheme.typography.titleMedium,
                            color = colors.title,
                        )
                        Spacer(Modifier.width(4.dp))
                        Icon(Icons.Default.KeyboardArrowDown, null, tint = colors.muted, modifier = Modifier.size(18.dp))
                    }
                    Text(
                        text = addr?.fullAddress ?: "Tap to set delivery address",
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.muted,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    addr?.contactNumber?.takeIf { it.isNotBlank() }?.let { contact ->
                        Spacer(Modifier.height(2.dp))
                        Text(
                            text = contact,
                            style = MaterialTheme.typography.labelMedium,
                            color = colors.primary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
                Surface(
                    color = colors.primaryLight,
                    shape = CircleShape,
                ) {
                    IconButton(onClick = {}) {
                        Icon(Icons.Default.Notifications, null, tint = colors.primary)
                    }
                }
            }
        }

        // ── Search bar ────────────────────────────────────────────────────────
        AppSurfaceCard(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .clickable { onSearchClick() },
            contentPadding = PaddingValues(horizontal = 14.dp, vertical = 12.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Search, null, tint = colors.muted, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(8.dp))
                Text("Search fresh groceries...", color = colors.muted, style = MaterialTheme.typography.bodyMedium)
            }
        }

        Spacer(Modifier.height(20.dp))

        // ── Special Offers Carousel ───────────────────────────────────────────
        Column(modifier = Modifier.padding(horizontal = 16.dp)) {
            SectionHeader("Special Offers")
            Spacer(Modifier.height(10.dp))

            val banners = state.specialOffers.ifEmpty {
                listOf(
                    SpecialOfferDto("1", null, "Up To 50% Discount", "Shop fresh products,\ngrab exclusive deals.", "🥕🍅🥦", null, "D9F2D8", 0, true),
                    SpecialOfferDto("2", null, "Free Delivery", "On orders above ₱1500.\nFresh to your door.", "🚚📦✨", null, "E8F0FF", 1, true),
                    SpecialOfferDto("3", null, "Buy 1 Get 1 Free", "Selected fruits & veggies\nthis weekend only.", "🍎🥑🍇", null, "FFF3E0", 2, true),
                )
            }

            HorizontalPager(
                state = pagerState,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(160.dp),
            ) { page ->
                val banner = banners.getOrNull(page) ?: return@HorizontalPager
                BannerCard(banner = banner, onShopNow = { onCategoryClick(banner.categoryId) })
            }

            Spacer(Modifier.height(8.dp))

            // Page dots
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
            ) {
                repeat(banners.size) { index ->
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 3.dp)
                            .size(if (pagerState.currentPage == index) 20.dp else 7.dp, 7.dp)
                            .clip(if (pagerState.currentPage == index) RoundedCornerShape(4.dp) else CircleShape)
                            .background(if (pagerState.currentPage == index) GreenPrimary else colors.muted.copy(alpha = 0.4f))
                    )
                }
            }
        }

        Spacer(Modifier.height(20.dp))

        // ── Categories ────────────────────────────────────────────────────────
        Column(modifier = Modifier.padding(horizontal = 16.dp)) {
            SectionHeader("Shop By Categories", onAction = { onCategoryClick(null) })
            Spacer(Modifier.height(10.dp))
            LazyRow(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                val cats = state.categories.ifEmpty {
                    listOf(
                        com.sanshare.groceryapp.data.remote.CategoryDto("1","Veggie",emoji="🥕",isActive=true,productCount=0),
                        com.sanshare.groceryapp.data.remote.CategoryDto("2","Fruits",emoji="🍎",isActive=true,productCount=0),
                        com.sanshare.groceryapp.data.remote.CategoryDto("3","Meats",emoji="🥩",isActive=true,productCount=0),
                        com.sanshare.groceryapp.data.remote.CategoryDto("4","Snacks",emoji="🍿",isActive=true,productCount=0),
                        com.sanshare.groceryapp.data.remote.CategoryDto("5","Drinks",emoji="🥤",isActive=true,productCount=0),
                        com.sanshare.groceryapp.data.remote.CategoryDto("6","Dairy",emoji="🧀",isActive=true,productCount=0),
                    )
                }
                items(cats) { cat ->
                    CategoryChip(
                        name = cat.name,
                        emoji = cat.emoji ?: emojiForCategory(cat.name),
                        onClick = { onCategoryClick(cat.id) }
                    )
                }
            }
        }

        Spacer(Modifier.height(20.dp))

        // ── Today's Deals ─────────────────────────────────────────────────────
        Column(modifier = Modifier.padding(horizontal = 16.dp)) {
            SectionHeader("Today's Deals")
            Spacer(Modifier.height(10.dp))

            if (state.isLoading) {
                LoadingBox(modifier = Modifier.height(200.dp))
            } else {
                val deals = state.deals
                val rows = (deals.size + 1) / 2
                val cardHeight = 288 // ProductCard height in dp
                val spacing = 12    // verticalArrangement spacing
                val bottomPad = 8   // extra bottom breathing room
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    contentPadding = PaddingValues(bottom = bottomPad.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(spacing.dp),
                    modifier = Modifier.height(
                        (rows * cardHeight + (rows - 1).coerceAtLeast(0) * spacing + bottomPad).dp
                    ),
                    userScrollEnabled = false,
                ) {
                    items(deals) { product ->
                        ProductCard(
                            product = product,
                            isFavorite = favState.favoriteIds.contains(product.id),
                            onFavoriteClick = { favoritesViewModel.toggleFavorite(product) },
                            onAddToCart = {
                                cartViewModel.addProduct(
                                    productId = product.id,
                                    productName = product.name,
                                    imageUrl = product.primaryImageUrl,
                                    price = product.displayPrice,
                                )
                            },
                            onClick = { onProductClick(product.id) },
                        )
                    }
                }
            }
        }

            Spacer(Modifier.height(96.dp))
        }

        if (showAddressSheet) {
            ModalBottomSheet(onDismissRequest = { showAddressSheet = false }) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Select Delivery Address", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.height(12.dp))
                    if (state.addresses.isEmpty()) {
                        Text("No saved addresses yet.", color = colors.muted, fontSize = 14.sp)
                    } else {
                        state.addresses.forEachIndexed { index, address ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        viewModel.selectAddress(index)
                                        showAddressSheet = false
                                    }
                                    .padding(vertical = 12.dp),
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Icon(Icons.Default.LocationOn, null, tint = GreenPrimary)
                                Spacer(Modifier.width(12.dp))
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(address.label, color = colors.title, fontWeight = FontWeight.SemiBold)
                                    Text(address.fullAddress, color = colors.subtitle, fontSize = 12.sp)
                                }
                                if (index == state.selectedAddressIndex) {
                                    Icon(Icons.Default.CheckCircle, null, tint = GreenPrimary)
                                }
                            }
                            HorizontalDivider(color = colors.cardBorder)
                        }
                    }
                    Spacer(Modifier.height(24.dp))
                }
            }
        }

        CartNoticeHost(
            cartViewModel = cartViewModel,
            modifier = Modifier.statusBarsPadding()
        )
    }
}

@Composable
private fun BannerCard(banner: SpecialOfferDto, onShopNow: () -> Unit) {
    val isDark = isSystemInDarkTheme()
    val colors = MaterialTheme.grocery
    val bgColor = try {
        val hex = banner.backgroundColorHex.trimStart('#')
        val argb = android.graphics.Color.parseColor("#$hex")
        Color(argb)
    } catch (e: Exception) {
        Color(0xFFD9F2D8)
    }

    // Darken in dark mode for contrast
    val finalBg = if (isDark) {
        val blended = ColorUtils.blendARGB(bgColor.toArgb(), android.graphics.Color.BLACK, 0.45f)
        Color(blended)
    } else bgColor

    val textColor = if (isDark) Color.White else Color(0xFF1C1C1C)
    val subtitleColor = if (isDark) Color.White.copy(alpha = 0.85f) else Color(0xFF627067)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 2.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(finalBg)
            .padding(22.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text(banner.title, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = textColor, maxLines = 1, overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis)
                Spacer(Modifier.height(3.dp))
                Text(banner.subtitle, fontSize = 11.sp, color = subtitleColor, lineHeight = 14.sp, maxLines = 2, overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis)
                Spacer(Modifier.height(8.dp))
                Button(
                    onClick = onShopNow,
                    colors = ButtonDefaults.buttonColors(containerColor = colors.primary, contentColor = Color.White),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 6.dp),
                    modifier = Modifier.height(34.dp),
                ) {
                    Text("Shop Now", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                }
            }
            Spacer(Modifier.width(12.dp))
            if (!banner.imageUrl.isNullOrBlank()) {
                SubcomposeAsyncImage(
                    model = banner.imageUrl,
                    contentDescription = null,
                    modifier = Modifier.size(88.dp).clip(RoundedCornerShape(14.dp)),
                    error = {
                        // Image URL exists but failed to load — show emoji instead
                        Text(banner.emoji, fontSize = 32.sp)
                    },
                )
            } else {
                Text(banner.emoji, fontSize = 32.sp)
            }
        }
    }
}

@Composable
private fun CategoryChip(name: String, emoji: String, onClick: () -> Unit) {
    val colors = MaterialTheme.grocery
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.clickable { onClick() }
    ) {
        Surface(
            modifier = Modifier
                .size(60.dp),
            shape = CircleShape,
            color = colors.primaryLight,
            tonalElevation = 0.dp,
        ) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(emoji, fontSize = 24.sp)
            }
        }
        Spacer(Modifier.height(8.dp))
        Text(
            text = name,
            style = MaterialTheme.typography.labelMedium,
            color = colors.subtitle,
            maxLines = 1,
        )
    }
}

@Composable
private fun isSystemInDarkTheme(): Boolean {
    return androidx.compose.foundation.isSystemInDarkTheme()
}
