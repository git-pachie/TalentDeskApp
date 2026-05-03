package com.sanshare.groceryapp.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sanshare.groceryapp.data.remote.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AddressState(
    val addresses: List<AddressDto> = emptyList(),
    val isLoading: Boolean = false,
)

@HiltViewModel
class AddressViewModel @Inject constructor(private val apiClient: ApiClient) : ViewModel() {
    private val _state = MutableStateFlow(AddressState())
    val state: StateFlow<AddressState> = _state.asStateFlow()

    fun loadAddresses() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            val result = apiClient.get<List<AddressDto>>(ApiConfig.ADDRESSES)
            if (result is ApiResult.Success) _state.update { it.copy(addresses = result.data, isLoading = false) }
            else _state.update { it.copy(isLoading = false) }
        }
    }

    fun createAddress(request: CreateAddressRequest) {
        viewModelScope.launch {
            val result = apiClient.post<CreateAddressRequest, AddressDto>(ApiConfig.ADDRESSES, request)
            if (result is ApiResult.Success) loadAddresses()
        }
    }

    fun updateAddress(id: String, request: UpdateAddressRequest) {
        viewModelScope.launch {
            val result = apiClient.put<UpdateAddressRequest, AddressDto>("${ApiConfig.ADDRESSES}/$id", request)
            if (result is ApiResult.Success) loadAddresses()
        }
    }

    fun deleteAddress(id: String) {
        viewModelScope.launch {
            apiClient.delete("${ApiConfig.ADDRESSES}/$id")
            loadAddresses()
        }
    }
}
