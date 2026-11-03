import SwiftUI
import Combine

final class ItemStore: ObservableObject {
    private var database: [String: Item] = [:]

    // newest first. sessions[0] is the current session
    @Published var sessions: [Session] = []
    @Published var message: String? = nil

    // the scanner is paused while another screen (History) is open
    var isScanning = true

    private var lastScannedCode = ""
    private var lastScannedTime = Date.distantPast

    // items of the current session, shown on the home screen
    var scanned: [ScannedEntry] {
        sessions.first?.entries ?? []
    }

    init() {
        loadDatabase()
        createFolderIfNeeded()
        loadSessions()
    }

    // MARK: Item database (items.json)

    private func loadDatabase() {
        guard let url = Bundle.main.url(forResource: "items", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([Item].self, from: data) else {
            print("Could not load items.json")
            return
        }
        for item in items {
            database[item.barcode] = item
        }
    }

    // MARK: Scanning

    func handleScan(_ code: String) {
        guard isScanning else { return }

        // ignore the same barcode arriving again within 1 second
        if code == lastScannedCode && Date().timeIntervalSince(lastScannedTime) < 1 {
            return
        }
        lastScannedCode = code
        lastScannedTime = Date()

        guard let found = database[code] else {
            showMessage("Not found: \(code)")
            return
        }

        let entry = ScannedEntry(barcode: found.barcode, name: found.name, photo: found.photo)
        sessions[0].entries.insert(entry, at: 0)
        save(sessions[0])
        showMessage("Added: \(found.name)")
    }

    private func showMessage(_ text: String) {
        message = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.message == text { self.message = nil }
        }
    }

    // MARK: Changing the current session

    func remove(_ entry: ScannedEntry) {
        sessions[0].entries.removeAll { $0.id == entry.id }
        save(sessions[0])
    }

    func delete(at offsets: IndexSet) {
        sessions[0].entries.remove(atOffsets: offsets)
        save(sessions[0])
    }

    // keeps the old session on disk and starts an empty one
    func startNewSession() {
        if sessions[0].entries.isEmpty {
            showMessage("Current session is already empty")
            return
        }
        sessions.insert(Session(startedAt: Date()), at: 0)
        showMessage("New session started")
    }

    // MARK: Deleting a saved session (only from History)

    func deleteSession(_ session: Session) {
        try? FileManager.default.removeItem(at: fileURL(for: session))
        let wasCurrent = sessions.first?.id == session.id
        sessions.removeAll { $0.id == session.id }
        if wasCurrent || sessions.isEmpty {
            sessions.insert(Session(startedAt: Date()), at: 0)
        }
    }

    // MARK: Files on disk

    private var folderURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("Sessions", isDirectory: true)
    }

    private func createFolderIfNeeded() {
        try? FileManager.default.createDirectory(at: folderURL,
                                                 withIntermediateDirectories: true)
    }

    // file name = date and time the session started
    private func fileURL(for session: Session) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let name = "session_\(formatter.string(from: session.startedAt)).json"
        return folderURL.appendingPathComponent(name)
    }

    private func save(_ session: Session) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        do {
            let data = try encoder.encode(session)
            try data.write(to: fileURL(for: session), options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }

    private func loadSessions() {
        let files = (try? FileManager.default.contentsOfDirectory(at: folderURL,
                                                                  includingPropertiesForKeys: nil)) ?? []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var loaded: [Session] = []
        for url in files where url.pathExtension == "json" {
            if let data = try? Data(contentsOf: url),
               let session = try? decoder.decode(Session.self, from: data) {
                loaded.append(session)
            }
        }
        loaded.sort { $0.startedAt > $1.startedAt }
        sessions = loaded

        if sessions.isEmpty {
            sessions = [Session(startedAt: Date())]
        }
    }
}
