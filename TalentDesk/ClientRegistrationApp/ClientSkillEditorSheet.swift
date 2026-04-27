import SwiftUI

struct ClientSkillEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let initialSkill: ClientSkill?
    let onSave: (ClientSkill) -> Void

    @State private var skillName: String
    @State private var hourlyRate: String

    init(title: String, initialSkill: ClientSkill? = nil, onSave: @escaping (ClientSkill) -> Void) {
        self.title = title
        self.initialSkill = initialSkill
        self.onSave = onSave
        _skillName = State(initialValue: initialSkill?.name ?? "")
        _hourlyRate = State(initialValue: initialSkill?.hourlyRate.map { String($0) } ?? "")
    }

    private var trimmedSkill: String {
        skillName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Skill", systemImage: "star.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)

                    sheetField(placeholder: "Skill name", text: $skillName)
                    sheetField(placeholder: "Hourly Rate", text: $hourlyRate)
                        .keyboardType(.decimalPad)
                }
                .dashboardCard()
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()
            }
            .background(AppTheme.accent.opacity(0.2))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(
                            ClientSkill(
                                id: initialSkill?.id ?? UUID(),
                                name: trimmedSkill,
                                hourlyRate: trimmedOptional(hourlyRate).flatMap(Double.init)
                            )
                        )
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                    .disabled(trimmedSkill.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func sheetField(placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .leading) {
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedText)
            }
            TextField("", text: text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.darkText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }

    private func trimmedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
