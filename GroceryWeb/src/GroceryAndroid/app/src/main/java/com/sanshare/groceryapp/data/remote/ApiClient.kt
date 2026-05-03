package com.sanshare.groceryapp.data.remote

import android.util.Log
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.android.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

sealed class ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>()
    data class Error(val message: String, val code: Int = 0) : ApiResult<Nothing>()
}

@Singleton
class ApiClient @Inject constructor(
    private val tokenManager: TokenManager,
) {
    private val _unauthorizedEvent = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    val unauthorizedEvent = _unauthorizedEvent.asSharedFlow()

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
        coerceInputValues = true
    }

    val httpClient = HttpClient(Android) {
        install(ContentNegotiation) {
            json(json)
        }
        install(Logging) {
            logger = object : Logger {
                override fun log(message: String) {
                    Log.d("ApiClient", message)
                }
            }
            level = LogLevel.BODY
        }
        install(HttpTimeout) {
            requestTimeoutMillis = 30_000
            connectTimeoutMillis = 15_000
        }
        engine {
            // Trust all certs in dev — remove in production
            sslManager = { httpsURLConnection ->
                httpsURLConnection.hostnameVerifier = javax.net.ssl.HostnameVerifier { _, _ -> true }
                val trustAllCerts = arrayOf<javax.net.ssl.TrustManager>(
                    object : javax.net.ssl.X509TrustManager {
                        override fun checkClientTrusted(chain: Array<java.security.cert.X509Certificate>, authType: String) {}
                        override fun checkServerTrusted(chain: Array<java.security.cert.X509Certificate>, authType: String) {}
                        override fun getAcceptedIssuers(): Array<java.security.cert.X509Certificate> = arrayOf()
                    }
                )
                val sc = javax.net.ssl.SSLContext.getInstance("TLS")
                sc.init(null, trustAllCerts, java.security.SecureRandom())
                httpsURLConnection.sslSocketFactory = sc.socketFactory
            }
        }
    }

    private fun HttpRequestBuilder.addAuth() {
        tokenManager.getToken()?.let { token ->
            header(HttpHeaders.Authorization, "Bearer $token")
        }
    }

    private fun HttpRequestBuilder.addCacheControl() {
        header("Cache-Control", "no-cache, no-store, must-revalidate")
        header("Pragma", "no-cache")
    }

    suspend inline fun <reified T> get(path: String, params: Map<String, String> = emptyMap()): ApiResult<T> {
        return try {
            val response = httpClient.get("${ApiConfig.BASE_URL}$path") {
                addAuth()
                addCacheControl()
                params.forEach { (k, v) -> parameter(k, v) }
            }
            handleResponse(response)
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Network error")
        }
    }

    suspend inline fun <reified B, reified T> post(path: String, body: B): ApiResult<T> {
        return try {
            val response = httpClient.post("${ApiConfig.BASE_URL}$path") {
                addAuth()
                contentType(ContentType.Application.Json)
                setBody(body)
            }
            handleResponse(response)
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Network error")
        }
    }

    suspend inline fun <reified B, reified T> put(path: String, body: B): ApiResult<T> {
        return try {
            val response = httpClient.put("${ApiConfig.BASE_URL}$path") {
                addAuth()
                contentType(ContentType.Application.Json)
                setBody(body)
            }
            handleResponse(response)
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Network error")
        }
    }

    suspend fun delete(path: String): ApiResult<Unit> {
        return try {
            val response = httpClient.delete("${ApiConfig.BASE_URL}$path") {
                addAuth()
            }
            if (response.status.isSuccess()) ApiResult.Success(Unit)
            else ApiResult.Error("Delete failed: ${response.status.value}", response.status.value)
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Network error")
        }
    }

    suspend inline fun <reified T> handleResponse(response: HttpResponse): ApiResult<T> {
        return when {
            response.status.isSuccess() -> {
                try {
                    ApiResult.Success(response.body<T>())
                } catch (e: Exception) {
                    ApiResult.Error("Failed to parse response: ${e.message}")
                }
            }
            response.status == HttpStatusCode.Unauthorized -> {
                tokenManager.clearToken()
                _unauthorizedEvent.tryEmit(Unit)
                ApiResult.Error("Session expired. Please log in again.", 401)
            }
            response.status == HttpStatusCode.BadRequest -> {
                val body = try { response.bodyAsText() } catch (e: Exception) { "" }
                ApiResult.Error(extractErrorMessage(body), 400)
            }
            response.status == HttpStatusCode.NotFound ->
                ApiResult.Error("Resource not found.", 404)
            else ->
                ApiResult.Error("Server error: ${response.status.value}", response.status.value)
        }
    }

    private fun extractErrorMessage(body: String): String {
        return try {
            val parsed = json.decodeFromString<Map<String, String>>(body)
            parsed["error"] ?: parsed["message"] ?: "Bad request"
        } catch (e: Exception) {
            "Bad request"
        }
    }

    suspend fun checkConnectivity(): Boolean {
        return try {
            val response = httpClient.get("${ApiConfig.BASE_URL}${ApiConfig.HEALTH}")
            response.status.isSuccess()
        } catch (e: Exception) {
            false
        }
    }
}
