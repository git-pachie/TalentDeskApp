package com.sanshare.groceryapp.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sanshare.groceryapp.data.remote.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CartItem(
    val serverId: String?,
    val productId: String,
    val productName: String,
    val productImageUrl: String?,
    val unitPrice: Double,
    var quantity: Int,
    var remarks: String = "",
)

data class CartState(
    val items: List<CartItem> = emptyList(),
    val isLoading: Boolean = false,
)

data class CartNotice(
    val message: String,
    val isError: Boolean = false,
)

@HiltViewModel
class CartViewModel @Inject constructor(
    private val apiClient: ApiClient,
) : ViewModel() {

    private val _state = MutableStateFlow(CartState())
    val state: StateFlow<CartState> = _state.asStateFlow()
    private val _notices = MutableSharedFlow<CartNotice>(extraBufferCapacity = 1)
    val notices = _notices.asSharedFlow()

    val totalItems: Int get() = _state.value.items.sumOf { it.quantity }
    val totalPrice: Double get() = _state.value.items.sumOf { it.unitPrice * it.quantity }

    fun loadFromServer() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            val result = apiClient.get<List<CartItemDto>>(ApiConfig.CART)
            if (result is ApiResult.Success) {
                val items = result.data.map { dto ->
                    CartItem(
                        serverId = dto.id,
                        productId = dto.productId,
                        productName = dto.productName,
                        productImageUrl = dto.productImageFullUrl ?: dto.productImageUrl,
                        unitPrice = dto.unitPrice,
                        quantity = dto.quantity,
                        remarks = dto.remarks ?: "",
                    )
                }
                _state.update { it.copy(items = items, isLoading = false) }
            } else {
                _state.update { it.copy(isLoading = false) }
            }
        }
    }

    fun addProduct(productId: String, productName: String, imageUrl: String?, price: Double, quantity: Int = 1) {
        val existing = _state.value.items.indexOfFirst { it.productId == productId }
        if (existing >= 0) {
            val newQty = _state.value.items[existing].quantity + quantity
            updateQuantity(productId, newQty)
            _notices.tryEmit(CartNotice("$productName quantity updated"))
        } else {
            val newItem = CartItem(
                serverId = null,
                productId = productId,
                productName = productName,
                productImageUrl = imageUrl,
                unitPrice = price,
                quantity = quantity,
            )
            _state.update { it.copy(items = it.items + newItem) }
            viewModelScope.launch {
                val result = apiClient.post<AddToCartRequest, CartItemDto>(
                    ApiConfig.CART,
                    AddToCartRequest(productId = productId, quantity = quantity)
                )
                if (result is ApiResult.Success) {
                    val idx = _state.value.items.indexOfFirst { it.productId == productId }
                    if (idx >= 0) {
                        val updated = _state.value.items.toMutableList()
                        updated[idx] = updated[idx].copy(serverId = result.data.id)
                        _state.update { it.copy(items = updated) }
                    }
                    _notices.tryEmit(CartNotice("$productName added to cart"))
                } else if (result is ApiResult.Error) {
                    _state.update { it.copy(items = it.items.filter { cartItem -> cartItem.productId != productId }) }
                    _notices.tryEmit(CartNotice(result.message.ifBlank { "Failed to add item to cart" }, isError = true))
                }
            }
        }
    }

    fun updateQuantity(productId: String, quantity: Int) {
        val idx = _state.value.items.indexOfFirst { it.productId == productId }
        if (idx < 0) return
        if (quantity <= 0) {
            removeProduct(productId)
            return
        }
        val previousQuantity = _state.value.items[idx].quantity
        val updated = _state.value.items.toMutableList()
        val item = updated[idx].copy(quantity = quantity)
        updated[idx] = item
        _state.update { it.copy(items = updated) }
        item.serverId?.let { serverId ->
            viewModelScope.launch {
                val result = apiClient.put<UpdateCartItemRequest, CartItemDto>(
                    "${ApiConfig.CART}/$serverId",
                    UpdateCartItemRequest(quantity = quantity, remarks = item.remarks)
                )
                if (result is ApiResult.Error) {
                    val reverted = _state.value.items.toMutableList()
                    val revertIdx = reverted.indexOfFirst { it.productId == productId }
                    if (revertIdx >= 0) {
                        reverted[revertIdx] = reverted[revertIdx].copy(quantity = previousQuantity)
                        _state.update { it.copy(items = reverted) }
                    }
                    _notices.tryEmit(CartNotice(result.message.ifBlank { "Failed to update cart" }, isError = true))
                }
            }
        }
    }

    fun updateRemarks(productId: String, remarks: String) {
        val idx = _state.value.items.indexOfFirst { it.productId == productId }
        if (idx < 0) return
        val updated = _state.value.items.toMutableList()
        val item = updated[idx].copy(remarks = remarks)
        updated[idx] = item
        _state.update { it.copy(items = updated) }
        item.serverId?.let { serverId ->
            viewModelScope.launch {
                apiClient.put<UpdateCartItemRequest, CartItemDto>(
                    "${ApiConfig.CART}/$serverId",
                    UpdateCartItemRequest(quantity = item.quantity, remarks = remarks)
                )
            }
        }
    }

    fun removeProduct(productId: String) {
        val item = _state.value.items.firstOrNull { it.productId == productId }
        _state.update { it.copy(items = it.items.filter { i -> i.productId != productId }) }
        item?.serverId?.let { serverId ->
            viewModelScope.launch { apiClient.delete("${ApiConfig.CART}/$serverId") }
        }
    }

    fun clearCart() {
        _state.update { it.copy(items = emptyList()) }
    }

    fun isInCart(productId: String): Boolean =
        _state.value.items.any { it.productId == productId }

    fun quantityInCart(productId: String): Int =
        _state.value.items.firstOrNull { it.productId == productId }?.quantity ?: 0
}
