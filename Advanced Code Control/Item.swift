import Foundation

struct Item: Identifiable, Codable {
    let id = UUID()
    let barcode: String
    let name: String
    let photo: String              // image name in Assets ("" for items added in the app)
    var photoFile: String? = nil   // photo file saved by the app (nil for items.json items)

    enum CodingKeys: String, CodingKey {
        case barcode, name, photo, photoFile
    }
}
