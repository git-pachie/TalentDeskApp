package com.sanshare.groceryapp.ui.screens.search

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.sanshare.groceryapp.ui.components.*
import com.sanshare.groceryapp.ui.theme.GreenPrimary
import com.sanshare.groceryapp.ui.theme.grocery
import com.sanshare.groceryapp.ui.viewmodel.ProductViewModel

private val POPULAR_SEARCHES = listOf(
    "Bakery & Biscuits" to "🍪",
    "Coffee" to "☕",
    "Bread" to "🍞",
    "Eggs" to "🥚",
    "Milk" to "🥛",
    "Fruits" to "🍎",
    "Vegetables" to "🥕",
    "Meat" to "🥩",
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SearchScreen(
    onBack: () -> Unit,
    onProductClick: (String) -> Unit,
    viewModel: ProductViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsState()
    val colors = MaterialTheme.grocery
    val focusRequester = remember { FocusRequester() }

    LaunchedEffect(Unit) { focusRequester.requestFocus() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(colors.background)
    ) {
        // Search bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onBack) {
                Icon(Icons.Default.ArrowBack, null, tint = colors.title)
            }
            Box(
                modifier = Modifier
                    .weight(1f)
                    .background(colors.card, RoundedCornerShape(12.dp))
                    .padding(horizontal = 14.dp, vertical = 12.dp)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Search, null, tint = colors.muted, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.width(8.dp))
                    BasicTextField(
                        value = state.searchQuery,
                        onValueChange = { viewModel.search(it) },
                        singleLine = true,
                        textStyle = TextStyle(color = colors.title, fontSize = 14.sp),
                        modifier = Modifier.weight(1f).focusRequester(focusRequester),
                        decorationBox = { inner ->
                            if (state.searchQuery.isEmpty()) {
                                Text("Search fresh groceries...", color = colors.muted, fontSize = 14.sp)
                            }
                            inner()
                        }
                    )
                    if (state.searchQuery.isNotBlank()) {
                        IconButton(onClick = { viewModel.search("") }, modifier = Modifier.size(20.dp)) {
                            Icon(Icons.Default.Close, null, tint = colors.muted, modifier = Modifier.size(16.dp))
                        }
                    }
                }
            }
        }

        if (state.searchQuery.isBlank()) {
            LazyColumn(contentPadding = PaddingValues(16.dp)) {
                item {
                    Text("Popular Searches", fontWeight = FontWeight.Bold, color = colors.title, fontSize = 15.sp)
                    Spacer(Modifier.height(12.dp))
                }
                items(POPULAR_SEARCHES) { (label, emoji) ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { viewModel.search(label) }
                            .padding(vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(emoji, fontSize = 20.sp)
                        Spacer(Modifier.width(12.dp))
                        Text(label, fontSize = 14.sp, color = colors.title, modifier = Modifier.weight(1f))
                        Icon(Icons.Default.NorthWest, null, tint = colors.muted, modifier = Modifier.size(16.dp))
                    }
                    HorizontalDivider(color = colors.cardBorder)
                }
                if (state.products.isNotEmpty()) {
                    item {
                        Spacer(Modifier.height(20.dp))
                        Text("Browse Products", fontWeight = FontWeight.Bold, color = colors.title, fontSize = 15.sp)
                        Spacer(Modifier.height(12.dp))
                    }
                    items(state.products, key = { it.id }) { product ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { onProductClick(product.id) }
                                .padding(vertical = 10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(emojiForCategory(product.categoryName), fontSize = 22.sp)
                            Spacer(Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(product.name, fontSize = 14.sp, color = colors.title, fontWeight = FontWeight.Medium)
                                Text(product.categoryName, fontSize = 12.sp, color = colors.muted)
                            }
                            Text(formatPeso(product.displayPrice), fontSize = 13.sp, color = GreenPrimary, fontWeight = FontWeight.SemiBold)
                        }
                        HorizontalDivider(color = colors.cardBorder)
                    }
                }
            }
        } else if (state.isLoading) {
            LoadingBox()
        } else if (state.products.isEmpty()) {
            EmptyState("🔍", "No results for \"${state.searchQuery}\"", "Try a different search term")
        } else {
            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                contentPadding = PaddingValues(16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(state.products, key = { it.id }) { product ->
                    ProductCard(
                        product = product,
                        onClick = { onProductClick(product.id) },
                    )
                }
            }
        }
    }
}
