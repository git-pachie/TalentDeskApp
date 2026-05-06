package com.sanshare.groceryapp.data.remote

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.net.URI

// ── Auth ──────────────────────────────────────────────────────────────────────

@Serializable
data class LoginRequest(
    val email: String,
    val password: String,
    val deviceGuid: String? = null,
    val osVersion: String? = null,
    val hardwareVersion: String? = null,
)

@Serializable
data class RegisterRequest(
    val firstName: String,
    val lastName: String,
    val email: String,
    val password: String,
    val phoneNumber: String? = null,
    val deviceGuid: String? = null,
    val osVersion: String? = null,
    val hardwareVersion: String? = null,
)

@Serializable
data class AuthResponse(
    val success: Boolean,
    val token: String? = null,
    val expiresAt: String? = null,
    val user: UserDto? = null,
    val errors: List<String>? = null,
    val requiresEmailVerification: Boolean? = null,
)

@Serializable
data class VerifyEmailRequest(val email: String, val code: String)

@Serializable
data class VerifyEmailResponse(
    val success: Boolean,
    val token: String? = null,
    val error: String? = null,
)

@Serializable
data class VerifyPhoneRequest(val code: String)

@Serializable
data class VerifyPhoneResponse(val success: Boolean, val error: String? = null)

@Serializable
class EmptyRequest

@Serializable
data class SimpleMessageResponse(val message: String? = null)

@Serializable
data class UserDto(
    val id: String,
    val firstName: String,
    val lastName: String,
    val email: String,
    val phoneNumber: String? = null,
    val profileImageUrl: String? = null,
    val roles: List<String>? = null,
    val isEmailVerified: Boolean? = null,
    val isPhoneVerified: Boolean? = null,
) {
    val fullName: String get() = "$firstName $lastName".trim().ifEmpty { email }
}

// ── Categories ────────────────────────────────────────────────────────────────

@Serializable
data class CategoryDto(
    val id: String,
    val name: String,
    val description: String? = null,
    val imageUrl: String? = null,
    val emoji: String? = null,
    val isActive: Boolean = true,
    val productCount: Int = 0,
)

// ── Products ──────────────────────────────────────────────────────────────────

@Serializable
data class ProductDto(
    val id: String,
    val name: String,
    val description: String? = null,
    val price: Double,
    val discountPrice: Double? = null,
    val stockQuantity: Int = 0,
    val unit: String? = null,
    val isActive: Boolean = true,
    val categoryId: String,
    val categoryName: String,
    val categories: List<ProductCategoryDto>? = null,
    val images: List<ProductImageDto> = emptyList(),
    val averageRating: Double = 0.0,
    val reviewCount: Int = 0,
    val createdAt: String? = null,
) {
    val displayPrice: Double get() = discountPrice ?: price
    val primaryImageUrl: String? get() = resolveApiUrl(
        images.firstOrNull { it.isPrimary }?.displayUrl
            ?: images.firstOrNull()?.displayUrl
    )
    val discountPercent: Int? get() {
        if (discountPrice == null || discountPrice >= price) return null
        return ((price - discountPrice) / price * 100).toInt()
    }
}

@Serializable
data class ProductCategoryDto(val id: String, val name: String)

@Serializable
data class ProductImageDto(
    val id: String,
    val imageUrl: String,
    val fullUrl: String? = null,
    val isPrimary: Boolean = false,
    val sortOrder: Int = 0,
    val dateCreated: String? = null,
    val dateModified: String? = null,
) {
    val displayUrl: String get() = resolveApiUrl(fullUrl ?: imageUrl) ?: imageUrl
}

private fun resolveApiUrl(url: String?): String? {
    if (url.isNullOrBlank()) return null
    if (url.startsWith("http", ignoreCase = true)) return rebuildUsingBaseUrl(url)
    val normalizedBase = ApiConfig.BASE_URL.trimEnd('/')
    val normalizedPath = if (url.startsWith("/")) url else "/$url"
    return "$normalizedBase$normalizedPath"
}

private fun rebuildUsingBaseUrl(url: String): String {
    return try {
        val source = URI(url)
        val path = source.path.orEmpty()
        val normalizedPath = when {
            path.contains("/uploads/products/", ignoreCase = true) ->
                path.substringAfter("/uploads/products/").substringBefore("?")
            path.contains("/products/", ignoreCase = true) ->
                path.substringAfter("/products/").substringBefore("?")
            else -> path.substringAfterLast('/').substringBefore("?")
        }.trimStart('/')

        if (normalizedPath.isBlank()) url
        else "${ApiConfig.BASE_URL.trimEnd('/')}/uploads/products/$normalizedPath"
    } catch (_: Exception) {
        url
    }
}

@Serializable
data class PagedResult<T>(
    val items: List<T>,
    val totalCount: Int,
    val page: Int,
    val pageSize: Int,
    val totalPages: Int,
)

// ── Cart ──────────────────────────────────────────────────────────────────────

@Serializable
data class CartItemDto(
    val id: String,
    val productId: String,
    val productName: String,
    val productImageUrl: String? = null,
    val productImageFullUrl: String? = null,
    val productImageDateModified: String? = null,
    val unitPrice: Double,
    val quantity: Int,
    val totalPrice: Double,
    val remarks: String? = null,
)

@Serializable
data class AddToCartRequest(
    val productId: String,
    val quantity: Int,
    val remarks: String? = null,
)

@Serializable
data class UpdateCartItemRequest(
    val quantity: Int,
    val remarks: String? = null,
)

// ── Orders ────────────────────────────────────────────────────────────────────

@Serializable
data class OrderDto(
    val id: String,
    val orderNumber: String,
    val subTotal: Double,
    val discountAmount: Double = 0.0,
    val deliveryFee: Double = 0.0,
    val platformFee: Double? = null,
    val otherCharges: Double? = null,
    val totalAmount: Double,
    val status: String,
    val notes: String? = null,
    val voucherCode: String? = null,
    val createdAt: String,
    val deliveryDate: String? = null,
    val deliveryTimeSlot: String? = null,
    val riderId: String? = null,
    val riderName: String? = null,
    val riderContact: String? = null,
    val riderImageUrl: String? = null,
    val actualDeliveryDate: String? = null,
    val items: List<OrderItemDto>? = null,
    val payment: PaymentSummaryDto? = null,
    val address: OrderAddressDto? = null,
    val statusHistory: List<OrderStatusHistoryDto>? = null,
    val reviews: List<OrderReviewDto>? = null,
)

@Serializable
data class OrderItemDto(
    val productId: String,
    val productName: String,
    val productImageUrl: String? = null,
    val productImageDateModified: String? = null,
    val unitPrice: Double,
    val quantity: Int,
    val totalPrice: Double,
    val remarks: String? = null,
)

@Serializable
data class PaymentSummaryDto(
    val method: String,
    val status: String,
    val paidAt: String? = null,
)

@Serializable
data class OrderAddressDto(
    val label: String,
    val street: String,
    val city: String,
    val province: String,
    val zipCode: String,
    val deliveryInstructions: String? = null,
    val contactNumber: String? = null,
) {
    val fullAddress: String get() = listOf(street, city, province, zipCode)
        .filter { it.isNotBlank() }.joinToString(", ")
}

@Serializable
data class OrderStatusHistoryDto(
    val status: String,
    val notes: String? = null,
    val createdBy: String,
    val createdAt: String,
)

@Serializable
data class OrderReviewDto(
    val id: String,
    val userName: String,
    val productName: String,
    val rating: Int,
    val comment: String? = null,
    val createdAt: String,
    val photos: List<OrderReviewPhotoDto>? = null,
)

@Serializable
data class OrderReviewPhotoDto(
    val id: String,
    val photoUrl: String,
    val sortOrder: Int = 0,
)

@Serializable
data class CreateOrderRequest(
    val addressId: String? = null,
    val voucherCode: String? = null,
    val notes: String? = null,
    val deliveryDate: String? = null,   // "yyyy-MM-dd" plain string
    val deliveryTimeSlot: String? = null,
    val platformFee: Double = 2.0,
    val otherCharges: Double = 1.0,
)

// ── Addresses ─────────────────────────────────────────────────────────────────

@Serializable
data class AddressDto(
    val id: String,
    val label: String,
    val street: String,
    val city: String,
    val province: String,
    val zipCode: String,
    val country: String? = null,
    val deliveryInstructions: String? = null,
    val contactNumber: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val isDefault: Boolean = false,
) {
    val fullAddress: String get() = listOf(street, city, province, zipCode)
        .filter { it.isNotBlank() }.joinToString(", ")
}

@Serializable
data class CreateAddressRequest(
    val label: String,
    val street: String,
    val city: String,
    val province: String,
    val zipCode: String,
    val country: String? = "Philippines",
    val deliveryInstructions: String? = null,
    val contactNumber: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val isDefault: Boolean = false,
)

@Serializable
data class UpdateAddressRequest(
    val label: String? = null,
    val street: String? = null,
    val city: String? = null,
    val province: String? = null,
    val zipCode: String? = null,
    val country: String? = null,
    val deliveryInstructions: String? = null,
    val contactNumber: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val isDefault: Boolean? = null,
)

// ── Favorites ─────────────────────────────────────────────────────────────────

@Serializable
data class FavoriteDto(
    val id: String? = null,
    val productId: String,
    val productName: String? = null,
    val price: Double? = null,
    val discountPrice: Double? = null,
    val imageUrl: String? = null,
    val addedAt: String? = null,
    val product: ProductDto? = null,
)

// ── Payment Methods ───────────────────────────────────────────────────────────

@Serializable
data class PaymentMethodDto(
    val id: String,
    val name: String,
    val detail: String? = null,
    val paymentType: String,
    val icon: String? = null,
    val isDefault: Boolean = false,
    val createdAt: String? = null,
)

@Serializable
data class CreatePaymentMethodRequest(
    val name: String,
    val detail: String? = null,
    val paymentType: String,
    val icon: String? = null,
    val isDefault: Boolean = false,
)

// ── Vouchers ──────────────────────────────────────────────────────────────────

@Serializable
data class VoucherDto(
    val id: String,
    val code: String,
    val description: String? = null,
    val type: String,
    val value: Double,
    val maxDiscount: Double? = null,
    val minimumSpend: Double,
    val usageLimit: Int,
    val usedCount: Int,
    val isActive: Boolean,
    val startDate: String? = null,
    val expiryDate: String,
)

@Serializable
data class ApplyVoucherRequest(val code: String, val cartTotal: Double)

@Serializable
data class VoucherValidationResult(
    val isValid: Boolean,
    val errorMessage: String? = null,
    val discountAmount: Double = 0.0,
    val voucher: VoucherDto? = null,
)

// ── Payments ──────────────────────────────────────────────────────────────────

@Serializable
data class CheckoutPaymentRequest(
    val orderId: String,
    val method: Int,   // 4=COD
    val stripeToken: String? = null,
    val returnUrl: String? = null,
)

@Serializable
data class PaymentResultDto(
    val success: Boolean,
    val paymentId: String,
    val status: String,
    val redirectUrl: String? = null,
    val failureReason: String? = null,
)

// ── Special Offers ────────────────────────────────────────────────────────────

@Serializable
data class SpecialOfferDto(
    val id: String,
    val categoryId: String? = null,
    val title: String,
    val subtitle: String,
    val emoji: String,
    val imageUrl: String? = null,
    val backgroundColorHex: String,
    val sortOrder: Int = 0,
    val isActive: Boolean = true,
)

@Serializable
data class TodayDealDto(
    val id: String,
    val productId: String,
    val sortOrder: Int = 0,
    val isActive: Boolean = true,
    val product: ProductDto,
)

// ── Notifications ─────────────────────────────────────────────────────────────

@Serializable
data class NotificationDto(
    val id: String,
    val title: String,
    val message: String,
    val type: String? = null,
    val referenceId: String? = null,
    val isRead: Boolean = false,
    val createdAt: String,
)

// ── Create Review ─────────────────────────────────────────────────────────────

@Serializable
data class CreateReviewRequest(
    val productId: String,
    val orderId: String,
    val rating: Int,
    val comment: String? = null,
    val photoUrls: List<String>? = null,
)

@Serializable
data class UploadReviewPhotosResponse(
    val urls: List<String>,
)
