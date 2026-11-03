import Foundation

struct ScannedEntry: Identifiable, Codable {
    var id = UUID()
    let barcode: String
    let name: String
    let photo: String
    var photoFile: String? = nil
}

struct Session: Identifiable, Codable {
    var id = UUID()
    let startedAt: Date
    var entries: [ScannedEntry] = []
}
