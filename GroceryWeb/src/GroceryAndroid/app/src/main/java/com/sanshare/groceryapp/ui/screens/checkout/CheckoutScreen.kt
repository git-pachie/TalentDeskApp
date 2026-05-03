package com.sanshare.groceryapp.ui.screens.checkout

import android.app.DatePickerDialog
import androidx.compose.animation.*
import androidx.compose.foundation.*
import androidx.compose.foundation.text.KeyboardOptions
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
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
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

    LaunchedEffect(Unit) {
        cartViewModel.loadFromServer()
        orderViewModel.initCheckout()
    }

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

    cs.error?.let { err ->
        AlertDialog(
            onDismissRequest = { orderViewModel.clearCheckoutError() },
            title = { Text("Checkout") },
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
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = colors.card),
                elevation = CardDefaults.cardElevation(if (colors.isDark) 0.dp else 3.dp),
                border = if (colors.isDark) androidx.compose.foundation.BorderStroke(1.dp, colors.cardBorder) else null,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Column {
                    // Header
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Box(
                            modifier = Modifier
                                .size(32.dp)
                                .background(GreenPrimary.copy(alpha = 0.12f), RoundedCornerShape(8.dp)),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Default.ShoppingBag, null, tint = GreenPrimary, modifier = Modifier.size(16.dp))
                        }
                        Spacer(Modifier.width(10.dp))
                        Text(
                            "Order Summary",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.SemiBold,
                            color = colors.title,
                        )
                        Spacer(Modifier.weight(1f))
                        if (!cartState.isLoading) {
                            Text(
                                "${cartState.items.size} item${if (cartState.items.size != 1) "s" else ""}",
                                fontSize = 12.sp,
                                color = colors.muted,
                            )
                        }
                    }

                    HorizontalDivider(color = colors.divider)

                    if (cartState.isLoading) {
                        Box(
                            modifier = Modifier.fillMaxWidth().padding(24.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            CircularProgressIndicator(color = GreenPrimary, modifier = Modifier.size(22.dp), strokeWidth = 2.dp)
                        }
                    } else if (cartState.items.isEmpty()) {
                        Box(
                            modifier = Modifier.fillMaxWidth().padding(24.dp),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text("No items in cart yet.", fontSize = 13.sp, color = colors.muted)
                        }
                    } else {
                        val items = cartState.items
                        items.forEachIndexed { index, item ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(IntrinsicSize.Min),
                                verticalAlignment = Alignment.Top,
                            ) {
                                // Image — flush left, corners match card on first/last
                                Box(
                                    modifier = Modifier
                                        .width(88.dp)
                                        .fillMaxHeight()
                                        .clip(
                                            RoundedCornerShape(
                                                topStart = if (index == 0) 0.dp else 0.dp,
                                                bottomStart = if (index == items.size - 1) 16.dp else 0.dp,
                                                topEnd = 0.dp,
                                                bottomEnd = 0.dp,
                                            )
                                        )
                                        .background(
                                            if (colors.isDark) Color(0xFF1E1E1E) else Color(0xFFF5F5F5)
                                        ),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    if (!item.productImageUrl.isNullOrBlank()) {
                                        AsyncImage(
                                            model = item.productImageUrl,
                                            contentDescription = item.productName,
                                            contentScale = ContentScale.Crop,
                                            modifier = Modifier.fillMaxSize(),
                                        )
                                    } else {
                                        Text("🛒", fontSize = 26.sp)
                                    }
                                }

                                // Content
                                Column(
                                    modifier = Modifier
                                        .weight(1f)
                                        .padding(horizontal = 12.dp, vertical = 12.dp),
                                ) {
                                    Text(
                                        item.productName,
                                        fontSize = 13.sp,
                                        fontWeight = FontWeight.Medium,
                                        color = colors.title,
                                        lineHeight = 18.sp,
                                    )
                                    Spacer(Modifier.height(5.dp))
                                    Row(
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    ) {
                                        Text(
                                            formatPeso(item.unitPrice),
                                            fontSize = 12.sp,
                                            color = colors.subtitle,
                                        )
                                        Text("·", fontSize = 12.sp, color = colors.muted)
                                        // Qty badge
                                        Box(
                                            modifier = Modifier
                                                .background(GreenPrimary.copy(alpha = 0.12f), RoundedCornerShape(6.dp))
                                                .padding(horizontal = 7.dp, vertical = 2.dp),
                                        ) {
                                            Text(
                                                "×${item.quantity}",
                                                fontSize = 11.sp,
                                                fontWeight = FontWeight.SemiBold,
                                                color = GreenPrimary,
                                            )
                                        }
                                    }
                                    if (!item.remarks.isNullOrBlank()) {
                                        Spacer(Modifier.height(4.dp))
                                        Text(
                                            item.remarks,
                                            fontSize = 11.sp,
                                            color = colors.muted,
                                            fontStyle = androidx.compose.ui.text.font.FontStyle.Italic,
                                        )
                                    }
                                }

                                // Line total
                                Box(
                                    modifier = Modifier
                                        .fillMaxHeight()
                                        .padding(end = 14.dp),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    Text(
                                        formatPeso(item.unitPrice * item.quantity),
                                        fontSize = 13.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = colors.title,
                                    )
                                }
                            }

                            if (index < items.size - 1) {
                                HorizontalDivider(
                                    modifier = Modifier.padding(start = 88.dp),
                                    color = colors.divider,
                                )
                            }
                        }

                        // Subtotal row at bottom of card
                        HorizontalDivider(color = colors.divider)
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 12.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                "${cartState.items.sumOf { it.quantity }} items",
                                fontSize = 13.sp,
                                color = colors.subtitle,
                            )
                            Text(
                                formatPeso(subtotal),
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold,
                                color = colors.primary,
                            )
                        }
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

            AnimatedVisibility(
                visible = cs.paymentMethod == "Credit Card" || cs.paymentMethod == "Debit Card",
                enter = fadeIn() + expandVertically(),
                exit = fadeOut() + shrinkVertically(),
            ) {
                SectionCard(title = "Card Details", icon = Icons.Default.CreditCard) {
                    CardPreview(
                        cardHolderName = cs.cardHolderName,
                        cardNumber = cs.cardNumber,
                        cardExpiry = cs.cardExpiry,
                        cardType = cs.paymentMethod,
                    )
                    Spacer(Modifier.height(12.dp))
                    OutlinedTextField(
                        value = cs.cardHolderName,
                        onValueChange = { orderViewModel.setCardHolderName(it) },
                        label = { Text("Cardholder Name") },
                        placeholder = { Text("Juan Dela Cruz") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        shape = RoundedCornerShape(8.dp),
                        colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = GreenPrimary),
                    )
                    Spacer(Modifier.height(10.dp))
                    OutlinedTextField(
                        value = formatCardNumber(cs.cardNumber),
                        onValueChange = { orderViewModel.setCardNumber(it.filter(Char::isDigit).take(19)) },
                        label = { Text("Card Number") },
                        placeholder = { Text("1234 5678 9012 3456") },
                        modifier = Modifier.fillMaxWidth(),
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        shape = RoundedCornerShape(8.dp),
                        colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = GreenPrimary),
                    )
                    Spacer(Modifier.height(10.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        OutlinedTextField(
                            value = cs.cardExpiry,
                            onValueChange = { orderViewModel.setCardExpiry(formatExpiry(it)) },
                            label = { Text("Expiry") },
                            placeholder = { Text("MM/YY") },
                            modifier = Modifier.weight(1f),
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                            shape = RoundedCornerShape(8.dp),
                            colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = GreenPrimary),
                        )
                        OutlinedTextField(
                            value = cs.cardCvv,
                            onValueChange = { orderViewModel.setCardCvv(it.filter(Char::isDigit).take(4)) },
                            label = { Text("CVV") },
                            placeholder = { Text("123") },
                            modifier = Modifier.width(112.dp),
                            singleLine = true,
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                            visualTransformation = PasswordVisualTransformation(),
                            shape = RoundedCornerShape(8.dp),
                            colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = GreenPrimary),
                        )
                    }
                }
            }

            // ── Voucher ───────────────────────────────────────────────────────
            SectionCard(
                title = "Voucher",
                icon = Icons.Default.LocalOffer,
                trailingIcon = Icons.Default.ChevronRight,
                onClick = { showVoucherSheet = true },
            ) {
                val appliedVoucher = cs.appliedVoucher
                if (appliedVoucher != null) {
                    Text(appliedVoucher.code, fontWeight = FontWeight.Bold, color = GreenPrimary)
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
                colors = ButtonDefaults.buttonColors(
                    containerColor = GreenPrimary,
                    contentColor = Color.White,
                ),
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
                            .padding(vertical = 12.dp),
                        verticalAlignment = Alignment.Top,
                    ) {
                        Icon(
                            Icons.Default.LocationOn,
                            null,
                            tint = GreenPrimary,
                            modifier = Modifier.padding(top = 2.dp),
                        )
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Text(addr.label, fontWeight = FontWeight.SemiBold, color = colors.title)
                            Text(addr.fullAddress, fontSize = 12.sp, color = colors.subtitle)
                            if (!addr.contactNumber.isNullOrBlank()) {
                                Spacer(Modifier.height(2.dp))
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        Icons.Default.Phone,
                                        null,
                                        tint = GreenPrimary,
                                        modifier = Modifier.size(12.dp),
                                    )
                                    Spacer(Modifier.width(4.dp))
                                    Text(addr.contactNumber, fontSize = 12.sp, color = GreenPrimary)
                                }
                            }
                            if (!addr.deliveryInstructions.isNullOrBlank()) {
                                Spacer(Modifier.height(2.dp))
                                Row(verticalAlignment = Alignment.CenterVertically) {
                                    Icon(
                                        Icons.Default.Info,
                                        null,
                                        tint = colors.muted,
                                        modifier = Modifier.size(12.dp),
                                    )
                                    Spacer(Modifier.width(4.dp))
                                    Text(
                                        addr.deliveryInstructions,
                                        fontSize = 11.sp,
                                        color = colors.muted,
                                        maxLines = 2,
                                        overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis,
                                    )
                                }
                            }
                        }
                        Spacer(Modifier.width(8.dp))
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
private fun CardPreview(
    cardHolderName: String,
    cardNumber: String,
    cardExpiry: String,
    cardType: String,
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(
                Brush.linearGradient(
                    listOf(Color(0xFF23643A), Color(0xFF3B9457), Color(0xFF62B96C))
                )
            )
            .padding(16.dp)
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.CreditCard, contentDescription = null, tint = Color.White.copy(alpha = 0.95f))
                Spacer(Modifier.weight(1f))
                Text(cardType, color = Color.White.copy(alpha = 0.92f), fontSize = 12.sp, fontWeight = FontWeight.Medium)
            }
            Text(
                text = formatCardNumber(cardNumber).ifBlank { "•••• •••• •••• ••••" },
                color = Color.White,
                fontSize = 20.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 1.sp,
            )
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Column {
                    Text("CARDHOLDER", color = Color.White.copy(alpha = 0.72f), fontSize = 10.sp)
                    Text(
                        cardHolderName.ifBlank { "YOUR NAME" },
                        color = Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                    )
                }
                Column(horizontalAlignment = Alignment.End) {
                    Text("EXPIRES", color = Color.White.copy(alpha = 0.72f), fontSize = 10.sp)
                    Text(
                        cardExpiry.ifBlank { "MM/YY" },
                        color = Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                    )
                }
            }
        }
    }
}

private fun formatCardNumber(raw: String): String =
    raw.filter(Char::isDigit).chunked(4).joinToString(" ").take(23)

private fun formatExpiry(raw: String): String {
    val digits = raw.filter(Char::isDigit).take(4)
    return when {
        digits.length <= 2 -> digits
        else -> "${digits.take(2)}/${digits.drop(2)}"
    }
}

@Composable
private fun SectionCard(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    trailingIcon: androidx.compose.ui.graphics.vector.ImageVector? = null,
    onClick: (() -> Unit)? = null,
    flushContent: Boolean = false,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = MaterialTheme.grocery
    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = colors.card),
        elevation = CardDefaults.cardElevation(2.dp),
        modifier = if (onClick != null) Modifier.fillMaxWidth().clickable { onClick() } else Modifier.fillMaxWidth(),
    ) {
        Column {
            // Header always has padding
            Row(
                modifier = Modifier.padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Icon(icon, null, tint = GreenPrimary, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text(title, fontWeight = FontWeight.SemiBold, color = GreenPrimary, fontSize = 13.sp)
                if (trailingIcon != null) {
                    Spacer(Modifier.weight(1f))
                    Icon(trailingIcon, null, tint = colors.muted, modifier = Modifier.size(18.dp))
                }
            }
            // Content — flush means no horizontal padding (image can reach edges)
            Column(
                modifier = if (flushContent) Modifier.padding(bottom = 8.dp)
                           else Modifier.padding(start = 14.dp, end = 14.dp, bottom = 14.dp),
                content = content,
            )
        }
    }
}
