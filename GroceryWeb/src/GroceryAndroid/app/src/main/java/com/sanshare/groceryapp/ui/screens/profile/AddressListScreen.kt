package com.sanshare.groceryapp.ui.screens.profile

import android.annotation.SuppressLint
import android.content.Context
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import org.osmdroid.config.Configuration
import org.osmdroid.tileprovider.tilesource.TileSourceFactory
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker
import com.sanshare.groceryapp.data.remote.AddressDto
import com.sanshare.groceryapp.data.remote.CreateAddressRequest
import com.sanshare.groceryapp.data.remote.UpdateAddressRequest
import com.sanshare.groceryapp.ui.components.EmptyState
import com.sanshare.groceryapp.ui.components.LoadingBox
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.AddressViewModel
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.delay
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

// ── Nominatim geocoding (OpenStreetMap, free, no key) ────────────────────────
private suspend fun geocodeAddress(street: String, city: String, province: String): GeoPoint? {
    val query = listOf(street, city, province, "Philippines")
        .filter { it.isNotBlank() }
        .joinToString(", ")
    if (query.length < 5) return null
    return geocodeQuery(query)
}

private suspend fun geocodeQuery(query: String): GeoPoint? {
    if (query.length < 3) return null
    return try {
        // Try Philippines-scoped first, fall back to global if no result
        val result = nominatimSearch(query, countryCode = "ph")
            ?: nominatimSearch(query, countryCode = null)
        result
    } catch (e: Exception) {
        null
    }
}

private suspend fun nominatimSearch(query: String, countryCode: String?): GeoPoint? {
    return withContext(Dispatchers.IO) {
        try {
            val encoded = java.net.URLEncoder.encode(query, "UTF-8")
            val countryParam = if (countryCode != null) "&countrycodes=$countryCode" else ""
            val urlStr = "https://nominatim.openstreetmap.org/search" +
                "?q=$encoded&format=json&limit=1&addressdetails=0$countryParam"
            android.util.Log.d("Geocode", "Querying: $urlStr")
            val url = java.net.URL(urlStr)
            val conn = (url.openConnection() as java.net.HttpURLConnection).apply {
                setRequestProperty("User-Agent", "GroceryApp Android/1.0 (sanshare.groceryapp@gmail.com)")
                setRequestProperty("Accept-Language", "en")
                connectTimeout = 10_000
                readTimeout = 10_000
            }
            val responseCode = conn.responseCode
            android.util.Log.d("Geocode", "Response code: $responseCode")
            if (responseCode != 200) { conn.disconnect(); return@withContext null }
            val body = conn.inputStream.bufferedReader().readText()
            conn.disconnect()
            android.util.Log.d("Geocode", "Response body: $body")
            val arr = Json { ignoreUnknownKeys = true }.parseToJsonElement(body).jsonArray
            if (arr.isEmpty()) return@withContext null
            val obj = arr[0].jsonObject
            val lat = obj["lat"]?.jsonPrimitive?.content?.toDoubleOrNull() ?: return@withContext null
            val lng = obj["lon"]?.jsonPrimitive?.content?.toDoubleOrNull() ?: return@withContext null
            android.util.Log.d("Geocode", "Found: $lat, $lng")
            GeoPoint(lat, lng)
        } catch (e: Exception) {
            android.util.Log.e("Geocode", "Exception: ${e.message}", e)
            null
        }
    }
}

// Default center — Philippines
private val DEFAULT_GEO = GeoPoint(12.8797, 121.7740)

// ── OSMDroid init helper ──────────────────────────────────────────────────────
private fun initOsm(context: Context) {
    Configuration.getInstance().apply {
        userAgentValue = context.packageName
        load(context, context.getSharedPreferences("osmdroid", Context.MODE_PRIVATE))
    }
}

// ── Device location helper ────────────────────────────────────────────────────
@SuppressLint("MissingPermission")
private suspend fun getDeviceLocation(context: Context): GeoPoint? {
    return try {
        val client = LocationServices.getFusedLocationProviderClient(context)
        // Try last known location first (fast)
        val last = suspendCancellableCoroutine<android.location.Location?> { cont ->
            client.lastLocation
                .addOnSuccessListener { cont.resume(it) }
                .addOnFailureListener { cont.resume(null) }
        }
        if (last != null) return GeoPoint(last.latitude, last.longitude)

        // Fall back to current location request
        val cts = CancellationTokenSource()
        val current = suspendCancellableCoroutine<android.location.Location?> { cont ->
            cont.invokeOnCancellation { cts.cancel() }
            client.getCurrentLocation(Priority.PRIORITY_BALANCED_POWER_ACCURACY, cts.token)
                .addOnSuccessListener { cont.resume(it) }
                .addOnFailureListener { cont.resume(null) }
        }
        current?.let { GeoPoint(it.latitude, it.longitude) }
    } catch (e: Exception) {
        null
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddressListScreen(
    onBack: () -> Unit,
    viewModel: AddressViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsState()
    val colors = MaterialTheme.grocery
    val context = LocalContext.current

    var showAddSheet by remember { mutableStateOf(false) }
    var editingAddress by remember { mutableStateOf<AddressDto?>(null) }
    var deviceLocation by remember { mutableStateOf<GeoPoint?>(null) }
    var fetchingLocation by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        initOsm(context)
        viewModel.loadAddresses()
    }

    // Fetch device location once on screen enter so it's ready when Add is tapped
    LaunchedEffect(Unit) {
        deviceLocation = getDeviceLocation(context)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Addresses") },
                navigationIcon = {
                    IconButton(onClick = onBack) { Icon(Icons.Default.ArrowBack, null) }
                },
                actions = {
                    IconButton(
                        onClick = {
                            if (!fetchingLocation) showAddSheet = true
                        }
                    ) {
                        if (fetchingLocation) {
                            CircularProgressIndicator(
                                color = GreenPrimary,
                                modifier = Modifier.size(20.dp),
                                strokeWidth = 2.dp,
                            )
                        } else {
                            Icon(Icons.Default.Add, null, tint = GreenPrimary)
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = colors.background),
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
                        onEdit = { editingAddress = addr },
                        onDelete = { viewModel.deleteAddress(addr.id) },
                    )
                }
            }
        }
    }

    if (showAddSheet) {
        AddressSheet(
            title = "Add Address",
            initial = null,
            initialLocation = deviceLocation,
            onDismiss = { showAddSheet = false },
            onSave = { label, street, city, province, zip, contact, instructions, isDefault, lat, lng ->
                viewModel.createAddress(
                    CreateAddressRequest(
                        label = label, street = street, city = city,
                        province = province, zipCode = zip,
                        contactNumber = contact.ifBlank { null },
                        deliveryInstructions = instructions.ifBlank { null },
                        isDefault = isDefault,
                        latitude = lat, longitude = lng,
                    )
                )
                showAddSheet = false
            },
        )
    }

    editingAddress?.let { addr ->
        AddressSheet(
            title = "Edit Address",
            initial = addr,
            initialLocation = null,  // edit uses saved coordinates
            onDismiss = { editingAddress = null },
            onSave = { label, street, city, province, zip, contact, instructions, isDefault, lat, lng ->
                viewModel.updateAddress(
                    addr.id,
                    UpdateAddressRequest(
                        label = label, street = street, city = city,
                        province = province, zipCode = zip,
                        contactNumber = contact.ifBlank { null },
                        deliveryInstructions = instructions.ifBlank { null },
                        isDefault = isDefault,
                        latitude = lat, longitude = lng,
                    )
                )
                editingAddress = null
            },
        )
    }
}

// ── Address Card ──────────────────────────────────────────────────────────────

@Composable
private fun AddressCard(address: AddressDto, onEdit: () -> Unit, onDelete: () -> Unit) {
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
                                    .padding(horizontal = 6.dp, vertical = 2.dp),
                            ) {
                                Text("Default", fontSize = 10.sp, color = GreenPrimary, fontWeight = FontWeight.SemiBold)
                            }
                        }
                    }
                    Text(address.fullAddress, fontSize = 12.sp, color = colors.subtitle)
                    address.contactNumber?.takeIf { it.isNotBlank() }?.let {
                        Spacer(Modifier.height(2.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Phone, null, tint = GreenPrimary, modifier = Modifier.size(12.dp))
                            Spacer(Modifier.width(4.dp))
                            Text(it, fontSize = 12.sp, color = GreenPrimary)
                        }
                    }
                    address.deliveryInstructions?.takeIf { it.isNotBlank() }?.let {
                        Spacer(Modifier.height(2.dp))
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Default.Info, null, tint = colors.muted, modifier = Modifier.size(12.dp))
                            Spacer(Modifier.width(4.dp))
                            Text(it, fontSize = 11.sp, color = colors.muted, maxLines = 2)
                        }
                    }
                }
                IconButton(onClick = onEdit, modifier = Modifier.size(32.dp)) {
                    Icon(Icons.Default.Edit, null, tint = GreenPrimary, modifier = Modifier.size(18.dp))
                }
                IconButton(onClick = onDelete, modifier = Modifier.size(32.dp)) {
                    Icon(Icons.Default.Delete, null, tint = Color(0xFFEF4444), modifier = Modifier.size(18.dp))
                }
        }
    }
}

// ── OSM Static Map (non-interactive thumbnail) ────────────────────────────────

@Composable
private fun OsmStaticMap(geoPoint: GeoPoint, zoom: Double, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    AndroidView(
        factory = { ctx ->
            MapView(ctx).apply {
                setTileSource(TileSourceFactory.MAPNIK)
                setMultiTouchControls(false)
                isClickable = false
                isFocusable = false
                controller.setZoom(zoom)
                controller.setCenter(geoPoint)
                val marker = Marker(this).apply {
                    position = geoPoint
                    setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
                }
                overlays.add(marker)
            }
        },
        update = { mapView ->
            mapView.controller.setCenter(geoPoint)
            mapView.controller.setZoom(zoom)
        },
        modifier = modifier,
    )
}

// ── OSM Interactive Map Picker (with animated target support) ─────────────────

@Composable
private fun OsmMapPickerWithTarget(
    initial: GeoPoint,
    target: GeoPoint?,           // when non-null, map animates to this point
    onLocationPicked: (GeoPoint) -> Unit,
    modifier: Modifier = Modifier,
) {
    val markerHolder = remember { arrayOfNulls<Marker>(1) }
    val mapViewHolder = remember { arrayOfNulls<MapView>(1) }

    // Animate map to target whenever it changes
    LaunchedEffect(target) {
        target ?: return@LaunchedEffect
        val mv = mapViewHolder[0] ?: return@LaunchedEffect
        mv.controller.animateTo(target, 16.0, 800L)
        markerHolder[0]?.position = target
        mv.invalidate()
    }

    AndroidView(
        factory = { ctx ->
            MapView(ctx).apply {
                setTileSource(TileSourceFactory.MAPNIK)
                setMultiTouchControls(true)
                controller.setZoom(15.0)
                controller.setCenter(initial)
                mapViewHolder[0] = this

                val marker = Marker(this).apply {
                    position = initial
                    setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
                    title = "Delivery location"
                    isDraggable = true
                    setOnMarkerDragListener(object : Marker.OnMarkerDragListener {
                        override fun onMarkerDrag(m: Marker) {}
                        override fun onMarkerDragEnd(m: Marker) { onLocationPicked(m.position) }
                        override fun onMarkerDragStart(m: Marker) {}
                    })
                }
                markerHolder[0] = marker

                overlays.add(0, object : org.osmdroid.views.overlay.Overlay() {
                    override fun onSingleTapConfirmed(
                        e: android.view.MotionEvent,
                        mapView: MapView,
                    ): Boolean {
                        val geo = mapView.projection.fromPixels(e.x.toInt(), e.y.toInt()) as GeoPoint
                        markerHolder[0]?.position = geo
                        mapView.invalidate()
                        onLocationPicked(geo)
                        return true
                    }
                })
                overlays.add(marker)
            }
        },
        modifier = modifier,
    )
}

// ── OSM Interactive Map Picker ────────────────────────────────────────────────

@Composable
private fun OsmMapPicker(
    initial: GeoPoint,
    onLocationPicked: (GeoPoint) -> Unit,
    modifier: Modifier = Modifier,
) {
    // Use arrayOf so the reference is stable across recompositions and accessible inside factory
    val markerHolder = remember { arrayOfNulls<Marker>(1) }

    AndroidView(
        factory = { ctx ->
            MapView(ctx).apply {
                setTileSource(TileSourceFactory.MAPNIK)
                setMultiTouchControls(true)
                controller.setZoom(15.0)
                controller.setCenter(initial)

                val marker = Marker(this).apply {
                    position = initial
                    setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
                    title = "Delivery location"
                    isDraggable = true
                    setOnMarkerDragListener(object : Marker.OnMarkerDragListener {
                        override fun onMarkerDrag(m: Marker) {}
                        override fun onMarkerDragEnd(m: Marker) { onLocationPicked(m.position) }
                        override fun onMarkerDragStart(m: Marker) {}
                    })
                }
                markerHolder[0] = marker

                // Add tap overlay FIRST so it gets priority over the marker overlay
                overlays.add(0, object : org.osmdroid.views.overlay.Overlay() {
                    override fun onSingleTapConfirmed(
                        e: android.view.MotionEvent,
                        mapView: MapView,
                    ): Boolean {
                        val geo = mapView.projection.fromPixels(e.x.toInt(), e.y.toInt()) as GeoPoint
                        markerHolder[0]?.position = geo
                        mapView.invalidate()
                        onLocationPicked(geo)
                        return true
                    }
                })
                overlays.add(marker)
            }
        },
        modifier = modifier,
    )
}

// ── Add / Edit Address Sheet ──────────────────────────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun AddressSheet(
    title: String,
    initial: AddressDto?,
    initialLocation: GeoPoint?,   // device GPS location for new addresses
    onDismiss: () -> Unit,
    onSave: (
        label: String, street: String, city: String, province: String,
        zip: String, contact: String, instructions: String,
        isDefault: Boolean, lat: Double?, lng: Double?,
    ) -> Unit,
) {
    val colors = MaterialTheme.grocery

    var label        by remember { mutableStateOf(initial?.label ?: "") }
    var street       by remember { mutableStateOf(initial?.street ?: "") }
    var city         by remember { mutableStateOf(initial?.city ?: "") }
    var province     by remember { mutableStateOf(initial?.province ?: "") }
    var zipCode      by remember { mutableStateOf(initial?.zipCode ?: "") }
    var contact      by remember { mutableStateOf(initial?.contactNumber ?: "") }
    var instructions by remember { mutableStateOf(initial?.deliveryInstructions ?: "") }
    var isDefault    by remember { mutableStateOf(initial?.isDefault ?: false) }
    var showMapPicker by remember { mutableStateOf(false) }
    var isGeocoding  by remember { mutableStateOf(false) }

    // Priority: saved address coords → device GPS → null (Philippines default used in picker)
    val initLat = initial?.latitude?.takeIf { it != 0.0 }
    val initLng = initial?.longitude?.takeIf { it != 0.0 }
    var pinnedPoint by remember {
        mutableStateOf(
            when {
                initLat != null && initLng != null -> GeoPoint(initLat, initLng)
                initialLocation != null -> initialLocation
                else -> null
            }
        )
    }

    // ── Debounced geocoding — fires 800ms after street/city/province stop changing ──
    val geocodeQuery = remember(street, city, province) { "$street $city $province" }
    LaunchedEffect(geocodeQuery) {
        // Only geocode if user hasn't manually pinned yet, or if address text has meaningful content
        val hasText = street.length >= 3 || city.length >= 2
        if (!hasText) return@LaunchedEffect
        delay(800)  // debounce
        isGeocoding = true
        val result = geocodeAddress(street, city, province)
        isGeocoding = false
        if (result != null) {
            pinnedPoint = result
        }
    }

    if (showMapPicker) {
        MapPickerSheet(
            initial = pinnedPoint ?: DEFAULT_GEO,
            onDismiss = { showMapPicker = false },
            onConfirm = { geo ->
                pinnedPoint = geo
                showMapPicker = false
            },
        )
        return
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = colors.background,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp)
                .navigationBarsPadding()
                .padding(bottom = 16.dp),
        ) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold, color = colors.title)
            Spacer(Modifier.height(14.dp))

            // ── Map pin section ───────────────────────────────────────────────
            Card(
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(containerColor = colors.card),
                elevation = CardDefaults.cardElevation(1.dp),
                modifier = Modifier.fillMaxWidth(),
            ) {
                Column {
                    pinnedPoint?.let { geo ->
                        OsmStaticMap(
                            geoPoint = geo,
                            zoom = 15.0,
                            modifier = Modifier.fillMaxWidth().height(150.dp),
                        )
                    }
                    // Status row — geocoding spinner or coordinates
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 12.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        if (isGeocoding) {
                            CircularProgressIndicator(
                                color = GreenPrimary,
                                modifier = Modifier.size(14.dp),
                                strokeWidth = 2.dp,
                            )
                            Spacer(Modifier.width(6.dp))
                            Text("Finding location…", fontSize = 11.sp, color = colors.muted)
                        } else if (pinnedPoint != null) {
                            Icon(Icons.Default.LocationOn, null, tint = GreenPrimary, modifier = Modifier.size(14.dp))
                            Spacer(Modifier.width(4.dp))
                            Text(
                                "${"%.5f".format(pinnedPoint!!.latitude)}, ${"%.5f".format(pinnedPoint!!.longitude)}",
                                fontSize = 11.sp,
                                color = GreenPrimary,
                            )
                        } else {
                            Text(
                                "Pinning helps the rider find your exact location.",
                                fontSize = 11.sp,
                                color = colors.muted,
                            )
                        }
                    }
                    OutlinedButton(
                        onClick = { showMapPicker = true },
                        modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp).padding(bottom = 10.dp),
                        shape = RoundedCornerShape(10.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = GreenPrimary),
                    ) {
                        Icon(Icons.Default.LocationOn, null, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(6.dp))
                        Text(
                            if (pinnedPoint != null) "Adjust Pin on Map" else "📍 Pin Location on Map",
                            fontWeight = FontWeight.Medium,
                        )
                    }
                }
            }

            Spacer(Modifier.height(12.dp))

            // ── Form fields ───────────────────────────────────────────────────
            AddressField(label, { label = it }, "Label (e.g. Home)")
            AddressField(street, { street = it }, "Street")
            AddressField(city, { city = it }, "City")
            AddressField(province, { province = it }, "Province")
            AddressField(zipCode, { zipCode = it }, "ZIP Code")
            AddressField(contact, { contact = it }, "Contact Number")
            AddressField(instructions, { instructions = it }, "Delivery Instructions (optional)")

            Row(verticalAlignment = Alignment.CenterVertically) {
                Checkbox(
                    checked = isDefault,
                    onCheckedChange = { isDefault = it },
                    colors = CheckboxDefaults.colors(checkedColor = GreenPrimary),
                )
                Text("Set as default address", fontSize = 14.sp, color = colors.title)
            }

            Spacer(Modifier.height(8.dp))

            Button(
                onClick = {
                    onSave(
                        label, street, city, province, zipCode,
                        contact, instructions, isDefault,
                        pinnedPoint?.latitude, pinnedPoint?.longitude,
                    )
                },
                enabled = label.isNotBlank() && street.isNotBlank() && city.isNotBlank(),
                modifier = Modifier.fillMaxWidth().height(50.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
            ) {
                Text("Save Address", fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

// ── Map Picker — Full Screen Dialog with Search ───────────────────────────────

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MapPickerSheet(
    initial: GeoPoint,
    onDismiss: () -> Unit,
    onConfirm: (GeoPoint) -> Unit,
) {
    val colors = MaterialTheme.grocery
    var picked by remember { mutableStateOf(initial) }
    var searchQuery by remember { mutableStateOf("") }
    var isSearching by remember { mutableStateOf(false) }
    var searchError by remember { mutableStateOf<String?>(null) }
    // Trigger map to animate to a new center
    var mapTarget by remember { mutableStateOf<GeoPoint?>(null) }

    // Debounced search — fires 700ms after user stops typing
    LaunchedEffect(searchQuery) {
        searchError = null
        val q = searchQuery.trim()
        if (q.length < 3) return@LaunchedEffect
        delay(900)  // wait for user to finish typing
        isSearching = true
        val result = geocodeQuery(q)
        isSearching = false
        if (result != null) {
            picked = result
            mapTarget = result
        } else {
            searchError = "\"$q\" not found. Try: city name, landmark, or full address."
        }
    }

    // Full-screen dialog
    androidx.compose.ui.window.Dialog(
        onDismissRequest = onDismiss,
        properties = androidx.compose.ui.window.DialogProperties(
            usePlatformDefaultWidth = false,
            dismissOnBackPress = true,
            dismissOnClickOutside = false,
        ),
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(colors.background),
        ) {
            // ── Map fills entire screen ───────────────────────────────────────
            OsmMapPickerWithTarget(
                initial = initial,
                target = mapTarget,
                onLocationPicked = { picked = it },
                modifier = Modifier.fillMaxSize(),
            )

            // ── Top bar overlay ───────────────────────────────────────────────
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.TopCenter),
            ) {
                // Search bar card
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp)
                        .padding(top = 48.dp, bottom = 4.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = colors.card),
                    elevation = CardDefaults.cardElevation(6.dp),
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 12.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        if (isSearching) {
                            CircularProgressIndicator(
                                color = GreenPrimary,
                                modifier = Modifier.size(20.dp),
                                strokeWidth = 2.dp,
                            )
                        } else {
                            Icon(Icons.Default.Search, null, tint = colors.muted, modifier = Modifier.size(20.dp))
                        }
                        Spacer(Modifier.width(8.dp))
                        OutlinedTextField(
                            value = searchQuery,
                            onValueChange = { searchQuery = it },
                            placeholder = { Text("Search address or place…", fontSize = 14.sp) },
                            singleLine = true,
                            modifier = Modifier.weight(1f),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = androidx.compose.ui.graphics.Color.Transparent,
                                unfocusedBorderColor = androidx.compose.ui.graphics.Color.Transparent,
                                focusedContainerColor = androidx.compose.ui.graphics.Color.Transparent,
                                unfocusedContainerColor = androidx.compose.ui.graphics.Color.Transparent,
                            ),
                            keyboardOptions = androidx.compose.foundation.text.KeyboardOptions(
                                imeAction = androidx.compose.ui.text.input.ImeAction.Search,
                            ),
                            keyboardActions = androidx.compose.foundation.text.KeyboardActions(
                                onSearch = { /* debounce handles it */ }
                            ),
                        )
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { searchQuery = ""; searchError = null }) {
                                Icon(Icons.Default.Close, null, tint = colors.muted, modifier = Modifier.size(18.dp))
                            }
                        }
                    }
                }

                // Search error
                searchError?.let { err ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 12.dp, vertical = 2.dp),
                        shape = RoundedCornerShape(10.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.9f)
                        ),
                    ) {
                        Text(
                            err,
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.error,
                            modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                        )
                    }
                }
            }

            // ── Back button (top-left) ────────────────────────────────────────
            IconButton(
                onClick = onDismiss,
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .padding(top = 44.dp, start = 4.dp)
                    .background(colors.card.copy(alpha = 0.9f), RoundedCornerShape(50))
                    .size(40.dp),
            ) {
                Icon(Icons.Default.ArrowBack, null, tint = colors.title)
            }

            // ── Bottom confirm bar ────────────────────────────────────────────
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.BottomCenter)
                    .background(colors.background.copy(alpha = 0.95f)),
            ) {
                Text(
                    "📍 ${"%.5f".format(picked.latitude)}, ${"%.5f".format(picked.longitude)}",
                    fontSize = 11.sp,
                    color = colors.muted,
                    modifier = Modifier
                        .align(Alignment.CenterHorizontally)
                        .padding(top = 8.dp),
                )
                Text(
                    "Tap map or drag pin to adjust",
                    fontSize = 11.sp,
                    color = colors.muted,
                    modifier = Modifier.align(Alignment.CenterHorizontally),
                )
                Button(
                    onClick = { onConfirm(picked) },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 10.dp)
                        .navigationBarsPadding()
                        .height(50.dp),
                    shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = GreenPrimary),
                ) {
                    Icon(Icons.Default.LocationOn, null, modifier = Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("Confirm Location", fontWeight = FontWeight.SemiBold)
                }
            }
        }
    }
}

// ── Reusable field ────────────────────────────────────────────────────────────

@Composable
private fun AddressField(value: String, onChange: (String) -> Unit, label: String) {
    OutlinedTextField(
        value = value,
        onValueChange = onChange,
        label = { Text(label) },
        modifier = Modifier.fillMaxWidth().padding(bottom = 8.dp),
        shape = RoundedCornerShape(10.dp),
        singleLine = true,
        colors = OutlinedTextFieldDefaults.colors(focusedBorderColor = GreenPrimary),
    )
}
