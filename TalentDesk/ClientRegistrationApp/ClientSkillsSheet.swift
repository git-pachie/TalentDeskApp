import SwiftUI

struct ClientSkillsSheet: View {
    private struct SkillSelection: Identifiable {
        let id: Int
    }

    @Environment(\.dismiss) private var dismiss

    @Bindable var clientStore: ClientStore
    @State private var draftClient: ClientRegistration
    @State private var showingAddSkill = false
    @State private var editingSkillSelection: SkillSelection?

    init(clientStore: ClientStore, client: ClientRegistration) {
        self.clientStore = clientStore
        _draftClient = State(initialValue: client)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if draftClient.skills.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Skills",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Tap + to add skills.")
                    )
                    .foregroundStyle(AppTheme.subtitleText)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(draftClient.skills.enumerated()), id: \.element.id) { index, skill in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(skill.name)
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.darkText)
                                        Text(formattedRate(skill.hourlyRate))
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.subtitleText)
                                    }
                                    Spacer()
                                    Button("Edit") {
                                        editingSkillSelection = SkillSelection(id: index)
                                    }
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AppTheme.accent)
                                    .buttonStyle(.borderless)
                                }
                                .padding(12)
                                .background(AppTheme.secondarySurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(AppTheme.accent.opacity(0.2))
            .navigationTitle("Skills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddSkill = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddSkill) {
                ClientSkillEditorSheet(title: "Add Skill") { skill in
                    draftClient.skills.append(skill)
                    persistChanges()
                }
            }
            .sheet(item: $editingSkillSelection) { selection in
                ClientSkillEditorSheet(
                    title: "Edit Skill",
                    initialSkill: draftClient.skills[selection.id]
                ) { skill in
                    draftClient.skills[selection.id] = skill
                    persistChanges()
                }
            }
        }
    }

    private func persistChanges() {
        clientStore.update(draftClient)
    }

    private func formattedRate(_ rate: Double?) -> String {
        guard let rate else { return "Rate not set" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        return formatter.string(from: NSNumber(value: rate)) ?? String(format: "%.2f", rate)
    }
}
