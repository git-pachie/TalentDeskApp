package com.sanshare.groceryapp.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sanshare.groceryapp.data.remote.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import javax.inject.Inject

data class ProductState(
    val products: List<ProductDto> = emptyList(),
    val categories: List<CategoryDto> = emptyList(),
    val selectedCategoryId: String? = null,
    val searchQuery: String = "",
    val isLoading: Boolean = false,
    val isLoadingMore: Boolean = false,
    val hasMore: Boolean = true,
    val page: Int = 1,
    val error: String? = null,
)

@HiltViewModel
class ProductViewModel @Inject constructor(
    private val apiClient: ApiClient,
) : ViewModel() {

    private val _state = MutableStateFlow(ProductState())
    val state: StateFlow<ProductState> = _state.asStateFlow()

    private var searchJob: Job? = null

    init {
        loadCategories()
        loadProducts(reset = true)
    }

    private fun loadCategories() {
        viewModelScope.launch {
            val result = apiClient.get<List<CategoryDto>>(ApiConfig.CATEGORIES)
            if (result is ApiResult.Success) {
                _state.update { it.copy(categories = result.data.filter { c -> c.isActive }) }
            }
        }
    }

    fun loadProducts(reset: Boolean = false) {
        if (_state.value.isLoading || _state.value.isLoadingMore) return
        viewModelScope.launch {
            val currentState = _state.value
            val page = if (reset) 1 else currentState.page
            if (reset) {
                _state.update { it.copy(isLoading = true, page = 1, products = emptyList(), hasMore = true) }
            } else {
                if (!currentState.hasMore) return@launch
                _state.update { it.copy(isLoadingMore = true) }
            }

            val params = buildMap<String, String> {
                put("page", page.toString())
                put("pageSize", "20")
                put("includeInactive", "false")
                currentState.selectedCategoryId?.let { put("categoryId", it) }
            }

            val endpoint = if (currentState.searchQuery.isNotBlank()) {
                ApiConfig.PRODUCTS_SEARCH
            } else {
                ApiConfig.PRODUCTS
            }

            val allParams = if (currentState.searchQuery.isNotBlank()) {
                params + mapOf("q" to currentState.searchQuery)
            } else params

            val result = apiClient.get<PagedResult<ProductDto>>(endpoint, allParams)
            when (result) {
                is ApiResult.Success -> {
                    val newProducts = result.data.items
                    _state.update {
                        it.copy(
                            products = if (reset) newProducts else it.products + newProducts,
                            page = page + 1,
                            hasMore = page < result.data.totalPages,
                            isLoading = false,
                            isLoadingMore = false,
                        )
                    }
                }
                is ApiResult.Error -> {
                    _state.update { it.copy(isLoading = false, isLoadingMore = false, error = result.message) }
                }
            }
        }
    }

    fun selectCategory(categoryId: String?) {
        _state.update { it.copy(selectedCategoryId = categoryId, searchQuery = "") }
        loadProducts(reset = true)
    }

    fun search(query: String) {
        searchJob?.cancel()
        _state.update { it.copy(searchQuery = query) }
        searchJob = viewModelScope.launch {
            delay(300)
            loadProducts(reset = true)
        }
    }

    fun loadMore() {
        if (!_state.value.isLoadingMore && _state.value.hasMore) {
            loadProducts(reset = false)
        }
    }

    fun getProductById(id: String): Flow<ProductDto?> = flow {
        val result = apiClient.get<ProductDto>("${ApiConfig.PRODUCTS}/$id")
        emit(if (result is ApiResult.Success) result.data else null)
    }
}
