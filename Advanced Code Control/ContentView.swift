import SwiftUI

struct ContentView: View {
    @StateObject private var store = ItemStore()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                scannerSection
                headerSection
                listSection
            }
            .navigationTitle("Barcode Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: HistoryView(store: store)) {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New session") {
                        store.startNewSession()
                    }
                    .disabled(store.scanned.isEmpty)
                }
            }
            .onAppear { store.isScanning = true }
            .onDisappear { store.isScanning = false }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Camera box
    private var scannerSection: some View {
        ZStack(alignment: .bottom) {
            ScannerView { code in
                store.handleScan(code)
            }

            if let message = store.message {
                Text(message)
                    .font(.subheadline.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.bottom, 10)
                    .transition(.opacity)
            }
        }
        .frame(height: 230)
        .cornerRadius(14)
        .padding(.horizontal)
        .padding(.top, 8)
        .animation(.easeInOut, value: store.message)
    }
    // MARK: Header with session date and count
       private var headerSection: some View {
           HStack {
               VStack(alignment: .leading, spacing: 2) {
                   Text("Current session")
                       .font(.headline)
                   if let start = store.sessions.first?.startedAt {
                       Text("Started " + start.formatted(date: .abbreviated, time: .shortened))
                           .font(.caption)
                           .foregroundColor(.secondary)
                   }
               }
               Spacer()
               Text("\(store.scanned.count)")
                   .font(.headline)
                   .padding(.horizontal, 10)
                   .padding(.vertical, 2)
                   .background(Color.accentColor.opacity(0.15))
                   .cornerRadius(10)
           }
           .padding(.horizontal)
           .padding(.vertical, 10)
       }

       // MARK: List
       private var listSection: some View {
           Group {
               if store.scanned.isEmpty {
                   VStack(spacing: 8) {
                       Spacer()
                       Image(systemName: "barcode.viewfinder")
                           .font(.system(size: 44))
                           .foregroundColor(.secondary)
                       Text("Nothing scanned yet")
                           .font(.headline)
                       Text("Point the camera at an item barcode")
                           .font(.subheadline)
                           .foregroundColor(.secondary)
                       Spacer()
                   }
                   .frame(maxWidth: .infinity)
               } else {
                   List {
                       ForEach(store.scanned) { item in
                           HStack(spacing: 12) {
                               Image(item.photo)
                                   .resizable()
                                   .scaledToFill()
                                   .frame(width: 56, height: 56)
                                   .clipped()
                                   .cornerRadius(8)

                               VStack(alignment: .leading, spacing: 4) {
                                   Text(item.name)
                                       .font(.headline)
                                   Text(item.barcode)
                                       .font(.caption)
                                       .foregroundColor(.secondary)
                               }

                               Spacer()

                               Button {
                                   withAnimation {
                                       store.remove(item)
                                   }
                               } label: {
                                   Image(systemName: "xmark.circle.fill")
                                       .font(.title2)
                                       .foregroundColor(.secondary)
                               }
                               .buttonStyle(.borderless)
                           }
                           .padding(.vertical, 4)
                       }
                       .onDelete(perform: store.delete)
                   }
                   .listStyle(.plain)
               }
           }
       }
}




#Preview {
    ContentView()
}
