import Foundation

struct Item: Identifiable, Codable {
    let id = UUID()          // unique per row, so the same item can be listed twice
    let barcode: String
    let name: String
    let photo: String        // name of the image in Assets

    enum CodingKeys: String, CodingKey {
        case barcode, name, photo
    }
}
