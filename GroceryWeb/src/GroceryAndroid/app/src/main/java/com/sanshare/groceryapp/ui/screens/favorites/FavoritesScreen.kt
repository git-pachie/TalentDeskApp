package com.sanshare.groceryapp.ui.screens.favorites

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sanshare.groceryapp.ui.components.*
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.CartViewModel
import com.sanshare.groceryapp.ui.viewmodel.FavoritesViewModel

@Composable
fun FavoritesScreen(
    favoritesViewModel: FavoritesViewModel,
    cartViewModel: CartViewModel,
    onProductClick: (String) -> Unit,
) {
    val state by favoritesViewModel.state.collectAsState()
    val colors = MaterialTheme.grocery

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
        ) {
            Text("Favorites", style = MaterialTheme.typography.headlineMedium, color = colors.title, fontWeight = FontWeight.Bold)
        }

        if (state.isLoading) {
            LoadingBox()
        } else if (state.favorites.isEmpty()) {
            EmptyState("❤️", "No Favorites Yet", "Tap the heart icon on any product to save it here.")
        } else {
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                contentPadding = PaddingValues(16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(state.favorites, key = { it.id }) { product ->
                    ProductCard(
                        product = product,
                        isFavorite = true,
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
}
