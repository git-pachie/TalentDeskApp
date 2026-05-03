package com.sanshare.groceryapp.ui.screens.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.AuthViewModel

@Composable
fun ProfileScreen(
    authViewModel: AuthViewModel,
    onLogout: () -> Unit,
    onNavigateToOrders: () -> Unit,
    onNavigateToAddresses: () -> Unit,
    onNavigateToPaymentMethods: () -> Unit,
    onNavigateToVouchers: () -> Unit,
) {
    val authState by authViewModel.state.collectAsState()
    val colors = MaterialTheme.grocery
    val user = authState.currentUser

    var showLogoutDialog by remember { mutableStateOf(false) }

    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            title = { Text("Sign Out") },
            text = { Text("Are you sure you want to sign out?") },
            confirmButton = {
                TextButton(onClick = {
                    showLogoutDialog = false
                    authViewModel.logout()
                    onLogout()
                }) { Text("Sign Out", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = {
                TextButton(onClick = { showLogoutDialog = false }) { Text("Cancel") }
            }
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
            .verticalScroll(rememberScrollState())
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(GreenPrimary.copy(alpha = if (colors.isDark) 0.16f else 0.08f))
                .padding(horizontal = 20.dp, vertical = 28.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(70.dp)
                        .clip(CircleShape)
                        .background(GreenPrimary),
                    contentAlignment = Alignment.Center,
                ) {
                    val initials = buildString {
                        user?.firstName?.firstOrNull()?.let { append(it) }
                        user?.lastName?.firstOrNull()?.let { append(it) }
                    }.ifEmpty { "?" }
                    Text(initials, color = Color.White, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                }
                Spacer(Modifier.width(16.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(user?.fullName ?: "Guest", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = colors.title)
                    Spacer(Modifier.height(2.dp))
                    Text(
                        user?.email ?: "",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.subtitle,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    user?.phoneNumber?.let {
                        Spacer(Modifier.height(2.dp))
                        Text(it, style = MaterialTheme.typography.bodySmall, color = colors.muted)
                    }
                }
            }
        }

        Spacer(Modifier.height(14.dp))

        Card(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = colors.card),
            border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.9f)),
        ) {
            Column(modifier = Modifier.padding(18.dp)) {
                Text("Verification", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.title)
                Spacer(Modifier.height(12.dp))
                VerificationRow(
                    label = "Email",
                    isVerified = user?.isEmailVerified ?: false,
                    onSendCode = { /* TODO: send email code */ }
                )
                HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp), color = colors.cardBorder)
                VerificationRow(
                    label = "Mobile",
                    isVerified = user?.isPhoneVerified ?: false,
                    onSendCode = { /* TODO: send phone code */ }
                )
            }
        }

        Spacer(Modifier.height(14.dp))

        Card(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = colors.card),
            border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.9f)),
        ) {
            Column {
                ProfileMenuItem(Icons.Default.ShoppingBag, "My Orders", onClick = onNavigateToOrders)
                HorizontalDivider(color = colors.cardBorder)
                ProfileMenuItem(Icons.Default.LocationOn, "Addresses", onClick = onNavigateToAddresses)
                HorizontalDivider(color = colors.cardBorder)
                ProfileMenuItem(Icons.Default.CreditCard, "Payment Methods", onClick = onNavigateToPaymentMethods)
                HorizontalDivider(color = colors.cardBorder)
                ProfileMenuItem(Icons.Default.LocalOffer, "Vouchers", onClick = onNavigateToVouchers)
            }
        }

        Spacer(Modifier.height(14.dp))

        Card(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = colors.card),
            border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.9f)),
        ) {
            ProfileMenuItem(
                icon = Icons.Default.Logout,
                label = "Sign Out",
                tint = MaterialTheme.colorScheme.error,
                onClick = { showLogoutDialog = true }
            )
        }

        Spacer(Modifier.height(32.dp))
    }
}

@Composable
private fun VerificationRow(label: String, isVerified: Boolean, onSendCode: () -> Unit) {
    val colors = MaterialTheme.grocery
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Column {
            Text(label, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold, color = colors.title)
            Text(
                if (isVerified) "Verified" else "Not verified",
                style = MaterialTheme.typography.bodySmall,
                color = if (isVerified) GreenPrimary else Color(0xFFF59E0B),
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            if (!isVerified) {
                OutlinedButton(
                    onClick = onSendCode,
                    contentPadding = PaddingValues(horizontal = 14.dp, vertical = 4.dp),
                    modifier = Modifier.height(34.dp),
                    shape = RoundedCornerShape(12.dp),
                ) {
                    Text("Send Code", style = MaterialTheme.typography.labelMedium, color = GreenPrimary)
                }
            }
        }
    }
}

@Composable
private fun ProfileMenuItem(
    icon: ImageVector,
    label: String,
    tint: Color = GreenPrimary,
    onClick: () -> Unit,
) {
    val colors = MaterialTheme.grocery
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(horizontal = 18.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = Modifier
                .size(38.dp)
                .clip(RoundedCornerShape(12.dp))
                .background(if (tint == GreenPrimary) colors.primaryLight else tint.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(icon, null, tint = tint, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.width(14.dp))
        Text(label, modifier = Modifier.weight(1f), color = if (tint == GreenPrimary) colors.title else tint, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
        Icon(Icons.Default.ChevronRight, null, tint = colors.muted, modifier = Modifier.size(18.dp))
    }
}
