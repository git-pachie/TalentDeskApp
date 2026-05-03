package com.sanshare.groceryapp.ui.screens.checkout

import android.app.DatePickerDialog
import androidx.compose.animation.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sanshare.groceryapp.ui.components.*
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.CartViewModel
import com.sanshare.groceryapp.ui.viewmodel.OrderViewModel
import java.util.*

private val DELIVERY_TIME_SLOTS = listOf(
    "Anytime","08:00 AM","09:00 AM","10:00 AM","11:00 AM","12:00 PM",
    "01:00 PM","02:00 PM","03:00 PM","04:00 PM","05:00 PM","06:00 PM",
)

private val PAYMENT_METHODS = listOf(
    "Credit Card" to Icons.Default.CreditCard,
    "Debit Card"  to Icons.Default.CreditCard,
    "GCash"       to Icons.Default.PhoneAndroid,
    "Cash on Delivery" to Icons.Default.Money,
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CheckoutScreen(
    onBack: () -> Unit,
    onOrderPlaced: (String) -> Unit,
    orderViewModel: OrderViewModel = hiltViewModel(),
    cartViewModel: CartViewModel = hiltViewModel(),
) {
    val cs by orderViewModel.checkoutState.collectAsState()
    val cartState by cartViewModel.state.collectAsState()
    val colors = MaterialTheme.grocery
    val context = LocalContext.current

    val deliveryFee = 5.0
    val platformFee = 2.0
    val otherCharges = 1.0
    val subtotal = cartState.items.sumOf { it.unitPrice * it.quantity }
    val total = (subtotal + deliveryFee + platformFee + otherCharges - cs.voucherDiscount).coerceAtLeast(0.0)

    var showAddressPicker by remember { mutableStateOf(false) }
    var showPaymentPicker by remember { mutableStateOf(false) }
    var showVoucherSheet by remember { mutableStateOf(false) }
    var showTimeSlotPicker by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { orderViewModel.initCheckout() }

    // Navigate on success
    LaunchedEffect(cs.orderPlaced, cs.placedOrder) {
        if (cs.orderPlaced && cs.placedOrder != null) {
            cartViewModel.clearCart()
            onOrderPlaced(cs.placedOrder!!.id)
        }
    }

    // Verification error dialog
    cs.verificationError?.let { err ->
        AlertDialog(
            onDismissRequest = { orderViewModel.clearCheckoutError() },
            title = { Text("Verification Required") },
            text = { Text(err) },
            confirmButton = {
                TextButton(onClick = { orderViewModel.clearCheckoutError() }) { Text("OK") }
            }
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Checkout") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null) } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = colors.background)
            )
        },
        containerColor = colors.background,
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            // ── Order Summary ─────────────────────────────────────────────────
            SectionCard(title = "Order Summary", icon = Icons.Default.ShoppingBag) {
                cartState.items.forEach { item ->
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                    ) {
                        Text("${item.productName} x${item.quantity}", fontSize = 13.sp, color = colors.subtitle, modifier = Modifier.weight(1f))
                        Text(formatPeso(item.unitPrice * item.quantity), fontSize = 13.sp, fontWeight = FontWeight.Medium, color = colors.title)
                    }
                }
            }

            // ── Delivery Address ──────────────────────────────────────────────
            SectionCard(
                title = "Delivery Address",
                icon = Icons.Default.LocationOn,
                trailingIcon = Icons.Default.ChevronRight,
                onClick = { showAddressPicker = true },
            ) {
                val addr = cs.addresses.firstOrNull { it.id == cs.selectedAddressId } ?: cs.addresses.firstOrNull()
                if (addr != null) {
                    Text(addr.label, fontWeight = FontWeight.SemiBold, color = colors.title)
                    Text(addr.fullAddress, fontSize = 12.sp, color = colors.subtitle)
                    if (!addr.contactNumber.isNullOrBlank()) {
                        Text(addr.contactNumber, fontSize = 12.sp, color = GreenPrimary)
                    }
                } else {
                    Text("No address selected", color = colors.muted)
                }
            }

            // ── Payment Method ────────────────────────────────────────────────
            SectionCard(
                title = "Payment Method",
                icon = Icons.Default.CreditCard,
                trailingIcon = Icons.Default.ChevronRight,
                onClick = { showPaymentPicker = true },
            ) {
                Text(cs.paymentMethod, fontWeight = FontWeight.SemiBold, color = colors.title)
            }

            // ── Voucher ───────────────────────────────────────────────────────
            SectionCard(
                title = "Voucher",
                icon = Icons.Default.LocalOffer,
                trailingIcon = Icons.Default.ChevronRight,
                onClick = { showVoucherSheet = true },
            ) {
                if (cs.appliedVoucher != null) {
                    Text(cs.appliedVoucher.code, fontWeight = FontWeight.Bold, color = GreenPrimary)
                    Text("-${formatPeso(cs.voucherDiscount)} applied", fontSize = 12.sp, color = GreenPrimary)
                } else {
                    Text("Apply a voucher code", color = colors.muted)
                }
            }

            // ── Order Remarks ─────────────────────────────────────────────────
            SectionCard(title = "Order Remarks", icon = Icons.Default.ChatBubbleOutline) {
                OutlinedTextField(
                    value = cs.orderRemarks,
                    onValueChange = { orderViewModel.setOrderRemarks(it) },
                    placeholder = { Text("Any special instructions?", fontSize = 13.sp) },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(8.dp),
                    minLines = 2,
                    maxLines = 4,
                    colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = GreenPrimary),
                )
            }

            // ── Delivery Schedule ─────────────────────────────────────────────
            SectionCard(title = "Delivery Schedule", icon = Icons.Default.CalendarMonth) {
                // Date picker
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .background(colors.background)
                        .clickable {
                            val cal = Calendar.getInstance()
                            DatePickerDialog(
                                context,
                                { _, y, m, d ->
                                    orderViewModel.setDeliveryDate("$y-${(m+1).toString().padStart(2,'0')}-${d.toString().padStart(2,'0')}")
                                },
                                cal.get(Calendar.YEAR),
                                cal.get(Calendar.MONTH),
                                cal.get(Calendar.DAY_OF_MONTH),
                            ).apply {
                                datePicker.minDate = System.currentTimeMillis()
                                show()
                            }
                        }
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Date", fontSize = 13.sp, color = colors.subtitle)
                    Text(
                        cs.deliveryDate.ifBlank { "Select date" },
                        fontWeight = FontWeight.SemiBold,
                        color = if (cs.deliveryDate.isBlank()) colors.muted else colors.title,
                    )
                }

                Spacer(Modifier.height(8.dp))

                // Time slot
                ExposedDropdownMenuBox(
                    expanded = showTimeSlotPicker,
                    onExpandedChange = { showTimeSlotPicker = it },
                ) {
                    OutlinedTextField(
                        value = cs.deliveryTimeSlot,
                        onValueChange = {},
                        readOnly = true,
                        label = { Text("Time Slot") },
                        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = showTimeSlotPicker) },
                        modifier = Modifier.fillMaxWidth().menuAnchor(),
                        shape = RoundedCornerShape(8.dp),
                        colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = GreenPrimary),
                    )
                    ExposedDropdownMenu(
                        expanded = showTimeSlotPicker,
                        onDismissRequest = { showTimeSlotPicker = false },
                    ) {
                        DELIVERY_TIME_SLOTS.forEach { slot ->
                            DropdownMenuItem(
                                text = { Text(slot) },
                                onClick = {
                                    orderViewModel.setDeliveryTimeSlot(slot)
                                    showTimeSlotPicker = false
                                }
                            )
                        }
                    }
                }
            }

            // ── Price Breakdown ───────────────────────────────────────────────
            Card(
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = colors.card),
                elevation = CardDefaults.cardElevation(2.dp),
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Payment Summary", fontWeight = FontWeight.Bold, color = colors.title)
                    Spacer(Modifier.height(10.dp))
                    PriceRow("Subtotal", formatPeso(subtotal))
                    PriceRow("Delivery Fee", formatPeso(deliveryFee))
                    PriceRow("Platform Fee", formatPeso(platformFee))
                    PriceRow("Other Charges", formatPeso(otherCharges))
                    if (cs.voucherDiscount > 0) {
                        PriceRow("Voucher (${cs.appliedVoucher?.code})", "-${formatPeso(cs.voucherDiscount)}", valueColor = GreenPrimary)
                    }
                    Divider(modifier = Modifier.padding(vertical = 8.dp), color = colors.cardBorder)
                    PriceRow("Total", formatPeso(total), isTotal = true)
                }
            }

            // ── Place Order Button ────────────────────────────────────────────
            Button(
                onClick = {
                    orderViewModel.validateAndPlaceOrder(subtotal) { /* handled via state */ }
                },
                enabled = !cs.isPlacingOrder && !cs.isValidatingCheckout,
                modifier = Modifier.fillMaxWidth().height(56.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
            ) {
                if (cs.isPlacingOrder || cs.isValidatingCheckout) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(22.dp), strokeWidth = 2.dp)
                } else {
                    Text(
                        "Place Order — ${formatPeso(total)}",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                    )
                }
            }

            Spacer(Modifier.height(16.dp))
        }
    }

    // ── Address Picker Sheet ──────────────────────────────────────────────────
    if (showAddressPicker) {
        ModalBottomSheet(onDismissRequest = { showAddressPicker = false }) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text("Select Address", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(12.dp))
                cs.addresses.forEach { addr ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                orderViewModel.selectAddress(addr.id)
                                showAddressPicker = false
                            }
                            .padding(vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Default.LocationOn, null, tint = GreenPrimary)
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(addr.label, fontWeight = FontWeight.SemiBold, color = colors.title)
                            Text(addr.fullAddress, fontSize = 12.sp, color = colors.subtitle)
                        }
                        if (addr.id == cs.selectedAddressId) {
                            Icon(Icons.Default.CheckCircle, null, tint = GreenPrimary)
                        }
                    }
                    Divider(color = colors.cardBorder)
                }
                Spacer(Modifier.height(32.dp))
            }
        }
    }

    // ── Payment Method Sheet ──────────────────────────────────────────────────
    if (showPaymentPicker) {
        ModalBottomSheet(onDismissRequest = { showPaymentPicker = false }) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text("Payment Method", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(12.dp))
                PAYMENT_METHODS.forEach { (method, icon) ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                orderViewModel.selectPaymentMethod(method)
                                showPaymentPicker = false
                            }
                            .padding(vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(icon, null, tint = GreenPrimary)
                        Spacer(Modifier.width(12.dp))
                        Text(method, modifier = Modifier.weight(1f), color = colors.title)
                        if (method == cs.paymentMethod) {
                            Icon(Icons.Default.Check, null, tint = GreenPrimary)
                        }
                    }
                    Divider(color = colors.cardBorder)
                }
                Spacer(Modifier.height(32.dp))
            }
        }
    }

    // ── Voucher Sheet ─────────────────────────────────────────────────────────
    if (showVoucherSheet) {
        ModalBottomSheet(onDismissRequest = { showVoucherSheet = false }) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text("Vouchers", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(12.dp))
                if (cs.appliedVoucher != null) {
                    TextButton(onClick = {
                        orderViewModel.removeVoucher()
                        showVoucherSheet = false
                    }) {
                        Icon(Icons.Default.Close, null, tint = MaterialTheme.colorScheme.error)
                        Spacer(Modifier.width(4.dp))
                        Text("Remove Applied Voucher", color = MaterialTheme.colorScheme.error)
                    }
                    Divider(color = colors.cardBorder)
                }
                if (cs.vouchers.isEmpty()) {
                    EmptyState("🎟️", "No vouchers available")
                } else {
                    cs.vouchers.forEach { v ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    orderViewModel.applyVoucher(v, subtotal)
                                    showVoucherSheet = false
                                }
                                .padding(vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Icon(Icons.Default.LocalOffer, null, tint = GreenPrimary)
                            Spacer(Modifier.width(12.dp))
                            Column(Modifier.weight(1f)) {
                                Text(v.code, fontWeight = FontWeight.Bold, color = colors.title)
                                Text(v.description ?: "", fontSize = 12.sp, color = colors.subtitle)
                                Text("Min. ₱${v.minimumSpend.toInt()} · Expires ${v.expiryDate.take(10)}", fontSize = 11.sp, color = colors.muted)
                            }
                            if (cs.appliedVoucher?.id == v.id) {
                                Icon(Icons.Default.CheckCircle, null, tint = GreenPrimary)
                            }
                        }
                        Divider(color = colors.cardBorder)
                    }
                }
                Spacer(Modifier.height(32.dp))
            }
        }
    }
}

@Composable
private fun SectionCard(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    trailingIcon: androidx.compose.ui.graphics.vector.ImageVector? = null,
    onClick: (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = MaterialTheme.grocery
    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = colors.card),
        elevation = CardDefaults.cardElevation(2.dp),
        modifier = if (onClick != null) Modifier.fillMaxWidth().clickable { onClick() } else Modifier.fillMaxWidth(),
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(icon, null, tint = GreenPrimary, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text(title, fontWeight = FontWeight.SemiBold, color = GreenPrimary, fontSize = 13.sp)
                if (trailingIcon != null) {
                    Spacer(Modifier.weight(1f))
                    Icon(trailingIcon, null, tint = colors.muted, modifier = Modifier.size(18.dp))
                }
            }
            Spacer(Modifier.height(8.dp))
            content()
        }
    }
}
