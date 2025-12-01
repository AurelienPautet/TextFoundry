import SwiftUI
import Charts

struct RequestData: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

struct StatsView: View {
    @EnvironmentObject var historyStore: HistoryStore
    @State private var timeRange: TimeRange = .all

    private struct ComputedStats {
        var totalCorrections: Int = 0
        var avgResponseTime: Double = 0
        var avgTokensPerSecond: Double = 0
        var totalOutputTokens: Int = 0
        var providerUsage: [(String, Int)] = []
        var modelUsage: [(String, Int)] = []
        var requestsOverTime: [RequestData] = []
    }

    @State private var computedStats = ComputedStats()

    enum TimeRange: String, CaseIterable, Identifiable {
        case hour = "Last Hour"
        case day = "Last 24h"
        case week = "Last 7 Days"
        case month = "Last 30 Days"
        case all = "All Time"
        var id: String { self.rawValue }
    }

    var body: some View {
                    ScrollView {

        VStack(spacing: 4) {
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
                .frame(width: 400)
                .padding(.trailing, 16)
            }
            .padding(.bottom, 0)

                VStack(spacing: 16) {
                    // Key Metrics Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "Total Corrections", value: "\(computedStats.totalCorrections)", icon: "number.circle.fill", color: .blue)
                        StatCard(title: "Avg Response Time", value: String(format: "%.2fs", computedStats.avgResponseTime), icon: "stopwatch.fill", color: .orange)
                        StatCard(title: "Avg Speed", value: String(format: "%.1f t/s", computedStats.avgTokensPerSecond), icon: "bolt.fill", color: .green)
                        StatCard(title: "Total Output Tokens", value: "\(computedStats.totalOutputTokens)", icon: "list.number", color: .purple)
                    }

                    // Charts Section
                    HStack(alignment: .top, spacing: 20) {
                        // Provider Usage
                        VStack(alignment: .leading) {
                            Text("Provider Usage")
                                .font(.headline)

                            if computedStats.providerUsage.isEmpty {
                                Text("No data available")
                                    .foregroundColor(.secondary)
                                    .frame(height: 200, alignment: .center)
                                    .frame(maxWidth: .infinity)

                            } else {
                                Chart(computedStats.providerUsage, id: \.0) { item in
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

                            if computedStats.modelUsage.isEmpty {
                                Text("No data available")
                                    .foregroundColor(.secondary)
                                    .frame(height: 200, alignment: .center)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Chart(computedStats.modelUsage, id: \.0) { item in
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

                    // Requests Over Time
                    VStack(alignment: .leading) {
                        Text("Requests Over Time")
                            .font(.headline)

                        if computedStats.requestsOverTime.isEmpty {
                            Text("No data available")
                                .foregroundColor(.secondary)
                                .frame(height: 250, alignment: .center)
                                .frame(maxWidth: .infinity)
                        } else {
                            Chart(computedStats.requestsOverTime) { item in
                                BarMark(
                                    x: .value("Date", item.date, unit: timeRange == .hour ? .hour : .day),
                                    y: .value("Count", item.count)
                                )
                                .foregroundStyle(Color.accentColor.gradient)
                            }
                            .frame(height: 250)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                }
                .padding()
            
        }
        .padding()
        .navigationTitle("Stats")
        .onAppear { updateStats(for: timeRange) }
        .onChange(of: timeRange) {
            updateStats(for: $0)
        }
        .onChange(of: historyStore.history) {
             updateStats(for: timeRange)
        }
        }
    }

    private func updateStats(for timeRange: TimeRange) {
        let now = Date()
        let filtered: [CorrectionHistoryItem]

        switch timeRange {
        case .hour:
            filtered = historyStore.history.filter { $0.date >= Calendar.current.date(byAdding: .hour, value: -1, to: now)! }
        case .day:
            filtered = historyStore.history.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -1, to: now)! }
        case .week:
            filtered = historyStore.history.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -7, to: now)! }
        case .month:
            filtered = historyStore.history.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -30, to: now)! }
        case .all:
            filtered = historyStore.history
        }

        var newStats = ComputedStats()
        newStats.totalCorrections = filtered.count

        if !filtered.isEmpty {
            newStats.avgResponseTime = filtered.reduce(0) { $0 + $1.duration } / Double(filtered.count)

            let itemsWithTPS = filtered.compactMap { $0.tokensPerSecond }
            if !itemsWithTPS.isEmpty {
                newStats.avgTokensPerSecond = itemsWithTPS.reduce(0, +) / Double(itemsWithTPS.count)
            }

            let itemsWithTokens = filtered.compactMap { $0.tokenCount }
            newStats.totalOutputTokens = itemsWithTokens.reduce(0, +)
        }

        let groupedProvider = Dictionary(grouping: filtered, by: { $0.provider })
        newStats.providerUsage = groupedProvider.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }

        let groupedModel = Dictionary(grouping: filtered, by: { $0.model })
        newStats.modelUsage = groupedModel.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }

        let calendar = Calendar.current
        let componentsToExtract: Set<Calendar.Component> = timeRange == .hour ? [.year, .month, .day, .hour] : [.year, .month, .day]
        let groupedByDate = Dictionary(grouping: filtered) { item in
            let components = calendar.dateComponents(componentsToExtract, from: item.date)
            return calendar.date(from: components)!
        }

        newStats.requestsOverTime = groupedByDate.map { (date, items) in
            RequestData(date: date, count: items.count)
        }.sorted { $0.date < $1.date }

        self.computedStats = newStats
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
