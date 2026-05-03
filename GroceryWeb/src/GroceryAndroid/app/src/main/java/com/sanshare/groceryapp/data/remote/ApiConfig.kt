package com.sanshare.groceryapp.data.remote

object ApiConfig {
    // Change to your server IP/hostname
    // For emulator: "http://10.0.2.2:5000" (maps to localhost on host machine)
    // For physical device: "http://192.168.7.136:5000" or your server IP
    const val BASE_URL = "http://127.0.0.1:5000"

    // Endpoints
    const val AUTH_LOGIN           = "/api/auth/login"
    const val AUTH_REGISTER        = "/api/auth/register"
    const val AUTH_VERIFY_EMAIL    = "/api/auth/verify-email"
    const val AUTH_VERIFY_PHONE    = "/api/auth/verify-phone"
    const val AUTH_SEND_EMAIL_CODE = "/api/auth/send-email-code"
    const val AUTH_SEND_PHONE_CODE = "/api/auth/send-phone-code"
    const val AUTH_ME              = "/api/auth/me"

    const val CATEGORIES           = "/api/categories"
    const val PRODUCTS             = "/api/products"
    const val PRODUCTS_SEARCH      = "/api/products/search"
    const val TODAY_DEALS          = "/api/today-deals"
    const val SPECIAL_OFFERS       = "/api/special-offers"

    const val CART                 = "/api/cart"
    const val ORDERS               = "/api/orders"
    const val ADDRESSES            = "/api/addresses"
    const val FAVORITES            = "/api/favorites"
    const val VOUCHERS_USER        = "/api/vouchers/user"
    const val VOUCHERS_APPLY       = "/api/vouchers/apply"
    const val PAYMENT_METHODS      = "/api/payment-methods"
    const val PAYMENTS_CHECKOUT    = "/api/payments/checkout"
    const val NOTIFICATIONS        = "/api/notifications"
    const val HEALTH               = "/api/health"
}
