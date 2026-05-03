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
        if (state.categories.isEmpty() || state.deals.isEmpty()) {
            viewModel.loadHome()
        }
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
        // ── Header ────────────────────────────────────────────────────────────
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            GroceryIconView(size = 38)
            Spacer(Modifier.width(10.dp))
            Column(
                modifier = Modifier
                    .weight(1f)
                    .clickable { showAddressSheet = true }
            ) {
                Text("Delivery to", fontSize = 11.sp, color = colors.muted)
                val addr = state.addresses.getOrNull(state.selectedAddressIndex)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = addr?.label ?: "Set address",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = colors.title,
                    )
                    Icon(Icons.Default.KeyboardArrowDown, null, tint = colors.title, modifier = Modifier.size(16.dp))
                }
                Text(
                    text = addr?.fullAddress ?: "Tap to set delivery address",
                    fontSize = 11.sp,
                    color = colors.muted,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                addr?.contactNumber?.takeIf { it.isNotBlank() }?.let { contact ->
                    Spacer(Modifier.height(2.dp))
                    Text(
                        text = contact,
                        fontSize = 11.sp,
                        color = GreenPrimary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            IconButton(onClick = {}) {
                Icon(Icons.Default.Notifications, null, tint = colors.title)
            }
        }

        // ── Search bar ────────────────────────────────────────────────────────
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(colors.card)
                .clickable { onSearchClick() }
                .padding(horizontal = 14.dp, vertical = 12.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Search, null, tint = colors.muted, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(8.dp))
                Text("Search fresh groceries...", color = colors.muted, fontSize = 14.sp)
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
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    contentPadding = PaddingValues(bottom = 20.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.height(
                        ((deals.size / 2 + deals.size % 2) * 306).dp.coerceAtMost(980.dp)
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
    val subtitleColor = if (isDark) Color.White.copy(alpha = 0.85f) else Color(0xFF727272)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 2.dp)
            .clip(RoundedCornerShape(16.dp))
            .background(finalBg)
            .padding(20.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text(banner.title, fontSize = 18.sp, fontWeight = FontWeight.Bold, color = textColor)
                Spacer(Modifier.height(4.dp))
                Text(banner.subtitle, fontSize = 12.sp, color = subtitleColor, lineHeight = 16.sp)
                Spacer(Modifier.height(12.dp))
                Button(
                    onClick = onShopNow,
                    colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 6.dp),
                    modifier = Modifier.height(32.dp),
                ) {
                    Text("Shop Now", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                }
            }
            Spacer(Modifier.width(12.dp))
            if (banner.imageUrl != null) {
                AsyncImage(
                    model = banner.imageUrl,
                    contentDescription = null,
                    modifier = Modifier.size(88.dp).clip(RoundedCornerShape(14.dp))
                )
            } else {
                Text(banner.emoji, fontSize = 44.sp)
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
        Box(
            modifier = Modifier
                .size(56.dp)
                .background(GreenPrimary.copy(alpha = 0.12f), CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Text(emoji, fontSize = 24.sp)
        }
        Spacer(Modifier.height(4.dp))
        Text(
            text = name,
            fontSize = 11.sp,
            color = colors.subtitle,
            maxLines = 1,
        )
    }
}

@Composable
private fun isSystemInDarkTheme(): Boolean {
    return androidx.compose.foundation.isSystemInDarkTheme()
}
