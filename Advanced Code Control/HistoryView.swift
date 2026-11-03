import SwiftUI

// list of all saved sessions
struct HistoryView: View {
    @ObservedObject var store: ItemStore
    @State private var sessionToDelete: Session? = nil

    private var savedSessions: [Session] {
        store.sessions.filter { !$0.entries.isEmpty }
    }

    var body: some View {
        List {
            ForEach(savedSessions) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                        Text("\(session.entries.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        sessionToDelete = session
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .overlay {
            if savedSessions.isEmpty {
                Text("No saved sessions yet")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Saved Sessions")
        .alert("Delete this session?",
               isPresented: Binding(
                   get: { sessionToDelete != nil },
                   set: { if !$0 { sessionToDelete = nil } }
               )) {
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    store.deleteSession(session)
                }
                sessionToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                sessionToDelete = nil
            }
        } message: {
            Text("This cannot be undone.")
        }
    }
}

// items inside one saved session
struct SessionDetailView: View {
    let session: Session

    var body: some View {
        List(session.entries) { entry in
            HStack(spacing: 12) {
                ItemImage(photo: entry.photo, photoFile: entry.photoFile)
                    .frame(width: 56, height: 56)
                    .clipped()
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.name)
                        .font(.headline)
                    Text(entry.barcode)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
        .navigationTitle(session.startedAt.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
    }
}
