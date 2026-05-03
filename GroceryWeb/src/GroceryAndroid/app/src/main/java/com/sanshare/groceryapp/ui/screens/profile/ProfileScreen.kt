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
import androidx.compose.ui.unit.sp
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.AuthViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    authViewModel: AuthViewModel,
    onLogout: () -> Unit,
    onNavigateToOrders: () -> Unit,
    onNavigateToAddresses: () -> Unit,
    onNavigateToPaymentMethods: () -> Unit,
    onNavigateToVouchers: () -> Unit,
) {
    val state by authViewModel.state.collectAsState()
    val colors = MaterialTheme.grocery
    val user = state.currentUser

    var showLogoutDialog by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        authViewModel.refreshCurrentUser()
    }

    // Auto-dismiss success banner after 5 seconds
    LaunchedEffect(state.successMessage) {
        if (state.successMessage != null) {
            kotlinx.coroutines.delay(5_000)
            authViewModel.dismissSuccessMessage()
        }
    }

    // ── Logout dialog ─────────────────────────────────────────────────────────
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

    // ── Email OTP sheet ───────────────────────────────────────────────────────
    if (state.showEmailVerifySheet) {
        OtpSheet(
            title = "Email Verification",
            subtitle = "Enter the 4-digit code sent to\n${user?.email ?: "your email"}",
            isLoading = state.isLoading,
            isSendingCode = state.isSendingEmailCode,
            errorMessage = state.errorMessage,
            onDismiss = { authViewModel.dismissEmailVerifySheet() },
            onResend = { authViewModel.resendEmailCodeFromProfile() },
            onVerify = { code -> authViewModel.verifyEmailFromProfile(code) },
        )
    }

    // ── Phone OTP sheet ───────────────────────────────────────────────────────
    if (state.showPhoneVerifySheet) {
        OtpSheet(
            title = "Mobile Verification",
            subtitle = "Enter the 4-digit code sent to\n${user?.phoneNumber ?: "your mobile number"}",
            isLoading = state.isLoading,
            isSendingCode = state.isSendingPhoneCode,
            errorMessage = state.errorMessage,
            onDismiss = { authViewModel.dismissPhoneVerifySheet() },
            onResend = { authViewModel.resendPhoneCodeFromProfile() },
            onVerify = { code -> authViewModel.verifyPhoneFromProfile(code) },
        )
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
            .verticalScroll(rememberScrollState()),
    ) {
        // ── Success banner ────────────────────────────────────────────────────
        state.successMessage?.let { msg ->
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 10.dp),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(containerColor = colors.banner),
                border = BorderStroke(1.5.dp, GreenPrimary.copy(alpha = if (colors.isDark) 0.5f else 0.35f)),
                elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(
                        Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = GreenPrimary,
                        modifier = Modifier.size(22.dp),
                    )
                    Spacer(Modifier.width(12.dp))
                    Text(
                        msg,
                        modifier = Modifier.weight(1f),
                        color = if (colors.isDark) Color(0xFFBBF7B0) else Color(0xFF14532D),
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.SemiBold,
                    )
                    IconButton(
                        onClick = { authViewModel.dismissSuccessMessage() },
                        modifier = Modifier.size(28.dp),
                    ) {
                        Icon(
                            Icons.Default.Close,
                            contentDescription = "Dismiss",
                            tint = if (colors.isDark) Color(0xFFBBF7B0) else Color(0xFF14532D),
                            modifier = Modifier.size(16.dp),
                        )
                    }
                }
            }
        }

        // ── Error banner (e.g. no phone number on account) ────────────────────
        state.errorMessage?.let { err ->
            if (!state.showEmailVerifySheet && !state.showPhoneVerifySheet) {
                val errBg = if (colors.isDark) Color(0xFF3B1A1A) else Color(0xFFFFEDED)
                val errBorder = if (colors.isDark) Color(0xFF7F2020) else Color(0xFFFFAAAA)
                val errText = if (colors.isDark) Color(0xFFFFB3B3) else Color(0xFF7F1D1D)
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 4.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = errBg),
                    border = BorderStroke(1.5.dp, errBorder),
                    elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(
                            Icons.Default.Warning,
                            contentDescription = null,
                            tint = errText,
                            modifier = Modifier.size(20.dp),
                        )
                        Spacer(Modifier.width(12.dp))
                        Text(
                            err,
                            modifier = Modifier.weight(1f),
                            color = errText,
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Medium,
                        )
                        IconButton(
                            onClick = { authViewModel.clearError() },
                            modifier = Modifier.size(28.dp),
                        ) {
                            Icon(
                                Icons.Default.Close,
                                contentDescription = "Dismiss",
                                tint = errText,
                                modifier = Modifier.size(16.dp),
                            )
                        }
                    }
                }
            }
        }
        // ── Header ────────────────────────────────────────────────────────────
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
                    Text(
                        initials,
                        color = Color.White,
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                    )
                }
                Spacer(Modifier.width(16.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        user?.fullName ?: "Guest",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = colors.title,
                    )
                    Spacer(Modifier.height(2.dp))
                    Text(
                        user?.email ?: "",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.subtitle,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                    user?.phoneNumber?.let {
                        Spacer(Modifier.height(2.dp))
                        Text(it, style = MaterialTheme.typography.bodySmall, color = colors.muted)
                    }
                }
            }
        }

        Spacer(Modifier.height(14.dp))

        // ── Verification card ─────────────────────────────────────────────────
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = colors.card),
            border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.9f)),
        ) {
            Column(modifier = Modifier.padding(18.dp)) {
                Text(
                    "Verification",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = colors.title,
                )
                Spacer(Modifier.height(14.dp))

                VerificationRow(
                    icon = Icons.Default.Email,
                    label = "Email",
                    value = user?.email ?: "—",
                    isVerified = user?.isEmailVerified ?: false,
                    isSending = state.isSendingEmailCode,
                    onVerify = { authViewModel.startEmailVerification() },
                )

                HorizontalDivider(
                    modifier = Modifier.padding(vertical = 14.dp),
                    color = colors.cardBorder,
                )

                VerificationRow(
                    icon = Icons.Default.Phone,
                    label = "Mobile",
                    value = user?.phoneNumber ?: "Not set",
                    isVerified = user?.isPhoneVerified ?: false,
                    isSending = state.isSendingPhoneCode,
                    onVerify = if (!user?.phoneNumber.isNullOrBlank()) {
                        { authViewModel.startPhoneVerification() }
                    } else null,
                )
            }
        }

        Spacer(Modifier.height(14.dp))

        // ── Account menu ──────────────────────────────────────────────────────
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
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

        // ── Sign out ──────────────────────────────────────────────────────────
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = colors.card),
            border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.9f)),
        ) {
            ProfileMenuItem(
                icon = Icons.Default.Logout,
                label = "Sign Out",
                tint = MaterialTheme.colorScheme.error,
                onClick = { showLogoutDialog = true },
            )
        }

        Spacer(Modifier.height(32.dp))
    }
}

// ── Verification Row ──────────────────────────────────────────────────────────

@Composable
private fun VerificationRow(
    icon: ImageVector,
    label: String,
    value: String,
    isVerified: Boolean,
    isSending: Boolean,
    onVerify: (() -> Unit)?,
) {
    val colors = MaterialTheme.grocery
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, contentDescription = null, tint = GreenPrimary, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                label,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = colors.title,
            )
            Text(
                value,
                style = MaterialTheme.typography.bodySmall,
                color = colors.muted,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(Modifier.height(4.dp))
            val verifiedColor = if (isVerified) Color(0xFF22C55E) else Color(0xFFF59E0B)
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
                modifier = Modifier
                    .background(verifiedColor.copy(alpha = 0.12f), RoundedCornerShape(50))
                    .padding(horizontal = 8.dp, vertical = 3.dp),
            ) {
                Icon(
                    if (isVerified) Icons.Default.CheckCircle else Icons.Default.Warning,
                    contentDescription = null,
                    tint = verifiedColor,
                    modifier = Modifier.size(12.dp),
                )
                Text(
                    if (isVerified) "Verified" else "Unverified",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = verifiedColor,
                )
            }
        }

        if (!isVerified && onVerify != null) {
            Spacer(Modifier.width(8.dp))
            if (isSending) {
                CircularProgressIndicator(
                    color = GreenPrimary,
                    modifier = Modifier.size(24.dp),
                    strokeWidth = 2.dp,
                )
            } else {
                Button(
                    onClick = onVerify,
                    contentPadding = PaddingValues(horizontal = 14.dp, vertical = 6.dp),
                    modifier = Modifier.height(34.dp),
                    shape = RoundedCornerShape(50),
                    colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
                ) {
                    Text("Verify", fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}

// ── OTP Bottom Sheet ──────────────────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun OtpSheet(
    title: String,
    subtitle: String,
    isLoading: Boolean,
    isSendingCode: Boolean,
    errorMessage: String?,
    onDismiss: () -> Unit,
    onResend: () -> Unit,
    onVerify: (String) -> Unit,
) {
    val colors = MaterialTheme.grocery
    // Local OTP state — reset each time the sheet is shown
    var otpValue by remember { mutableStateOf("") }
    var submitted by remember { mutableStateOf(false) }

    // Reset when error comes back (wrong code — let user retry)
    LaunchedEffect(errorMessage) {
        if (errorMessage != null) {
            otpValue = ""
            submitted = false
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = colors.background,
        dragHandle = { BottomSheetDefaults.DragHandle() },
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .padding(horizontal = 28.dp)
                .padding(bottom = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(title, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = colors.title)
            Spacer(Modifier.height(8.dp))
            Text(
                subtitle,
                fontSize = 13.sp,
                color = colors.subtitle,
                textAlign = androidx.compose.ui.text.style.TextAlign.Center,
            )

            Spacer(Modifier.height(28.dp))

            // OTP input using OutlinedTextField — reliable keyboard, no zero-size hacks
            OutlinedTextField(
                value = otpValue,
                onValueChange = { input ->
                    if (!submitted) {
                        val digits = input.filter { it.isDigit() }.take(4)
                        otpValue = digits
                        if (digits.length == 4) {
                            submitted = true
                            onVerify(digits)
                        }
                    }
                },
                label = { Text("4-digit code") },
                placeholder = { Text("_ _ _ _") },
                singleLine = true,
                enabled = !isLoading && !submitted,
                keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
                    keyboardType = androidx.compose.ui.text.input.KeyboardType.NumberPassword,
                ),
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = GreenPrimary,
                    focusedLabelColor = GreenPrimary,
                ),
            )

            Spacer(Modifier.height(8.dp))

            errorMessage?.let {
                Text(
                    it,
                    color = MaterialTheme.colorScheme.error,
                    fontSize = 13.sp,
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                )
            }

            Spacer(Modifier.height(20.dp))

            Button(
                onClick = {
                    if (otpValue.length == 4 && !submitted) {
                        submitted = true
                        onVerify(otpValue)
                    }
                },
                enabled = otpValue.length == 4 && !isLoading && !submitted,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = GreenPrimary,
                    disabledContainerColor = GreenPrimary.copy(alpha = 0.4f),
                ),
            ) {
                if (isLoading || submitted) {
                    CircularProgressIndicator(
                        color = Color.White,
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp,
                    )
                } else {
                    Text("Verify", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                }
            }

            Spacer(Modifier.height(10.dp))

            TextButton(
                onClick = {
                    otpValue = ""
                    submitted = false
                    onResend()
                },
                enabled = !isLoading && !isSendingCode,
            ) {
                if (isSendingCode) {
                    CircularProgressIndicator(
                        color = GreenPrimary,
                        modifier = Modifier.size(16.dp),
                        strokeWidth = 2.dp,
                    )
                    Spacer(Modifier.width(6.dp))
                }
                Text("Resend Code", color = GreenPrimary, fontWeight = FontWeight.Medium)
            }

            TextButton(onClick = onDismiss) {
                Text("Cancel", color = colors.muted)
            }
        }
    }
}

// ── Profile Menu Item ─────────────────────────────────────────────────────────

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
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.width(14.dp))
        Text(
            label,
            modifier = Modifier.weight(1f),
            color = if (tint == GreenPrimary) colors.title else tint,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Medium,
        )
        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = colors.muted, modifier = Modifier.size(18.dp))
    }
}
