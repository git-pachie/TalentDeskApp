# Product Overview

This workspace contains multiple projects under a shared monorepo:

## 1. TalentDesk (iOS App)
A SwiftUI iOS app for freelancers and recruiters to register, manage, and track client profiles.
- User onboarding with splash transition
- Client CRUD: name, age, mobile, email, photo, skills (with hourly rates), address
- Dashboard with hiring/opportunity charts and job listings
- Push notification support (APNs)
- Settings with Light/Dark/System appearance toggle
- Dark theme with mint/teal accent (adaptive light mode)

## 2. TalentDeskAPI (.NET 9 Web API)
A .NET 9 Web API backend for sending Apple Push Notifications (APNs) to iOS devices.
- JWT token-based APNs authentication using .p8 keys
- POST endpoint to send push notifications with title, body, badge, sound, and custom data

## 3. GroceryMobileApp (iOS App)
A full-featured SwiftUI grocery shopping app with:
- Home: delivery address picker, search, carousel banners, categories (2-row grid), product deals
- Product catalog with real images (Unsplash), favorites, cart with item remarks
- Item detail: image gallery, quantity selector, related products, add to cart
- Cart: quantity controls, item remarks, checkout flow
- Checkout: delivery address, payment method (Credit Card, Debit Card, Apple Pay, GCash, COD), vouchers, order remarks, price breakdown, success animation
- Orders: current/history tabs, order detail with status timeline, pull-to-refresh status progression
- Reviews: star rating, text remarks, photo uploads for delivered orders
- Profile: appearance toggle, orders, addresses (with map + reverse geocoding), payment methods, vouchers
- PDF export and share for order details
- Light/Dark mode with adaptive theme colors

## 4. GroceryWeb (ASP.NET Core 9)
A layered ASP.NET Core 9 web solution with:
- GroceryApp.API — REST API
- GroceryApp.Admin — MVC admin panel
- GroceryApp.Application — business logic layer
- GroceryApp.Domain — domain entities
- GroceryApp.Infrastructure — data access

## 5. Database
SQL Server schema for GroceryApp with 16 tables: Users, Categories, Products, ProductCategories, ProductImages, Addresses, PaymentMethods, Vouchers, Cart, Orders, OrderStatusHistory, Payments, OrderItems, OrderReviews, ReviewPhotos, Favorites, UserSettings.
