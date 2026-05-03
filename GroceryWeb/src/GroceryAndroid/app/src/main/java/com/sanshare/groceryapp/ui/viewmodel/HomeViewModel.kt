package com.sanshare.groceryapp.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sanshare.groceryapp.data.remote.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeState(
    val categories: List<CategoryDto> = emptyList(),
    val deals: List<ProductDto> = emptyList(),
    val specialOffers: List<SpecialOfferDto> = emptyList(),
    val addresses: List<AddressDto> = emptyList(),
    val selectedAddressIndex: Int = 0,
    val isLoading: Boolean = false,
    val error: String? = null,
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val apiClient: ApiClient,
) : ViewModel() {

    private val _state = MutableStateFlow(HomeState())
    val state: StateFlow<HomeState> = _state.asStateFlow()

    init {
        loadHome()
    }

    fun loadHome() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            loadCategories()
            loadDeals()
            loadSpecialOffers()
            loadAddresses()
            _state.update { it.copy(isLoading = false) }
        }
    }

    private suspend fun loadCategories() {
        val result = apiClient.get<List<CategoryDto>>(ApiConfig.CATEGORIES)
        if (result is ApiResult.Success) {
            _state.update { it.copy(categories = result.data.filter { c -> c.isActive }) }
        }
    }

    private suspend fun loadDeals() {
        val result = apiClient.get<List<TodayDealDto>>(ApiConfig.TODAY_DEALS)
        if (result is ApiResult.Success) {
            _state.update { it.copy(deals = result.data.filter { d -> d.isActive }.map { it.product }) }
        }
    }

    private suspend fun loadSpecialOffers() {
        val result = apiClient.get<List<SpecialOfferDto>>(ApiConfig.SPECIAL_OFFERS)
        if (result is ApiResult.Success) {
            _state.update {
                it.copy(specialOffers = result.data.filter { o -> o.isActive }.sortedBy { o -> o.sortOrder })
            }
        }
    }

    private suspend fun loadAddresses() {
        val result = apiClient.get<List<AddressDto>>(ApiConfig.ADDRESSES)
        if (result is ApiResult.Success) {
            val addresses = result.data
            val defaultIdx = addresses.indexOfFirst { it.isDefault }.takeIf { it >= 0 } ?: 0
            _state.update { it.copy(addresses = addresses, selectedAddressIndex = defaultIdx) }
        }
    }

    fun selectAddress(index: Int) {
        _state.update { it.copy(selectedAddressIndex = index) }
    }
}
