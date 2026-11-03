import SwiftUI
import UIKit

enum ItemPhotoStorage {
    static var folderURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ItemPhotos", isDirectory: true)
    }
}

struct ItemImage: View {
    let photo: String
    let photoFile: String?

    var body: some View {
        if let file = photoFile,
           let uiImage = UIImage(contentsOfFile: ItemPhotoStorage.folderURL
                                    .appendingPathComponent(file).path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if !photo.isEmpty {
            Image(photo)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Color.gray.opacity(0.2)
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }
        }
    }
}
