package com.sanshare.groceryapp.ui.screens.main

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sanshare.groceryapp.ui.screens.cart.CartScreen
import com.sanshare.groceryapp.ui.screens.favorites.FavoritesScreen
import com.sanshare.groceryapp.ui.screens.home.HomeScreen
import com.sanshare.groceryapp.ui.screens.product.ProductsScreen
import com.sanshare.groceryapp.ui.screens.profile.ProfileScreen
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.AuthViewModel
import com.sanshare.groceryapp.ui.viewmodel.CartViewModel
import com.sanshare.groceryapp.ui.viewmodel.FavoritesViewModel

private data class TabItem(
    val label: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
)

private val tabs = listOf(
    TabItem("Home",     Icons.Filled.Home,        Icons.Outlined.Home),
    TabItem("Products", Icons.Filled.ShoppingBag, Icons.Outlined.ShoppingBag),
    TabItem("Cart",     Icons.Filled.ShoppingCart, Icons.Outlined.ShoppingCart),
    TabItem("Favorites",Icons.Filled.Favorite,    Icons.Outlined.FavoriteBorder),
    TabItem("Profile",  Icons.Filled.Person,      Icons.Outlined.Person),
)

@Composable
fun MainScreen(
    authViewModel: AuthViewModel,
    onLogout: () -> Unit,
    onNavigateToProductDetail: (String) -> Unit,
    onNavigateToOrders: () -> Unit,
    onNavigateToOrderDetail: (String) -> Unit,
    onNavigateToCheckout: () -> Unit,
    onNavigateToAddresses: () -> Unit,
    onNavigateToPaymentMethods: () -> Unit,
    onNavigateToVouchers: () -> Unit,
    onNavigateToSearch: () -> Unit,
) {
    val cartViewModel: CartViewModel = hiltViewModel()
    val favoritesViewModel: FavoritesViewModel = hiltViewModel()
    val cartState by cartViewModel.state.collectAsState()

    var selectedTab by remember { mutableIntStateOf(0) }

    // Load data on first launch
    LaunchedEffect(Unit) {
        cartViewModel.loadFromServer()
        favoritesViewModel.loadFromServer()
    }

    val colors = MaterialTheme.grocery

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = colors.card,
                tonalElevation = 0.dp,
            ) {
                tabs.forEachIndexed { index, tab ->
                    NavigationBarItem(
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        icon = {
                            BadgedBox(
                                badge = {
                                    if (index == 2 && cartState.items.isNotEmpty()) {
                                        Badge { Text(cartViewModel.totalItems.toString()) }
                                    }
                                }
                            ) {
                                Icon(
                                    imageVector = if (selectedTab == index) tab.selectedIcon else tab.unselectedIcon,
                                    contentDescription = tab.label,
                                )
                            }
                        },
                        label = { Text(tab.label) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = GreenPrimary,
                            selectedTextColor = GreenPrimary,
                            indicatorColor = GreenPrimary.copy(alpha = 0.12f),
                            unselectedIconColor = colors.muted,
                            unselectedTextColor = colors.muted,
                        )
                    )
                }
            }
        }
    ) { padding ->
        Box(modifier = Modifier.padding(padding)) {
            when (selectedTab) {
                0 -> HomeScreen(
                    cartViewModel = cartViewModel,
                    favoritesViewModel = favoritesViewModel,
                    onProductClick = onNavigateToProductDetail,
                    onSearchClick = onNavigateToSearch,
                    onCategoryClick = { selectedTab = 1 },
                )
                1 -> ProductsScreen(
                    cartViewModel = cartViewModel,
                    favoritesViewModel = favoritesViewModel,
                    onProductClick = onNavigateToProductDetail,
                )
                2 -> CartScreen(
                    cartViewModel = cartViewModel,
                    onCheckout = onNavigateToCheckout,
                )
                3 -> FavoritesScreen(
                    favoritesViewModel = favoritesViewModel,
                    cartViewModel = cartViewModel,
                    onProductClick = onNavigateToProductDetail,
                )
                4 -> ProfileScreen(
                    authViewModel = authViewModel,
                    onLogout = onLogout,
                    onNavigateToOrders = onNavigateToOrders,
                    onNavigateToAddresses = onNavigateToAddresses,
                    onNavigateToPaymentMethods = onNavigateToPaymentMethods,
                    onNavigateToVouchers = onNavigateToVouchers,
                )
            }
        }
    }
}
