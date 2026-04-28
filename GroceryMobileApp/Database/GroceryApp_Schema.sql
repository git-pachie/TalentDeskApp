-- ============================================
-- GroceryApp SQL Server Database Schema
-- Generated: April 29, 2026
-- ============================================

CREATE DATABASE GroceryAppDB;
GO

USE GroceryAppDB;
GO

-- ============================================
-- 1. Users
-- ============================================
CREATE TABLE Users (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    Name            NVARCHAR(100)       NOT NULL,
    Email           NVARCHAR(255)       NOT NULL,
    Phone           NVARCHAR(20)        NULL,
    ProfileImage    NVARCHAR(500)       NULL,
    PasswordHash    NVARCHAR(500)       NOT NULL,
    IsActive        BIT                 NOT NULL DEFAULT 1,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_Users PRIMARY KEY (Id),
    CONSTRAINT UQ_Users_Email UNIQUE (Email)
);
GO

-- ============================================
-- 2. Categories
-- ============================================
CREATE TABLE Categories (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    Name            NVARCHAR(100)       NOT NULL,
    Emoji           NVARCHAR(10)        NULL,
    SortOrder       INT                 NOT NULL DEFAULT 0,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_Categories PRIMARY KEY (Id),
    CONSTRAINT UQ_Categories_Name UNIQUE (Name)
);
GO

-- ============================================
-- 3. Products
-- ============================================
CREATE TABLE Products (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    Name            NVARCHAR(200)       NOT NULL,
    Location        NVARCHAR(200)       NULL,
    Price           DECIMAL(10,2)       NOT NULL,
    OriginalPrice   DECIMAL(10,2)       NULL,
    Discount        NVARCHAR(50)        NULL,
    Emoji           NVARCHAR(10)        NULL,
    IsActive        BIT                 NOT NULL DEFAULT 1,
    IsDeal          BIT                 NOT NULL DEFAULT 0,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_Products PRIMARY KEY (Id)
);
GO

-- ============================================
-- 3b. ProductCategories (many-to-many junction)
-- ============================================
CREATE TABLE ProductCategories (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    ProductId       UNIQUEIDENTIFIER    NOT NULL,
    CategoryId      UNIQUEIDENTIFIER    NOT NULL,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_ProductCategories PRIMARY KEY (Id),
    CONSTRAINT FK_ProductCategories_Products FOREIGN KEY (ProductId) REFERENCES Products(Id) ON DELETE CASCADE,
    CONSTRAINT FK_ProductCategories_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(Id) ON DELETE CASCADE,
    CONSTRAINT UQ_ProductCategories UNIQUE (ProductId, CategoryId)
);
GO

-- ============================================
-- 3c. ProductImages (multiple images per product)
-- ============================================
CREATE TABLE ProductImages (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    ProductId       UNIQUEIDENTIFIER    NOT NULL,
    ImageURL        NVARCHAR(500)       NOT NULL,
    IsPrimary       BIT                 NOT NULL DEFAULT 0,
    SortOrder       INT                 NOT NULL DEFAULT 0,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_ProductImages PRIMARY KEY (Id),
    CONSTRAINT FK_ProductImages_Products FOREIGN KEY (ProductId) REFERENCES Products(Id) ON DELETE CASCADE
);
GO

-- Ensure only one primary image per product
CREATE UNIQUE INDEX IX_ProductImages_PrimaryPerProduct
    ON ProductImages(ProductId)
    WHERE IsPrimary = 1;
GO

-- ============================================
-- 4. Addresses
-- ============================================
CREATE TABLE Addresses (
    Id                      UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    UserId                  UNIQUEIDENTIFIER    NOT NULL,
    Label                   NVARCHAR(50)        NOT NULL,
    Address                 NVARCHAR(500)       NOT NULL,
    DeliveryInstructions    NVARCHAR(500)       NULL,
    ContactNumber           NVARCHAR(20)        NULL,
    Latitude                FLOAT               NULL,
    Longitude               FLOAT               NULL,
    IsDefault               BIT                 NOT NULL DEFAULT 0,
    DateCreated             DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy               NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_Addresses PRIMARY KEY (Id),
    CONSTRAINT FK_Addresses_Users FOREIGN KEY (UserId) REFERENCES Users(Id)
);
GO

-- ============================================
-- 5. PaymentMethods
-- ============================================
CREATE TABLE PaymentMethods (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    UserId          UNIQUEIDENTIFIER    NOT NULL,
    Name            NVARCHAR(100)       NOT NULL,
    Detail          NVARCHAR(200)       NULL,
    PaymentType     NVARCHAR(50)        NOT NULL DEFAULT 'CreditCard',
    Icon            NVARCHAR(50)        NULL,
    IsDefault       BIT                 NOT NULL DEFAULT 0,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_PaymentMethods PRIMARY KEY (Id),
    CONSTRAINT FK_PaymentMethods_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT CK_PaymentMethods_Type CHECK (PaymentType IN ('CreditCard', 'DebitCard', 'ApplePay', 'GCash', 'CashOnDelivery'))
);
GO

-- ============================================
-- 6. Vouchers
-- ============================================
CREATE TABLE Vouchers (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    Code            NVARCHAR(50)        NOT NULL,
    Description     NVARCHAR(200)       NOT NULL,
    Discount        NVARCHAR(50)        NOT NULL,
    DiscountValue   DECIMAL(10,2)       NOT NULL DEFAULT 0,
    MinOrder        NVARCHAR(50)        NULL,
    MinOrderValue   DECIMAL(10,2)       NULL,
    ValidUntil      DATETIME2           NOT NULL,
    IsActive        BIT                 NOT NULL DEFAULT 1,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_Vouchers PRIMARY KEY (Id),
    CONSTRAINT UQ_Vouchers_Code UNIQUE (Code)
);
GO

-- ============================================
-- 7. Cart
-- ============================================
CREATE TABLE Cart (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    UserId          UNIQUEIDENTIFIER    NOT NULL,
    ProductId       UNIQUEIDENTIFIER    NOT NULL,
    Quantity        INT                 NOT NULL DEFAULT 1,
    Remarks         NVARCHAR(500)       NULL,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_Cart PRIMARY KEY (Id),
    CONSTRAINT FK_Cart_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT FK_Cart_Products FOREIGN KEY (ProductId) REFERENCES Products(Id),
    CONSTRAINT UQ_Cart_UserProduct UNIQUE (UserId, ProductId)
);
GO

-- ============================================
-- 8. Orders
-- ============================================
CREATE TABLE Orders (
    Id                  UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    UserId              UNIQUEIDENTIFIER    NOT NULL,
    OrderNumber         NVARCHAR(20)        NOT NULL,
    AddressId           UNIQUEIDENTIFIER    NULL,
    PaymentMethodId     UNIQUEIDENTIFIER    NULL,
    VoucherId           UNIQUEIDENTIFIER    NULL,
    PaymentMethod       NVARCHAR(50)        NOT NULL DEFAULT 'CreditCard',
    PaymentDetail       NVARCHAR(200)       NULL,
    Subtotal            DECIMAL(10,2)       NOT NULL DEFAULT 0,
    DeliveryFee         DECIMAL(10,2)       NOT NULL DEFAULT 0,
    PlatformFee         DECIMAL(10,2)       NOT NULL DEFAULT 0,
    OtherCharges        DECIMAL(10,2)       NOT NULL DEFAULT 0,
    VoucherDiscount     DECIMAL(10,2)       NOT NULL DEFAULT 0,
    Total               DECIMAL(10,2)       NOT NULL DEFAULT 0,
    Status              NVARCHAR(20)        NOT NULL DEFAULT 'Processing',
    OrderRemarks        NVARCHAR(1000)      NULL,
    DeliveredBy         NVARCHAR(100)       NULL,
    DeliveredAt         DATETIME2           NULL,
    DateCreated         DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy           NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_Orders PRIMARY KEY (Id),
    CONSTRAINT FK_Orders_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT FK_Orders_Addresses FOREIGN KEY (AddressId) REFERENCES Addresses(Id),
    CONSTRAINT FK_Orders_PaymentMethods FOREIGN KEY (PaymentMethodId) REFERENCES PaymentMethods(Id),
    CONSTRAINT FK_Orders_Vouchers FOREIGN KEY (VoucherId) REFERENCES Vouchers(Id),
    CONSTRAINT UQ_Orders_OrderNumber UNIQUE (OrderNumber),
    CONSTRAINT CK_Orders_Status CHECK (Status IN ('Processing', 'Shipped', 'Delivered', 'Cancelled')),
    CONSTRAINT CK_Orders_PaymentMethod CHECK (PaymentMethod IN ('CreditCard', 'DebitCard', 'ApplePay', 'GCash', 'CashOnDelivery'))
);
GO

-- ============================================
-- 8b. OrderStatusHistory (track status changes)
-- ============================================
CREATE TABLE OrderStatusHistory (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    OrderId         UNIQUEIDENTIFIER    NOT NULL,
    Status          NVARCHAR(20)        NOT NULL,
    Notes           NVARCHAR(500)       NULL,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_OrderStatusHistory PRIMARY KEY (Id),
    CONSTRAINT FK_OrderStatusHistory_Orders FOREIGN KEY (OrderId) REFERENCES Orders(Id) ON DELETE CASCADE,
    CONSTRAINT CK_OrderStatusHistory_Status CHECK (Status IN ('Processing', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'))
);
GO

-- ============================================
-- 8c. Payments (transaction records)
-- ============================================
CREATE TABLE Payments (
    Id                  UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    OrderId             UNIQUEIDENTIFIER    NOT NULL,
    PaymentMethod       NVARCHAR(50)        NOT NULL,
    PaymentDetail       NVARCHAR(200)       NULL,
    Amount              DECIMAL(10,2)       NOT NULL,
    TransactionId       NVARCHAR(100)       NULL,
    Status              NVARCHAR(20)        NOT NULL DEFAULT 'Pending',
    PaidAt              DATETIME2           NULL,
    DateCreated         DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy           NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_Payments PRIMARY KEY (Id),
    CONSTRAINT FK_Payments_Orders FOREIGN KEY (OrderId) REFERENCES Orders(Id) ON DELETE CASCADE,
    CONSTRAINT CK_Payments_Status CHECK (Status IN ('Pending', 'Completed', 'Failed', 'Refunded')),
    CONSTRAINT CK_Payments_Method CHECK (PaymentMethod IN ('CreditCard', 'DebitCard', 'ApplePay', 'GCash', 'CashOnDelivery'))
);
GO

-- ============================================
-- 9. OrderItems (line items per order)
-- ============================================
CREATE TABLE OrderItems (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    OrderId         UNIQUEIDENTIFIER    NOT NULL,
    ProductId       UNIQUEIDENTIFIER    NOT NULL,
    Quantity        INT                 NOT NULL DEFAULT 1,
    UnitPrice       DECIMAL(10,2)       NOT NULL,
    LineTotal       AS (Quantity * UnitPrice) PERSISTED,
    Remarks         NVARCHAR(500)       NULL,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_OrderItems PRIMARY KEY (Id),
    CONSTRAINT FK_OrderItems_Orders FOREIGN KEY (OrderId) REFERENCES Orders(Id) ON DELETE CASCADE,
    CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ProductId) REFERENCES Products(Id)
);
GO

-- ============================================
-- 10. OrderReviews
-- ============================================
CREATE TABLE OrderReviews (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    OrderId         UNIQUEIDENTIFIER    NOT NULL,
    UserId          UNIQUEIDENTIFIER    NOT NULL,
    Rating          INT                 NOT NULL,
    Remarks         NVARCHAR(2000)      NULL,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_OrderReviews PRIMARY KEY (Id),
    CONSTRAINT FK_OrderReviews_Orders FOREIGN KEY (OrderId) REFERENCES Orders(Id) ON DELETE CASCADE,
    CONSTRAINT FK_OrderReviews_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT UQ_OrderReviews_Order UNIQUE (OrderId),
    CONSTRAINT CK_OrderReviews_Rating CHECK (Rating BETWEEN 1 AND 5)
);
GO

-- ============================================
-- 11. ReviewPhotos
-- ============================================
CREATE TABLE ReviewPhotos (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    ReviewId        UNIQUEIDENTIFIER    NOT NULL,
    PhotoURL        NVARCHAR(500)       NOT NULL,
    SortOrder       INT                 NOT NULL DEFAULT 0,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_ReviewPhotos PRIMARY KEY (Id),
    CONSTRAINT FK_ReviewPhotos_Reviews FOREIGN KEY (ReviewId) REFERENCES OrderReviews(Id) ON DELETE CASCADE
);
GO

-- ============================================
-- 12. Favorites
-- ============================================
CREATE TABLE Favorites (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    UserId          UNIQUEIDENTIFIER    NOT NULL,
    ProductId       UNIQUEIDENTIFIER    NOT NULL,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_Favorites PRIMARY KEY (Id),
    CONSTRAINT FK_Favorites_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT FK_Favorites_Products FOREIGN KEY (ProductId) REFERENCES Products(Id),
    CONSTRAINT UQ_Favorites_UserProduct UNIQUE (UserId, ProductId)
);
GO

-- ============================================
-- 13. UserSettings
-- ============================================
CREATE TABLE UserSettings (
    Id              UNIQUEIDENTIFIER    NOT NULL DEFAULT NEWID(),
    UserId          UNIQUEIDENTIFIER    NOT NULL,
    SettingKey      NVARCHAR(50)        NOT NULL,
    SettingValue    NVARCHAR(200)       NOT NULL,
    DateCreated     DATETIME2           NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy       NVARCHAR(100)       NOT NULL DEFAULT 'SYSTEM',

    CONSTRAINT PK_UserSettings PRIMARY KEY (Id),
    CONSTRAINT FK_UserSettings_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT UQ_UserSettings_UserKey UNIQUE (UserId, SettingKey)
);
GO

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IX_ProductCategories_ProductId ON ProductCategories(ProductId);
CREATE INDEX IX_ProductCategories_CategoryId ON ProductCategories(CategoryId);
CREATE INDEX IX_ProductImages_ProductId ON ProductImages(ProductId);
CREATE INDEX IX_Products_IsActive ON Products(IsActive) WHERE IsActive = 1;
CREATE INDEX IX_Products_IsDeal ON Products(IsDeal) WHERE IsDeal = 1;
CREATE INDEX IX_Addresses_UserId ON Addresses(UserId);
CREATE INDEX IX_PaymentMethods_UserId ON PaymentMethods(UserId);
CREATE INDEX IX_Cart_UserId ON Cart(UserId);
CREATE INDEX IX_Orders_UserId ON Orders(UserId);
CREATE INDEX IX_Orders_Status ON Orders(Status);
CREATE INDEX IX_Orders_OrderNumber ON Orders(OrderNumber);
CREATE INDEX IX_Orders_PaymentMethod ON Orders(PaymentMethod);
CREATE INDEX IX_OrderStatusHistory_OrderId ON OrderStatusHistory(OrderId);
CREATE INDEX IX_Payments_OrderId ON Payments(OrderId);
CREATE INDEX IX_Payments_Status ON Payments(Status);
CREATE INDEX IX_Payments_TransactionId ON Payments(TransactionId) WHERE TransactionId IS NOT NULL;
CREATE INDEX IX_OrderItems_OrderId ON OrderItems(OrderId);
CREATE INDEX IX_OrderReviews_OrderId ON OrderReviews(OrderId);
CREATE INDEX IX_ReviewPhotos_ReviewId ON ReviewPhotos(ReviewId);
CREATE INDEX IX_Favorites_UserId ON Favorites(UserId);
CREATE INDEX IX_Vouchers_Code ON Vouchers(Code);
CREATE INDEX IX_Vouchers_IsActive ON Vouchers(IsActive) WHERE IsActive = 1;
GO
