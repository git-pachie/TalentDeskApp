package com.sanshare.groceryapp.ui.screens.splash

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sanshare.groceryapp.ui.components.GroceryIconView
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.viewmodel.AuthViewModel
import kotlinx.coroutines.delay

@Composable
fun SplashScreen(
    onReady: (Boolean) -> Unit,
    authViewModel: AuthViewModel = hiltViewModel(),
) {
    var visible by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        visible = true
        delay(1400)
        onReady(true)
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF2D7A2A),
                        GreenPrimary,
                        Color(0xFF7DC97A),
                    )
                )
            ),
        contentAlignment = Alignment.Center,
    ) {
        AnimatedVisibility(
            visible = visible,
            enter = fadeIn() + scaleIn(initialScale = 0.8f),
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                GroceryIconView(size = 80)
                Spacer(Modifier.height(16.dp))
                Text(
                    text = "GroceryApp",
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                )
                Spacer(Modifier.height(6.dp))
                Text(
                    text = "Fresh groceries, delivered fast",
                    fontSize = 14.sp,
                    color = Color.White.copy(alpha = 0.8f),
                )
            }
        }
    }
}
