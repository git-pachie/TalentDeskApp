import SwiftUI

struct CardPaymentView: View {
    let cardType: String // "Credit Card" or "Debit Card"
    let amount: Double
    let orderDescription: String
    let onSuccess: (String) -> Void // returns masked card number
    let onCancel: () -> Void

    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var saveCard = true
    @State private var isProcessing = false
    @State private var showingError = false

    private var isValid: Bool {
        cardNumber.filter(\.isNumber).count >= 13 &&
        expiryDate.count >= 4 &&
        cvv.count >= 3 &&
        !cardholderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var maskedNumber: String {
        let digits = cardNumber.filter(\.isNumber)
        let last4 = String(digits.suffix(4))
        return "•••• •••• •••• \(last4)"
    }

    private var cardBrand: String {
        let digits = cardNumber.filter(\.isNumber)
        guard let first = digits.first else { return "" }
        switch first {
        case "4": return "VISA"
        case "5": return "Mastercard"
        case "3": return "AMEX"
        case "6": return "Discover"
        default: return ""
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Card preview
                    cardPreview

                    // Card form
                    VStack(alignment: .leading, spacing: 14) {
                        Label("\(cardType) Details", systemImage: "creditcard.fill")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(GroceryTheme.primary)

                        // Card number
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Card Number")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                            HStack {
                                TextField("1234 5678 9012 3456", text: $cardNumber)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .keyboardType(.numberPad)
                                    .onChange(of: cardNumber) { _, newValue in
                                        cardNumber = formatCardNumber(newValue)
                                    }
                                if !cardBrand.isEmpty {
                                    Text(cardBrand)
                                        .font(.system(.caption2, design: .rounded, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(GroceryTheme.primaryLight)
                                        .foregroundStyle(GroceryTheme.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Expiry + CVV row
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Expiry Date")
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundStyle(.secondary)
                                TextField("MM/YY", text: $expiryDate)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .keyboardType(.numberPad)
                                    .onChange(of: expiryDate) { _, newValue in
                                        expiryDate = formatExpiry(newValue)
                                    }
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("CVV")
                                    .font(.system(.caption, design: .rounded, weight: .medium))
                                    .foregroundStyle(.secondary)
                                SecureField("123", text: $cvv)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .frame(width: 100)
                        }

                        // Cardholder name
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cardholder Name")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                            TextField("John Doe", text: $cardholderName)
                                .font(.system(.subheadline, design: .rounded))
                                .textInputAutocapitalization(.words)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Save card toggle
                        Toggle(isOn: $saveCard) {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.caption)
                                Text("Save card for future payments")
                                    .font(.system(.caption, design: .rounded))
                            }
                        }
                        .tint(GroceryTheme.primary)
                    }
                    .padding(14)
                    .background(GroceryTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

                    // Pay button
                    Button {
                        processPayment()
                    } label: {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                            }
                            Text(isProcessing ? "Processing..." : "Pay $\(Int(amount))")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isValid && !isProcessing ? GroceryTheme.primary : Color(.systemGray4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(!isValid || isProcessing)

                    // Security note
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption2)
                        Text("256-bit SSL encrypted. Your card details are secure.")
                            .font(.system(.caption2, design: .rounded))
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
            }
            .background(GroceryTheme.background)
            .navigationTitle("Pay with \(cardType)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
            .alert("Payment Failed", isPresented: $showingError) {
                Button("Try Again", role: .cancel) { }
            } message: {
                Text("Unable to process your payment. Please check your card details and try again.")
            }
        }
    }

    // MARK: - Card Preview

    private var cardPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: cardType == "Credit Card"
                            ? [Color(red: 0.15, green: 0.15, blue: 0.20), Color(red: 0.25, green: 0.25, blue: 0.35)]
                            : [Color(red: 0.0, green: 0.35, blue: 0.55), Color(red: 0.0, green: 0.50, blue: 0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 190)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(cardType)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    Text(cardBrand)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text(cardNumber.isEmpty ? "•••• •••• •••• ••••" : cardNumber)
                    .font(.system(.title3, design: .monospaced, weight: .medium))
                    .foregroundStyle(.white)
                    .tracking(2)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CARDHOLDER")
                            .font(.system(size: 8, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(cardholderName.isEmpty ? "YOUR NAME" : cardholderName.uppercased())
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("EXPIRES")
                            .font(.system(size: 8, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(expiryDate.isEmpty ? "MM/YY" : expiryDate)
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Helpers

    private func formatCardNumber(_ input: String) -> String {
        let digits = input.filter(\.isNumber).prefix(16)
        var result = ""
        for (i, char) in digits.enumerated() {
            if i > 0 && i % 4 == 0 { result += " " }
            result.append(char)
        }
        return result
    }

    private func formatExpiry(_ input: String) -> String {
        let digits = input.filter(\.isNumber).prefix(4)
        if digits.count > 2 {
            return "\(digits.prefix(2))/\(digits.suffix(from: digits.index(digits.startIndex, offsetBy: 2)))"
        }
        return String(digits)
    }

    private func processPayment() {
        isProcessing = true
        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessing = false
            onSuccess(maskedNumber)
        }
    }
}

#Preview {
    CardPaymentView(
        cardType: "Credit Card",
        amount: 45,
        orderDescription: "3 items",
        onSuccess: { _ in },
        onCancel: { }
    )
}
