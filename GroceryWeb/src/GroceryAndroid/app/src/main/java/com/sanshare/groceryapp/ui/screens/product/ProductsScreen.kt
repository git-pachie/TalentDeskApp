package com.sanshare.groceryapp.ui.screens.product

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sanshare.groceryapp.ui.components.*
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.CartViewModel
import com.sanshare.groceryapp.ui.viewmodel.FavoritesViewModel
import com.sanshare.groceryapp.ui.viewmodel.ProductViewModel

@Composable
fun ProductsScreen(
    cartViewModel: CartViewModel,
    favoritesViewModel: FavoritesViewModel,
    onProductClick: (String) -> Unit,
    viewModel: ProductViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsState()
    val favState by favoritesViewModel.state.collectAsState()
    val colors = MaterialTheme.grocery
    val gridState = rememberLazyGridState()

    // Load more when near end
    val shouldLoadMore by remember {
        derivedStateOf {
            val lastVisible = gridState.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: 0
            lastVisible >= state.products.size - 4 && state.hasMore && !state.isLoadingMore
        }
    }
    LaunchedEffect(shouldLoadMore) {
        if (shouldLoadMore) viewModel.loadMore()
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
    ) {
        // Search bar
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(colors.card)
                .padding(horizontal = 14.dp, vertical = 12.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Search, null, tint = colors.muted, modifier = Modifier.size(20.dp))
                Spacer(Modifier.width(8.dp))
                BasicSearchField(
                    value = state.searchQuery,
                    onValueChange = { viewModel.search(it) },
                    placeholder = "Search products...",
                )
            }
        }

        // Category filter chips
        LazyRow(
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item {
                FilterChip(
                    selected = state.selectedCategoryId == null,
                    onClick = { viewModel.selectCategory(null) },
                    label = { Text("All") },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = GreenPrimary,
                        selectedLabelColor = androidx.compose.ui.graphics.Color.White,
                    )
                )
            }
            items(state.categories) { cat ->
                FilterChip(
                    selected = state.selectedCategoryId == cat.id,
                    onClick = { viewModel.selectCategory(cat.id) },
                    label = { Text("${cat.emoji ?: emojiForCategory(cat.name)} ${cat.name}") },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = GreenPrimary,
                        selectedLabelColor = androidx.compose.ui.graphics.Color.White,
                    )
                )
            }
        }

        Spacer(Modifier.height(8.dp))

        if (state.isLoading) {
            LoadingBox()
        } else if (state.products.isEmpty()) {
            EmptyState("🛒", "No products found", "Try a different search or category")
        } else {
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                state = gridState,
                contentPadding = PaddingValues(16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(state.products, key = { it.id }) { product ->
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
                if (state.isLoadingMore) {
                    item(span = { GridItemSpan(2) }) {
                        Box(Modifier.fillMaxWidth().padding(16.dp), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator(color = GreenPrimary, modifier = Modifier.size(24.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun BasicSearchField(value: String, onValueChange: (String) -> Unit, placeholder: String) {
    val colors = MaterialTheme.grocery
    androidx.compose.foundation.text.BasicTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = true,
        textStyle = androidx.compose.ui.text.TextStyle(color = colors.title, fontSize = 14.sp),
        modifier = Modifier.fillMaxWidth(),
        decorationBox = { inner ->
            if (value.isEmpty()) Text(placeholder, color = colors.muted, fontSize = 14.sp)
            inner()
        }
    )
}
