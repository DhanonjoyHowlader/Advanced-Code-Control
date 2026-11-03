import Foundation

// one scanned row, with its own copy of name and photo
// (so old sessions stay readable even if items.json changes later)
struct ScannedEntry: Identifiable, Codable {
    var id = UUID()
    let barcode: String
    let name: String
    let photo: String
}

// one scanning session = one file on disk
struct Session: Identifiable, Codable {
    var id = UUID()
    let startedAt: Date
    var entries: [ScannedEntry] = []
}
