package com.sanshare.groceryapp.ui.screens.profile

import androidx.compose.foundation.background
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
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
        // ── Profile Header ────────────────────────────────────────────────────
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(GreenPrimary.copy(alpha = 0.08f))
                .padding(24.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Avatar
                Box(
                    modifier = Modifier
                        .size(64.dp)
                        .clip(CircleShape)
                        .background(GreenPrimary),
                    contentAlignment = Alignment.Center,
                ) {
                    val initials = buildString {
                        user?.firstName?.firstOrNull()?.let { append(it) }
                        user?.lastName?.firstOrNull()?.let { append(it) }
                    }.ifEmpty { "?" }
                    Text(initials, color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                }
                Spacer(Modifier.width(16.dp))
                Column {
                    Text(user?.fullName ?: "Guest", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = colors.title)
                    Text(user?.email ?: "", fontSize = 13.sp, color = colors.subtitle)
                    user?.phoneNumber?.let {
                        Text(it, fontSize = 12.sp, color = colors.muted)
                    }
                }
            }
        }

        Spacer(Modifier.height(8.dp))

        // ── Verification Status ───────────────────────────────────────────────
        Card(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            shape = RoundedCornerShape(14.dp),
            colors = CardDefaults.cardColors(containerColor = colors.card),
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text("Verification", fontWeight = FontWeight.Bold, color = colors.title)
                Spacer(Modifier.height(10.dp))
                VerificationRow(
                    label = "Email",
                    isVerified = user?.isEmailVerified ?: false,
                    onSendCode = { /* TODO: send email code */ }
                )
                Divider(modifier = Modifier.padding(vertical = 8.dp), color = colors.cardBorder)
                VerificationRow(
                    label = "Mobile",
                    isVerified = user?.isPhoneVerified ?: false,
                    onSendCode = { /* TODO: send phone code */ }
                )
            }
        }

        Spacer(Modifier.height(12.dp))

        // ── Account Links ─────────────────────────────────────────────────────
        Card(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            shape = RoundedCornerShape(14.dp),
            colors = CardDefaults.cardColors(containerColor = colors.card),
        ) {
            Column {
                ProfileMenuItem(Icons.Default.ShoppingBag, "My Orders", onClick = onNavigateToOrders)
                Divider(color = colors.cardBorder)
                ProfileMenuItem(Icons.Default.LocationOn, "Addresses", onClick = onNavigateToAddresses)
                Divider(color = colors.cardBorder)
                ProfileMenuItem(Icons.Default.CreditCard, "Payment Methods", onClick = onNavigateToPaymentMethods)
                Divider(color = colors.cardBorder)
                ProfileMenuItem(Icons.Default.LocalOffer, "Vouchers", onClick = onNavigateToVouchers)
            }
        }

        Spacer(Modifier.height(12.dp))

        // ── Sign Out ──────────────────────────────────────────────────────────
        Card(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp),
            shape = RoundedCornerShape(14.dp),
            colors = CardDefaults.cardColors(containerColor = colors.card),
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
            Text(label, fontSize = 14.sp, fontWeight = FontWeight.Medium, color = colors.title)
            Text(
                if (isVerified) "Verified" else "Not verified",
                fontSize = 12.sp,
                color = if (isVerified) GreenPrimary else Color(0xFFF59E0B),
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            if (!isVerified) {
                OutlinedButton(
                    onClick = onSendCode,
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                    modifier = Modifier.height(32.dp),
                ) {
                    Text("Send Code", fontSize = 11.sp, color = GreenPrimary)
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
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = tint, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(14.dp))
        Text(label, modifier = Modifier.weight(1f), color = if (tint == GreenPrimary) colors.title else tint, fontSize = 15.sp)
        Icon(Icons.Default.ChevronRight, null, tint = colors.muted, modifier = Modifier.size(18.dp))
    }
}
