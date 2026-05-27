import SwiftData
import SwiftUI
import UIKit

struct PropertyCard: View {
    let property: RentalProperty
    var openIssues: Int = 0
    var todaysChecks: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(property.name.isEmpty ? "Unnamed property" : property.name)
                        .font(.headline)
                    Text(property.address.isEmpty ? property.propertyType : property.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "house.and.flag.fill")
                    .foregroundStyle(Color.stayTeal)
                    .font(.title3)
            }

            HStack(spacing: 10) {
                Label("\(property.bedrooms) bed", systemImage: "bed.double")
                Label("\(property.bathrooms) bath", systemImage: "shower")
                if !property.assignedCleaner.isEmpty {
                    Label(property.assignedCleaner, systemImage: "person.crop.circle")
                        .lineLimit(1)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                SmallMetric(title: "Today", value: "\(todaysChecks)")
                SmallMetric(title: "Open issues", value: "\(openIssues)")
                Spacer()
                GuestReadyPill(text: openIssues == 0 ? "Monitor" : "Review", status: openIssues == 0 ? .ready : .needsReview)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct TurnoverCheckCard: View {
    let check: TurnoverCheck
    let propertyName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(propertyName)
                        .font(.headline)
                    Text(check.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                GuestReadyPill(text: check.guestReadyStatus, status: GuestReadyStatus(rawValue: check.guestReadyStatus) ?? .needsReview)
            }

            HStack(spacing: 14) {
                Label(check.cleanerName.isEmpty ? "Cleaner not set" : check.cleanerName, systemImage: "person.text.rectangle")
                Label(check.status, systemImage: "checklist")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ProgressView(value: Double(check.guestReadyScore), total: 100)
                .tint(Color.stayTeal)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct ChecklistRow: View {
    @Bindable var item: TurnoverChecklistItem
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                    Toggle("Cleaned", isOn: $item.cleaned)
                    Toggle("Restocked", isOn: $item.restocked)
                    Toggle("Photo proof", isOn: $item.photoProofAdded)
                    Toggle("Issue found", isOn: $item.issueFound)
                    Toggle("Guest-ready", isOn: $item.guestReady)
                }
                .toggleStyle(.switch)
                .font(.subheadline)

                TextField("Notes", text: $item.notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)

                if item.photoRequired {
                    Label("Photo proof recommended", systemImage: "camera.fill")
                        .font(.caption)
                        .foregroundStyle(Color.stayTeal)
                }
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 12) {
                Button {
                    item.completed.toggle()
                    if item.completed {
                        item.cleaned = true
                    }
                } label: {
                    Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.completed ? Color.stayTeal : Color.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.completed ? "Mark incomplete" : "Mark complete")

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                    Text(item.section)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(item.issueFound ? Color.stayAmber : Color.secondary.opacity(0.16), lineWidth: 1)
        )
    }
}

struct RoomPhotoCard: View {
    let photo: RoomPhoto

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                if let data = photo.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle().fill(Color.staySoftTeal)
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(Color.stayTeal)
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(photo.room)
                        .font(.headline)
                    Text(photo.beforeAfterType)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if photo.flagIssue {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.stayAmber)
                }
            }

            if !photo.caption.isEmpty {
                Text(photo.caption)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct StayIssueCard: View {
    let issue: StayIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(issue.title.isEmpty ? "Untitled issue" : issue.title)
                        .font(.headline)
                    Text("\(issue.room) - \(issue.category)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                SeverityBadge(severity: issue.severity)
            }

            if !issue.issueDescription.isEmpty {
                Text(issue.issueDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !issue.suggestedAction.isEmpty {
                Label(issue.suggestedAction, systemImage: "wand.and.stars")
                    .font(.caption)
                    .foregroundStyle(Color.stayTeal)
            }

            HStack {
                Label(issue.status, systemImage: "circle.dashed")
                if !issue.assignedAction.isEmpty {
                    Label(issue.assignedAction, systemImage: "person.crop.circle.badge.checkmark")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct InventoryItemCard: View {
    @Bindable var item: InventoryItem
    var onReminder: (() -> Void)?

    private var isLow: Bool {
        item.currentQuantity < item.minimumQuantity || item.needsRestock
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                    Text(item.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                GuestReadyPill(text: isLow ? "Restock" : "OK", status: isLow ? .needsReview : .ready)
            }

            Stepper(value: $item.currentQuantity, in: 0...999) {
                Text("Current: \(item.currentQuantity)")
            }
            Stepper(value: $item.minimumQuantity, in: 0...999) {
                Text("Minimum: \(item.minimumQuantity)")
            }

            Toggle("Needs restock", isOn: $item.needsRestock)

            if isLow, let onReminder {
                Button {
                    onReminder()
                } label: {
                    Label("Schedule reminder", systemImage: "bell.badge")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isLow ? Color.stayAmber : Color.secondary.opacity(0.16), lineWidth: 1)
        )
    }
}

struct GuestReadyScoreView: View {
    let assessment: GuestReadyAssessment

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: CGFloat(assessment.score) / 100)
                        .stroke(statusColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(assessment.score)")
                        .font(.title.bold())
                }
                .frame(width: 86, height: 86)

                VStack(alignment: .leading, spacing: 7) {
                    GuestReadyPill(text: assessment.status.rawValue, status: assessment.status)
                    Text(assessment.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if assessment.blockers.isNotEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(assessment.blockers, id: \.self) { blocker in
                        Label(blocker, systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch assessment.status {
        case .ready:
            return .stayTeal
        case .needsReview:
            return .stayAmber
        case .notReady:
            return .stayRed
        }
    }
}

struct SeverityBadge: View {
    let severity: String

    var body: some View {
        Text(severity)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .foregroundStyle(.white)
            .background(color, in: Capsule())
    }

    private var color: Color {
        switch IssueSeverity(rawValue: severity) ?? .low {
        case .low:
            return .stayTeal
        case .medium:
            return .stayAmber
        case .high:
            return .orange
        case .urgent:
            return .stayRed
        }
    }
}

struct ReportPreviewView: View {
    let report: TurnoverReport

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "doc.richtext")
                    .foregroundStyle(Color.stayTeal)
                VStack(alignment: .leading, spacing: 3) {
                    Text(report.title)
                        .font(.headline)
                    Text(report.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if report.pdfURL != nil {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                }
            }

            if !report.summary.isEmpty {
                Text(report.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 42))
                .foregroundStyle(Color.stayTeal)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}

private struct SmallMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct GuestReadyPill: View {
    let text: String
    let status: GuestReadyStatus

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .foregroundStyle(foreground)
            .background(background, in: Capsule())
    }

    private var foreground: Color {
        switch status {
        case .ready:
            return .stayTeal
        case .needsReview:
            return .orange
        case .notReady:
            return .stayRed
        }
    }

    private var background: Color {
        foreground.opacity(0.14)
    }
}
