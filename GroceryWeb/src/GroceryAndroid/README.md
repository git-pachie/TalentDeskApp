# GroceryApp Android

Android replica of the GroceryApp iOS app, built with Kotlin + Jetpack Compose.

## Tech Stack
- **Language**: Kotlin
- **UI**: Jetpack Compose + Material 3
- **DI**: Hilt
- **HTTP**: Ktor Client
- **Images**: Coil
- **Navigation**: Navigation Compose
- **State**: ViewModel + StateFlow
- **Storage**: DataStore + EncryptedSharedPreferences (JWT)
- **Maps**: Google Maps Compose

## Project Structure
```
app/src/main/java/com/sanshare/groceryapp/
├── data/
│   ├── remote/          # ApiClient, ApiModels, ApiConfig
│   └── local/           # TokenManager, UserPreferences
├── di/                  # Hilt modules
├── ui/
│   ├── theme/           # GroceryAppTheme, colors, typography
│   ├── navigation/      # AppNavigation, Screen routes
│   ├── components/      # Shared composables (ProductCard, etc.)
│   ├── viewmodel/       # AuthViewModel, CartViewModel, etc.
│   └── screens/
│       ├── splash/      # SplashScreen
│       ├── auth/        # LoginScreen, RegisterScreen, EmailVerificationScreen
│       ├── main/        # MainScreen (bottom nav host)
│       ├── home/        # HomeScreen
│       ├── product/     # ProductsScreen, ProductDetailScreen
│       ├── cart/        # CartScreen
│       ├── checkout/    # CheckoutScreen
│       ├── orders/      # OrdersScreen, OrderDetailScreen
│       ├── favorites/   # FavoritesScreen
│       ├── search/      # SearchScreen
│       └── profile/     # ProfileScreen, AddressListScreen,
│                          PaymentMethodsScreen, VouchersScreen
```

## Setup

1. Open in Android Studio (Hedgehog or newer)
2. Update `ApiConfig.BASE_URL` in `data/remote/ApiConfig.kt`:
   - Emulator: `http://10.0.2.2:5000`
   - Physical device: `http://192.168.7.136:5000`
3. Add your Google Maps API key in `AndroidManifest.xml`
4. Run the API: `dotnet run --project GroceryWeb/src/GroceryApp.API`
5. Press ▶ in Android Studio

## Features
- ✅ Login / Register / Email Verification
- ✅ Home: Special Offers carousel, Categories, Today's Deals
- ✅ Products: Search, category filter, pagination
- ✅ Product Detail: Image gallery, quantity selector, add to cart
- ✅ Cart: Quantity controls, item remarks, checkout validation
- ✅ Checkout: Address, payment method, voucher, delivery schedule
- ✅ Orders: Current/History tabs, status timeline
- ✅ Order Detail: Items, address, payment, delivery schedule, review
- ✅ Favorites: Toggle, sync with server
- ✅ Profile: Verification status, addresses, payment methods, vouchers
- ✅ Dark mode support
- ✅ JWT authentication with auto-logout on 401
