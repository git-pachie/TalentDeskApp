package com.sanshare.groceryapp.ui.screens.auth

import androidx.compose.foundation.background
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.*
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
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
                .padding(horizontal = 24.dp),
        ) {
            Spacer(Modifier.height(8.dp))

            fun field(
                value: String,
                onChange: (String) -> Unit,
                label: String,
                icon: @Composable () -> Unit,
                keyboardType: KeyboardType = KeyboardType.Text,
                imeAction: ImeAction = ImeAction.Next,
                visualTransformation: VisualTransformation = VisualTransformation.None,
                trailingIcon: (@Composable () -> Unit)? = null,
            ) {
                OutlinedTextField(
                    value = value,
                    onValueChange = onChange,
                    label = { Text(label) },
                    leadingIcon = icon,
                    trailingIcon = trailingIcon,
                    keyboardOptions = KeyboardOptions(keyboardType = keyboardType, imeAction = imeAction),
                    keyboardActions = KeyboardActions(
                        onNext = { focusManager.moveFocus(FocusDirection.Down) },
                        onDone = { focusManager.clearFocus() }
                    ),
                    visualTransformation = visualTransformation,
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = GreenPrimary,
                        focusedLabelColor = GreenPrimary,
                    )
                )
                Spacer(Modifier.height(12.dp))
            }

            field(firstName, { firstName = it }, "First Name",
                { Icon(Icons.Default.Person, null, tint = colors.muted) })
            field(lastName, { lastName = it }, "Last Name",
                { Icon(Icons.Default.Person, null, tint = colors.muted) })
            field(email, { email = it }, "Email",
                { Icon(Icons.Default.Email, null, tint = colors.muted) },
                keyboardType = KeyboardType.Email)
            field(phone, { phone = it }, "Phone (optional)",
                { Icon(Icons.Default.Phone, null, tint = colors.muted) },
                keyboardType = KeyboardType.Phone)
            field(
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
                }
            )
            field(
                confirmPassword, { confirmPassword = it }, "Confirm Password",
                { Icon(Icons.Default.Lock, null, tint = colors.muted) },
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done,
                visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
            )

            // Errors
            val displayError = localError ?: state.errorMessage
            displayError?.let {
                Text(it, color = MaterialTheme.colorScheme.error, fontSize = 13.sp)
                Spacer(Modifier.height(8.dp))
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
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
            ) {
                if (state.isLoading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                } else {
                    Text("Create Account", fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                }
            }
            Spacer(Modifier.height(32.dp))
        }
    }
}
