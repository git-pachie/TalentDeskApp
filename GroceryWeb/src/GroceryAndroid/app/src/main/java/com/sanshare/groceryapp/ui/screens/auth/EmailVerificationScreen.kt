package com.sanshare.groceryapp.ui.screens.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.AuthViewModel

/**
 * Full-screen email verification shown after login/register when
 * requiresEmailVerification = true.
 *
 * - Sends a code automatically on first appear.
 * - Auto-submits when 4 digits are entered.
 * - Resend Code re-sends via API.
 * - "Log In Instead" logs out and goes back to login.
 */
@Composable
fun EmailVerificationScreen(
    authViewModel: AuthViewModel,
    onVerified: () -> Unit,
    onBack: (() -> Unit)? = null,
) {
    val state by authViewModel.state.collectAsState()
    val colors = MaterialTheme.grocery

    var otpValue by remember { mutableStateOf("") }
    var submitted by remember { mutableStateOf(false) }
    var statusMessage by remember { mutableStateOf("") }

    // Navigate away once authenticated
    LaunchedEffect(state.isAuthenticated) {
        if (state.isAuthenticated) onVerified()
    }

    // Send code on first appear
    LaunchedEffect(Unit) {
        authViewModel.resendEmailVerificationCode()
        statusMessage = "A verification code has been sent to your email."
    }

    // Reset boxes when error arrives (wrong code — let user retry)
    LaunchedEffect(state.errorMessage) {
        if (state.errorMessage != null) {
            otpValue = ""
            submitted = false
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(72.dp))

        Box(
            modifier = Modifier
                .size(90.dp)
                .background(GreenPrimary.copy(alpha = 0.12f), CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                Icons.Default.Email,
                contentDescription = null,
                tint = GreenPrimary,
                modifier = Modifier.size(42.dp),
            )
        }

        Spacer(Modifier.height(24.dp))

        Text(
            "Verify Your Email",
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = colors.title,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            "We sent a 4-digit code to",
            fontSize = 14.sp,
            color = colors.subtitle,
            textAlign = TextAlign.Center,
        )
        Text(
            state.pendingVerificationEmail.ifBlank { "your email" },
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
            color = GreenPrimary,
            textAlign = TextAlign.Center,
        )

        Spacer(Modifier.height(32.dp))

        // OTP input — standard OutlinedTextField, no zero-size hacks
        OutlinedTextField(
            value = otpValue,
            onValueChange = { input ->
                if (!submitted) {
                    val digits = input.filter { it.isDigit() }.take(4)
                    otpValue = digits
                    if (digits.length == 4) {
                        submitted = true
                        authViewModel.verifyEmail(digits)
                    }
                }
            },
            label = { Text("4-digit code") },
            placeholder = { Text("_ _ _ _") },
            singleLine = true,
            enabled = !state.isLoading && !submitted,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(14.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = GreenPrimary,
                focusedLabelColor = GreenPrimary,
                unfocusedBorderColor = colors.cardBorder,
            ),
        )

        Spacer(Modifier.height(10.dp))

        state.errorMessage?.let { err ->
            Text(
                err,
                color = MaterialTheme.colorScheme.error,
                fontSize = 13.sp,
                textAlign = TextAlign.Center,
            )
        }

        if (statusMessage.isNotBlank() && state.errorMessage == null) {
            Text(
                statusMessage,
                color = GreenPrimary,
                fontSize = 13.sp,
                textAlign = TextAlign.Center,
            )
        }

        Spacer(Modifier.height(24.dp))

        Button(
            onClick = {
                if (otpValue.length == 4 && !submitted) {
                    submitted = true
                    authViewModel.verifyEmail(otpValue)
                }
            },
            enabled = otpValue.length == 4 && !state.isLoading && !submitted,
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp),
            shape = RoundedCornerShape(14.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = GreenPrimary,
                disabledContainerColor = GreenPrimary.copy(alpha = 0.4f),
            ),
        ) {
            if (state.isLoading || submitted) {
                CircularProgressIndicator(
                    color = Color.White,
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp,
                )
            } else {
                Text("Verify Email", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            }
        }

        Spacer(Modifier.height(12.dp))

        TextButton(
            onClick = {
                otpValue = ""
                submitted = false
                statusMessage = ""
                authViewModel.clearError()
                authViewModel.resendEmailVerificationCode()
                statusMessage = "A new code has been sent."
            },
            enabled = !state.isLoading && !state.isSendingEmailCode,
        ) {
            if (state.isSendingEmailCode) {
                CircularProgressIndicator(
                    color = GreenPrimary,
                    modifier = Modifier.size(16.dp),
                    strokeWidth = 2.dp,
                )
                Spacer(Modifier.width(6.dp))
            }
            Text("Resend Code", color = GreenPrimary, fontWeight = FontWeight.Medium)
        }

        if (onBack != null) {
            TextButton(onClick = {
                authViewModel.logout()
                onBack()
            }) {
                Text("Log In Instead", color = colors.subtitle)
            }
        }

        Spacer(Modifier.height(40.dp))
    }
}
