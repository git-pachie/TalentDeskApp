package com.sanshare.groceryapp.ui.screens.orders

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.sanshare.groceryapp.data.remote.OrderDto
import com.sanshare.groceryapp.ui.components.*
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.OrderViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrderDetailScreen(
    orderId: String,
    onBack: () -> Unit,
    viewModel: OrderViewModel = hiltViewModel(),
) {
    val colors = MaterialTheme.grocery
    var order by remember { mutableStateOf<OrderDto?>(null) }
    var rating by remember { mutableIntStateOf(0) }
    var reviewText by remember { mutableStateOf("") }
    var reviewSubmitted by remember { mutableStateOf(false) }

    LaunchedEffect(orderId) {
        viewModel.getOrderDetail(orderId).collect { order = it }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(order?.orderNumber ?: "Order Details") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null) } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = colors.background)
            )
        },
        containerColor = colors.background,
    ) { padding ->
        if (order == null) {
            LoadingBox()
            return@Scaffold
        }

        val o = order!!
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            // Header
            Card(shape = RoundedCornerShape(14.dp), colors = CardDefaults.cardColors(containerColor = colors.card)) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column {
                        Text(o.orderNumber, fontWeight = FontWeight.Bold, fontSize = 18.sp, color = colors.title)
                        Text(o.createdAt.take(10), fontSize = 12.sp, color = colors.muted)
                    }
                    OrderStatusBadge(o.status)
                }
            }

            // Status timeline
            if (!o.statusHistory.isNullOrEmpty()) {
                Card(shape = RoundedCornerShape(14.dp), colors = CardDefaults.cardColors(containerColor = colors.card)) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Order Status", fontWeight = FontWeight.Bold, color = colors.title)
                        Spacer(Modifier.height(12.dp))
                        o.statusHistory.forEachIndexed { idx, entry ->
                            Row(verticalAlignment = Alignment.Top) {
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Box(
                                        modifier = Modifier
                                            .size(10.dp)
                                            .background(
                                                if (idx == o.statusHistory.size - 1) GreenPrimary else Color.Gray.copy(alpha = 0.4f),
                                                CircleShape
                                            )
                                    )
                                    if (idx < o.statusHistory.size - 1) {
                                        Box(modifier = Modifier.width(2.dp).height(32.dp).background(Color.Gray.copy(alpha = 0.3f)))
                                    }
                                }
                                Spacer(Modifier.width(12.dp))
                                Column(modifier = Modifier.padding(bottom = if (idx < o.statusHistory.size - 1) 8.dp else 0.dp)) {
                                    Text(entry.status, fontWeight = FontWeight.SemiBold, fontSize = 13.sp, color = colors.title)
                                    Text("${entry.createdAt.take(16).replace("T", " ")} · ${entry.createdBy}", fontSize = 11.sp, color = colors.muted)
                                    entry.notes?.let { Text(it, fontSize = 11.sp, color = colors.subtitle) }
                                }
                            }
                        }
                    }
                }
            }

            // Items
            Card(shape = RoundedCornerShape(14.dp), colors = CardDefaults.cardColors(containerColor = colors.card)) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Items Ordered", fontWeight = FontWeight.Bold, color = colors.title)
                    Spacer(Modifier.height(10.dp))
                    o.items?.forEach { item ->
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Box(
                                modifier = Modifier.size(44.dp).clip(RoundedCornerShape(8.dp)).background(Color(0xFFF5F5F5)),
                                contentAlignment = Alignment.Center,
                            ) {
                                if (item.productImageUrl != null) {
                                    AsyncImage(model = item.productImageUrl, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
                                } else {
                                    Text("🛒", fontSize = 20.sp)
                                }
                            }
                            Spacer(Modifier.width(10.dp))
                            Column(Modifier.weight(1f)) {
                                Text(item.productName, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = colors.title)
                                Text("x${item.quantity} @ ₱${item.unitPrice.toInt()}", fontSize = 11.sp, color = colors.muted)
                                item.remarks?.let { if (it.isNotBlank()) Text(it, fontSize = 11.sp, color = GreenPrimary) }
                            }
                            Text(formatPeso(item.totalPrice), fontWeight = FontWeight.SemiBold, color = colors.title)
                        }
                        Divider(color = colors.cardBorder)
                    }
                    // Totals
                    Spacer(Modifier.height(8.dp))
                    PriceRow("Subtotal", formatPeso(o.subTotal))
                    if (o.discountAmount > 0) PriceRow("Discount", "-${formatPeso(o.discountAmount)}", valueColor = GreenPrimary)
                    PriceRow("Delivery Fee", formatPeso(o.deliveryFee))
                    o.platformFee?.let { if (it > 0) PriceRow("Platform Fee", formatPeso(it)) }
                    Divider(modifier = Modifier.padding(vertical = 6.dp), color = colors.cardBorder)
                    PriceRow("Total", formatPeso(o.totalAmount), isTotal = true)
                }
            }

            // Delivery schedule
            if (!o.deliveryDate.isNullOrBlank()) {
                InfoCard(title = "Delivery Schedule", icon = Icons.Default.CalendarMonth) {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Date", fontSize = 13.sp, color = colors.subtitle)
                        Text(o.deliveryDate, fontWeight = FontWeight.SemiBold, color = colors.title)
                    }
                    Spacer(Modifier.height(4.dp))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Time Slot", fontSize = 13.sp, color = colors.subtitle)
                        Text(o.deliveryTimeSlot ?: "Anytime", fontWeight = FontWeight.SemiBold, color = colors.title)
                    }
                }
            }

            // Address
            o.address?.let { addr ->
                InfoCard(title = "Delivery Address", icon = Icons.Default.LocationOn) {
                    Text(addr.label, fontWeight = FontWeight.SemiBold, color = colors.title)
                    Text(addr.fullAddress, fontSize = 12.sp, color = colors.subtitle)
                    addr.contactNumber?.let { Text(it, fontSize = 12.sp, color = GreenPrimary) }
                    addr.deliveryInstructions?.let { Text(it, fontSize = 12.sp, color = colors.muted) }
                }
            }

            // Payment
            o.payment?.let { pay ->
                InfoCard(title = "Payment", icon = Icons.Default.CreditCard) {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Method", fontSize = 13.sp, color = colors.subtitle)
                        Text(pay.method, fontWeight = FontWeight.SemiBold, color = colors.title)
                    }
                    Spacer(Modifier.height(4.dp))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Status", fontSize = 13.sp, color = colors.subtitle)
                        OrderStatusBadge(pay.status)
                    }
                }
            }

            // Rating (delivered orders)
            if (o.status.lowercase() == "delivered" && !reviewSubmitted) {
                Card(shape = RoundedCornerShape(14.dp), colors = CardDefaults.cardColors(containerColor = colors.card)) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Rate this Order", fontWeight = FontWeight.Bold, color = colors.title)
                        Spacer(Modifier.height(10.dp))
                        Row {
                            (1..5).forEach { star ->
                                IconButton(onClick = { rating = star }, modifier = Modifier.size(36.dp)) {
                                    Icon(
                                        if (star <= rating) Icons.Default.Star else Icons.Default.StarBorder,
                                        null,
                                        tint = if (star <= rating) Color(0xFFFACC15) else Color.Gray,
                                    )
                                }
                            }
                        }
                        Spacer(Modifier.height(8.dp))
                        OutlinedTextField(
                            value = reviewText,
                            onValueChange = { reviewText = it },
                            placeholder = { Text("How was your experience?", fontSize = 13.sp) },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(8.dp),
                            minLines = 2,
                            colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = GreenPrimary),
                        )
                        Spacer(Modifier.height(10.dp))
                        Button(
                            onClick = {
                                o.items?.firstOrNull()?.let { item ->
                                    viewModel.submitReview(o.id, item.productId, rating, reviewText)
                                    reviewSubmitted = true
                                }
                            },
                            enabled = rating > 0,
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
                        ) {
                            Text("Submit Review")
                        }
                    }
                }
            }

            Spacer(Modifier.height(16.dp))
        }
    }
}

@Composable
private fun InfoCard(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = MaterialTheme.grocery
    Card(shape = RoundedCornerShape(14.dp), colors = CardDefaults.cardColors(containerColor = colors.card)) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(icon, null, tint = GreenPrimary, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text(title, fontWeight = FontWeight.Bold, color = colors.title)
            }
            Spacer(Modifier.height(10.dp))
            content()
        }
    }
}
