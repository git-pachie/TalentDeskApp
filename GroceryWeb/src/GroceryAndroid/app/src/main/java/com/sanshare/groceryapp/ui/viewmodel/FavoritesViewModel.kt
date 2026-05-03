package com.sanshare.groceryapp.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sanshare.groceryapp.data.remote.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import java.net.URI
import javax.inject.Inject

data class FavoritesState(
    val favorites: List<ProductDto> = emptyList(),
    val favoriteIds: Set<String> = emptySet(),
    val isLoading: Boolean = false,
)

@HiltViewModel
class FavoritesViewModel @Inject constructor(
    private val apiClient: ApiClient,
) : ViewModel() {

    private val _state = MutableStateFlow(FavoritesState())
    val state: StateFlow<FavoritesState> = _state.asStateFlow()

    fun loadFromServer() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            val result = apiClient.get<List<FavoriteDto>>(ApiConfig.FAVORITES)
            if (result is ApiResult.Success) {
                val products = result.data.mapNotNull { fav ->
                    fav.product ?: if (fav.productName != null) {
                        val favoriteImageUrl = resolveFavoriteImageUrl(fav.imageUrl)
                        ProductDto(
                            id = fav.productId,
                            name = fav.productName,
                            price = fav.price ?: 0.0,
                            discountPrice = fav.discountPrice,
                            categoryId = "",
                            categoryName = "",
                            images = if (favoriteImageUrl != null) listOf(
                                ProductImageDto(
                                    id = "",
                                    imageUrl = favoriteImageUrl,
                                    fullUrl = favoriteImageUrl,
                                    isPrimary = true
                                )
                            ) else emptyList(),
                        )
                    } else null
                }
                _state.update {
                    it.copy(
                        favorites = products,
                        favoriteIds = products.map { p -> p.id }.toSet(),
                        isLoading = false,
                    )
                }
            } else {
                _state.update { it.copy(isLoading = false) }
            }
        }
    }

    fun toggleFavorite(product: ProductDto) {
        val isFav = _state.value.favoriteIds.contains(product.id)
        if (isFav) {
            _state.update {
                it.copy(
                    favorites = it.favorites.filter { p -> p.id != product.id },
                    favoriteIds = it.favoriteIds - product.id,
                )
            }
            viewModelScope.launch {
                apiClient.delete("${ApiConfig.FAVORITES}/${product.id}")
            }
        } else {
            _state.update {
                it.copy(
                    favorites = it.favorites + product,
                    favoriteIds = it.favoriteIds + product.id,
                )
            }
            viewModelScope.launch {
                apiClient.post<Unit, FavoriteDto>("${ApiConfig.FAVORITES}/${product.id}", Unit)
            }
        }
    }

    fun isFavorite(productId: String): Boolean = _state.value.favoriteIds.contains(productId)

    private fun resolveFavoriteImageUrl(imageUrl: String?): String? {
        if (imageUrl.isNullOrBlank()) return null
        if (imageUrl.startsWith("http", ignoreCase = true)) {
            return rebuildUsingBaseUrl(imageUrl)
        }
        if (imageUrl.startsWith("/")) return "${ApiConfig.BASE_URL.trimEnd('/')}$imageUrl"
        if (imageUrl.startsWith("uploads/", ignoreCase = true)) {
            return "${ApiConfig.BASE_URL.trimEnd('/')}/${imageUrl.trimStart('/')}"
        }
        if (imageUrl.startsWith("products/", ignoreCase = true)) {
            return "${ApiConfig.BASE_URL.trimEnd('/')}/uploads/${imageUrl.trimStart('/')}"
        }

        return "${ApiConfig.BASE_URL.trimEnd('/')}/uploads/products/$imageUrl"
    }

    private fun rebuildUsingBaseUrl(imageUrl: String): String {
        return try {
            val source = URI(imageUrl)
            val path = source.path.orEmpty()
            val normalizedPath = when {
                path.contains("/uploads/products/", ignoreCase = true) ->
                    path.substringAfter("/uploads/products/").substringBefore("?")
                path.contains("/products/", ignoreCase = true) ->
                    path.substringAfter("/products/").substringBefore("?")
                else -> path.substringAfterLast('/').substringBefore("?")
            }.trimStart('/')

            if (normalizedPath.isBlank()) imageUrl
            else "${ApiConfig.BASE_URL.trimEnd('/')}/uploads/products/$normalizedPath"
        } catch (_: Exception) {
            imageUrl
        }
    }
}
