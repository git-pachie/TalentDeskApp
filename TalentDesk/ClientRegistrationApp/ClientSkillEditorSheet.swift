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
            Form {
                Section("Skill") {
                    TextField("Skill name", text: $skillName)
                        .font(.subheadline)
                    TextField("Hourly Rate", text: $hourlyRate)
                        .keyboardType(.decimalPad)
                        .font(.subheadline)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.subheadline)
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
                    .disabled(trimmedSkill.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func trimmedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
