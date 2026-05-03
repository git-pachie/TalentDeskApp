package com.sanshare.groceryapp.ui.screens.profile

import androidx.compose.foundation.background
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
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sanshare.groceryapp.data.remote.ApiClient
import com.sanshare.groceryapp.data.remote.ApiConfig
import com.sanshare.groceryapp.data.remote.ApiResult
import com.sanshare.groceryapp.data.remote.VoucherDto
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
class VoucherViewModel @Inject constructor(private val apiClient: ApiClient) : ViewModel() {
    private val _vouchers = MutableStateFlow<List<VoucherDto>>(emptyList())
    val vouchers: StateFlow<List<VoucherDto>> = _vouchers.asStateFlow()
    private val _loading = MutableStateFlow(false)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()

    fun load() {
        viewModelScope.launch {
            _loading.value = true
            val r = apiClient.get<List<VoucherDto>>(ApiConfig.VOUCHERS_USER)
            if (r is ApiResult.Success) _vouchers.value = r.data
            _loading.value = false
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VouchersScreen(
    onBack: () -> Unit,
    viewModel: VoucherViewModel = hiltViewModel(),
) {
    val vouchers by viewModel.vouchers.collectAsState()
    val loading by viewModel.loading.collectAsState()
    val colors = MaterialTheme.grocery
    val clipboard = LocalClipboardManager.current

    LaunchedEffect(Unit) { viewModel.load() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("My Vouchers") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null) } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = colors.background)
            )
        },
        containerColor = colors.background,
    ) { padding ->
        if (loading) LoadingBox()
        else if (vouchers.isEmpty()) EmptyState("🎟️", "No Vouchers", "Vouchers assigned to you will appear here.")
        else LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            items(vouchers, key = { it.id }) { v ->
                val isExpired = v.expiryDate < java.time.LocalDate.now().toString()
                Card(
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = colors.card),
                    elevation = CardDefaults.cardElevation(2.dp),
                ) {
                    Row(modifier = Modifier.fillMaxWidth()) {
                        // Left accent strip
                        Box(
                            modifier = Modifier
                                .width(6.dp)
                                .fillMaxHeight()
                                .background(if (isExpired) Color.Gray else GreenPrimary, RoundedCornerShape(topStart = 14.dp, bottomStart = 14.dp))
                        )
                        Column(modifier = Modifier.padding(14.dp).weight(1f)) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                // Discount value
                                Text(
                                    if (v.type.lowercase() == "percentage") "${v.value.toInt()}% OFF"
                                    else "₱${v.value.toInt()} OFF",
                                    fontSize = 20.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = if (isExpired) Color.Gray else GreenPrimary,
                                )
                                // Status badge
                                Box(
                                    modifier = Modifier
                                        .background(
                                            if (isExpired) Color.Gray.copy(alpha = 0.15f) else GreenPrimary.copy(alpha = 0.12f),
                                            RoundedCornerShape(6.dp)
                                        )
                                        .padding(horizontal = 8.dp, vertical = 3.dp)
                                ) {
                                    Text(
                                        if (isExpired) "Expired" else "Active",
                                        fontSize = 11.sp,
                                        color = if (isExpired) Color.Gray else GreenPrimary,
                                        fontWeight = FontWeight.SemiBold,
                                    )
                                }
                            }

                            Spacer(Modifier.height(4.dp))
                            v.description?.let { Text(it, fontSize = 13.sp, color = colors.subtitle) }

                            Spacer(Modifier.height(8.dp))
                            Divider(color = colors.cardBorder)
                            Spacer(Modifier.height(8.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically,
                            ) {
                                Column {
                                    Text("Code", fontSize = 11.sp, color = colors.muted)
                                    Text(v.code, fontWeight = FontWeight.Bold, color = colors.title, fontSize = 15.sp)
                                }
                                IconButton(
                                    onClick = { clipboard.setText(AnnotatedString(v.code)) },
                                    modifier = Modifier.size(32.dp),
                                ) {
                                    Icon(Icons.Default.ContentCopy, null, tint = GreenPrimary, modifier = Modifier.size(18.dp))
                                }
                            }

                            Spacer(Modifier.height(4.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                                if (v.minimumSpend > 0) {
                                    Text("Min. ₱${v.minimumSpend.toInt()}", fontSize = 11.sp, color = colors.muted)
                                }
                                Text("Expires ${v.expiryDate.take(10)}", fontSize = 11.sp, color = colors.muted)
                            }
                        }
                    }
                }
            }
        }
    }
}
