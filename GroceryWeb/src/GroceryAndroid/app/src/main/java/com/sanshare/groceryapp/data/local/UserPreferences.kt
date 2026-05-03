package com.sanshare.groceryapp.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "user_prefs")

@Singleton
class UserPreferences @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private val dataStore = context.dataStore

    // Current user JSON
    val currentUserJson: Flow<String?> = dataStore.data.map { it[KEY_USER_JSON] }

    suspend fun saveUserJson(json: String) {
        dataStore.edit { it[KEY_USER_JSON] = json }
    }

    suspend fun clearUser() {
        dataStore.edit { it.remove(KEY_USER_JSON) }
    }

    // Appearance: "system" | "light" | "dark"
    val appearance: Flow<String> = dataStore.data.map { it[KEY_APPEARANCE] ?: "system" }

    suspend fun setAppearance(value: String) {
        dataStore.edit { it[KEY_APPEARANCE] = value }
    }

    // Device GUID
    val deviceGuid: Flow<String?> = dataStore.data.map { it[KEY_DEVICE_GUID] }

    suspend fun setDeviceGuid(guid: String) {
        dataStore.edit { it[KEY_DEVICE_GUID] = guid }
    }

    companion object {
        private val KEY_USER_JSON   = stringPreferencesKey("current_user_json")
        private val KEY_APPEARANCE  = stringPreferencesKey("appearance")
        private val KEY_DEVICE_GUID = stringPreferencesKey("device_guid")
    }
}
