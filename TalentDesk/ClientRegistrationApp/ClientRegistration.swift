import Foundation
import Observation

struct ClientSkill: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var hourlyRate: Double?

    init(id: UUID = UUID(), name: String, hourlyRate: Double? = nil) {
        self.id = id
        self.name = name
        self.hourlyRate = hourlyRate
    }
}

struct ClientRegistration: Identifiable, Equatable, Codable {
    let id: UUID
    var firstName: String
    var lastName: String
    var age: Int
    var mobile: String
    var email: String
    var skills: [ClientSkill]
    var address: String?
    var photoData: Data?

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        age: Int,
        mobile: String,
        email: String,
        skills: [ClientSkill] = [],
        address: String? = nil,
        photoData: Data? = nil
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        self.mobile = mobile
        self.email = email
        self.skills = skills
        self.address = address
        self.photoData = photoData
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case age
        case mobile
        case email
        case skills
        case hourlyRate
        case address
        case photoData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        age = try container.decode(Int.self, forKey: .age)
        mobile = try container.decode(String.self, forKey: .mobile)
        email = try container.decode(String.self, forKey: .email)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        photoData = try container.decodeIfPresent(Data.self, forKey: .photoData)

        let legacyHourlyRate = try container.decodeIfPresent(Double.self, forKey: .hourlyRate)

        if let decodedSkills = try container.decodeIfPresent([ClientSkill].self, forKey: .skills) {
            skills = decodedSkills
        } else if let legacySkillNames = try container.decodeIfPresent([String].self, forKey: .skills) {
            skills = legacySkillNames.map { ClientSkill(name: $0, hourlyRate: legacyHourlyRate) }
        } else if let legacySkills = try container.decodeIfPresent(String.self, forKey: .skills) {
            let trimmed = legacySkills.trimmingCharacters(in: .whitespacesAndNewlines)
            skills = trimmed.isEmpty ? [] : [ClientSkill(name: trimmed, hourlyRate: legacyHourlyRate)]
        } else {
            skills = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(age, forKey: .age)
        try container.encode(mobile, forKey: .mobile)
        try container.encode(email, forKey: .email)
        try container.encode(skills, forKey: .skills)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(photoData, forKey: .photoData)
    }
}

@Observable
final class ClientStore {
    var clients: [ClientRegistration] = []

    private let storageURL: URL

    init() {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        let directory = baseDirectory.appendingPathComponent("ClientRegistrationApp", isDirectory: true)
        storageURL = directory.appendingPathComponent("clients.json")

        loadClients()
    }

    func add(_ client: ClientRegistration) {
        clients.insert(client, at: 0)
        saveClients()
    }

    func update(_ client: ClientRegistration) {
        guard let index = clients.firstIndex(where: { $0.id == client.id }) else {
            return
        }
        clients[index] = client
        saveClients()
    }

    func delete(at offsets: IndexSet, from filteredClients: [ClientRegistration]) {
        let idsToDelete = offsets.map { filteredClients[$0].id }
        clients.removeAll { idsToDelete.contains($0.id) }
        saveClients()
    }

    func client(withID id: UUID) -> ClientRegistration? {
        clients.first { $0.id == id }
    }

    private func loadClients() {
        do {
            let data = try Data(contentsOf: storageURL)
            clients = try JSONDecoder().decode([ClientRegistration].self, from: data)
        } catch CocoaError.fileReadNoSuchFile {
            clients = []
        } catch {
            clients = []
            NSLog("Failed to load clients: \(error.localizedDescription)")
        }
    }

    private func saveClients() {
        do {
            let directory = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(clients)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            NSLog("Failed to save clients: \(error.localizedDescription)")
        }
    }
}
