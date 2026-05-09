import PassKit
import SwiftUI

struct ApplePayService {
    static let merchantIdentifier = "merchant.com.sanshare.GroceryApp"
    static let supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex, .discover]

    static var isAvailable: Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
    }

    static func createPaymentRequest(
        items: [(name: String, amount: Double)],
        deliveryFee: Double,
        platformFee: Double,
        otherCharges: Double,
        voucherDiscount: Double
    ) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.supportedNetworks = supportedNetworks
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US"
        request.currencyCode = "USD"

        var summaryItems: [PKPaymentSummaryItem] = []

        // Line items
        for item in items {
            summaryItems.append(
                PKPaymentSummaryItem(
                    label: item.name,
                    amount: NSDecimalNumber(value: item.amount)
                )
            )
        }

        // Fees
        summaryItems.append(
            PKPaymentSummaryItem(label: "Delivery Fee", amount: NSDecimalNumber(value: deliveryFee))
        )
        summaryItems.append(
            PKPaymentSummaryItem(label: "Platform Fee", amount: NSDecimalNumber(value: platformFee))
        )
        summaryItems.append(
            PKPaymentSummaryItem(label: "Other Charges", amount: NSDecimalNumber(value: otherCharges))
        )

        // Voucher discount
        if voucherDiscount > 0 {
            summaryItems.append(
                PKPaymentSummaryItem(
                    label: "Voucher Discount",
                    amount: NSDecimalNumber(value: -voucherDiscount)
                )
            )
        }

        // Total
        let total = items.reduce(0) { $0 + $1.amount } + deliveryFee + platformFee + otherCharges - voucherDiscount
        summaryItems.append(
            PKPaymentSummaryItem(
                label: "GroceryApp",
                amount: NSDecimalNumber(value: max(0, total)),
                type: .final
            )
        )

        request.paymentSummaryItems = summaryItems
        return request
    }
}
