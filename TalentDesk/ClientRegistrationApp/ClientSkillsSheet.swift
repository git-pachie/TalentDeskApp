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
            List {
                if draftClient.skills.isEmpty {
                    ContentUnavailableView(
                        "No Skills",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Tap + to add skills.")
                    )
                } else {
                    ForEach(Array(draftClient.skills.enumerated()), id: \.element.id) { index, skill in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(skill.name)
                                    .font(.subheadline)
                                Text(formattedRate(skill.hourlyRate))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Edit") {
                                editingSkillSelection = SkillSelection(id: index)
                            }
                            .font(.caption)
                            .buttonStyle(.borderless)
                        }
                    }
                    .onDelete(perform: deleteSkills)
                }
            }
            .navigationTitle("Skills")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .font(.subheadline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddSkill = true } label: {
                        Image(systemName: "plus")
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

    private func deleteSkills(at offsets: IndexSet) {
        draftClient.skills.remove(atOffsets: offsets)
        persistChanges()
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
