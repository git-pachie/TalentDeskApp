package com.sanshare.groceryapp.data.remote

import android.util.Log
import com.sanshare.groceryapp.data.local.TokenManager
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.android.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.plugins.logging.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.client.request.forms.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.serialization.json.Json

sealed class ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>()
    data class Error(val message: String, val code: Int = 0) : ApiResult<Nothing>()
}

class ApiClient(
    tokenManager: TokenManager,
) {
    @PublishedApi internal val _tokenManager = tokenManager
    @PublishedApi internal val _unauthorizedEvent = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    val unauthorizedEvent = _unauthorizedEvent.asSharedFlow()

    @PublishedApi
    internal val json = Json {
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

    @PublishedApi
    internal fun HttpRequestBuilder.addAuth() {
        _tokenManager.getToken()?.let { token ->
            header(HttpHeaders.Authorization, "Bearer $token")
        }
    }

    @PublishedApi
    internal fun HttpRequestBuilder.addCacheControl() {
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

    @PublishedApi
    internal suspend inline fun <reified T> handleResponse(response: HttpResponse): ApiResult<T> {
        return when {
            response.status.isSuccess() -> {
                try {
                    ApiResult.Success(response.body<T>())
                } catch (e: Exception) {
                    ApiResult.Error("Failed to parse response: ${e.message}")
                }
            }
            response.status == HttpStatusCode.Unauthorized -> {
                _tokenManager.clearToken()
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

    @PublishedApi
    internal fun extractErrorMessage(body: String): String {
        return try {
            val parsed = json.decodeFromString<Map<String, String>>(body)
            parsed["error"] ?: parsed["message"] ?: "Bad request"
        } catch (e: Exception) {
            "Bad request"
        }
    }

    /** POST with empty JSON body — returns true on 2xx.
     *  Uses ByteArray body to guarantee Content-Type: application/json is respected by Ktor. */
    suspend fun postEmpty(path: String): Pair<Boolean, String?> {
        return try {
            val response = httpClient.post("${ApiConfig.BASE_URL}$path") {
                addAuth()
                contentType(ContentType.Application.Json)
                setBody("{}".toByteArray(Charsets.UTF_8))
            }
            if (response.status == HttpStatusCode.Unauthorized) {
                _tokenManager.clearToken()
                _unauthorizedEvent.tryEmit(Unit)
                return Pair(false, "Session expired. Please log in again.")
            }
            if (response.status.isSuccess()) {
                Pair(true, null)
            } else {
                val body = try { response.bodyAsText() } catch (_: Exception) { "" }
                val msg = extractErrorMessage(body).ifBlank { "Request failed (${response.status.value})" }
                Log.w("ApiClient", "postEmpty $path → ${response.status.value}: $body")
                Pair(false, msg)
            }
        } catch (e: Exception) {
            Log.e("ApiClient", "postEmpty $path exception: ${e.message}")
            Pair(false, e.message ?: "Network error")
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

    suspend fun uploadReviewPhotos(files: List<ByteArray>): ApiResult<List<String>> {
        return try {
            val response = httpClient.submitFormWithBinaryData(
                url = "${ApiConfig.BASE_URL}/api/reviews/upload",
                formData = formData {
                    files.forEachIndexed { index, bytes ->
                        append(
                            key = "files",
                            value = bytes,
                            headers = Headers.build {
                                append(HttpHeaders.ContentDisposition, "filename=\"review_$index.jpg\"")
                                append(HttpHeaders.ContentType, "image/jpeg")
                            }
                        )
                    }
                }
            ) {
                addAuth()
            }

            if (response.status.isSuccess()) {
                val payload = response.body<UploadReviewPhotosResponse>()
                ApiResult.Success(payload.urls)
            } else {
                ApiResult.Error("Upload failed: ${response.status.value}", response.status.value)
            }
        } catch (e: Exception) {
            ApiResult.Error(e.message ?: "Photo upload failed")
        }
    }
}
