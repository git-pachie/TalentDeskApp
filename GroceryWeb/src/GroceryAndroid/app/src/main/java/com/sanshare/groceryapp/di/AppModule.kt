package com.sanshare.groceryapp.di

import com.sanshare.groceryapp.data.local.SecureTokenManager
import com.sanshare.groceryapp.data.local.TokenManager
import com.sanshare.groceryapp.data.remote.ApiClient
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideApiClient(tokenManager: TokenManager): ApiClient {
        return ApiClient(tokenManager)
    }
}
