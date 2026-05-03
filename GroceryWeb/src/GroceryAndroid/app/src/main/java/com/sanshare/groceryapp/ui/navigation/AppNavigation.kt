package com.sanshare.groceryapp.ui.navigation

import androidx.compose.runtime.*
import androidx.compose.runtime.collectAsState
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavType
import androidx.navigation.compose.*
import androidx.navigation.navArgument
import com.sanshare.groceryapp.ui.screens.auth.LoginScreen
import com.sanshare.groceryapp.ui.screens.auth.RegisterScreen
import com.sanshare.groceryapp.ui.screens.auth.EmailVerificationScreen
import com.sanshare.groceryapp.ui.screens.main.MainScreen
import com.sanshare.groceryapp.ui.screens.splash.SplashScreen
import com.sanshare.groceryapp.ui.viewmodel.AuthViewModel

sealed class Screen(val route: String) {
    object Splash       : Screen("splash")
    object Login        : Screen("login")
    object Register     : Screen("register")
    object EmailVerify  : Screen("email_verify")
    object Main         : Screen("main")
    object Orders       : Screen("orders")
    object ProductDetail: Screen("product/{productId}") {
        fun createRoute(id: String) = "product/$id"
    }
    object OrderDetail  : Screen("order/{orderId}") {
        fun createRoute(id: String) = "order/$id"
    }
    object Checkout     : Screen("checkout")
    object Addresses    : Screen("addresses")
    object PaymentMethods: Screen("payment_methods")
    object Vouchers     : Screen("vouchers")
    object Search       : Screen("search")
}

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val authViewModel: AuthViewModel = hiltViewModel()
    val authState by authViewModel.state.collectAsState()

    NavHost(navController = navController, startDestination = Screen.Splash.route) {

        composable(Screen.Splash.route) {
            SplashScreen(
                onReady = { apiReachable ->
                    val dest = when {
                        authState.requiresEmailVerification -> Screen.EmailVerify.route
                        authState.isAuthenticated           -> Screen.Main.route
                        else                               -> Screen.Login.route
                    }
                    navController.navigate(dest) {
                        popUpTo(Screen.Splash.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Login.route) {
            LoginScreen(
                authViewModel = authViewModel,
                onLoginSuccess = {
                    navController.navigate(Screen.Main.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                },
                onNeedsVerification = {
                    navController.navigate(Screen.EmailVerify.route)
                },
                onNavigateToRegister = {
                    navController.navigate(Screen.Register.route)
                }
            )
        }

        composable(Screen.Register.route) {
            RegisterScreen(
                authViewModel = authViewModel,
                onSuccess = {
                    navController.navigate(Screen.Main.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                },
                onNeedsVerification = {
                    navController.navigate(Screen.EmailVerify.route)
                },
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.EmailVerify.route) {
            EmailVerificationScreen(
                authViewModel = authViewModel,
                onVerified = {
                    navController.navigate(Screen.Main.route) {
                        popUpTo(Screen.Login.route) { inclusive = true }
                    }
                },
                onBack = {
                    authViewModel.logout()
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.EmailVerify.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Main.route) {
            MainScreen(
                authViewModel = authViewModel,
                onLogout = {
                    navController.navigate(Screen.Login.route) {
                        popUpTo(Screen.Main.route) { inclusive = true }
                    }
                },
                onNavigateToProductDetail = { productId ->
                    navController.navigate(Screen.ProductDetail.createRoute(productId))
                },
                onNavigateToOrders = {
                    navController.navigate(Screen.Orders.route)
                },
                onNavigateToOrderDetail = { orderId ->
                    navController.navigate(Screen.OrderDetail.createRoute(orderId))
                },
                onNavigateToCheckout = {
                    navController.navigate(Screen.Checkout.route)
                },
                onNavigateToAddresses = {
                    navController.navigate(Screen.Addresses.route)
                },
                onNavigateToPaymentMethods = {
                    navController.navigate(Screen.PaymentMethods.route)
                },
                onNavigateToVouchers = {
                    navController.navigate(Screen.Vouchers.route)
                },
                onNavigateToSearch = {
                    navController.navigate(Screen.Search.route)
                }
            )
        }

        composable(Screen.Orders.route) {
            com.sanshare.groceryapp.ui.screens.orders.OrdersScreen(
                onBack = { navController.popBackStack() },
                onOrderClick = { orderId ->
                    navController.navigate(Screen.OrderDetail.createRoute(orderId))
                }
            )
        }

        composable(
            Screen.ProductDetail.route,
            arguments = listOf(navArgument("productId") { type = NavType.StringType })
        ) { backStack ->
            val productId = backStack.arguments?.getString("productId") ?: return@composable
            com.sanshare.groceryapp.ui.screens.product.ProductDetailScreen(
                productId = productId,
                onBack = { navController.popBackStack() },
                onNavigateToCart = { navController.navigate(Screen.Main.route) }
            )
        }

        composable(
            Screen.OrderDetail.route,
            arguments = listOf(navArgument("orderId") { type = NavType.StringType })
        ) { backStack ->
            val orderId = backStack.arguments?.getString("orderId") ?: return@composable
            com.sanshare.groceryapp.ui.screens.orders.OrderDetailScreen(
                orderId = orderId,
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Checkout.route) {
            com.sanshare.groceryapp.ui.screens.checkout.CheckoutScreen(
                onBack = { navController.popBackStack() },
                onOrderPlaced = { orderId ->
                    navController.navigate(Screen.OrderDetail.createRoute(orderId)) {
                        popUpTo(Screen.Checkout.route) { inclusive = true }
                    }
                }
            )
        }

        composable(Screen.Addresses.route) {
            com.sanshare.groceryapp.ui.screens.profile.AddressListScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.PaymentMethods.route) {
            com.sanshare.groceryapp.ui.screens.profile.PaymentMethodsScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Vouchers.route) {
            com.sanshare.groceryapp.ui.screens.profile.VouchersScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Search.route) {
            com.sanshare.groceryapp.ui.screens.search.SearchScreen(
                onBack = { navController.popBackStack() },
                onProductClick = { productId ->
                    navController.navigate(Screen.ProductDetail.createRoute(productId))
                }
            )
        }
    }
}
