import Charts
import SwiftUI

private struct HiringTrend: Identifiable {
    let id = UUID()
    let month: String
    let posted: Int
}

private struct RevenueTrend: Identifiable {
    let id = UUID()
    let week: String
    let value: Double
}

private struct JobOpportunity: Identifiable {
    let id = UUID()
    let title: String
    let company: String
    let location: String
    let rate: String
}

struct HomeDashboardView: View {
    @Bindable var sessionStore: AppSessionStore

    private let hiringTrends = [
        HiringTrend(month: "Jan", posted: 8),
        HiringTrend(month: "Feb", posted: 11),
        HiringTrend(month: "Mar", posted: 14),
        HiringTrend(month: "Apr", posted: 10),
        HiringTrend(month: "May", posted: 17)
    ]

    private let revenueTrend = [
        RevenueTrend(week: "W1", value: 18),
        RevenueTrend(week: "W2", value: 24),
        RevenueTrend(week: "W3", value: 21),
        RevenueTrend(week: "W4", value: 29),
        RevenueTrend(week: "W5", value: 33)
    ]

    private let jobs = [
        JobOpportunity(title: "iOS Contractor", company: "Northstar Labs", location: "Remote", rate: "$85/hr"),
        JobOpportunity(title: "Frontend Consultant", company: "Pine & Co", location: "Austin, TX", rate: "$72/hr"),
        JobOpportunity(title: "Data Visual Analyst", company: "Motive Grid", location: "New York, NY", rate: "$68/hr")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Greeting
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hello\(sessionStore.profile.map { ", \($0.name)" } ?? "") 👋")
                            .font(.title3.weight(.semibold))
                        Text("Here's your activity overview.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Stat pills
                    HStack(spacing: 10) {
                        statPill(value: "4", label: "Jobs", color: .blue)
                        statPill(value: "9", label: "Interviews", color: .orange)
                        statPill(value: "3", label: "Wins", color: .green)
                    }

                    // Hiring chart
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Hiring Activity", systemImage: "chart.bar.fill")
                            .font(.subheadline.weight(.semibold))

                        Chart(hiringTrends) { item in
                            BarMark(
                                x: .value("Month", item.month),
                                y: .value("Jobs", item.posted)
                            )
                            .foregroundStyle(AppTheme.accent.gradient)
                            .cornerRadius(4)
                        }
                        .frame(height: 150)
                        .chartYAxis { AxisMarks(position: .leading) }
                    }
                    .dashboardCard()

                    // Trend chart
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Opportunity Trend", systemImage: "chart.xyaxis.line")
                            .font(.subheadline.weight(.semibold))

                        Chart(revenueTrend) { item in
                            LineMark(
                                x: .value("Week", item.week),
                                y: .value("Value", item.value)
                            )
                            .foregroundStyle(AppTheme.accent)
                            .lineStyle(.init(lineWidth: 2, lineCap: .round))

                            AreaMark(
                                x: .value("Week", item.week),
                                y: .value("Value", item.value)
                            )
                            .foregroundStyle(AppTheme.accent.opacity(0.12))
                        }
                        .frame(height: 130)
                        .chartYAxis { AxisMarks(position: .leading) }
                    }
                    .dashboardCard()

                    // Jobs list
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Available Jobs", systemImage: "briefcase.fill")
                            .font(.subheadline.weight(.semibold))

                        ForEach(jobs) { job in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(job.title)
                                        .font(.subheadline.weight(.medium))
                                    Text("\(job.company) · \(job.location)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(job.rate)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppTheme.accent.opacity(0.1))
                                    .foregroundStyle(AppTheme.accent)
                                    .clipShape(Capsule())
                            }
                            if job.id != jobs.last?.id {
                                Divider()
                            }
                        }
                    }
                    .dashboardCard()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    let session = AppSessionStore()
    session.profile = AppUserProfile(name: "Jordan", email: "jordan@example.com", mobile: "5551234567")
    session.launchStage = .ready
    return HomeDashboardView(sessionStore: session)
}
