package com.sanshare.groceryapp.ui.screens.orders

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sanshare.groceryapp.ui.components.*
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.OrderViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrdersScreen(
    onBack: () -> Unit,
    onOrderClick: (String) -> Unit,
    viewModel: OrderViewModel = hiltViewModel(),
) {
    val state by viewModel.ordersState.collectAsState()
    val colors = MaterialTheme.grocery
    var selectedTab by remember { mutableIntStateOf(0) }

    LaunchedEffect(Unit) { viewModel.loadOrders() }

    val currentOrders = state.orders.filter { it.status.lowercase() in listOf("pending","paid","processing","outfordelivery") }
    val historyOrders = state.orders.filter { it.status.lowercase() in listOf("delivered","cancelled") }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("My Orders") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null) } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = colors.background)
            )
        },
        containerColor = colors.background,
    ) { padding ->
        Column(modifier = Modifier.fillMaxSize().padding(padding)) {
            TabRow(
                selectedTabIndex = selectedTab,
                containerColor = colors.background,
                contentColor = GreenPrimary,
            ) {
                Tab(selected = selectedTab == 0, onClick = { selectedTab = 0 }, text = { Text("Current (${currentOrders.size})") })
                Tab(selected = selectedTab == 1, onClick = { selectedTab = 1 }, text = { Text("History (${historyOrders.size})") })
            }

            val displayOrders = if (selectedTab == 0) currentOrders else historyOrders

            if (state.isLoading) {
                LoadingBox()
            } else if (displayOrders.isEmpty()) {
                EmptyState("📦", "No orders", if (selectedTab == 0) "Your active orders will appear here." else "Your order history will appear here.")
            } else {
                LazyColumn(
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    items(displayOrders, key = { it.id }) { order ->
                        Card(
                            shape = RoundedCornerShape(14.dp),
                            colors = CardDefaults.cardColors(containerColor = colors.card),
                            elevation = CardDefaults.cardElevation(2.dp),
                            modifier = Modifier.fillMaxWidth().clickable { onOrderClick(order.id) },
                        ) {
                            Column(modifier = Modifier.padding(14.dp)) {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    Text(order.orderNumber, fontWeight = FontWeight.Bold, color = colors.title)
                                    OrderStatusBadge(order.status)
                                }
                                Spacer(Modifier.height(4.dp))
                                Text(order.createdAt.take(10), fontSize = 12.sp, color = colors.muted)
                                Spacer(Modifier.height(6.dp))
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                ) {
                                    Text("${order.items?.sumOf { it.quantity } ?: 0} item(s)", fontSize = 13.sp, color = colors.subtitle)
                                    Text(formatPeso(order.totalAmount), fontWeight = FontWeight.Bold, color = GreenPrimary, fontSize = 15.sp)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
