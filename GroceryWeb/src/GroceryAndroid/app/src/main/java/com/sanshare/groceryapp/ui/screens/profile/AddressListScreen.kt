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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sanshare.groceryapp.data.remote.AddressDto
import com.sanshare.groceryapp.data.remote.CreateAddressRequest
import com.sanshare.groceryapp.ui.components.EmptyState
import com.sanshare.groceryapp.ui.components.LoadingBox
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.AddressViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddressListScreen(
    onBack: () -> Unit,
    viewModel: AddressViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsState()
    val colors = MaterialTheme.grocery
    var showAddSheet by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { viewModel.loadAddresses() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Addresses") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null) } },
                actions = {
                    IconButton(onClick = { showAddSheet = true }) {
                        Icon(Icons.Default.Add, null, tint = GreenPrimary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = colors.background)
            )
        },
        containerColor = colors.background,
    ) { padding ->
        if (state.isLoading) {
            LoadingBox()
        } else if (state.addresses.isEmpty()) {
            EmptyState("📍", "No Addresses", "Add a delivery address to get started.")
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(state.addresses, key = { it.id }) { addr ->
                    AddressCard(
                        address = addr,
                        onDelete = { viewModel.deleteAddress(addr.id) },
                    )
                }
            }
        }
    }

    if (showAddSheet) {
        AddAddressSheet(
            onDismiss = { showAddSheet = false },
            onSave = { req ->
                viewModel.createAddress(req)
                showAddSheet = false
            }
        )
    }
}

@Composable
private fun AddressCard(address: AddressDto, onDelete: () -> Unit) {
    val colors = MaterialTheme.grocery
    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = colors.card),
        elevation = CardDefaults.cardElevation(2.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth().padding(14.dp),
            verticalAlignment = Alignment.Top,
        ) {
            Icon(Icons.Default.LocationOn, null, tint = GreenPrimary, modifier = Modifier.size(22.dp))
            Spacer(Modifier.width(10.dp))
            Column(Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(address.label, fontWeight = FontWeight.SemiBold, color = colors.title)
                    if (address.isDefault) {
                        Spacer(Modifier.width(6.dp))
                        Box(
                            modifier = Modifier
                                .background(GreenPrimary.copy(alpha = 0.12f), RoundedCornerShape(4.dp))
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text("Default", fontSize = 10.sp, color = GreenPrimary, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
                Text(address.fullAddress, fontSize = 12.sp, color = colors.subtitle)
                address.contactNumber?.let { Text(it, fontSize = 12.sp, color = GreenPrimary) }
                address.deliveryInstructions?.let { Text(it, fontSize = 11.sp, color = colors.muted) }
            }
            IconButton(onClick = onDelete, modifier = Modifier.size(32.dp)) {
                Icon(Icons.Default.Delete, null, tint = Color(0xFFEF4444), modifier = Modifier.size(18.dp))
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddAddressSheet(onDismiss: () -> Unit, onSave: (CreateAddressRequest) -> Unit) {
    val colors = MaterialTheme.grocery
    var label by remember { mutableStateOf("") }
    var street by remember { mutableStateOf("") }
    var city by remember { mutableStateOf("") }
    var province by remember { mutableStateOf("") }
    var zipCode by remember { mutableStateOf("") }
    var contact by remember { mutableStateOf("") }
    var instructions by remember { mutableStateOf("") }
    var isDefault by remember { mutableStateOf(false) }

    ModalBottomSheet(onDismissRequest = onDismiss) {
        Column(modifier = Modifier.padding(16.dp).navigationBarsPadding()) {
            Text("Add Address", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(12.dp))

            @Composable
            fun Field(value: String, onChange: (String) -> Unit, label: String) {
                OutlinedTextField(
                    value = value, onValueChange = onChange, label = { Text(label) },
                    modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
                    shape = RoundedCornerShape(10.dp),
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = GreenPrimary),
                )
            }

            Field(label, { label = it }, "Label (e.g. Home)")
            Field(street, { street = it }, "Street")
            Field(city, { city = it }, "City")
            Field(province, { province = it }, "Province")
            Field(zipCode, { zipCode = it }, "ZIP Code")
            Field(contact, { contact = it }, "Contact Number")
            Field(instructions, { instructions = it }, "Delivery Instructions (optional)")

            Row(verticalAlignment = Alignment.CenterVertically) {
                Checkbox(checked = isDefault, onCheckedChange = { isDefault = it }, colors = CheckboxDefaults.colors(checkedColor = GreenPrimary))
                Text("Set as default address", fontSize = 14.sp, color = colors.title)
            }

            Spacer(Modifier.height(8.dp))
            Button(
                onClick = {
                    onSave(CreateAddressRequest(
                        label = label, street = street, city = city,
                        province = province, zipCode = zipCode,
                        contactNumber = contact.ifBlank { null },
                        deliveryInstructions = instructions.ifBlank { null },
                        isDefault = isDefault,
                    ))
                },
                enabled = label.isNotBlank() && street.isNotBlank() && city.isNotBlank(),
                modifier = Modifier.fillMaxWidth().height(50.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
            ) { Text("Save Address", fontWeight = FontWeight.SemiBold) }
            Spacer(Modifier.height(16.dp))
        }
    }
}
