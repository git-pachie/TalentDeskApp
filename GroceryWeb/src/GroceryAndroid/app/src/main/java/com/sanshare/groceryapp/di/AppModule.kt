package com.sanshare.groceryapp.di

import android.content.Context
import com.sanshare.groceryapp.data.local.TokenManager
import com.sanshare.groceryapp.data.local.UserPreferences
import com.sanshare.groceryapp.data.remote.ApiClient
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideTokenManager(
        @ApplicationContext context: Context,
    ): TokenManager = TokenManager(context)

    @Provides
    @Singleton
    fun provideUserPreferences(
        @ApplicationContext context: Context,
    ): UserPreferences = UserPreferences(context)

    @Provides
    @Singleton
    fun provideApiClient(
        tokenManager: TokenManager,
    ): ApiClient = ApiClient(tokenManager)
}
