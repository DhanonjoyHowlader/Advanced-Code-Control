import SwiftUI
import UIKit

struct AddItemView: View {
    @ObservedObject var store: ItemStore
    @Environment(\.dismiss) private var dismiss

    @State private var barcode = ""
    @State private var name = ""
    @State private var photo: UIImage? = nil

    @State private var scanningBarcode = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var errorText: String? = nil

    private var trimmedBarcode: String {
        barcode.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var existing: Item? {
        store.existingItem(for: trimmedBarcode)
    }
    private var canSave: Bool {
        !trimmedBarcode.isEmpty && !trimmedName.isEmpty && existing == nil
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: Barcode
                Section(header: Text("Barcode")) {
                    TextField("Barcode number", text: $barcode)
                        .keyboardType(.numbersAndPunctuation)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)

                    Button {
                        scanningBarcode.toggle()
                    } label: {
                        Label(scanningBarcode ? "Stop scanning" : "Scan barcode with camera",
                              systemImage: "barcode.viewfinder")
                    }

                    if scanningBarcode {
                        ScannerView { code in
                            barcode = code
                            scanningBarcode = false
                        }
                        .frame(height: 200)
                        .cornerRadius(10)
                    }

                    if let existing = existing {
                        Text("This barcode already exists: \(existing.name)")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                }

                // MARK: Name
                Section(header: Text("Item name")) {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                // MARK: Photo
                Section(header: Text("Photo")) {
                    if let photo = photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .cornerRadius(10)
                    }

                    Button {
                        scanningBarcode = false
                        showCamera = true
                    } label: {
                        Label(photo == nil ? "Take photo" : "Retake photo",
                              systemImage: "camera")
                    }

                    Button {
                        scanningBarcode = false
                        showLibrary = true
                    } label: {
                        Label("Choose from library", systemImage: "photo.on.rectangle")
                    }
                }
            }
            .navigationTitle("Add item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                ImagePicker(source: .camera, isPresented: $showCamera) { image in
                    photo = image
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showLibrary) {
                ImagePicker(source: .library, isPresented: $showLibrary) { image in
                    photo = image
                }
            }
            .alert("Could not save",
                   isPresented: Binding(
                       get: { errorText != nil },
                       set: { if !$0 { errorText = nil } }
                   )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorText ?? "")
            }
        }
    }

    private func save() {
        if let error = store.addItem(barcode: trimmedBarcode,
                                     name: trimmedName,
                                     image: photo) {
            errorText = error
        } else {
            dismiss()
        }
    }
}
