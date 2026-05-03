package com.sanshare.groceryapp.ui.screens.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.AuthViewModel

@Composable
fun EmailVerificationScreen(
    authViewModel: AuthViewModel,
    onVerified: () -> Unit,
) {
    val state by authViewModel.state.collectAsState()
    val colors = MaterialTheme.grocery

    var code by remember { mutableStateOf("") }
    val focusRequester = remember { FocusRequester() }

    LaunchedEffect(state.isAuthenticated) {
        if (state.isAuthenticated) onVerified()
    }

    LaunchedEffect(Unit) {
        focusRequester.requestFocus()
    }

    // Auto-submit when 4 digits entered
    LaunchedEffect(code) {
        if (code.length == 4) {
            authViewModel.verifyEmail(code)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(80.dp))

        Text("📧", fontSize = 56.sp)
        Spacer(Modifier.height(16.dp))
        Text("Verify Your Email", fontSize = 22.sp, fontWeight = FontWeight.Bold, color = colors.title)
        Spacer(Modifier.height(8.dp))
        Text(
            "Enter the 4-digit code sent to\n${state.pendingVerificationEmail}",
            fontSize = 14.sp,
            color = colors.subtitle,
            textAlign = TextAlign.Center,
        )

        Spacer(Modifier.height(40.dp))

        // Hidden text field driving the OTP boxes
        BasicTextField(
            value = code,
            onValueChange = { if (it.length <= 4 && it.all { c -> c.isDigit() }) code = it },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
            modifier = Modifier
                .size(0.dp)
                .focusRequester(focusRequester),
        )

        // OTP boxes
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            repeat(4) { index ->
                val digit = code.getOrNull(index)?.toString() ?: ""
                val isFocused = index == code.length
                Box(
                    modifier = Modifier
                        .size(60.dp)
                        .background(colors.card, RoundedCornerShape(12.dp))
                        .border(
                            width = if (isFocused) 2.dp else 1.dp,
                            color = if (isFocused) GreenPrimary else colors.cardBorder,
                            shape = RoundedCornerShape(12.dp),
                        ),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = digit,
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        color = colors.title,
                    )
                }
            }
        }

        state.errorMessage?.let { err ->
            Spacer(Modifier.height(12.dp))
            Text(err, color = MaterialTheme.colorScheme.error, fontSize = 13.sp)
        }

        Spacer(Modifier.height(32.dp))

        if (state.isLoading) {
            CircularProgressIndicator(color = GreenPrimary)
        } else {
            Button(
                onClick = { if (code.length == 4) authViewModel.verifyEmail(code) },
                enabled = code.length == 4,
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
            ) {
                Text("Verify Email", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
            }
        }

        Spacer(Modifier.height(16.dp))

        TextButton(onClick = { /* TODO: resend code */ }) {
            Text("Resend Code", color = GreenPrimary)
        }
    }
}
