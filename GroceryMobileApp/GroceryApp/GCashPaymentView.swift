import SwiftUI
import WebKit

struct GCashPaymentView: View {
    let amount: Double
    let orderDescription: String
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var isLoading = true
    @State private var showingConfirmation = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // GCash header
                HStack(spacing: 10) {
                    Image(systemName: "creditcard.circle.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GCash Payment")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        Text("$\(Int(amount)) • \(orderDescription)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(red: 0.0, green: 0.44, blue: 0.87))

                // Simulated GCash login/confirm screen
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 20)

                        // GCash logo
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.0, green: 0.44, blue: 0.87).opacity(0.1))
                                .frame(width: 80, height: 80)
                            Text("G")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 0.0, green: 0.44, blue: 0.87))
                        }

                        Text("Pay with GCash")
                            .font(.system(.title3, design: .rounded, weight: .bold))

                        // Amount card
                        VStack(spacing: 8) {
                            Text("Amount to Pay")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                            Text("$\(Int(amount))")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(Color(red: 0.0, green: 0.44, blue: 0.87))
                            Text(orderDescription)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        // Phone number input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GCash Mobile Number")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                Text("+63")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                TextField("9XX XXX XXXX", text: .constant(""))
                                    .font(.system(.subheadline, design: .rounded))
                                    .keyboardType(.phonePad)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }

                        // MPIN input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("GCash MPIN")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                            SecureField("Enter 4-digit MPIN", text: .constant(""))
                                .font(.system(.subheadline, design: .rounded))
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // Pay button
                        Button {
                            showingConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                Text("Pay $\(Int(amount))")
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.0, green: 0.44, blue: 0.87))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        // Security note
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption2)
                            Text("Secured by GCash. Your data is encrypted.")
                                .font(.system(.caption2, design: .rounded))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
            }
            .alert("Confirm Payment", isPresented: $showingConfirmation) {
                Button("Confirm") {
                    // Simulate payment processing
                    onSuccess()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Pay $\(Int(amount)) via GCash for \(orderDescription)?")
            }
        }
    }
}

#Preview {
    GCashPaymentView(
        amount: 45,
        orderDescription: "3 items from GroceryApp",
        onSuccess: { print("Success") },
        onCancel: { print("Cancelled") }
    )
}
