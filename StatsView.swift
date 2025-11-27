import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @State private var timeRange: TimeRange = .all
    
    // Computed state to avoid re-calculating in body and causing update loops
    @State private var filteredHistory: [CorrectionHistoryItem] = []
    @State private var totalCorrections: Int = 0
    @State private var avgResponseTime: Double = 0
    @State private var avgTokensPerSecond: Double = 0
    @State private var totalOutputTokens: Int = 0
    @State private var providerUsage: [(String, Int)] = []
    @State private var modelUsage: [(String, Int)] = []
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case day = "Last 24h"
        case week = "Last 7 Days"
        case month = "Last 30 Days"
        case all = "All Time"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header & Filter
            HStack {
                Text("Statistics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
            .padding(.bottom, 8)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Key Metrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Total Corrections", value: "\(totalCorrections)", icon: "number.circle.fill", color: .blue)
                        StatCard(title: "Avg Response Time", value: String(format: "%.2fs", avgResponseTime), icon: "stopwatch.fill", color: .orange)
                        StatCard(title: "Avg Speed", value: String(format: "%.1f t/s", avgTokensPerSecond), icon: "bolt.fill", color: .green)
                        StatCard(title: "Total Output Tokens", value: "\(totalOutputTokens)", icon: "list.number", color: .purple)
                        }
                    
                    // Charts Section
                    HStack(alignment: .top, spacing: 20) {
                        // Provider Usage
                        VStack(alignment: .leading) {
                            Text("Provider Usage")
                                .font(.headline)
                            
                            if providerUsage.isEmpty {
                                Text("No data available")
                                    .foregroundColor(.secondary)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Chart(providerUsage, id: \.0) { item in
                                    SectorMark(
                                        angle: .value("Count", item.1),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(by: .value("Provider", item.0))
                                    .annotation(position: .overlay) {
                                        Text("\(item.1)")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(height: 200)
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)
                        
                        // Model Usage
                        VStack(alignment: .leading) {
                            Text("Model Usage")
                                .font(.headline)
                            
                            if modelUsage.isEmpty {
                                Text("No data available")
                                    .foregroundColor(.secondary)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Chart(modelUsage, id: \.0) { item in
                                    BarMark(
                                        x: .value("Count", item.1),
                                        y: .value("Model", item.0)
                                    )
                                    .foregroundStyle(Color.accentColor.gradient)
                                }
                                .frame(height: 200)
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .padding(.horizontal)
        .navigationTitle("Stats")
        .onAppear { updateStats() }
        .onChange(of: timeRange) { updateStats() }
        .onChange(of: historyStore.history) { updateStats() }
    }
    
    private func updateStats() {
        let now = Date()
        let filtered: [CorrectionHistoryItem]
        
        switch timeRange {
        case .day:
            filtered = historyStore.history.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -1, to: now)! }
        case .week:
            filtered = historyStore.history.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -7, to: now)! }
        case .month:
            filtered = historyStore.history.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -30, to: now)! }
        case .all:
            filtered = historyStore.history
        }
        
        self.filteredHistory = filtered
        self.totalCorrections = filtered.count
        
        if filtered.count > 0 {
            self.avgResponseTime = filtered.reduce(0) { $0 + $1.duration } / Double(filtered.count)
            
            let itemsWithTPS = filtered.compactMap { $0.tokensPerSecond }
            if !itemsWithTPS.isEmpty {
                self.avgTokensPerSecond = itemsWithTPS.reduce(0, +) / Double(itemsWithTPS.count)
            } else {
                self.avgTokensPerSecond = 0
            }
            
            let itemsWithTokens = filtered.compactMap { $0.tokenCount }
            self.totalOutputTokens = itemsWithTokens.reduce(0, +)
        } else {
            self.avgResponseTime = 0
            self.avgTokensPerSecond = 0
            self.totalOutputTokens = 0
        }
        
        let groupedProvider = Dictionary(grouping: filtered, by: { $0.provider })
        self.providerUsage = groupedProvider.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
        
        let groupedModel = Dictionary(grouping: filtered, by: { $0.model })
        self.modelUsage = groupedModel.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}
