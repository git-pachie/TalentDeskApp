package com.sanshare.groceryapp.ui.screens.cart

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.sanshare.groceryapp.ui.components.*
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.CartItem
import com.sanshare.groceryapp.ui.viewmodel.CartViewModel

@Composable
fun CartScreen(
    cartViewModel: CartViewModel,
    onCheckout: () -> Unit,
) {
    val state by cartViewModel.state.collectAsState()
    val colors = MaterialTheme.grocery

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
    ) {
        // Header
        ScreenHeader(
            title = "Cart",
            subtitle = if (state.items.isNotEmpty()) "${cartViewModel.totalItems} items ready for checkout" else "Review your items before placing the order.",
            modifier = Modifier.padding(16.dp)
        )

        if (state.items.isEmpty()) {
            Box(Modifier.weight(1f)) {
                EmptyState("🛒", "Cart is Empty", "Tap the cart icon on any product to add it here.")
            }
        } else {
            LazyColumn(
                modifier = Modifier.weight(1f),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(state.items, key = { it.productId }) { item ->
                    CartItemRow(
                        item = item,
                        onIncrement = { cartViewModel.updateQuantity(item.productId, item.quantity + 1) },
                        onDecrement = { cartViewModel.updateQuantity(item.productId, item.quantity - 1) },
                        onRemove = { cartViewModel.removeProduct(item.productId) },
                        onRemarksChange = { cartViewModel.updateRemarks(item.productId, it) },
                    )
                }
            }

            // Checkout bar
            Surface(
                shadowElevation = if (colors.isDark) 0.dp else 10.dp,
                color = colors.navBar,
                border = androidx.compose.foundation.BorderStroke(1.dp, colors.cardBorder),
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column {
                            Text("Total", fontSize = 12.sp, color = colors.muted)
                            Text(
                                formatPeso(cartViewModel.totalPrice),
                                fontSize = 22.sp,
                                fontWeight = FontWeight.Bold,
                                color = GreenPrimary,
                            )
                        }
                        Button(
                            onClick = onCheckout,
                            modifier = Modifier.height(52.dp),
                            shape = RoundedCornerShape(14.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = GreenPrimary,
                                contentColor = Color.White,
                            ),
                        ) {
                            Text(
                                "Checkout (${cartViewModel.totalItems})",
                                fontSize = 15.sp,
                                fontWeight = FontWeight.SemiBold,
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CartItemRow(
    item: CartItem,
    onIncrement: () -> Unit,
    onDecrement: () -> Unit,
    onRemove: () -> Unit,
    onRemarksChange: (String) -> Unit,
) {
    val colors = MaterialTheme.grocery
    var showRemarksField by remember { mutableStateOf(item.remarks.isNotBlank()) }
    var remarksText by remember(item.productId) { mutableStateOf(item.remarks) }

    Card(
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = colors.card),
        border = androidx.compose.foundation.BorderStroke(1.dp, colors.cardBorder),
        elevation = CardDefaults.cardElevation(if (colors.isDark) 0.dp else 2.dp),
    ) {
        Column {
            // IntrinsicSize.Min makes the Row measure its min intrinsic height
            // so the image Box can use fillMaxHeight() to match the content height
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(IntrinsicSize.Min),
                verticalAlignment = Alignment.Top,
            ) {
                // Image — flush to card left edge, fills full row height
                Box(
                    modifier = Modifier
                        .width(80.dp)
                        .fillMaxHeight()
                        .clip(RoundedCornerShape(topStart = 20.dp, bottomStart = 20.dp))
                        .background(Color(0xFFF5F5F5)),
                    contentAlignment = Alignment.Center,
                ) {
                    if (item.productImageUrl != null) {
                        AsyncImage(
                            model = item.productImageUrl,
                            contentDescription = item.productName,
                            contentScale = ContentScale.Crop,
                            modifier = Modifier.fillMaxSize(),
                        )
                    } else {
                        Text("🛒", fontSize = 28.sp)
                    }
                }

                Spacer(Modifier.width(10.dp))

                Column(
                    modifier = Modifier
                        .weight(1f)
                        .padding(end = 10.dp)
                        .padding(top = 12.dp),
                ) {
                    Text(
                        item.productName,
                        style = MaterialTheme.typography.titleSmall,
                        color = colors.title,
                        maxLines = 2
                    )
                    Text("₱${item.unitPrice.toInt()} each", style = MaterialTheme.typography.bodySmall, color = colors.muted)

                    // Add note button
                    TextButton(
                        onClick = { showRemarksField = !showRemarksField },
                        contentPadding = PaddingValues(0.dp),
                        modifier = Modifier.height(24.dp),
                    ) {
                        Icon(Icons.Default.ChatBubbleOutline, null, modifier = Modifier.size(14.dp), tint = GreenPrimary)
                        Spacer(Modifier.width(4.dp))
                        Text(
                            if (remarksText.isBlank()) "Add note" else "Edit note",
                            fontSize = 11.sp,
                            color = GreenPrimary,
                        )
                    }
                }

                Column(
                    horizontalAlignment = Alignment.End,
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    modifier = Modifier.padding(top = 10.dp, end = 12.dp, bottom = 10.dp),
                ) {
                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(999.dp))
                            .background(colors.inputBackground)
                            .padding(horizontal = 4.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp),
                    ) {
                        FilledTonalIconButton(
                            onClick = { if (item.quantity == 1) onRemove() else onDecrement() },
                            modifier = Modifier.size(28.dp),
                            colors = IconButtonDefaults.filledTonalIconButtonColors(
                                containerColor = if (item.quantity == 1) com.sanshare.groceryapp.ui.theme.RedBadge.copy(alpha = 0.12f)
                                else GreenPrimary.copy(alpha = 0.12f),
                                contentColor = if (item.quantity == 1) com.sanshare.groceryapp.ui.theme.RedBadge else GreenPrimary,
                            )
                        ) {
                            Icon(
                                if (item.quantity == 1) Icons.Default.Delete else Icons.Default.Remove,
                                null,
                                modifier = Modifier.size(14.dp),
                            )
                        }

                        Text(
                            "${item.quantity}",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            color = colors.title,
                            modifier = Modifier.widthIn(min = 18.dp),
                        )

                        FilledIconButton(
                            onClick = onIncrement,
                            modifier = Modifier.size(28.dp),
                            colors = IconButtonDefaults.filledIconButtonColors(
                                containerColor = GreenPrimary,
                                contentColor = Color.White,
                            )
                        ) {
                            Icon(Icons.Default.Add, null, tint = Color.White, modifier = Modifier.size(14.dp))
                        }
                    }

                    Text(
                        formatPeso(item.unitPrice * item.quantity),
                        fontWeight = FontWeight.SemiBold,
                        color = colors.title,
                        fontSize = 13.sp,
                    )
                }
            }

            // Remarks field
            if (showRemarksField) {
                Spacer(Modifier.height(8.dp))
                OutlinedTextField(
                    value = remarksText,
                    onValueChange = {
                        remarksText = it
                        onRemarksChange(it)
                    },
                    placeholder = { Text("e.g. ripe ones please", fontSize = 12.sp) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp)
                        .padding(bottom = 10.dp),
                    shape = RoundedCornerShape(8.dp),
                    singleLine = true,
                    textStyle = androidx.compose.ui.text.TextStyle(fontSize = 13.sp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = GreenPrimary,
                    )
                )
            }
        }
    }
}
