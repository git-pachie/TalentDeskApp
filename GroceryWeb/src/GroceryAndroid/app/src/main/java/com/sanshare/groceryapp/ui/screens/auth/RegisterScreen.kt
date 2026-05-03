package com.sanshare.groceryapp.ui.screens.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusManager
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.*
import androidx.compose.ui.unit.dp
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.AuthViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RegisterScreen(
    authViewModel: AuthViewModel,
    onSuccess: () -> Unit,
    onNeedsVerification: () -> Unit,
    onBack: () -> Unit,
) {
    val state by authViewModel.state.collectAsState()
    val focusManager = LocalFocusManager.current
    val colors = MaterialTheme.grocery

    var firstName by remember { mutableStateOf("") }
    var lastName by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }
    var localError by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(state.isAuthenticated, state.requiresEmailVerification) {
        when {
            state.isAuthenticated           -> onSuccess()
            state.requiresEmailVerification -> onNeedsVerification()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Create Account") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, null)
                    }
                },
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
                .padding(horizontal = 20.dp),
        ) {
            Spacer(Modifier.height(12.dp))

            Text("Join GroceryApp", style = MaterialTheme.typography.headlineMedium, color = colors.title)
            Spacer(Modifier.height(6.dp))
            Text(
                "Create your account to start ordering fresh groceries.",
                style = MaterialTheme.typography.bodyMedium,
                color = colors.muted
            )

            Spacer(Modifier.height(20.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(28.dp),
                colors = CardDefaults.cardColors(containerColor = colors.card),
                border = BorderStroke(1.dp, colors.cardBorder.copy(alpha = 0.9f))
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    RegisterField(firstName, { firstName = it }, "First Name",
                        { Icon(Icons.Default.Person, null, tint = colors.muted) }, focusManager = focusManager)
                    RegisterField(lastName, { lastName = it }, "Last Name",
                        { Icon(Icons.Default.Person, null, tint = colors.muted) }, focusManager = focusManager)
                    RegisterField(email, { email = it }, "Email",
                        { Icon(Icons.Default.Email, null, tint = colors.muted) },
                        keyboardType = KeyboardType.Email, focusManager = focusManager)
                    RegisterField(phone, { phone = it }, "Phone (optional)",
                        { Icon(Icons.Default.Phone, null, tint = colors.muted) },
                        keyboardType = KeyboardType.Phone, focusManager = focusManager)
                    RegisterField(
                        password, { password = it }, "Password",
                        { Icon(Icons.Default.Lock, null, tint = colors.muted) },
                        keyboardType = KeyboardType.Password,
                        visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                        trailingIcon = {
                            IconButton(onClick = { passwordVisible = !passwordVisible }) {
                                Icon(
                                    if (passwordVisible) Icons.Default.Visibility else Icons.Default.VisibilityOff,
                                    null, tint = colors.muted
                                )
                            }
                        },
                        focusManager = focusManager,
                    )
                    RegisterField(
                        confirmPassword, { confirmPassword = it }, "Confirm Password",
                        { Icon(Icons.Default.Lock, null, tint = colors.muted) },
                        keyboardType = KeyboardType.Password,
                        imeAction = ImeAction.Done,
                        visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                        focusManager = focusManager,
                    )

                    val displayError = localError ?: state.errorMessage
                    displayError?.let {
                        Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
                        Spacer(Modifier.height(12.dp))
                    }

                    Button(
                        onClick = {
                            localError = null
                            when {
                                firstName.isBlank() || lastName.isBlank() || email.isBlank() || password.isBlank() ->
                                    localError = "Please fill in all required fields."
                                password != confirmPassword ->
                                    localError = "Passwords do not match."
                                password.length < 8 ->
                                    localError = "Password must be at least 8 characters."
                                else -> authViewModel.register(firstName, lastName, email, password, phone.ifBlank { null })
                            }
                        },
                        enabled = !state.isLoading,
                        modifier = Modifier.fillMaxWidth().height(56.dp),
                        shape = RoundedCornerShape(18.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
                    ) {
                        if (state.isLoading) {
                            CircularProgressIndicator(color = Color.White, modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                        } else {
                            Text("Create Account", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }

            Spacer(Modifier.height(32.dp))
        }
    }
}

@Composable
private fun RegisterField(
    value: String,
    onChange: (String) -> Unit,
    label: String,
    leadingIcon: @Composable () -> Unit,
    keyboardType: KeyboardType = KeyboardType.Text,
    imeAction: ImeAction = ImeAction.Next,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    trailingIcon: (@Composable () -> Unit)? = null,
    focusManager: FocusManager,
) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        leadingIcon = leadingIcon,
        trailingIcon = trailingIcon,
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType, imeAction = imeAction),
        keyboardActions = KeyboardActions(
            onNext = { focusManager.moveFocus(FocusDirection.Down) },
            onDone = { focusManager.clearFocus() }
        ),
        visualTransformation = visualTransformation,
        singleLine = true,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(18.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = GreenPrimary,
            focusedLabelColor = GreenPrimary,
            unfocusedBorderColor = MaterialTheme.grocery.cardBorder.copy(alpha = 1f),
            unfocusedContainerColor = MaterialTheme.grocery.background.copy(alpha = if (MaterialTheme.grocery.isDark) 0.6f else 1f),
            focusedContainerColor = MaterialTheme.grocery.background.copy(alpha = if (MaterialTheme.grocery.isDark) 0.6f else 1f),
        )
    )
    Spacer(Modifier.height(14.dp))
}
