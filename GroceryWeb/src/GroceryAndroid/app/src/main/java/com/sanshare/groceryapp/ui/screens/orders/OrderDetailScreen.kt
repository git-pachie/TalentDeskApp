package com.sanshare.groceryapp.ui.screens.orders

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.sanshare.groceryapp.data.remote.OrderDto
import com.sanshare.groceryapp.data.remote.OrderReviewDto
import com.sanshare.groceryapp.data.remote.OrderReviewPhotoDto
import com.sanshare.groceryapp.ui.components.*
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.OrderViewModel
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OrderDetailScreen(
    orderId: String,
    onBack: () -> Unit,
    viewModel: OrderViewModel = hiltViewModel(),
) {
    val colors = MaterialTheme.grocery
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var order by remember { mutableStateOf<OrderDto?>(null) }
    var rating by remember { mutableIntStateOf(0) }
    var reviewText by remember { mutableStateOf("") }
    var reviewSubmitted by remember { mutableStateOf(false) }
    var selectedPhotoUris by remember { mutableStateOf<List<Uri>>(emptyList()) }
    var isSubmittingReview by remember { mutableStateOf(false) }
    var viewerPhotos by remember { mutableStateOf<List<String>>(emptyList()) }
    var viewerInitialPage by remember { mutableIntStateOf(0) }
    var showPhotoViewer by remember { mutableStateOf(false) }

    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickMultipleVisualMedia(maxItems = 5)
    ) { uris ->
        selectedPhotoUris = uris
    }

    LaunchedEffect(orderId) {
        viewModel.getOrderDetail(orderId).collect { loaded ->
            order = loaded
            val existing = loaded?.reviews?.firstOrNull()
            reviewSubmitted = existing != null
            if (existing != null) {
                rating = existing.rating
                reviewText = existing.comment.orEmpty()
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(order?.orderNumber ?: "Order Details") },
                navigationIcon = { IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null) } },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = colors.background)
            )
        },
        containerColor = colors.background,
    ) { padding ->
        if (order == null) {
            LoadingBox()
            return@Scaffold
        }

        val o = order!!
        val existingReview = o.reviews?.firstOrNull()
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            // Header
            Card(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(14.dp), colors = CardDefaults.cardColors(containerColor = colors.card)) {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column {
                        Text(o.orderNumber, fontWeight = FontWeight.Normal, fontSize = 18.sp, color = colors.title)
                        Text(formatLocalDate(o.createdAt), fontSize = 12.sp, color = colors.muted)
                    }
                    OrderStatusBadge(o.status)
                }
            }

            // Status timeline
            if (!o.statusHistory.isNullOrEmpty()) {
                Card(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(14.dp), colors = CardDefaults.cardColors(containerColor = colors.card)) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Order Status", fontWeight = FontWeight.Bold, color = colors.title)
                        Spacer(Modifier.height(12.dp))
                        o.statusHistory.forEachIndexed { idx, entry ->
                            Row(verticalAlignment = Alignment.Top) {
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Box(
                                        modifier = Modifier
                                            .size(10.dp)
                                            .background(
                                                if (idx == o.statusHistory.size - 1) GreenPrimary else Color.Gray.copy(alpha = 0.4f),
                                                CircleShape
                                            )
                                    )
                                    if (idx < o.statusHistory.size - 1) {
                                        Box(modifier = Modifier.width(2.dp).height(32.dp).background(Color.Gray.copy(alpha = 0.3f)))
                                    }
                                }
                                Spacer(Modifier.width(12.dp))
                                Column(modifier = Modifier.padding(bottom = if (idx < o.statusHistory.size - 1) 8.dp else 0.dp)) {
                                    Text(entry.status, fontWeight = FontWeight.SemiBold, fontSize = 13.sp, color = colors.title)
                                    Text("${entry.createdAt.take(16).replace("T", " ")} · ${entry.createdBy}", fontSize = 11.sp, color = colors.muted)
                                    entry.notes?.let { Text(it, fontSize = 11.sp, color = colors.subtitle) }
                                }
                            }
                        }
                    }
                }
            }

            // Items
            Card(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(14.dp), colors = CardDefaults.cardColors(containerColor = colors.card)) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Items Ordered", fontWeight = FontWeight.Bold, color = colors.title)
                    Spacer(Modifier.height(10.dp))
                    o.items?.forEach { item ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(IntrinsicSize.Min)
                                .padding(vertical = 4.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Box(
                                modifier = Modifier
                                    .width(52.dp)
                                    .fillMaxHeight()
                                    .clip(RoundedCornerShape(10.dp))
                                    .background(Color(0xFFF5F5F5)),
                                contentAlignment = Alignment.Center,
                            ) {
                                if (item.productImageUrl != null) {
                                    AsyncImage(model = item.productImageUrl, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
                                } else {
                                    Text("🛒", fontSize = 20.sp)
                                }
                            }
                            Spacer(Modifier.width(10.dp))
                            Column(Modifier.weight(1f)) {
                                Text(item.productName, fontSize = 12.sp, fontWeight = FontWeight.Normal, color = colors.title)
                                Text("x${item.quantity} @ ₱${item.unitPrice.toInt()}", fontSize = 11.sp, color = colors.muted)
                                item.remarks?.let { if (it.isNotBlank()) Text(it, fontSize = 11.sp, color = GreenPrimary) }
                            }
                            Text(formatPeso(item.totalPrice), fontWeight = FontWeight.Normal, fontSize = 12.sp, color = colors.title)
                        }
                        HorizontalDivider(color = colors.cardBorder)
                    }
                    // Totals
                    Spacer(Modifier.height(8.dp))
                    PriceRow("Subtotal", formatPeso(o.subTotal))
                    if (o.discountAmount > 0) PriceRow("Discount", "-${formatPeso(o.discountAmount)}", valueColor = GreenPrimary)
                    PriceRow("Delivery Fee", formatPeso(o.deliveryFee))
                    o.platformFee?.let { if (it > 0) PriceRow("Platform Fee", formatPeso(it)) }
                    HorizontalDivider(modifier = Modifier.padding(vertical = 6.dp), color = colors.cardBorder)
                    PriceRow("Total", formatPeso(o.totalAmount), isTotal = true)
                }
            }

            // Delivery schedule — hide when OutForDelivery or Delivered (rider handles it)
            val isOutForDelivery = o.status.equals("OutForDelivery", ignoreCase = true)
            val isDelivered = o.status.equals("Delivered", ignoreCase = true)
            if (!o.deliveryDate.isNullOrBlank() && !isOutForDelivery && !isDelivered) {
                InfoCard(title = "Delivery Schedule", icon = Icons.Default.CalendarMonth) {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Date", fontSize = 13.sp, color = colors.subtitle)
                        Text(formatDeliveryDate(o.deliveryDate), fontWeight = FontWeight.SemiBold, color = colors.title)
                    }
                    Spacer(Modifier.height(4.dp))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Time Slot", fontSize = 13.sp, color = colors.subtitle)
                        Text(o.deliveryTimeSlot ?: "Anytime", fontWeight = FontWeight.SemiBold, color = colors.title)
                    }
                }
            }

            // Delivery Details — shown when rider is assigned (OutForDelivery or Delivered)
            if ((isOutForDelivery || isDelivered) && !o.riderName.isNullOrBlank()) {
                InfoCard(
                    title = "Delivery Details",
                    icon = Icons.Default.DeliveryDining,
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Person, null, tint = GreenPrimary, modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(8.dp))
                            Text(o.riderName, fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = colors.title)
                        }
                        if (!o.riderContact.isNullOrBlank()) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(Icons.Default.Phone, null, tint = GreenPrimary, modifier = Modifier.size(16.dp))
                                Spacer(Modifier.width(8.dp))
                                Text(o.riderContact, fontSize = 13.sp, color = colors.subtitle)
                            }
                        }
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Schedule, null, tint = GreenPrimary, modifier = Modifier.size(16.dp))
                            Spacer(Modifier.width(8.dp))
                            if (!o.actualDeliveryDate.isNullOrBlank()) {
                                Text(
                                    formatLocalDate(o.actualDeliveryDate),
                                    fontSize = 13.sp,
                                    color = colors.subtitle,
                                )
                            } else {
                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                    Box(
                                        modifier = Modifier
                                            .background(Color(0xFFF59E0B).copy(alpha = 0.15f), RoundedCornerShape(6.dp))
                                            .padding(horizontal = 8.dp, vertical = 3.dp),
                                    ) {
                                        Text("In Progress", fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFFF59E0B))
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Address
            o.address?.let { addr ->
                InfoCard(title = "Delivery Address", icon = Icons.Default.LocationOn) {
                    Text(addr.label, fontWeight = FontWeight.SemiBold, color = colors.title)
                    Text(addr.fullAddress, fontSize = 12.sp, color = colors.subtitle)
                    addr.contactNumber?.let { Text(it, fontSize = 12.sp, color = GreenPrimary) }
                    addr.deliveryInstructions?.let { Text(it, fontSize = 12.sp, color = colors.muted) }
                }
            }

            // Payment
            o.payment?.let { pay ->
                InfoCard(title = "Payment", icon = Icons.Default.CreditCard) {
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Method", fontSize = 13.sp, color = colors.subtitle)
                        Text(pay.method, fontWeight = FontWeight.SemiBold, color = colors.title)
                    }
                    Spacer(Modifier.height(4.dp))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text("Status", fontSize = 13.sp, color = colors.subtitle)
                        OrderStatusBadge(pay.status)
                    }
                }
            }

            // Rating (delivered orders)
            if (o.status.lowercase() == "delivered" && reviewSubmitted && existingReview != null) {
                SubmittedReviewCard(
                    review = existingReview,
                    onPhotoClick = { urls, index ->
                        viewerPhotos = urls
                        viewerInitialPage = index
                        showPhotoViewer = true
                    }
                )
            } else if (o.status.lowercase() == "delivered" && !reviewSubmitted) {
                Card(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(14.dp), colors = CardDefaults.cardColors(containerColor = colors.card)) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Rate this Order", fontWeight = FontWeight.Bold, color = colors.title)
                        Spacer(Modifier.height(10.dp))
                        Row {
                            (1..5).forEach { star ->
                                IconButton(onClick = { rating = star }, modifier = Modifier.size(36.dp)) {
                                    Icon(
                                        if (star <= rating) Icons.Default.Star else Icons.Default.StarBorder,
                                        null,
                                        tint = if (star <= rating) Color(0xFFFACC15) else Color.Gray,
                                    )
                                }
                            }
                        }
                        Spacer(Modifier.height(8.dp))
                        OutlinedTextField(
                            value = reviewText,
                            onValueChange = { reviewText = it },
                            placeholder = { Text("How was your experience?", fontSize = 13.sp) },
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(8.dp),
                            minLines = 2,
                            colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = GreenPrimary),
                        )
                        Spacer(Modifier.height(10.dp))
                        Text("Upload Photos", fontSize = 12.sp, color = colors.muted)
                        Spacer(Modifier.height(8.dp))
                        LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            if (!reviewSubmitted) {
                                item {
                                    OutlinedButton(
                                        onClick = {
                                            photoPickerLauncher.launch(
                                                PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                                            )
                                        },
                                        modifier = Modifier.height(76.dp),
                                        shape = RoundedCornerShape(14.dp),
                                        contentPadding = PaddingValues(horizontal = 14.dp, vertical = 10.dp)
                                    ) {
                                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                            Icon(Icons.Default.AddAPhoto, null, tint = GreenPrimary)
                                            Spacer(Modifier.height(4.dp))
                                            Text("Add Photos", color = GreenPrimary, fontSize = 12.sp)
                                        }
                                    }
                                }
                            }
                            itemsIndexed(selectedPhotoUris) { index, uri ->
                                Box {
                                    AsyncImage(
                                        model = uri,
                                        contentDescription = null,
                                        contentScale = ContentScale.Crop,
                                        modifier = Modifier
                                            .size(76.dp)
                                            .clip(RoundedCornerShape(12.dp))
                                    )
                                    IconButton(
                                        onClick = {
                                            selectedPhotoUris = selectedPhotoUris.toMutableList().also { it.removeAt(index) }
                                        },
                                        modifier = Modifier
                                            .align(Alignment.TopEnd)
                                            .size(22.dp)
                                            .background(Color.Black.copy(alpha = 0.55f), CircleShape)
                                    ) {
                                        Icon(Icons.Default.Close, null, tint = Color.White, modifier = Modifier.size(12.dp))
                                    }
                                }
                            }
                        }

                        Spacer(Modifier.height(12.dp))
                        Button(
                            onClick = {
                                o.items?.firstOrNull()?.let { item ->
                                    scope.launch {
                                        isSubmittingReview = true
                                        val photoBytes = selectedPhotoUris.mapNotNull { uri ->
                                            context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
                                        }
                                        val submitted = viewModel.submitReview(o.id, item.productId, rating, reviewText, photoBytes)
                                        if (submitted) {
                                            reviewSubmitted = true
                                            selectedPhotoUris = emptyList()
                                            order = viewModel.getOrderDetail(orderId).firstOrNull()
                                        }
                                        isSubmittingReview = false
                                    }
                                }
                            },
                            enabled = rating > 0 && !isSubmittingReview,
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
                        ) {
                            if (isSubmittingReview) {
                                CircularProgressIndicator(color = Color.White, modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                            } else {
                                Text("Submit Review")
                            }
                        }
                    }
                }
            }

            Spacer(Modifier.height(16.dp))
        }
    }

    if (showPhotoViewer && viewerPhotos.isNotEmpty()) {
        Dialog(onDismissRequest = { showPhotoViewer = false }) {
            Surface(
                shape = RoundedCornerShape(20.dp),
                color = Color.Black
            ) {
                val pagerState = rememberPagerState(initialPage = viewerInitialPage, pageCount = { viewerPhotos.size })
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("${pagerState.currentPage + 1} / ${viewerPhotos.size}", color = Color.White)
                        IconButton(onClick = { showPhotoViewer = false }) {
                            Icon(Icons.Default.Close, null, tint = Color.White)
                        }
                    }
                    HorizontalPager(
                        state = pagerState,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(360.dp)
                    ) { page ->
                        AsyncImage(
                            model = viewerPhotos[page],
                            contentDescription = null,
                            contentScale = ContentScale.Fit,
                            modifier = Modifier.fillMaxSize()
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun InfoCard(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    content: @Composable ColumnScope.() -> Unit,
) {
    val colors = MaterialTheme.grocery
    Card(modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(14.dp), colors = CardDefaults.cardColors(containerColor = colors.card)) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(icon, null, tint = GreenPrimary, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text(title, fontWeight = FontWeight.Bold, color = colors.title)
            }
            Spacer(Modifier.height(10.dp))
            content()
        }
    }
}

@Composable
private fun ReviewPhotosRow(
    photos: List<OrderReviewPhotoDto>,
    onPhotoClick: (urls: List<String>, index: Int) -> Unit,
) {
    val resolvedUrls = photos.map { photo ->
        if (photo.photoUrl.startsWith("http")) photo.photoUrl else "${com.sanshare.groceryapp.data.remote.ApiConfig.BASE_URL}${photo.photoUrl}"
    }

    LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        itemsIndexed(resolvedUrls) { index, url ->
            AsyncImage(
                model = url,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .size(76.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .clickable { onPhotoClick(resolvedUrls, index) }
            )
        }
    }
}

@Composable
private fun SubmittedReviewCard(
    review: OrderReviewDto,
    onPhotoClick: (urls: List<String>, index: Int) -> Unit,
) {
    val colors = MaterialTheme.grocery
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = colors.card)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Your Review", fontWeight = FontWeight.Bold, color = colors.title)
            Spacer(Modifier.height(10.dp))
            Row(verticalAlignment = Alignment.CenterVertically) {
                repeat(5) { index ->
                    Icon(
                        imageVector = if (index < review.rating) Icons.Default.Star else Icons.Default.StarBorder,
                        contentDescription = null,
                        tint = if (index < review.rating) Color(0xFFFACC15) else Color.Gray,
                        modifier = Modifier.size(20.dp)
                    )
                }
                Spacer(Modifier.width(8.dp))
                Text("${review.rating}/5", fontSize = 13.sp, fontWeight = FontWeight.SemiBold, color = colors.title)
            }
            if (!review.comment.isNullOrBlank()) {
                Spacer(Modifier.height(10.dp))
                Text(review.comment, fontSize = 13.sp, color = colors.subtitle)
            }
            if (!review.photos.isNullOrEmpty()) {
                Spacer(Modifier.height(12.dp))
                Text("Uploaded Photos", fontSize = 12.sp, color = colors.muted)
                Spacer(Modifier.height(8.dp))
                ReviewPhotosRow(
                    photos = review.photos,
                    onPhotoClick = onPhotoClick
                )
            }
            Spacer(Modifier.height(10.dp))
            Text(
                text = "Submitted ${review.createdAt.take(16).replace("T", " ")}",
                fontSize = 11.sp,
                color = colors.muted
            )
        }
    }
}

// ── Date helpers ──────────────────────────────────────────────────────────────

/**
 * Converts a UTC ISO-8601 string (e.g. "2026-05-03T12:00:00Z") to the device's
 * local timezone and returns a readable date string like "May 3, 2026".
 */
private fun formatLocalDate(utcString: String): String {
    return try {
        val sdf = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US)
        sdf.timeZone = java.util.TimeZone.getTimeZone("UTC")
        val date = sdf.parse(utcString.take(19)) ?: return utcString.take(10)
        val out = java.text.SimpleDateFormat("MMM d, yyyy", java.util.Locale.getDefault())
        out.timeZone = java.util.TimeZone.getDefault()  // device local timezone
        out.format(date)
    } catch (_: Exception) {
        utcString.take(10)
    }
}

/**
 * Formats a plain date string "yyyy-MM-dd" (no timezone) into "MMM d, yyyy".
 * No timezone conversion — the date is already in local time.
 */
private fun formatDeliveryDate(dateStr: String?): String {
    if (dateStr.isNullOrBlank()) return "—"
    return try {
        val sdf = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US)
        sdf.timeZone = java.util.TimeZone.getDefault()  // treat as local date
        val date = sdf.parse(dateStr) ?: return dateStr
        val out = java.text.SimpleDateFormat("MMM d, yyyy", java.util.Locale.getDefault())
        out.format(date)
    } catch (_: Exception) {
        dateStr
    }
}
