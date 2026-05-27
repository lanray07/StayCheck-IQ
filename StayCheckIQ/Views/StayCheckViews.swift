import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }

            NavigationStack {
                PropertyListView()
            }
            .tabItem { Label("Properties", systemImage: "house") }

            NavigationStack {
                TurnoverListView()
            }
            .tabItem { Label("Checks", systemImage: "checklist") }

            NavigationStack {
                InventoryListView()
            }
            .tabItem { Label("Inventory", systemImage: "shippingbox") }

            NavigationStack {
                ReportsCenterView()
            }
            .tabItem { Label("Reports", systemImage: "doc.text") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("StayCheck IQ")
                            .font(.largeTitle.bold())
                        Text("AI-assisted turnover checks for short-let teams.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your role")
                            .font(.headline)
                        Picker("User type", selection: $viewModel.selectedUserType) {
                            ForEach(UserType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.inline)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Property count")
                            .font(.headline)
                        Stepper("\(viewModel.propertyCount) properties", value: $viewModel.propertyCount, in: 1...500)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI disclaimer")
                            .font(.headline)
                        DisclaimerBullets()
                        Toggle("I understand and will review AI suggestions", isOn: $viewModel.acceptedDisclaimer)
                    }

                    Button {
                        hasCompletedOnboarding = true
                    } label: {
                        Label("Start turnover checks", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!viewModel.canContinue)
                }
                .padding()
            }
            .navigationTitle("Welcome")
        }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var services: AppServices
    @Query(sort: \RentalProperty.createdAt, order: .reverse) private var properties: [RentalProperty]
    @Query(sort: \TurnoverCheck.date, order: .reverse) private var checks: [TurnoverCheck]
    @Query(sort: \StayIssue.createdAt, order: .reverse) private var issues: [StayIssue]
    @Query(sort: \TurnoverReport.createdAt, order: .reverse) private var reports: [TurnoverReport]

    @State private var showingPaywall = false

    private var todaysChecks: [TurnoverCheck] {
        checks.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var openIssues: [StayIssue] {
        issues.filter { $0.status != IssueStatus.resolved.rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Turnover command center")
                            .font(.largeTitle.bold())
                        Text("Move faster from cleaning to guest-ready.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DashboardActionCard(title: "New Turnover Check", value: "\(checks.count)", icon: "plus.circle.fill") {
                        NewTurnoverCheckView()
                    }
                    DashboardActionCard(title: "Today's Cleanings", value: "\(todaysChecks.count)", icon: "calendar") {
                        TurnoverListView(todaysOnly: true)
                    }
                    DashboardActionCard(title: "Open Issues", value: "\(openIssues.count)", icon: "exclamationmark.triangle") {
                        IssueListView()
                    }
                    DashboardActionCard(title: "Recent Reports", value: "\(reports.count)", icon: "doc.richtext") {
                        ReportsCenterView()
                    }
                    DashboardActionCard(title: "Properties", value: "\(properties.count)", icon: "house.and.flag") {
                        PropertyListView()
                    }
                }

                SectionHeader(title: "Properties", actionTitle: properties.isEmpty ? nil : "View all") {
                    PropertyListView()
                }

                if properties.isEmpty {
                    EmptyStateView(title: "No properties yet", message: "Add your first short-let property to start a turnover check.", systemImage: "house.badge.plus")
                } else {
                    ForEach(properties.prefix(3)) { property in
                        NavigationLink {
                            PropertyDetailView(property: property)
                        } label: {
                            PropertyCard(
                                property: property,
                                openIssues: issues.filter { $0.propertyId == property.id && $0.status != IssueStatus.resolved.rawValue }.count,
                                todaysChecks: todaysChecks.filter { $0.propertyId == property.id }.count
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                SectionHeader(title: "Recent reports")
                if reports.isEmpty {
                    EmptyStateView(title: "No reports saved", message: "Generate a PDF report from a turnover check.", systemImage: "doc.badge.plus")
                } else {
                    ForEach(reports.prefix(3)) { report in
                        ReportPreviewView(report: report)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .sheet(isPresented: $showingPaywall) {
            PaywallView(subscriptionService: services.subscriptionService)
        }
    }
}

struct PropertyListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var services: AppServices
    @Query(sort: \RentalProperty.createdAt, order: .reverse) private var properties: [RentalProperty]
    @Query(sort: \TurnoverCheck.date, order: .reverse) private var checks: [TurnoverCheck]
    @Query(sort: \StayIssue.createdAt, order: .reverse) private var issues: [StayIssue]

    @State private var showingEditor = false
    @State private var showingPaywall = false

    private var canAddProperty: Bool {
        PlanPolicy.canAddProperty(currentCount: properties.count, plan: services.subscriptionService.currentPlan)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if properties.isEmpty {
                    EmptyStateView(title: "Add a property", message: "Create a profile with cleaner, check-in, inventory, and report details.", systemImage: "house.badge.plus")
                } else {
                    ForEach(properties) { property in
                        NavigationLink {
                            PropertyDetailView(property: property)
                        } label: {
                            PropertyCard(
                                property: property,
                                openIssues: issues.filter { $0.propertyId == property.id && $0.status != IssueStatus.resolved.rawValue }.count,
                                todaysChecks: checks.filter { $0.propertyId == property.id && Calendar.current.isDateInToday($0.date) }.count
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Properties")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if canAddProperty {
                        showingEditor = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add property")
            }
        }
        .sheet(isPresented: $showingEditor) {
            PropertyEditorView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(subscriptionService: services.subscriptionService)
        }
    }
}

struct PropertyDetailView: View {
    let property: RentalProperty

    @Query private var checks: [TurnoverCheck]
    @Query private var issues: [StayIssue]
    @Query private var inventory: [InventoryItem]

    @State private var showingEditor = false

    init(property: RentalProperty) {
        self.property = property
        let propertyId = property.id
        _checks = Query(filter: #Predicate<TurnoverCheck> { $0.propertyId == propertyId }, sort: \TurnoverCheck.date, order: .reverse)
        _issues = Query(filter: #Predicate<StayIssue> { $0.propertyId == propertyId }, sort: \StayIssue.createdAt, order: .reverse)
        _inventory = Query(filter: #Predicate<InventoryItem> { $0.propertyId == propertyId }, sort: \InventoryItem.name)
    }

    private var openIssues: [StayIssue] {
        issues.filter { $0.status != IssueStatus.resolved.rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PropertyCard(property: property, openIssues: openIssues.count, todaysChecks: checks.filter { Calendar.current.isDateInToday($0.date) }.count)

                VStack(alignment: .leading, spacing: 10) {
                    DetailRow(label: "Type", value: property.propertyType)
                    DetailRow(label: "Bedrooms", value: "\(property.bedrooms)")
                    DetailRow(label: "Bathrooms", value: "\(property.bathrooms)")
                    DetailRow(label: "Cleaner/team", value: property.assignedCleaner.isEmpty ? "Unassigned" : property.assignedCleaner)
                    DetailRow(label: "Check-in", value: property.checkInTime.formatted(date: .omitted, time: .shortened))
                    DetailRow(label: "Check-out", value: property.checkOutTime.formatted(date: .omitted, time: .shortened))
                    if !property.notes.isEmpty {
                        DetailRow(label: "Notes", value: property.notes)
                    }
                }
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    NavigationLink {
                        NewTurnoverCheckView(property: property)
                    } label: {
                        QuickActionLabel(title: "New Check", icon: "plus.circle.fill")
                    }

                    NavigationLink {
                        InventoryListView(property: property)
                    } label: {
                        QuickActionLabel(title: "Inventory", icon: "shippingbox")
                    }

                    NavigationLink {
                        IssueListView(property: property)
                    } label: {
                        QuickActionLabel(title: "Issues", icon: "exclamationmark.triangle")
                    }

                    NavigationLink {
                        ReportsCenterView()
                    } label: {
                        QuickActionLabel(title: "Reports", icon: "doc.text")
                    }
                }
                .buttonStyle(.plain)

                SectionHeader(title: "Recent checks")
                if checks.isEmpty {
                    EmptyStateView(title: "No checks yet", message: "Start a turnover check for this property.", systemImage: "checklist")
                } else {
                    ForEach(checks.prefix(5)) { check in
                        NavigationLink {
                            TurnoverWorkflowView(check: check)
                        } label: {
                            TurnoverCheckCard(check: check, propertyName: property.name)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(property.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            PropertyEditorView(property: property)
        }
    }
}

struct PropertyEditorView: View {
    private let property: RentalProperty?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: PropertyFormViewModel

    init(property: RentalProperty? = nil) {
        self.property = property
        _viewModel = StateObject(wrappedValue: PropertyFormViewModel(property: property))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Property") {
                    TextField("Property name", text: $viewModel.name)
                    TextField("Address", text: $viewModel.address, axis: .vertical)
                    Picker("Property type", selection: $viewModel.propertyType) {
                        ForEach(PropertyType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    Stepper("Bedrooms: \(viewModel.bedrooms)", value: $viewModel.bedrooms, in: 0...30)
                    Stepper("Bathrooms: \(viewModel.bathrooms)", value: $viewModel.bathrooms, in: 0...30)
                }

                Section("Turnover") {
                    TextField("Cleaner/team assigned", text: $viewModel.assignedCleaner)
                    DatePicker("Check-in time", selection: $viewModel.checkInTime, displayedComponents: .hourAndMinute)
                    DatePicker("Check-out time", selection: $viewModel.checkOutTime, displayedComponents: .hourAndMinute)
                }

                Section("Notes") {
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle(property == nil ? "New Property" : "Edit Property")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }

    private func save() {
        if let property {
            viewModel.apply(to: property)
        } else {
            let newProperty = viewModel.makeProperty()
            modelContext.insert(newProperty)
            ChecklistTemplate.starterInventory(for: newProperty.id).forEach(modelContext.insert)
        }

        try? modelContext.save()
        dismiss()
    }
}

struct NewTurnoverCheckView: View {
    private let initialProperty: RentalProperty?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var services: AppServices
    @Query(sort: \RentalProperty.name) private var properties: [RentalProperty]
    @Query(sort: \TurnoverCheck.date, order: .reverse) private var existingChecks: [TurnoverCheck]
    @StateObject private var viewModel = NewTurnoverViewModel()
    @State private var selectedPropertyId: UUID?
    @State private var showingPaywall = false

    init(property: RentalProperty? = nil) {
        self.initialProperty = property
        _selectedPropertyId = State(initialValue: property?.id)
    }

    private var selectedProperty: RentalProperty? {
        if let selectedPropertyId {
            return properties.first { $0.id == selectedPropertyId } ?? initialProperty
        }
        return initialProperty ?? properties.first
    }

    private var monthlyCheckCount: Int {
        existingChecks.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }.count
    }

    private var canCreateCheck: Bool {
        !MonetizationConfig.isStoreKitEnabled || services.subscriptionService.currentPlan != .free || monthlyCheckCount < 5
    }

    var body: some View {
        Form {
            if properties.isEmpty && initialProperty == nil {
                EmptyStateView(title: "No property available", message: "Add a property before creating a turnover check.", systemImage: "house")
            } else {
                Section("Property") {
                    Picker("Property", selection: Binding(
                        get: { selectedProperty?.id },
                        set: { selectedPropertyId = $0 }
                    )) {
                        ForEach(properties) { property in
                            Text(property.name).tag(Optional(property.id))
                        }
                    }
                }

                Section("Check details") {
                    DatePicker("Turnover date", selection: $viewModel.date)
                    TextField("Cleaner name", text: $viewModel.cleanerName)
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                }

                Section {
                    Button {
                        createCheck()
                    } label: {
                        Label("Create checklist", systemImage: "checklist")
                    }
                    .disabled(selectedProperty == nil || !canCreateCheck)
                }
            }
        }
        .navigationTitle("New Turnover")
        .sheet(isPresented: $showingPaywall) {
            PaywallView(subscriptionService: services.subscriptionService)
        }
    }

    private func createCheck() {
        guard let property = selectedProperty else { return }
        let check = viewModel.makeCheck(for: property)
        modelContext.insert(check)
        ChecklistTemplate.makeDefaultItems(for: check.id).forEach(modelContext.insert)
        try? modelContext.save()
        dismiss()
    }
}

struct TurnoverListView: View {
    var todaysOnly = false

    @Query(sort: \TurnoverCheck.date, order: .reverse) private var checks: [TurnoverCheck]
    @Query(sort: \RentalProperty.name) private var properties: [RentalProperty]

    private var filteredChecks: [TurnoverCheck] {
        todaysOnly ? checks.filter { Calendar.current.isDateInToday($0.date) } : checks
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if filteredChecks.isEmpty {
                    EmptyStateView(
                        title: todaysOnly ? "No cleanings today" : "No turnover checks",
                        message: "Create a check to generate a cleaner checklist, photos, score, and PDF report.",
                        systemImage: "checklist"
                    )
                } else {
                    ForEach(filteredChecks) { check in
                        NavigationLink {
                            TurnoverWorkflowView(check: check)
                        } label: {
                            TurnoverCheckCard(check: check, propertyName: propertyName(for: check.propertyId))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(todaysOnly ? "Today's Cleanings" : "Turnover Checks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    NewTurnoverCheckView()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New turnover check")
            }
        }
    }

    private func propertyName(for propertyId: UUID) -> String {
        properties.first { $0.id == propertyId }?.name ?? "Property"
    }
}

struct TurnoverWorkflowView: View {
    let check: TurnoverCheck

    @Query(sort: \RentalProperty.name) private var properties: [RentalProperty]
    @Query private var checklistItems: [TurnoverChecklistItem]
    @Query private var photos: [RoomPhoto]
    @Query private var issues: [StayIssue]
    @Query private var inventory: [InventoryItem]

    @State private var selectedTab: WorkflowTab = .checklist

    init(check: TurnoverCheck) {
        self.check = check
        let checkId = check.id
        let propertyId = check.propertyId
        _checklistItems = Query(filter: #Predicate<TurnoverChecklistItem> { $0.turnoverCheckId == checkId }, sort: \TurnoverChecklistItem.sortOrder)
        _photos = Query(filter: #Predicate<RoomPhoto> { $0.turnoverCheckId == checkId }, sort: \RoomPhoto.createdAt, order: .reverse)
        _issues = Query(filter: #Predicate<StayIssue> { $0.turnoverCheckId == checkId }, sort: \StayIssue.createdAt, order: .reverse)
        _inventory = Query(filter: #Predicate<InventoryItem> { $0.propertyId == propertyId }, sort: \InventoryItem.name)
    }

    private var property: RentalProperty? {
        properties.first { $0.id == check.propertyId }
    }

    private var assessment: GuestReadyAssessment {
        GuestReadyCalculator.assess(checklistItems: checklistItems, issues: issues, photos: photos, inventory: inventory)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Workflow", selection: $selectedTab) {
                ForEach(WorkflowTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TurnoverCheckCard(check: check, propertyName: property?.name ?? "Property")

                    switch selectedTab {
                    case .checklist:
                        ChecklistWorkflowSection(items: checklistItems)
                    case .photos:
                        PhotoUploadView(check: check)
                    case .ai:
                        AIRoomScanView(check: check, property: property)
                    case .issues:
                        IssueListView(property: property, turnoverCheck: check)
                    case .score:
                        GuestReadyScoreView(assessment: assessment)
                        Button {
                            applyAssessment()
                        } label: {
                            Label("Apply score to check", systemImage: "speedometer")
                        }
                        .buttonStyle(.borderedProminent)
                    case .report:
                        if let property {
                            ReportGeneratorView(
                                property: property,
                                check: check,
                                checklistItems: checklistItems,
                                photos: photos,
                                issues: issues,
                                inventory: inventory
                            )
                        } else {
                            EmptyStateView(title: "Property missing", message: "This check needs a property before reports can be generated.", systemImage: "house.slash")
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Turnover")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Recalculate") {
                    applyAssessment()
                }
            }
        }
        .task {
            applyAssessment()
        }
    }

    private func applyAssessment() {
        let value = assessment
        check.guestReadyScore = value.score
        check.guestReadyStatus = value.status.rawValue
        switch value.status {
        case .ready:
            check.status = TurnoverStatus.completed.rawValue
        case .needsReview:
            check.status = TurnoverStatus.needsReview.rawValue
        case .notReady:
            check.status = TurnoverStatus.notReady.rawValue
        }
    }

    private enum WorkflowTab: String, CaseIterable, Identifiable {
        case checklist
        case photos
        case ai
        case issues
        case score
        case report

        var id: String { rawValue }

        var title: String {
            switch self {
            case .checklist:
                return "Checklist"
            case .photos:
                return "Photos"
            case .ai:
                return "AI"
            case .issues:
                return "Issues"
            case .score:
                return "Score"
            case .report:
                return "Report"
            }
        }
    }
}

struct ChecklistWorkflowSection: View {
    let items: [TurnoverChecklistItem]

    private var groupedSections: [(String, [TurnoverChecklistItem])] {
        ChecklistSection.allCases.compactMap { section in
            let sectionItems = items.filter { $0.section == section.rawValue }
            return sectionItems.isEmpty ? nil : (section.rawValue, sectionItems)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if items.isEmpty {
                EmptyStateView(title: "Checklist not created", message: "Create a new turnover check to add the guest-ready checklist.", systemImage: "checklist")
            } else {
                ForEach(groupedSections, id: \.0) { section, sectionItems in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section)
                            .font(.headline)
                        ForEach(sectionItems) { item in
                            ChecklistRow(item: item)
                        }
                    }
                }
            }
        }
    }
}

struct PhotoUploadView: View {
    let check: TurnoverCheck

    @Environment(\.modelContext) private var modelContext
    @Query private var photos: [RoomPhoto]
    @StateObject private var viewModel = PhotoUploadViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var errorMessage: String?

    init(check: TurnoverCheck) {
        self.check = check
        let checkId = check.id
        _photos = Query(filter: #Predicate<RoomPhoto> { $0.turnoverCheckId == checkId }, sort: \RoomPhoto.createdAt, order: .reverse)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Room", selection: $viewModel.room) {
                    ForEach(ChecklistSection.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }

                Picker("Photo type", selection: $viewModel.beforeAfterType) {
                    ForEach(BeforeAfterType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                TextField("Caption", text: $viewModel.caption)
                TextField("Notes", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(2...5)
                Toggle("Flag issue", isOn: $viewModel.flagIssue)

                HStack {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 8, matching: .images) {
                        Label("Upload photos", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        showingCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if photos.isEmpty {
                EmptyStateView(title: "No photo proof", message: "Add before and after photos by room for cleaner accountability.", systemImage: "camera")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 12)], spacing: 12) {
                    ForEach(photos) { photo in
                        RoomPhotoCard(photo: photo)
                    }
                }
            }
        }
        .onChange(of: selectedItems) { _, newItems in
            Task { await loadPhotos(newItems) }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker { image in
                if let data = image.jpegData(compressionQuality: 0.82) {
                    savePhoto(data)
                }
            }
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) async {
        errorMessage = nil
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    savePhoto(data)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        selectedItems.removeAll()
    }

    private func savePhoto(_ data: Data) {
        let photo = viewModel.makePhoto(turnoverCheckId: check.id, imageData: data)
        modelContext.insert(photo)
        try? modelContext.save()
        viewModel.resetCaption()
    }
}

struct AIRoomScanView: View {
    let check: TurnoverCheck
    let property: RentalProperty?

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var services: AppServices
    @Query private var photos: [RoomPhoto]

    @State private var selectedPhotoId: UUID?
    @State private var checklistNotes = ""
    @State private var result: RoomScanResult?
    @State private var isScanning = false
    @State private var errorMessage: String?
    @State private var showingPaywall = false

    init(check: TurnoverCheck, property: RentalProperty?) {
        self.check = check
        self.property = property
        let checkId = check.id
        _photos = Query(filter: #Predicate<RoomPhoto> { $0.turnoverCheckId == checkId }, sort: \RoomPhoto.createdAt, order: .reverse)
    }

    private var selectedPhoto: RoomPhoto? {
        if let selectedPhotoId {
            return photos.first { $0.id == selectedPhotoId }
        }
        return photos.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if photos.isEmpty {
                EmptyStateView(title: "Add photo proof first", message: "Upload a room photo before running an AI scan.", systemImage: "photo.badge.plus")
            } else {
                Picker("Photo", selection: Binding(
                    get: { selectedPhoto?.id },
                    set: { selectedPhotoId = $0 }
                )) {
                    ForEach(photos) { photo in
                        Text("\(photo.room) - \(photo.createdAt.formatted(date: .omitted, time: .shortened))").tag(Optional(photo.id))
                    }
                }

                TextField("Checklist notes for AI review", text: $checklistNotes, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await scan() }
                } label: {
                    if isScanning {
                        ProgressView()
                    } else {
                        Label("Run mock AI scan", systemImage: "wand.and.stars")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isScanning || selectedPhoto == nil)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let result {
                VStack(alignment: .leading, spacing: 12) {
                    GuestReadyScoreView(assessment: GuestReadyAssessment(
                        score: result.guestReadyScore,
                        status: status(for: result.guestReadyScore),
                        summary: result.summary,
                        blockers: result.issues.map(\.title)
                    ))

                    Text("Suggested next action")
                        .font(.headline)
                    Text(result.suggestedNextAction)
                        .foregroundStyle(.secondary)

                    ForEach(result.issues) { issue in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(issue.title)
                                    .font(.headline)
                                Spacer()
                                SeverityBadge(severity: issue.severity)
                            }
                            Text(issue.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                    Label(issue.suggestedAction, systemImage: "arrow.turn.down.right")
                        .font(.caption)
                        .foregroundStyle(Color.stayTeal)
                        }
                        .padding(14)
                        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(subscriptionService: services.subscriptionService)
        }
    }

    private func scan() async {
        guard let selectedPhoto else { return }
        isScanning = true
        errorMessage = nil
        defer { isScanning = false }

        do {
            let request = RoomScanRequest(
                propertyType: property?.propertyType ?? "Short-let",
                room: selectedPhoto.room,
                checklistNotes: checklistNotes.isEmpty ? selectedPhoto.notes : checklistNotes,
                imageBase64: selectedPhoto.imageData?.base64EncodedString() ?? ""
            )
            let scanResult = try await services.aiService.scanRoomPhoto(request)
            result = scanResult

            for suggested in scanResult.issues {
                modelContext.insert(StayIssue(
                    propertyId: check.propertyId,
                    turnoverCheckId: check.id,
                    photoId: selectedPhoto.id,
                    title: suggested.title,
                    room: selectedPhoto.room,
                    issueDescription: suggested.description,
                    category: suggested.category,
                    severity: suggested.severity,
                    suggestedAction: suggested.suggestedAction
                ))
            }

            check.guestReadyScore = scanResult.guestReadyScore
            check.guestReadyStatus = status(for: scanResult.guestReadyScore).rawValue
            try? modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func status(for score: Int) -> GuestReadyStatus {
        if score >= 85 { return .ready }
        if score >= 65 { return .needsReview }
        return .notReady
    }
}

struct IssueListView: View {
    private let property: RentalProperty?
    private let turnoverCheck: TurnoverCheck?

    @Query private var issues: [StayIssue]
    @Query(sort: \RentalProperty.name) private var properties: [RentalProperty]
    @State private var showingAddIssue = false

    init(property: RentalProperty? = nil, turnoverCheck: TurnoverCheck? = nil) {
        self.property = property
        self.turnoverCheck = turnoverCheck

        if let turnoverCheck {
            let checkId = turnoverCheck.id
            _issues = Query(filter: #Predicate<StayIssue> { $0.turnoverCheckId == checkId }, sort: \StayIssue.createdAt, order: .reverse)
        } else if let property {
            let propertyId = property.id
            _issues = Query(filter: #Predicate<StayIssue> { $0.propertyId == propertyId }, sort: \StayIssue.createdAt, order: .reverse)
        } else {
            _issues = Query(sort: \StayIssue.createdAt, order: .reverse)
        }
    }

    private var targetProperty: RentalProperty? {
        property ?? properties.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if issues.isEmpty {
                EmptyStateView(title: "No issues recorded", message: "Add cleaning, damage, inventory, safety, or maintenance findings with severity and actions.", systemImage: "exclamationmark.bubble")
            } else {
                ForEach(issues) { issue in
                    NavigationLink {
                        IssueEditorView(issue: issue)
                    } label: {
                        StayIssueCard(issue: issue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Issues")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddIssue = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(targetProperty == nil)
                .accessibilityLabel("Add issue")
            }
        }
        .sheet(isPresented: $showingAddIssue) {
            if let targetProperty {
                IssueEditorView(property: targetProperty, turnoverCheck: turnoverCheck)
            }
        }
    }
}

struct IssueEditorView: View {
    private let property: RentalProperty?
    private let turnoverCheck: TurnoverCheck?
    private let issue: StayIssue?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: IssueFormViewModel

    init(property: RentalProperty, turnoverCheck: TurnoverCheck? = nil) {
        self.property = property
        self.turnoverCheck = turnoverCheck
        self.issue = nil
        _viewModel = StateObject(wrappedValue: IssueFormViewModel())
    }

    init(issue: StayIssue) {
        self.property = nil
        self.turnoverCheck = nil
        self.issue = issue
        _viewModel = StateObject(wrappedValue: IssueFormViewModel(issue: issue))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Issue") {
                    TextField("Issue title", text: $viewModel.title)
                    Picker("Room", selection: $viewModel.room) {
                        ForEach(ChecklistSection.allCases) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    TextField("Description", text: $viewModel.issueDescription, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Classification") {
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(IssueCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    Picker("Severity", selection: $viewModel.severity) {
                        ForEach(IssueSeverity.allCases) { severity in
                            Text(severity.rawValue).tag(severity)
                        }
                    }
                    Picker("Status", selection: $viewModel.status) {
                        ForEach(IssueStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Action") {
                    TextField("Suggested action", text: $viewModel.suggestedAction, axis: .vertical)
                    TextField("Assigned action", text: $viewModel.assignedAction, axis: .vertical)
                }
            }
            .navigationTitle(issue == nil ? "New Issue" : "Edit Issue")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }

    private func save() {
        if let issue {
            viewModel.apply(to: issue)
        } else if let property {
            modelContext.insert(viewModel.makeIssue(propertyId: property.id, turnoverCheckId: turnoverCheck?.id))
        }

        try? modelContext.save()
        dismiss()
    }
}

struct InventoryListView: View {
    private let property: RentalProperty?

    @EnvironmentObject private var services: AppServices
    @Query private var items: [InventoryItem]
    @Query(sort: \RentalProperty.name) private var properties: [RentalProperty]
    @State private var showingEditor = false
    @State private var reminderMessage: String?
    @State private var showingPaywall = false

    init(property: RentalProperty? = nil) {
        self.property = property
        if let property {
            let propertyId = property.id
            _items = Query(filter: #Predicate<InventoryItem> { $0.propertyId == propertyId }, sort: \InventoryItem.name)
        } else {
            _items = Query(sort: \InventoryItem.name)
        }
    }

    private var targetProperty: RentalProperty? {
        property ?? properties.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if items.isEmpty {
                    EmptyStateView(title: "No inventory items", message: "Track towels, bedding, consumables, keys, remotes, and kitchen essentials.", systemImage: "shippingbox")
                } else {
                    ForEach(items) { item in
                        NavigationLink {
                            InventoryEditorView(item: item)
                        } label: {
                            InventoryItemCard(item: item) {
                                Task { await scheduleReminder(for: item) }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(property?.name ?? "Inventory")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(targetProperty == nil)
                .accessibilityLabel("Add inventory item")
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let targetProperty {
                InventoryEditorView(property: targetProperty)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(subscriptionService: services.subscriptionService)
        }
        .alert("Reminder", isPresented: Binding(
            get: { reminderMessage != nil },
            set: { if !$0 { reminderMessage = nil } }
        )) {
            Button("OK", role: .cancel) { reminderMessage = nil }
        } message: {
            Text(reminderMessage ?? "")
        }
    }

    private func scheduleReminder(for item: InventoryItem) async {
        guard !MonetizationConfig.isStoreKitEnabled || services.subscriptionService.currentPlan != .free else {
            showingPaywall = true
            return
        }

        let granted = await services.notificationService.requestAuthorization()
        guard granted else {
            reminderMessage = "Notifications are not enabled for StayCheck IQ."
            return
        }

        do {
            let propertyName = properties.first { $0.id == item.propertyId }?.name ?? property?.name ?? "Property"
            try await services.notificationService.scheduleRestockReminder(for: item, propertyName: propertyName)
            reminderMessage = "Restock reminder scheduled."
        } catch {
            reminderMessage = error.localizedDescription
        }
    }
}

struct InventoryEditorView: View {
    private let property: RentalProperty?
    private let item: InventoryItem?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: InventoryFormViewModel

    init(property: RentalProperty) {
        self.property = property
        self.item = nil
        _viewModel = StateObject(wrappedValue: InventoryFormViewModel())
    }

    init(item: InventoryItem) {
        self.property = nil
        self.item = item
        _viewModel = StateObject(wrappedValue: InventoryFormViewModel(item: item))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $viewModel.name)
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(InventoryCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }

                Section("Stock") {
                    Stepper("Current: \(viewModel.currentQuantity)", value: $viewModel.currentQuantity, in: 0...999)
                    Stepper("Minimum: \(viewModel.minimumQuantity)", value: $viewModel.minimumQuantity, in: 0...999)
                    Toggle("Needs restock", isOn: $viewModel.needsRestock)
                }

                Section("Notes") {
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                }
            }
            .navigationTitle(item == nil ? "New Inventory" : "Edit Inventory")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!viewModel.canSave)
                }
            }
        }
    }

    private func save() {
        if let item {
            viewModel.apply(to: item)
        } else if let property {
            modelContext.insert(viewModel.makeItem(propertyId: property.id))
        }
        try? modelContext.save()
        dismiss()
    }
}

struct ReportGeneratorView: View {
    let property: RentalProperty
    let check: TurnoverCheck
    let checklistItems: [TurnoverChecklistItem]
    let photos: [RoomPhoto]
    let issues: [StayIssue]
    let inventory: [InventoryItem]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var services: AppServices
    @StateObject private var viewModel = ReportGenerationViewModel()
    @State private var shareURL: URL?
    @State private var showingPaywall = false

    private var assessment: GuestReadyAssessment {
        GuestReadyCalculator.assess(checklistItems: checklistItems, issues: issues, photos: photos, inventory: inventory)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GuestReadyScoreView(assessment: assessment)

            Button {
                Task { await generateReport() }
            } label: {
                if viewModel.isGenerating {
                    ProgressView()
                } else {
                    Label("Generate PDF report", systemImage: "doc.richtext")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isGenerating)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let generatedURL = viewModel.generatedURL {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Report ready")
                        .font(.headline)
                    Text(generatedURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        shareURL = generatedURL
                    } label: {
                        Label("Share report", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if !$0 { shareURL = nil } }
        )) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(subscriptionService: services.subscriptionService)
        }
    }

    private func generateReport() async {
        let reportTextInput = ReportTextInput(
            propertyName: property.name,
            cleanerName: check.cleanerName,
            completedChecklistCount: checklistItems.filter(\.completed).count,
            totalChecklistCount: checklistItems.count,
            openIssueCount: issues.filter { $0.status != IssueStatus.resolved.rawValue }.count,
            restockCount: inventory.filter { $0.currentQuantity < $0.minimumQuantity || $0.needsRestock }.count,
            guestReadyAssessment: assessment
        )

        let summary = (try? await services.aiService.generateReportText(reportTextInput)) ?? assessment.summary
        let input = PDFReportInput(
            property: property,
            check: check,
            checklistItems: checklistItems,
            photos: photos,
            issues: issues,
            inventory: inventory,
            assessment: assessment,
            summary: summary
        )

        if let url = await viewModel.generate(input: input, services: services) {
            let report = TurnoverReport(
                turnoverCheckId: check.id,
                propertyId: property.id,
                title: "\(property.name) turnover - \(check.date.formatted(date: .abbreviated, time: .omitted))",
                summary: summary,
                pdfLocalPath: url.path
            )
            modelContext.insert(report)
            check.guestReadyScore = assessment.score
            check.guestReadyStatus = assessment.status.rawValue
            try? modelContext.save()
            shareURL = url
        }
    }
}

struct ReportsCenterView: View {
    @Query(sort: \TurnoverReport.createdAt, order: .reverse) private var reports: [TurnoverReport]
    @Query(sort: \RentalProperty.name) private var properties: [RentalProperty]
    @Query(sort: \StayIssue.createdAt, order: .reverse) private var issues: [StayIssue]

    @State private var searchText = ""
    @State private var shareURL: URL?

    private var filteredReports: [TurnoverReport] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return reports
        }

        let needle = searchText.lowercased()
        return reports.filter { report in
            let propertyName = properties.first { $0.id == report.propertyId }?.name.lowercased() ?? ""
            let severities = issues
                .filter { $0.propertyId == report.propertyId }
                .map { $0.severity.lowercased() }
                .joined(separator: " ")
            let date = report.createdAt.formatted(date: .abbreviated, time: .omitted).lowercased()
            return report.title.lowercased().contains(needle)
                || report.summary.lowercased().contains(needle)
                || propertyName.contains(needle)
                || severities.contains(needle)
                || date.contains(needle)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if reports.isEmpty {
                    EmptyStateView(title: "No saved reports", message: "Generate PDF turnover reports from completed checks.", systemImage: "doc.text.magnifyingglass")
                } else {
                    ForEach(filteredReports) { report in
                        Button {
                            shareURL = report.pdfURL
                        } label: {
                            ReportPreviewView(report: report)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Reports")
        .searchable(text: $searchText, prompt: "Property, date, severity")
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if !$0 { shareURL = nil } }
        )) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var services: AppServices
    @Environment(\.modelContext) private var modelContext
    @State private var showingPaywall = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteMessage: String?

    var body: some View {
        Form {
            Section("Access") {
                Label("All local inspection tools enabled", systemImage: "checkmark.seal")
                    .foregroundStyle(Color.stayTeal)
            }

            Section("Business profile") {
                NavigationLink {
                    StaticTextView(title: "Business Profile", text: "Business name, VAT/tax details, owner contact, billing address, and default report footer placeholders are ready for production wiring.")
                } label: {
                    Label("Business profile", systemImage: "building.2")
                }
                NavigationLink {
                    StaticTextView(title: "Report Branding", text: "Custom logo, brand colour, report footer, contact details, and white-label PDF settings are ready for future account configuration.")
                } label: {
                    Label("Report branding", systemImage: "paintpalette")
                }
                NavigationLink {
                    StaticTextView(title: "Cleaner Teams", text: "Invite cleaners, assign properties, track completion accountability, and review activity logs. This placeholder keeps the workflow ready for backend team accounts.")
                } label: {
                    Label("Cleaner/team settings", systemImage: "person.3")
                }
            }

            Section("Legal and AI") {
                NavigationLink {
                    StaticTextView(title: "Privacy Policy", text: "Add your production privacy policy here. Local mock mode stores turnover data on device using SwiftData. Never store API keys inside the iOS app.")
                } label: {
                    Label("Privacy policy", systemImage: "hand.raised")
                }

                NavigationLink {
                    StaticTextView(title: "Terms of Use", text: "Add your production terms here, including acceptable use, account terms, cancellation policies, and liability limitations.")
                } label: {
                    Label("Terms of use", systemImage: "doc.plaintext")
                }

                NavigationLink {
                    StaticTextView(title: "AI Disclaimer", text: "AI findings must be reviewed. StayCheck IQ is not a legal property inspection, not safety certification, and not a replacement for qualified maintenance professionals. Urgent safety concerns should be checked immediately.")
                } label: {
                    Label("AI disclaimer", systemImage: "exclamationmark.shield")
                }
            }

            Section("Local data") {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete all local data", systemImage: "trash")
                }

                if let deleteMessage {
                    Text(deleteMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPaywall) {
            PaywallView(subscriptionService: services.subscriptionService)
        }
        .alert("Delete all local data?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes properties, checks, photos, issues, inventory, reports, and settings stored locally on this device.")
        }
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: RentalProperty.self)
            try modelContext.delete(model: TurnoverCheck.self)
            try modelContext.delete(model: TurnoverChecklistItem.self)
            try modelContext.delete(model: RoomPhoto.self)
            try modelContext.delete(model: StayIssue.self)
            try modelContext.delete(model: InventoryItem.self)
            try modelContext.delete(model: TurnoverReport.self)
            try modelContext.delete(model: SubscriptionState.self)
            try modelContext.save()
            deleteMessage = "Local data deleted."
        } catch {
            deleteMessage = error.localizedDescription
        }
    }
}

struct StaticTextView: View {
    let title: String
    let text: String

    var body: some View {
        ScrollView {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(title)
    }
}

private struct DisclaimerBullets: View {
    private let items = [
        "AI suggestions must be reviewed by a responsible person.",
        "StayCheck IQ is not a legal property inspection.",
        "StayCheck IQ is not safety certification.",
        "It is not a replacement for qualified maintenance professionals.",
        "Urgent safety concerns should be checked immediately."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Label(item, systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct DashboardActionCard<Destination: View>: View {
    let title: String
    let value: String
    let icon: String
    let destination: Destination

    init(title: String, value: String, icon: String, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.value = value
        self.icon = icon
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.stayTeal)
                    Spacer()
                    Text(value)
                        .font(.title3.bold())
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
        }
        .buttonStyle(.plain)
    }
}

private struct SectionHeader<Destination: View>: View {
    let title: String
    let actionTitle: String?
    let destination: (() -> Destination)?

    init(title: String) where Destination == EmptyView {
        self.title = title
        self.actionTitle = nil
        self.destination = nil
    }

    init(title: String, actionTitle: String?, @ViewBuilder destination: @escaping () -> Destination) {
        self.title = title
        self.actionTitle = actionTitle
        self.destination = destination
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.bold())
            Spacer()
            if let actionTitle, let destination {
                NavigationLink(actionTitle) {
                    destination()
                }
                .font(.subheadline.weight(.semibold))
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

private struct QuickActionLabel: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.stayTeal)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
    }
}
