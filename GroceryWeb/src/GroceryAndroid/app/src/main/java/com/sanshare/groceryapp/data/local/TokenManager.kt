package com.sanshare.groceryapp.data.local

import android.content.Context
import android.util.Base64
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import org.json.JSONObject

class TokenManager(
    context: Context,
) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs = EncryptedSharedPreferences.create(
        context,
        "grocery_secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )

    fun getToken(): String? = prefs.getString(KEY_TOKEN, null)

    fun setToken(token: String) {
        prefs.edit().putString(KEY_TOKEN, token).apply()
    }

    fun clearToken() {
        prefs.edit().remove(KEY_TOKEN).apply()
    }

    val isAuthenticated: Boolean
        get() {
            val token = getToken() ?: return false
            return !isTokenExpired(token)
        }

    private fun isTokenExpired(token: String): Boolean {
        return try {
            val parts = token.split(".")
            if (parts.size != 3) return true
            var base64 = parts[1]
                .replace("-", "+")
                .replace("_", "/")
            val remainder = base64.length % 4
            if (remainder > 0) base64 += "=".repeat(4 - remainder)
            val decoded = Base64.decode(base64, Base64.DEFAULT)
            val json = JSONObject(String(decoded))
            val exp = json.optLong("exp", 0L)
            exp * 1000L < System.currentTimeMillis()
        } catch (e: Exception) {
            true
        }
    }

    companion object {
        private const val KEY_TOKEN = "jwt_token"
    }
}
