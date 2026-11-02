import Foundation

final class ItemStore: ObservableObject {
    // all items from your database, searched by barcode
    private var database: [String: Item] = [:]

    // the temporary list shown on screen
    @Published var scanned: [Item] = []

    init() {
        loadDatabase()
    }

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

    func handleScan(_ code: String) {
        guard let found = database[code] else {
            print("Barcode not in database: \(code)")
            return
        }
        // make a fresh copy so each scan gets its own row
        let entry = Item(barcode: found.barcode, name: found.name, photo: found.photo)
        scanned.insert(entry, at: 0)   // newest on top
    }

    func delete(at offsets: IndexSet) {
        scanned.remove(atOffsets: offsets)
    }

    func clearAll() {
        scanned.removeAll()
    }
}
