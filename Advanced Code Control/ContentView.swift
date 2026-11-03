import SwiftUI

struct ContentView: View {
    @StateObject private var store = ItemStore()
    @State private var cameraOn = true
    @State private var screenVisible = true
    @State private var showAddItem = false

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
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    Button("New session") {
                        store.startNewSession()
                    }
                    .disabled(store.scanned.isEmpty)
                }
            }
            .onAppear {
                screenVisible = true
                store.isScanning = true
            }
            .onDisappear {
                screenVisible = false
                store.isScanning = false
            }
            .sheet(isPresented: $showAddItem) {
                AddItemView(store: store)
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Camera box
    private var scannerSection: some View {
        ZStack {
            // the camera is switched off while the Add item screen is open
            if cameraOn && screenVisible && !showAddItem {
                ScannerView { code in
                    store.handleScan(code)
                }
            } else {
                Color.black
                VStack(spacing: 6) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 30))
                    Text("Camera is off")
                        .font(.subheadline)
                }
                .foregroundColor(.white.opacity(0.8))
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        cameraOn.toggle()
                    } label: {
                        Label(cameraOn ? "Stop camera" : "Start camera",
                              systemImage: cameraOn ? "video.slash.fill" : "video.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
                if let message = store.message {
                    Text(message)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .transition(.opacity)
                }
            }
            .padding(10)
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
                            ItemImage(photo: item.photo, photoFile: item.photoFile)
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


// Version 1.0.2 Working Perfectly

#Preview {
    ContentView()
}
