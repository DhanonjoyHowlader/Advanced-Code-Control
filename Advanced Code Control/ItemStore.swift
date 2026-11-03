import SwiftUI
import Combine
import UIKit

final class ItemStore: ObservableObject {
    // all known items by barcode: items.json + items added in the app
    private var database: [String: Item] = [:]
    // only the items added in the app (saved in Documents/Database/user_items.json)
    private var userItems: [Item] = []

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
        createFoldersIfNeeded()
        loadDatabase()
        loadSessions()
    }

    // MARK: Item database

    private func loadDatabase() {
        // 1. items.json inside the app
        if let url = Bundle.main.url(forResource: "items", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let items = try? JSONDecoder().decode([Item].self, from: data) {
            for item in items {
                database[item.barcode] = item
            }
        } else {
            print("Could not load items.json")
        }

        // 2. items added with the app
        if let data = try? Data(contentsOf: userItemsURL),
           let items = try? JSONDecoder().decode([Item].self, from: data) {
            userItems = items
            for item in items {
                database[item.barcode] = item
            }
        }
    }

    func existingItem(for barcode: String) -> Item? {
        database[barcode]
    }

    // returns an error text, or nil when the item was saved
    func addItem(barcode: String, name: String, image: UIImage?) -> String? {
        if let existing = database[barcode] {
            return "This barcode already exists: \(existing.name)"
        }

        // save the photo (if there is one)
        var photoFile: String? = nil
        if let image = image {
            let file = "\(UUID().uuidString).jpg"
            guard let data = resized(image).jpegData(compressionQuality: 0.8) else {
                return "Could not process the photo."
            }
            do {
                try data.write(to: ItemPhotoStorage.folderURL.appendingPathComponent(file),
                               options: .atomic)
            } catch {
                return "Could not save the photo."
            }
            photoFile = file
        }

        // save the item
        let item = Item(barcode: barcode, name: name, photo: "", photoFile: photoFile)
        userItems.append(item)
        if !saveUserItems() {
            userItems.removeLast()
            return "Could not save the item."
        }
        database[barcode] = item
        showMessage("Item added: \(name)")
        return nil
    }

    private func saveUserItems() -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        do {
            let data = try encoder.encode(userItems)
            try data.write(to: userItemsURL, options: .atomic)
            return true
        } catch {
            print("Save items failed: \(error)")
            return false
        }
    }

    // makes the photo smaller (max 800 pixels) so files stay small
    private func resized(_ image: UIImage, maxSide: CGFloat = 800) -> UIImage {
        let size = image.size
        let scale = min(1, maxSide / max(size.width, size.height))
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
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

        let entry = ScannedEntry(barcode: found.barcode,
                                 name: found.name,
                                 photo: found.photo,
                                 photoFile: found.photoFile)
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

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var sessionsFolderURL: URL {
        documentsURL.appendingPathComponent("Sessions", isDirectory: true)
    }

    private var databaseFolderURL: URL {
        documentsURL.appendingPathComponent("Database", isDirectory: true)
    }

    private var userItemsURL: URL {
        databaseFolderURL.appendingPathComponent("user_items.json")
    }

    private func createFoldersIfNeeded() {
        let folders = [sessionsFolderURL, databaseFolderURL, ItemPhotoStorage.folderURL]
        for folder in folders {
            try? FileManager.default.createDirectory(at: folder,
                                                     withIntermediateDirectories: true)
        }
    }

    // file name = date and time the session started
    private func fileURL(for session: Session) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let name = "session_\(formatter.string(from: session.startedAt)).json"
        return sessionsFolderURL.appendingPathComponent(name)
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
        let files = (try? FileManager.default.contentsOfDirectory(at: sessionsFolderURL,
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
