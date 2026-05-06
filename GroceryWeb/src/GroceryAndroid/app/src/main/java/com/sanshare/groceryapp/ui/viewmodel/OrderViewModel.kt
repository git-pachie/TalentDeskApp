package com.sanshare.groceryapp.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sanshare.groceryapp.data.remote.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class OrdersState(
    val orders: List<OrderDto> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
)

data class CheckoutState(
    val addresses: List<AddressDto> = emptyList(),
    val selectedAddressId: String? = null,
    val paymentMethod: String = "Cash on Delivery",
    val cardHolderName: String = "",
    val cardNumber: String = "",
    val cardExpiry: String = "",
    val cardCvv: String = "",
    val vouchers: List<VoucherDto> = emptyList(),
    val appliedVoucher: VoucherDto? = null,
    val voucherDiscount: Double = 0.0,
    val orderRemarks: String = "",
    val deliveryDate: String = "",   // "yyyy-MM-dd"
    val deliveryTimeSlot: String = "Anytime",
    val isPlacingOrder: Boolean = false,
    val isValidatingCheckout: Boolean = false,
    val orderPlaced: Boolean = false,
    val placedOrder: OrderDto? = null,
    val error: String? = null,
    val verificationError: String? = null,
    val voucherError: String? = null,
)

@HiltViewModel
class OrderViewModel @Inject constructor(
    private val apiClient: ApiClient,
) : ViewModel() {

    private val _ordersState = MutableStateFlow(OrdersState())
    val ordersState: StateFlow<OrdersState> = _ordersState.asStateFlow()

    private val _checkoutState = MutableStateFlow(CheckoutState())
    val checkoutState: StateFlow<CheckoutState> = _checkoutState.asStateFlow()

    // ── Orders ────────────────────────────────────────────────────────────────

    fun loadOrders() {
        viewModelScope.launch {
            _ordersState.update { it.copy(isLoading = true, error = null) }
            val result = apiClient.get<List<OrderDto>>(ApiConfig.ORDERS)
            when (result) {
                is ApiResult.Success -> _ordersState.update { it.copy(orders = result.data, isLoading = false) }
                is ApiResult.Error -> _ordersState.update { it.copy(isLoading = false, error = result.message) }
            }
        }
    }

    fun getOrderDetail(orderId: String): Flow<OrderDto?> = flow {
        val result = apiClient.get<OrderDto>("${ApiConfig.ORDERS}/$orderId")
        emit(if (result is ApiResult.Success) result.data else null)
    }

    suspend fun submitReview(orderId: String, productId: String, rating: Int, comment: String, photos: List<ByteArray> = emptyList()): Boolean {
        val photoUrls = if (photos.isNotEmpty()) {
            when (val upload = apiClient.uploadReviewPhotos(photos)) {
                is ApiResult.Success -> upload.data
                is ApiResult.Error -> return false
            }
        } else emptyList()

        val result = apiClient.post<CreateReviewRequest, Any>(
            "/api/reviews",
            CreateReviewRequest(
                productId = productId,
                orderId = orderId,
                rating = rating,
                comment = comment.ifBlank { null },
                photoUrls = photoUrls.ifEmpty { null },
            )
        )
        return result is ApiResult.Success
    }

    // ── Checkout ──────────────────────────────────────────────────────────────

    fun initCheckout() {
        viewModelScope.launch {
            loadCheckoutAddresses()
            loadVouchers()
            // Default delivery date = tomorrow
            val cal = java.util.Calendar.getInstance()
            cal.add(java.util.Calendar.DAY_OF_YEAR, 1)
            val sdf = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
            _checkoutState.update { it.copy(deliveryDate = sdf.format(cal.time)) }
        }
    }

    private suspend fun loadCheckoutAddresses() {
        val result = apiClient.get<List<AddressDto>>(ApiConfig.ADDRESSES)
        if (result is ApiResult.Success) {
            val addresses = result.data
            val defaultId = addresses.firstOrNull { it.isDefault }?.id ?: addresses.firstOrNull()?.id
            _checkoutState.update { it.copy(addresses = addresses, selectedAddressId = defaultId) }
        }
    }

    private suspend fun loadVouchers() {
        val result = apiClient.get<List<VoucherDto>>(ApiConfig.VOUCHERS_USER)
        if (result is ApiResult.Success) {
            _checkoutState.update { it.copy(vouchers = result.data.filter { v -> v.isActive }) }
        }
    }

    fun selectAddress(id: String) {
        _checkoutState.update { it.copy(selectedAddressId = id) }
    }

    fun selectPaymentMethod(method: String) {
        _checkoutState.update { it.copy(paymentMethod = method) }
    }

    fun setCardHolderName(name: String) {
        _checkoutState.update { it.copy(cardHolderName = name) }
    }

    fun setCardNumber(number: String) {
        _checkoutState.update { it.copy(cardNumber = number) }
    }

    fun setCardExpiry(expiry: String) {
        _checkoutState.update { it.copy(cardExpiry = expiry) }
    }

    fun setCardCvv(cvv: String) {
        _checkoutState.update { it.copy(cardCvv = cvv) }
    }

    fun setOrderRemarks(remarks: String) {
        _checkoutState.update { it.copy(orderRemarks = remarks) }
    }

    fun setDeliveryDate(date: String) {
        _checkoutState.update { it.copy(deliveryDate = date) }
    }

    fun setDeliveryTimeSlot(slot: String) {
        _checkoutState.update { it.copy(deliveryTimeSlot = slot) }
    }

    fun applyVoucher(voucher: VoucherDto, cartTotal: Double) {
        viewModelScope.launch {
            val result = apiClient.post<ApplyVoucherRequest, VoucherValidationResult>(
                ApiConfig.VOUCHERS_APPLY,
                ApplyVoucherRequest(code = voucher.code, cartTotal = cartTotal)
            )
            if (result is ApiResult.Success) {
                if (result.data.isValid) {
                    _checkoutState.update {
                        it.copy(appliedVoucher = voucher, voucherDiscount = result.data.discountAmount, voucherError = null)
                    }
                } else {
                    _checkoutState.update {
                        it.copy(voucherError = "Unable to use this voucher. Please check the applicable terms and conditions.")
                    }
                }
            } else if (result is ApiResult.Error) {
                _checkoutState.update {
                    it.copy(voucherError = "Unable to use this voucher. Please check the applicable terms and conditions.")
                }
            }
        }
    }

    fun clearVoucherError() {
        _checkoutState.update { it.copy(voucherError = null) }
    }

    fun removeVoucher() {
        _checkoutState.update { it.copy(appliedVoucher = null, voucherDiscount = 0.0) }
    }

    fun validateAndPlaceOrder(cartTotal: Double, onSuccess: (OrderDto) -> Unit) {
        viewModelScope.launch {
            _checkoutState.update { it.copy(isValidatingCheckout = true, verificationError = null) }
            val paymentValidationMessage = validatePaymentDetails(_checkoutState.value)
            if (paymentValidationMessage != null) {
                _checkoutState.update {
                    it.copy(
                        isValidatingCheckout = false,
                        error = paymentValidationMessage,
                    )
                }
                return@launch
            }

            // Validate email & phone verification
            val userResult = apiClient.get<com.sanshare.groceryapp.data.remote.UserDto>(ApiConfig.AUTH_ME)
            if (userResult is ApiResult.Success) {
                val user = userResult.data
                val emailVerified = user.isEmailVerified ?: false
                val phoneVerified = user.isPhoneVerified ?: false
                if (!emailVerified && !phoneVerified) {
                    _checkoutState.update {
                        it.copy(
                            isValidatingCheckout = false,
                            verificationError = "Your email address and mobile number are not yet verified. Please verify both before placing an order.",
                        )
                    }
                    return@launch
                }
                if (!emailVerified) {
                    _checkoutState.update {
                        it.copy(
                            isValidatingCheckout = false,
                            verificationError = "Your email address is not yet verified. Please verify your email before placing an order.",
                        )
                    }
                    return@launch
                }
                if (!phoneVerified) {
                    _checkoutState.update {
                        it.copy(
                            isValidatingCheckout = false,
                            verificationError = "Your mobile number is not yet verified. Please verify your mobile number before placing an order.",
                        )
                    }
                    return@launch
                }
            }

            _checkoutState.update { it.copy(isValidatingCheckout = false, isPlacingOrder = true) }
            placeOrder(onSuccess)
        }
    }

    private suspend fun placeOrder(onSuccess: (OrderDto) -> Unit) {
        val cs = _checkoutState.value
        val timeSlot = if (cs.deliveryTimeSlot == "Anytime") null else cs.deliveryTimeSlot

        val result = apiClient.post<CreateOrderRequest, OrderDto>(
            ApiConfig.ORDERS,
            CreateOrderRequest(
                addressId = cs.selectedAddressId,
                voucherCode = cs.appliedVoucher?.code,
                notes = cs.orderRemarks.ifBlank { null },
                deliveryDate = cs.deliveryDate.ifBlank { null },
                deliveryTimeSlot = timeSlot,
                platformFee = 2.0,
                otherCharges = 1.0,
            )
        )
        when (result) {
            is ApiResult.Success -> {
                val order = result.data
                // Record payment
                val paymentMethod = when (cs.paymentMethod) {
                    "Cash on Delivery" -> 4
                    else -> 4
                }
                apiClient.post<CheckoutPaymentRequest, PaymentResultDto>(
                    ApiConfig.PAYMENTS_CHECKOUT,
                    CheckoutPaymentRequest(orderId = order.id, method = paymentMethod)
                )
                _checkoutState.update { it.copy(isPlacingOrder = false, orderPlaced = true, placedOrder = order) }
                onSuccess(order)
            }
            is ApiResult.Error -> {
                _checkoutState.update { it.copy(isPlacingOrder = false, error = result.message) }
            }
        }
    }

    fun clearCheckoutError() {
        _checkoutState.update { it.copy(error = null, verificationError = null, voucherError = null) }
    }

    fun resetCheckout() {
        _checkoutState.update { CheckoutState() }
    }

    private fun validatePaymentDetails(state: CheckoutState): String? {
        return null
    }

    private fun isValidExpiry(expiry: String): Boolean {
        val parts = expiry.split("/")
        if (parts.size != 2) return false
        val month = parts[0].toIntOrNull() ?: return false
        val year = parts[1].toIntOrNull() ?: return false
        if (month !in 1..12) return false

        val now = java.util.Calendar.getInstance()
        val currentYear = now.get(java.util.Calendar.YEAR) % 100
        val currentMonth = now.get(java.util.Calendar.MONTH) + 1
        if (year < currentYear) return false
        if (year == currentYear && month < currentMonth) return false
        return true
    }
}
