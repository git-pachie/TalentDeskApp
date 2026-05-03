package com.sanshare.groceryapp.ui.screens.profile

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sanshare.groceryapp.data.remote.ApiClient
import com.sanshare.groceryapp.data.remote.ApiConfig
import com.sanshare.groceryapp.data.remote.ApiResult
import com.sanshare.groceryapp.data.remote.PaymentMethodDto
import com.sanshare.groceryapp.ui.components.EmptyState
import com.sanshare.groceryapp.ui.components.LoadingBox
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class PaymentMethodViewModel @Inject constructor(private val apiClient: ApiClient) : ViewModel() {
    private val _methods = MutableStateFlow<List<PaymentMethodDto>>(emptyList())
    val methods: StateFlow<List<PaymentMethodDto>> = _methods.asStateFlow()
    private val _loading = MutableStateFlow(false)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()

    fun load() {
        viewModelScope.launch {
            _loading.value = true
            val r = apiClient.get<List<PaymentMethodDto>>(ApiConfig.PAYMENT_METHODS)
            if (r is ApiResult.Success) _methods.value = r.data
            _loading.value = false
        }
    }

    fun delete(id: String) {
        viewModelScope.launch {
            apiClient.delete("${ApiConfig.PAYMENT_METHODS}/$id")
            load()
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PaymentMethodsScreen(
    onBack: () -> Unit,
    viewModel: PaymentMethodViewModel = hiltViewModel(),
) {
    val methods by viewModel.methods.collectAsState()
    val loading by viewModel.loading.collectAsState()
    val colors = MaterialTheme.grocery

    LaunchedEffect(Unit) { viewModel.load() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Payment Methods") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null) } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = colors.background)
            )
        },
        containerColor = colors.background,
    ) { padding ->
        if (loading) LoadingBox()
        else if (methods.isEmpty()) EmptyState("💳", "No Payment Methods", "Add a payment method to speed up checkout.")
        else LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            items(methods, key = { it.id }) { pm ->
                Card(
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = colors.card),
                    elevation = CardDefaults.cardElevation(2.dp),
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        val icon = when (pm.paymentType.lowercase()) {
                            "gcash" -> Icons.Default.PhoneAndroid
                            "cashondelivery" -> Icons.Default.Money
                            else -> Icons.Default.CreditCard
                        }
                        Icon(icon, null, tint = GreenPrimary, modifier = Modifier.size(24.dp))
                        Spacer(Modifier.width(12.dp))
                        Column(Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(pm.name, fontWeight = FontWeight.SemiBold, color = colors.title)
                                if (pm.isDefault) {
                                    Spacer(Modifier.width(6.dp))
                                    Text("Default", fontSize = 10.sp, color = GreenPrimary)
                                }
                            }
                            pm.detail?.let { Text(it, fontSize = 12.sp, color = colors.muted) }
                        }
                        IconButton(onClick = { viewModel.delete(pm.id) }, modifier = Modifier.size(32.dp)) {
                            Icon(Icons.Default.Delete, null, tint = Color(0xFFEF4444), modifier = Modifier.size(18.dp))
                        }
                    }
                }
            }
        }
    }
}
