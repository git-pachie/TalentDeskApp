package com.sanshare.groceryapp.ui.screens.product

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.sanshare.groceryapp.ui.components.*
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.CartViewModel
import com.sanshare.groceryapp.ui.viewmodel.FavoritesViewModel
import com.sanshare.groceryapp.ui.viewmodel.ProductViewModel

@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
fun ProductDetailScreen(
    productId: String,
    onBack: () -> Unit,
    onNavigateToCart: () -> Unit,
    productViewModel: ProductViewModel = hiltViewModel(),
    cartViewModel: CartViewModel = hiltViewModel(),
    favoritesViewModel: FavoritesViewModel = hiltViewModel(),
) {
    val colors = MaterialTheme.grocery
    var product by remember { mutableStateOf<com.sanshare.groceryapp.data.remote.ProductDto?>(null) }
    var quantity by remember { mutableIntStateOf(1) }
    var addedToCart by remember { mutableStateOf(false) }

    LaunchedEffect(productId) {
        productViewModel.getProductById(productId).collect { product = it }
    }

    val favState by favoritesViewModel.state.collectAsState()
    val isFav = product?.let { favState.favoriteIds.contains(it.id) } ?: false

    Scaffold(
        topBar = {
            TopAppBar(
                title = {},
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, null, tint = colors.title)
                    }
                },
                actions = {
                    product?.let { p ->
                        IconButton(onClick = { favoritesViewModel.toggleFavorite(p) }) {
                            Icon(
                                if (isFav) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                                null,
                                tint = if (isFav) com.sanshare.groceryapp.ui.theme.RedBadge else colors.muted
                            )
                        }
                    }
                    IconButton(onClick = onNavigateToCart) {
                        Icon(Icons.Default.ShoppingCart, null, tint = colors.title)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = colors.background)
            )
        },
        containerColor = colors.background,
    ) { padding ->
        if (product == null) {
            LoadingBox()
            return@Scaffold
        }

        val p = product!!
        val images = p.images.sortedBy { it.sortOrder }
        val pagerState = rememberPagerState { images.size.coerceAtLeast(1) }

        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(280.dp)
                        .background(Color.White)
                ) {
                    if (images.isNotEmpty()) {
                        HorizontalPager(state = pagerState, modifier = Modifier.fillMaxSize()) { page ->
                            AsyncImage(
                                model = images[page].displayUrl,
                                contentDescription = p.name,
                                contentScale = ContentScale.Fit,
                                modifier = Modifier.fillMaxSize(),
                            )
                        }

                        if (images.size > 1) {
                            Row(
                                modifier = Modifier
                                    .align(Alignment.BottomCenter)
                                    .padding(bottom = 8.dp),
                                horizontalArrangement = Arrangement.spacedBy(6.dp),
                            ) {
                                images.forEachIndexed { idx, _ ->
                                    Box(
                                        modifier = Modifier
                                            .size(if (pagerState.currentPage == idx) 10.dp else 7.dp)
                                            .clip(CircleShape)
                                            .background(if (pagerState.currentPage == idx) GreenPrimary else Color.Gray.copy(alpha = 0.4f))
                                    )
                                }
                            }
                        }
                    } else {
                        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Text(emojiForCategory(p.categoryName), fontSize = 80.sp)
                        }
                    }

                    p.discountPercent?.let { pct ->
                        Box(
                            modifier = Modifier
                                .padding(12.dp)
                                .align(Alignment.TopStart)
                                .background(com.sanshare.groceryapp.ui.theme.RedBadge, RoundedCornerShape(8.dp))
                                .padding(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text("$pct% off", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                }

                Column(modifier = Modifier.padding(16.dp)) {
                    Text(p.name, style = MaterialTheme.typography.headlineMedium, color = colors.title)
                    Spacer(Modifier.height(4.dp))
                    Text(p.categoryName, fontSize = 13.sp, color = colors.muted)

                    Spacer(Modifier.height(12.dp))

                    Row(verticalAlignment = Alignment.Bottom) {
                        Text(
                            "₱${p.displayPrice.toInt()}",
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Bold,
                            color = GreenPrimary,
                        )
                        if (p.discountPrice != null) {
                            Spacer(Modifier.width(8.dp))
                            Text(
                                "₱${p.price.toInt()}",
                                fontSize = 16.sp,
                                color = colors.muted,
                                textDecoration = TextDecoration.LineThrough,
                            )
                        }
                        p.unit?.let { unit ->
                            Spacer(Modifier.width(6.dp))
                            Text("/ $unit", fontSize = 13.sp, color = colors.muted)
                        }
                    }

                    if (p.reviewCount > 0) {
                        Spacer(Modifier.height(8.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Star, null, tint = Color(0xFFFACC15), modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(4.dp))
                            Text("${p.averageRating}", fontSize = 13.sp, color = colors.title, fontWeight = FontWeight.SemiBold)
                            Text(" (${p.reviewCount} reviews)", fontSize = 12.sp, color = colors.muted)
                        }
                    }

                    Spacer(Modifier.height(16.dp))
                    Divider(color = colors.cardBorder)
                    Spacer(Modifier.height(16.dp))

                    if (!p.description.isNullOrBlank()) {
                        Text("About this product", style = MaterialTheme.typography.titleSmall, color = colors.title)
                        Spacer(Modifier.height(6.dp))
                        Text(p.description, fontSize = 14.sp, color = colors.subtitle, lineHeight = 20.sp)
                        Spacer(Modifier.height(16.dp))
                    }

                    Text(
                        "In stock: ${p.stockQuantity} ${p.unit ?: "pcs"}",
                        fontSize = 13.sp,
                        color = if (p.stockQuantity > 0) GreenPrimary else com.sanshare.groceryapp.ui.theme.RedBadge,
                    )

                    Spacer(Modifier.height(24.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween,
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .background(colors.card, RoundedCornerShape(12.dp))
                                .padding(4.dp)
                        ) {
                            IconButton(
                                onClick = { if (quantity > 1) quantity-- },
                                modifier = Modifier.size(36.dp)
                            ) {
                                Icon(Icons.Default.Remove, null, tint = GreenPrimary)
                            }
                            Text(
                                "$quantity",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold,
                                color = colors.title,
                                modifier = Modifier.padding(horizontal = 12.dp)
                            )
                            IconButton(
                                onClick = { if (quantity < p.stockQuantity) quantity++ },
                                modifier = Modifier.size(36.dp)
                            ) {
                                Icon(Icons.Default.Add, null, tint = GreenPrimary)
                            }
                        }

                        Button(
                            onClick = {
                                cartViewModel.addProduct(
                                    productId = p.id,
                                    productName = p.name,
                                    imageUrl = p.primaryImageUrl,
                                    price = p.displayPrice,
                                    quantity = quantity,
                                )
                                addedToCart = true
                            },
                            modifier = Modifier.height(48.dp),
                            shape = RoundedCornerShape(14.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
                        ) {
                            Icon(Icons.Default.ShoppingCart, null, modifier = Modifier.size(18.dp))
                            Spacer(Modifier.width(8.dp))
                            Text(if (addedToCart) "Added!" else "Add to Cart", fontWeight = FontWeight.SemiBold)
                        }
                    }

                    Spacer(Modifier.height(32.dp))
                }
            }

            CartNoticeHost(
                cartViewModel = cartViewModel,
                modifier = Modifier.statusBarsPadding()
            )
        }
    }
}
