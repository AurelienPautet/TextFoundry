import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyStore: HistoryStore
    
    var body: some View {
        VStack {
            if historyStore.history.isEmpty {
                ContentUnavailableView("No History", systemImage: "clock", description: Text("Your correction history will appear here."))
            } else {
                List {
                    ForEach(historyStore.history) { item in
                        HistoryItemRow(item: item)
                            .padding(.vertical, 4)
                    }
                    .onDelete(perform: historyStore.deleteItem)
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            if !historyStore.history.isEmpty {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Clear All", role: .destructive) {
                        historyStore.clearHistory()
                    }
                }
            }
        }
    }
}

struct HistoryItemRow: View {
    let item: CorrectionHistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.provider)
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Text(item.model)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(item.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(item.date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("Original")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(item.originalText)
                        .lineLimit(3)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Corrected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(item.correctedText)
                        .lineLimit(3)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack {
                // Metrics
                HStack(spacing: 12) {
                    Label(String(format: "%.2fs", item.duration), systemImage: "stopwatch")
                    
                    if let ttft = item.timeToFirstToken {
                        Label(String(format: "TTFT: %.2fs", ttft), systemImage: "bolt")
                    }
                    
                    if let tokens = item.tokenCount {
                        Label("\(tokens) toks", systemImage: "text.quote")
                    }
                    
                    if let tps = item.tokensPerSecond {
                        Label(String(format: "%.1f t/s", tps), systemImage: "speedometer")
                    }
                    
                    if let retries = item.retryCount, retries > 0 {
                        Label("\(retries) retry", systemImage: "arrow.clockwise")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    ClipboardManager.write(item.correctedText)
                }) {
                    Label("Copy Result", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    HistoryView()
        .environmentObject(HistoryStore())
}
