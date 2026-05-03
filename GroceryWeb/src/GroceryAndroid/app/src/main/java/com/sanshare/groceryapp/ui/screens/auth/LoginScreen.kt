package com.sanshare.groceryapp.ui.screens.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.*
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.BorderStroke
import com.sanshare.groceryapp.ui.components.GroceryIconView
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.AuthViewModel

@Composable
fun LoginScreen(
    authViewModel: AuthViewModel,
    onLoginSuccess: () -> Unit,
    onNeedsVerification: () -> Unit,
    onNavigateToRegister: () -> Unit,
) {
    val state by authViewModel.state.collectAsState()
    val focusManager = LocalFocusManager.current

    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }

    // React to auth state changes
    LaunchedEffect(state.isAuthenticated, state.requiresEmailVerification) {
        when {
            state.isAuthenticated           -> onLoginSuccess()
            state.requiresEmailVerification -> onNeedsVerification()
        }
    }

    val colors = MaterialTheme.grocery

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
    ) {
        // Top gradient decoration
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(260.dp)
                .background(
                    Brush.verticalGradient(
                        colors = listOf(GreenPrimary.copy(alpha = 0.15f), Color.Transparent)
                    )
                )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.height(64.dp))

            GroceryIconView(size = 72)
            Spacer(Modifier.height(18.dp))
            Text("GroceryApp", style = MaterialTheme.typography.headlineMedium, color = colors.title)
            Spacer(Modifier.height(6.dp))
            Text(
                "Sign in to your account",
                style = MaterialTheme.typography.bodyMedium,
                color = colors.muted
            )

            Spacer(Modifier.height(32.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(28.dp),
                colors = CardDefaults.cardColors(containerColor = colors.card.copy(alpha = if (colors.isDark) 0.94f else 0.98f)),
                border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.9f))
            ) {
                Column(modifier = Modifier.padding(22.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    Text("Welcome back", style = MaterialTheme.typography.titleLarge, color = colors.title, fontWeight = FontWeight.Bold)

                    OutlinedTextField(
                        value = email,
                        onValueChange = { email = it },
                        label = { Text("Email") },
                        leadingIcon = { Icon(Icons.Default.Email, null, tint = colors.muted) },
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Email,
                            imeAction = ImeAction.Next,
                        ),
                        keyboardActions = KeyboardActions(onNext = { focusManager.moveFocus(FocusDirection.Down) }),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(18.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = GreenPrimary,
                            focusedLabelColor = GreenPrimary,
                            unfocusedBorderColor = colors.cardBorder.copy(alpha = 1f),
                            unfocusedContainerColor = colors.background.copy(alpha = if (colors.isDark) 0.6f else 1f),
                            focusedContainerColor = colors.background.copy(alpha = if (colors.isDark) 0.6f else 1f),
                        )
                    )

                    OutlinedTextField(
                        value = password,
                        onValueChange = { password = it },
                        label = { Text("Password") },
                        leadingIcon = { Icon(Icons.Default.Lock, null, tint = colors.muted) },
                        trailingIcon = {
                            IconButton(onClick = { passwordVisible = !passwordVisible }) {
                                Icon(
                                    if (passwordVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                                    null, tint = colors.muted
                                )
                            }
                        },
                        visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                        keyboardOptions = KeyboardOptions(
                            keyboardType = KeyboardType.Password,
                            imeAction = ImeAction.Done,
                        ),
                        keyboardActions = KeyboardActions(onDone = {
                            focusManager.clearFocus()
                            if (email.isNotBlank() && password.isNotBlank()) {
                                authViewModel.login(email, password)
                            }
                        }),
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(18.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = GreenPrimary,
                            focusedLabelColor = GreenPrimary,
                            unfocusedBorderColor = colors.cardBorder.copy(alpha = 1f),
                            unfocusedContainerColor = colors.background.copy(alpha = if (colors.isDark) 0.6f else 1f),
                            focusedContainerColor = colors.background.copy(alpha = if (colors.isDark) 0.6f else 1f),
                        )
                    )

                    state.errorMessage?.let { err ->
                        Text(err, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                    }

                    Button(
                        onClick = {
                            focusManager.clearFocus()
                            authViewModel.login(email, password)
                        },
                        enabled = email.isNotBlank() && password.isNotBlank() && !state.isLoading,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(56.dp),
                        shape = RoundedCornerShape(18.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
                    ) {
                        if (state.isLoading) {
                            CircularProgressIndicator(color = Color.White, modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                        } else {
                            Text("Sign In", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                        }
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.Center
                    ) {
                        Text("Don't have an account? ", color = colors.subtitle, style = MaterialTheme.typography.bodyMedium)
                        Text(
                            "Sign Up",
                            color = GreenPrimary,
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.SemiBold,
                            modifier = Modifier.clickable { onNavigateToRegister() }
                        )
                    }
                }
            }

            Spacer(Modifier.height(28.dp))
        }
    }
}
