
import SwiftUI

struct EmissionCalculator {
    // Emission factors in kg CO₂ equivalent
    private let emissionFactors: [String: Double] = [
        "car": 0.170,        // per km (average car)
        "bus": 0.082,        // per km
        "train": 0.041,      // per km
        "electricity": 0.233, // per kWh (US average)
        "recycling": 1.04,  // per kg
        "beef": 27.0,        // per kg
        "pork": 12.1,        // per kg
        "chicken": 6.9,      // per kg
        "vegetarian_meal": -3.5, // per meal (compared to average meat meal)
        "water": 0.298,      // per m³
        "tree_planted": -21.7, // per year per tree
        "composting": -0.24,   // per kg
    ]
    
    // Activity descriptions for user feedback
    let activityDescriptions: [String: String] = [
        "car": "Driving car",
        "bus": "Taking bus",
        "train": "Taking train",
        "electricity": "Electricity usage",
        "recycling": "Recycling",
        "beef": "Beef consumption",
        "pork": "Pork consumption",
        "chicken": "Chicken consumption",
        "vegetarian_meal": "Choosing vegetarian meal",
        "water": "Water usage",
        "tree_planted": "Planting tree",
        "composting": "Composting",
    ]
    
    /// Calculates CO₂ emissions for a given activity
    /// - Parameters:
    ///   - activity: The type of activity (e.g., "car", "recycling")
    ///   - value: The quantity (e.g., kilometers driven, kg recycled)
    /// - Returns: CO₂ impact in kg (negative values mean emissions saved)
    func calculateEmission(activity: String, value: Double) -> Double {
        guard let factor = emissionFactors[activity] else {
            return 0
        }
        return factor * value
    }
    
    /// Gets a user-friendly description of the environmental impact
    /// - Parameters:
    ///   - activity: The type of activity
    ///   - value: The quantity
    /// - Returns: A formatted string describing the impact
    func getImpactDescription(activity: String, value: Double) -> String {
        let emission = calculateEmission(activity: activity, value: value)
        let activityName = activityDescriptions[activity] ?? activity
        
        if emission < 0 {
            return "\(activityName) saved \(abs(emission).formatted(.number.precision(.fractionLength(1)))) kg CO₂"
        } else {
            return "\(activityName) produced \(emission.formatted(.number.precision(.fractionLength(1)))) kg CO₂"
        }
    }
}

struct Streak: Identifiable {
    let id = UUID()
    var count: Int
    var lastUpdated: Date?
    var completedTasks: Set<UUID> // Track completed tasks for today
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    var description: String  // Changed to var to update with current requirement
    let icon: String
    let initialRequirement: Int  // Add this to store the initial value
    var requirement: Int
    var progress: Int
    let unit: String
    var isLocked: Bool
    var dateUnlocked: Date?
    var level: Int = 1
    
    var progressPercentage: Double {
        // Ensure progress never exceeds 100%
        min(Double(progress) / Double(requirement), 1.0)
    }
    
    var displayProgress: Int {
        // Show only current level's progress
        progress
    }
    
    var displayRequirement: Int {
        // Show current level's requirement
        requirement
    }
    
    var nextLevelPreview: String {
        if isCompleted {
            return "Next Level: \(requirement * 2) \(unit)"
        }
        return ""
    }
    
    var isCompleted: Bool {
        progress >= requirement
    }
    
    // Add this computed property for total progress
    var totalProgress: Int {
        progress
    }
    
    // Function to create next level achievement
    func nextLevel() -> Achievement {
        let nextRequirement = requirement * 2
        let excessProgress = max(0, progress - requirement)
        
        return Achievement(
            title: title,
            description: updateDescription(for: nextRequirement),
            icon: icon,
            initialRequirement: initialRequirement,
            requirement: nextRequirement,
            progress: excessProgress, // Only carry over excess progress
            unit: unit,
            isLocked: true,
            dateUnlocked: nil,
            level: level + 1
        )
    }
    
    // Add helper function to update description
    private func updateDescription(for newRequirement: Int) -> String {
        switch title {
        case "Cycling Champion":
            return "Ride a bicycle for \(newRequirement) km"
        case "Tree Guardian":
            return "Maintain planted trees for \(newRequirement) days"
        case "Waste Warrior":
            return "Recycle \(newRequirement) kg of waste"
        case "Water Saver":
            return "Save \(newRequirement) liters of water"
        case "Green Diet":
            return "Choose \(newRequirement) vegetarian meals"
        default:
            return description
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var rotation: Double
    var color: Color
    var scale: Double
}

struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    @State private var isActive = false
    
    let colors: [Color] = [.green, .blue, .yellow, .pink, .purple, .orange]
    
    func createPieces() {
        pieces = (0..<60).map { _ in
            ConfettiPiece(
                x: Double.random(in: -20...420),
                y: -20,
                rotation: Double.random(in: 0...360),
                color: colors.randomElement() ?? .green,
                scale: Double.random(in: 0.5...1.5)
            )
        }
    }
    
    var body: some View {
        ZStack {
            ForEach(pieces) { piece in
                Image(systemName: ["star.fill", "heart.fill", "leaf.fill"].randomElement()!)
                    .foregroundColor(piece.color)
                    .scaleEffect(piece.scale)
                    .position(x: piece.x, y: piece.y)
                    .rotationEffect(.degrees(piece.rotation))
            }
        }
        .onAppear {
            createPieces()
            animate()
        }
    }
    
    func animate() {
        isActive = true
        
        for index in pieces.indices {
            withAnimation(.spring(response: Double.random(in: 0.5...1.2), dampingFraction: 0.7)
                .repeatCount(1)) {
                pieces[index].y = 700
                pieces[index].rotation += Double.random(in: 180...360)
            }
        }
        
        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isActive = false
            createPieces()
        }
    }
}

// First, create a class to manage shared state
class AppState: ObservableObject {
    @Published var selectedTab = 0
}

struct ContentView: View {
    @StateObject private var ecoData = EcoData()
    @StateObject private var appState = AppState()
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    let calculator = EmissionCalculator()
    
    init() {
        configureTabBarAppearance()
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        Group {
            if isFirstLaunch {
                OnboardingScreen(isFirstLaunch: $isFirstLaunch)
            } else {
                TabView(selection: $appState.selectedTab) {
                    HomeDashboardView()
                        .environmentObject(ecoData)
                        .environmentObject(appState)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)
                    
                    HabitTrackerView()
                        .environmentObject(ecoData)
                        .tabItem {
                            Label("Habits", systemImage: "checklist")
                        }
                        .tag(1)
                    
                    AchievementsView()
                        .environmentObject(ecoData)
                        .tabItem {
                            Label("Achievements", systemImage: "trophy.fill")
                        }
                        .tag(2)
                }
                .accentColor(.green)
            }
        }
    }
    
    private func calculateTotalImpact() -> Double {
        var total = 0.0
        
        // Example activities
        total += calculator.calculateEmission(activity: "vegetarian_meal", value: 5) // 5 vegetarian meals
        total += calculator.calculateEmission(activity: "recycling", value: 10)      // 10 kg recycled
        total += calculator.calculateEmission(activity: "car", value: -20)           // 20 km not driven
        total += calculator.calculateEmission(activity: "tree_planted", value: 1)    // 1 tree planted
        
        return abs(total) // Convert to positive number for display
    }
}

struct HomeDashboardView: View {
    @EnvironmentObject var ecoData: EcoData
    @EnvironmentObject var appState: AppState
    @State private var showHabits = false
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    @State private var isEarthRotating = true
    @State private var showTipCard = false
    @State private var selectedAction: String?
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("currentTipIndex") private var currentTipIndex = 0
    let calculator = EmissionCalculator()
    
    // Monthly target for CO₂ savings in kg
    let monthlyTarget: Double = 100.0
    
    // Calculate progress value based on actual savings
    var progressValue: Double {
        min(ecoData.totalCO2Saved / monthlyTarget, 1.0)
    }
    
    // Sample calculation
    private func calculateTotalImpact() -> Double {
        var total = 0.0
        
        // Example activities
        total += calculator.calculateEmission(activity: "vegetarian_meal", value: 5) // 5 vegetarian meals
        total += calculator.calculateEmission(activity: "recycling", value: 10)      // 10 kg recycled
        total += calculator.calculateEmission(activity: "car", value: -20)           // 20 km not driven
        total += calculator.calculateEmission(activity: "tree_planted", value: 1)    // 1 tree planted
        
        return abs(total) // Convert to positive number for display
    }
    
    var activeAchievements: [Achievement] {
        ecoData.achievements.filter {
            $0.progress > 0 && !$0.isCompleted && !$0.isLocked
        }.sorted { $0.progressPercentage > $1.progressPercentage }
    }
    
    // Add tips array
    let tips: [EcoTip] = [
        EcoTip(
            tip: "Turn off lights when leaving a room",
            fact: "A single LED bulb can save 300kg of CO2 emissions over its lifetime",
            category: "Energy",
            impact: "Save 0.15 kg CO2 per hour"
        ),
        EcoTip(
            tip: "Use a reusable water bottle",
            fact: "1 million plastic bottles are bought every minute globally",
            category: "Waste",
            impact: "Save 82.8 kg CO2 per year"
        ),
        EcoTip(
            tip: "Eat locally grown seasonal produce",
            fact: "Food transportation accounts for 6% of global emissions",
            category: "Food",
            impact: "Save up to 1 kg CO2 per meal"
        ),
        EcoTip(
            tip: "Take shorter showers",
            fact: "A 10-minute shower uses about 100 liters of water",
            category: "Water",
            impact: "Save 2.5 kg CO2 per week"
        ),
        EcoTip(
            tip: "Use public transportation",
            fact: "One bus can replace 60 cars on the road",
            category: "Transport",
            impact: "Save 2.6 kg CO2 per trip"
        ),
        EcoTip(
            tip: "Plant a tree",
            fact: "A single tree absorbs about 22kg of CO2 per year",
            category: "Nature",
            impact: "Save 22 kg CO2 per year"
        )
    ]
    
    var currentTip: EcoTip {
        // Safely handle index
        let safeIndex = currentTipIndex % tips.count
        return tips[safeIndex]
    }
    
    var body: some View {
        NavigationView {
            SwiftUI.ScrollView {
                VStack(spacing: 24) {
                    // Eco Tip Banner
                    if #available(iOS 18.0, *) {
                        EcoBanner(tip: currentTip)
                            .transition(.move(edge: .top))
                    }
                    
                    // Carbon Reduction Meter
                    VStack(spacing: 8) {
                        Text("Your Impact")
                            .font(.headline)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.green.opacity(0.2), lineWidth: 20)
                                .frame(width: 200, height: 200)
                            
                            Circle()
                                .trim(from: 0, to: progressValue)
                                .stroke(
                                    LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                                )
                                .frame(width: 200, height: 200)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 1), value: progressValue)
                            
                            VStack(spacing: 4) {
                                Text("\(Int(ecoData.totalCO2Saved))")
                                    .font(.system(size: 40, weight: .bold))
                                Text("kg CO₂ saved")
                                    .font(.subheadline)
                                Text("Goal: \(Int(monthlyTarget)) kg")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                    }
                    
                    // Quick Action Buttons - Only 2 main actions
//                    HStack(spacing: 16) {
//                        ActionButton(
//                            title: "Log Habit",
//                            icon: "leaf.arrow.circlepath",
//                            color: .green
//                        ) {
//                            withAnimation {
//                                appState.selectedTab = 1
//                            }
//                        }
//
//                        ActionButton(
//                            title: "Achievements",
//                            icon: "trophy.fill",
//                            color: .orange
//                        ) {
//                            withAnimation {
//                                appState.selectedTab = 2
//                            }
//                        }
//                    }
//                    .padding(.horizontal)
                    
                    // Environmental Impact Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Environmental Impact")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ImpactCard(
                                icon: "tree.fill",
                                value: String(format: "%.1f", ecoData.totalCO2Saved/2),
                                label: "Trees\nSaved"
                            )
                            
                            ImpactCard(
                                icon: "car.fill",
                                value: String(format: "%.1f", ecoData.totalCO2Saved*10),
                                label: "Km Not\nDriven"
                            )
                            
                            ImpactCard(
                                icon: "aqi.high",
                                value: String(format: "%.1f", ecoData.totalCO2Saved*0.8),
                                label: "Air Quality\nImproved (AQI)"
                            )
                            
                            ImpactCard(
                                icon: "leaf.fill",
                                value: String(format: "%.1f", ecoData.totalCO2Saved*0.3),
                                label: "Forest Area\nPreserved (m²)"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Real World Impact section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Real World Impact")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ImpactComparison(
                                    icon: "lungs.fill",
                                    text: "\(Int(ecoData.totalCO2Saved*0.4)) hours of clean air generated"
                                )
                                
                                ImpactComparison(
                                    icon: "drop.fill",
                                    text: "   \(Int(ecoData.totalCO2Saved*5)) liters of clean water preserved"
                                )
                                
                                ImpactComparison(
                                    icon: "globe.americas.fill",
                                    text: "  Reduced carbon footprint by \(Int(ecoData.totalCO2Saved*0.2)) earth days"
                                )
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("CarbonQuest")
            .sheet(isPresented: $showHabits) {
                HabitFormView(editingHabit: nil)
            }
            .onAppear {
                if isFirstLaunch {
                    // Show onboarding only once
                    isFirstLaunch = false
                }
                isEarthRotating = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showTipCard = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CompactStreakView()
                }
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.callout)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct WelcomeSection: View {
    @Binding var showHabits: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Welcome to CarbonQuest")
                .font(.title2.bold())
            
            Text("Start your journey towards a sustainable future. Every small action counts in saving our planet.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button {
                showHabits = true
            } label: {
                Text("Let's Save the Planet")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ImpactCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 30))
            Text(value)
                .font(.title2)
                .bold()
            Text(label)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let activity: String
    let value: Double
    let calculator = EmissionCalculator()
    
    var body: some View {
        Button(action: {
            let impact = calculator.calculateEmission(activity: activity, value: value)
            print(calculator.getImpactDescription(activity: activity, value: value))
        }) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 30))
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
        }
        .foregroundColor(.green)
    }
}

struct Habit: Identifiable, Equatable, Sendable {
    let id = UUID()
    var title: String
    var icon: String
    var activity: String
    var value: Double
    var unit: String
    var frequency: HabitFrequency
    var isCompleted: Bool
    var isCustom: Bool
    var category: HabitCategory
    var statistics: HabitStatistics
    var description: String
    
    enum HabitCategory: String, CaseIterable, Sendable {
        case transport = "Transport"
        case food = "Food"
        case recycling = "Recycling"
        case energy = "Energy"
        case water = "Water"
        case other = "Other"
    }
    
    enum HabitFrequency: String, CaseIterable, Sendable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }
    
    static func == (lhs: Habit, rhs: Habit) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.icon == rhs.icon &&
        lhs.activity == rhs.activity &&
        lhs.value == rhs.value &&
        lhs.unit == rhs.unit &&
        lhs.frequency == rhs.frequency &&
        lhs.isCompleted == rhs.isCompleted &&
        lhs.isCustom == rhs.isCustom &&
        lhs.category == rhs.category &&
        lhs.statistics == rhs.statistics
    }
}

struct CheckboxStyle: ViewModifier {
    let isCompleted: Bool
    let animate: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? 0.8 : 1.0)
            .animation(.spring(response: 0.2), value: animate)
    }
}

struct HabitFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var ecoData: EcoData
    @State private var title = ""
    @State private var selectedActivity = "car"
    @State private var value: Double = 0
    @State private var frequency: Habit.HabitFrequency = .daily
    @State private var showingError = false
    let editingHabit: Habit?
    @State private var customIcon = "star.fill"
    @State private var showIconPicker = false
    @State private var habitDescription = ""
    
    private let activities = [
        ("car", "Car Usage"),
        ("vegetarian_meal", "Vegetarian Meal"),
        ("recycling", "Recycling"),
        ("water", "Water Usage"),
        ("tree_planted", "Plant Tree")
    ]
    
    private let availableIcons = [
        "car.fill", "leaf", "arrow.3.trianglepath", "drop.fill",
        "leaf.fill", "star.fill", "heart.fill", "flame.fill",
        "sun.max.fill", "moon.fill", "cloud.fill", "bolt.fill"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Habit Details") {
                    TextField("Habit Name", text: $title)
                    
                    TextField("Description", text: $habitDescription)
                        .font(.subheadline)
                    
                    HStack {
                        Text("Icon")
                        Spacer()
                        Image(systemName: customIcon)
                            .foregroundColor(.green)
                        Button("Change") {
                            showIconPicker = true
                        }
                    }
                    
                    Picker("Activity Type", selection: $selectedActivity) {
                        ForEach(activities, id: \.0) { activity in
                            Text(activity.1).tag(activity.0)
                        }
                    }
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Habit.HabitFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    
                    HStack {
                        Text("Value")
                        TextField("Value", value: $value, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Impact Preview") {
                    if value != 0 {
                        Text(ecoData.calculator.getImpactDescription(
                            activity: selectedActivity,
                            value: value
                        ))
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(editingHabit == nil ? "Add Habit" : "Edit Habit")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") { saveHabit() }
            )
            .alert("Invalid Input", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please fill in all fields correctly.")
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $customIcon)
            }
            .onAppear {
                if let habit = editingHabit {
                    title = habit.title
                    selectedActivity = habit.activity
                    value = habit.value
                    frequency = habit.frequency
                    customIcon = habit.icon
                    habitDescription = habit.description
                }
            }
        }
    }
    
    private func saveHabit() {
        guard !title.isEmpty && value != 0 else {
            showingError = true
            return
        }
        
        // Create default description if none provided
        let description = habitDescription.isEmpty ?
            defaultDescription(for: selectedActivity, value: value) :
            habitDescription
        
        let habit = Habit(
            title: title,
            icon: customIcon,
            activity: selectedActivity,
            value: value,
            unit: unitForActivity(selectedActivity),
            frequency: frequency,
            isCompleted: false,
            isCustom: true,
            category: categoryForActivity(selectedActivity),
            statistics: HabitStatistics(),
            description: description
        )
        
        if let editingHabit = editingHabit,
           let index = ecoData.habits.firstIndex(where: { $0.id == editingHabit.id }) {
            ecoData.habits[index] = habit
        } else {
            ecoData.habits.append(habit)
        }
        
        ecoData.updateTotalCO2Savings()
        dismiss()
    }
    
    // Add helper function for default descriptions
    private func defaultDescription(for activity: String, value: Double) -> String {
        switch activity {
        case "car":
            return "Skip \(Int(abs(value)))km of driving"
        case "vegetarian_meal":
            return "Choose vegetarian meal"
        case "recycling":
            return "Recycle \(Int(value))kg of waste"
        case "water":
            return "Save \(Int(abs(value)))L of water"
        case "tree_planted":
            return "Plant a tree"
        default:
            return title
        }
    }
    
    private func iconForActivity(_ activity: String) -> String {
        switch activity {
        case "car": return "car.fill"
        case "vegetarian_meal": return "leaf"
        case "recycling": return "arrow.3.trianglepath"
        case "water": return "drop.fill"
        case "tree_planted": return "leaf.fill"
        default: return "star.fill"
        }
    }
    
    private func unitForActivity(_ activity: String) -> String {
        switch activity {
        case "car": return "km"
        case "vegetarian_meal": return "meal"
        case "recycling": return "kg"
        case "water": return "L"
        case "tree_planted": return "tree"
        default: return "unit"
        }
    }
    
    private func categoryForActivity(_ activity: String) -> Habit.HabitCategory {
        switch activity {
        case "car": return .transport
        case "vegetarian_meal": return .food
        case "recycling": return .recycling
        case "water": return .water
        case "tree_planted": return .other
        default: return .other
        }
    }
}

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    
    let icons = [
        "car.fill", "leaf", "arrow.3.trianglepath", "drop.fill",
        "leaf.fill", "star.fill", "heart.fill", "flame.fill",
        "sun.max.fill", "moon.fill", "cloud.fill", "bolt.fill"
    ]
    
    let columns = Array(repeating: GridItem(.flexible()), count: 4)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(icons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title)
                            .foregroundColor(selectedIcon == icon ? .green : .primary)
                            .padding()
                            .background(
                                Circle()
                                    .fill(selectedIcon == icon ? Color.green.opacity(0.2) : Color.clear)
                            )
                            .onTapGesture {
                                selectedIcon = icon
                                dismiss()
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct HabitRow: View {
    let habit: Habit
    @EnvironmentObject var ecoData: EcoData
    @State private var animatingHabitId: UUID?
    @State private var showImpactAnimation = false
    @State private var showParticles = false
    @State private var showDeleteAlert = false
    @State private var showEditMenu = false
    
    var body: some View {
        HStack {
            // Checkbox button with enhanced feedback
            Button {
                withAnimation {
                    toggleHabit()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if habit.isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .bold))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .overlay(
                    Group {
                        if showImpactAnimation {
                            Circle()
                                .fill(Color.green.opacity(0.3))
                                .scaleEffect(showImpactAnimation ? 2 : 0)
                                .opacity(showImpactAnimation ? 0 : 1)
                        }
                    }
                )
                .modifier(CheckboxStyle(
                    isCompleted: habit.isCompleted,
                    animate: animatingHabitId == habit.id
                ))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Habit details with enhanced feedback
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: habit.icon)
                        .foregroundColor(.green)
                        .scaleEffect(showImpactAnimation ? 1.2 : 1.0)
                    
                    Text(habit.title)
                        .font(.headline)
                    
                    if habit.isCustom {
                        Text("Custom")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Text(habit.frequency.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(habit.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if habit.isCompleted {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                            .scaleEffect(showImpactAnimation ? 1.2 : 1.0)
                        
                        Text(ecoData.calculator.getImpactDescription(
                            activity: habit.activity,
                            value: habit.value
                        ))
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.opacity)
                    }
                    .overlay(
                        Group {
                            if showParticles {
                                ParticleEffect()
                            }
                        }
                    )
                }
            }
            
            // Add menu button
            Menu {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 8)
        .opacity(habit.isCompleted ? 0.8 : 1.0)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(habit.isCompleted ? Color.green.opacity(0.05) : Color.clear)
        )
        .animation(.spring(), value: habit.isCompleted)
        .alert("Delete Habit", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                ecoData.deleteHabit(habit)
            }
        } message: {
            Text("Are you sure you want to delete this habit? This action cannot be undone.")
        }
    }
    
    private func toggleHabit() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let index = ecoData.habits.firstIndex(where: { $0.id == habit.id }) {
                let wasCompleted = ecoData.habits[index].isCompleted
                ecoData.habits[index].isCompleted.toggle()
                
                if !wasCompleted {
                    // Trigger success animations
                    showImpactAnimation = true
                    showParticles = true
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    ecoData.updateStreak(habitId: habit.id)
                    var updatedStats = ecoData.habits[index].statistics
                    updatedStats.trackCompletion(
                        co2Impact: ecoData.calculator.calculateEmission(
                            activity: habit.activity,
                            value: habit.value
                        )
                    )
                    ecoData.habits[index].statistics = updatedStats
                    
                    // Update achievements
                    ecoData.updateAchievements()
                    
                    // Reset animations
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        showImpactAnimation = false
                        showParticles = false
                    }
                }
                
                ecoData.updateTotalCO2Savings()
                
                // Animate checkbox
                animatingHabitId = habit.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animatingHabitId = nil
                }
            }
        }
    }
}

// Add a particle effect for completed habits
struct ParticleEffect: View {
    @State private var particles: [(id: Int, x: Double, y: Double, scale: Double)] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                    .scaleEffect(particle.scale)
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        for i in 0..<10 {
            let particle = (
                id: i,
                x: Double.random(in: -50...50),
                y: Double.random(in: -50...50),
                scale: Double.random(in: 0.2...0.5)
            )
            particles.append(particle)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double.random(in: 0...0.3))) {
                if let index = particles.firstIndex(where: { $0.id == i }) {
                    particles[index].x += Double.random(in: -30...30)
                    particles[index].y += Double.random(in: -30...30)
                    particles[index].scale *= 0.5
                }
            }
        }
    }
}

struct CategoryButton: View {
    let category: Habit.HabitCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color.green.opacity(0.1))
                .foregroundColor(isSelected ? .white : .green)
                .cornerRadius(20)
        }
    }
}

struct HabitTrackerView: View {
    @EnvironmentObject var ecoData: EcoData
    @State private var showingAddHabit = false
    @State private var editingHabit: Habit?
    @State private var selectedCategory: Habit.HabitCategory?
    
    var filteredHabits: [Habit] {
        if let category = selectedCategory {
            return ecoData.habits.filter { $0.category == category }
        }
        return ecoData.habits
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Habit.HabitCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 3, y: 2)
                
                // Habits list
                List {
                    ForEach(filteredHabits) { habit in
                        HabitRow(habit: habit)
                    }
                    .onDelete { indexSet in
                        let habitsToDelete = indexSet.map { filteredHabits[$0] }
                        for habit in habitsToDelete {
                            ecoData.deleteHabit(habit)
                        }
                    }
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                HabitFormView(editingHabit: nil)
            }
            .sheet(item: $editingHabit) { habit in
                HabitFormView(editingHabit: habit)
            }
        }
    }
}

struct CompactStreakView: View {
    @EnvironmentObject var ecoData: EcoData
    
    var body: some View {
        StreakAnimation(count: ecoData.streak.count)
    }
}

struct AchievementsView: View {
    @EnvironmentObject var ecoData: EcoData
    @State private var showingHistory = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(ecoData.achievements) { achievement in
                        AchievementCard(achievement: achievement)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Achievements")
            .toolbar {
                Button {
                    showingHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
            .sheet(isPresented: $showingHistory) {
                NavigationView {
                    AchievementHistoryView()
                        .environmentObject(ecoData)
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    @State private var showConfetti = false
    @State private var isTransitioning = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.isCompleted ? .green : .gray)
                
                VStack(alignment: .leading) {
                    Text(achievement.title)
                        .font(.headline)
                    if achievement.level > 1 {
                        Text("Level \(achievement.level)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                if achievement.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Text(achievement.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(achievement.displayProgress) / \(achievement.displayRequirement) \(achievement.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(achievement.progressPercentage * 100))%")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                        
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geometry.size.width * achievement.progressPercentage)
                    }
                    .cornerRadius(5)
                }
                .frame(height: 8)
                
                if !achievement.nextLevelPreview.isEmpty {
                    Text(achievement.nextLevelPreview)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(.spring(), value: achievement.level)
        .onChange(of: achievement.isCompleted) { completed in
            if completed {
                withAnimation {
                    showConfetti = true
                    isTransitioning = true
                }
                
                // Add haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Reset states after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    showConfetti = false
                    isTransitioning = false
                }
            }
        }
    }
}

struct CompletedAchievementsView: View {
    @EnvironmentObject var ecoData: EcoData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed Achievements")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ecoData.achievements.filter { !$0.isLocked }) { achievement in
                        CompletedBadgeView(achievement: achievement)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CompletedBadgeView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
            
            Text(achievement.title)
                .font(.caption)
                .multilineTextAlignment(.center)
            
            Text("Level \(achievement.level)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
    }
}

struct InProgressAchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text(achievement.title)
                        .font(.headline)
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: geometry.size.width, height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * achievement.progressPercentage, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text("\(achievement.progress)/\(achievement.requirement) \(achievement.unit)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 250)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct OngoingAchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text(achievement.title)
                        .font(.headline)
                    Text("Level \(achievement.level)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Text(achievement.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.green.opacity(0.2))
                    
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * achievement.progressPercentage)
                }
                .cornerRadius(4)
            }
            .frame(height: 6)
            
            Text("\(achievement.displayProgress)/\(achievement.displayRequirement) \(achievement.unit)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 250)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct AchievementHistoryView: View {
    @EnvironmentObject var ecoData: EcoData
    
    var body: some View {
        Group {
            if ecoData.achievementHistory.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trophy")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No achievements yet")
                        .font(.headline)
                    Text("Complete goals to see your history here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(ecoData.achievementHistory.sorted(by: { $0.completedDate > $1.completedDate })) { history in
                        AchievementHistoryRow(history: history)
                    }
                }
            }
        }
        .navigationTitle("Achievement History")
        .listStyle(InsetGroupedListStyle())
    }
}

struct AchievementHistoryRow: View {
    let history: AchievementHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: history.achievement.icon)
                    .foregroundColor(.green)
                    .font(.title3)
                
                VStack(alignment: .leading) {
                    Text(history.achievement.title)
                        .font(.headline)
                    Text("Level \(history.level)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text(history.completedDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if history.co2Impact != 0 {
                Text("CO₂ Impact: \(abs(history.co2Impact).formatted(.number.precision(.fractionLength(1)))) kg")
                    .font(.caption)
                    .foregroundColor(history.co2Impact < 0 ? .green : .orange)
            }
            
            Text("Completed: \(history.achievement.requirement) \(history.achievement.unit)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class EcoData: ObservableObject {
    @Published var totalCO2Saved: Double = 0
    @Published var habits: [Habit] = [
        Habit(
            title: "Bike to Work",
            icon: "bicycle",
            activity: "car",
            value: -5.0,
            unit: "km",
            frequency: .daily,
            isCompleted: false,
            isCustom: false,
            category: .transport,
            statistics: HabitStatistics(),
            description: "Skip 5km of driving"
        ),
        Habit(
            title: "Vegetarian Lunch",
            icon: "leaf",
            activity: "vegetarian_meal",
            value: 1.0,
            unit: "meal",
            frequency: .daily,
            isCompleted: false,
            isCustom: false,
            category: .food,
            statistics: HabitStatistics(),
            description: "Choose vegetarian meal"
        ),
        Habit(
            title: "Recycle",
            icon: "arrow.3.trianglepath",
            activity: "recycling",
            value: 1.0,
            unit: "kg",
            frequency: .daily,
            isCompleted: false,
            isCustom: false,
            category: .recycling,
            statistics: HabitStatistics(),
            description: "Recycle 1kg of waste"
        ),
        Habit(
            title: "Save Water",
            icon: "drop.fill",
            activity: "water",
            value: -50.0,
            unit: "L",
            frequency: .daily,
            isCompleted: false,
            isCustom: false,
            category: .water,
            statistics: HabitStatistics(),
            description: "Save 50L of water"
        ),
        Habit(
            title: "Plant Tree",
            icon: "leaf.fill",
            activity: "tree_planted",
            value: 1.0,
            unit: "tree",
            frequency: .daily,
            isCompleted: false,
            isCustom: false,
            category: .other,
            statistics: HabitStatistics(),
            description: "Plant a tree"
        )
    ]
    
    @Published var achievements: [Achievement] = [
        Achievement(
            title: "Cycling Champion",
            description: "Ride a bicycle for 5 km",
            icon: "bicycle",
            initialRequirement: 5,
            requirement: 5,
            progress: 0,
            unit: "km",
            isLocked: false,
            dateUnlocked: nil
        ),
        Achievement(
            title: "Tree Guardian",
            description: "Maintain planted trees for 30 days",
            icon: "leaf.fill",
            initialRequirement: 30,
            requirement: 30,
            progress: 0,
            unit: "days",
            isLocked: true,
            dateUnlocked: nil
        ),
        Achievement(
            title: "Waste Warrior",
            description: "Recycle 50 kg of waste",
            icon: "arrow.3.trianglepath",
            initialRequirement: 50,
            requirement: 50,
            progress: 0,
            unit: "kg",
            isLocked: true,
            dateUnlocked: nil
        ),
        Achievement(
            title: "Water Saver",
            description: "Save 1000 liters of water",
            icon: "drop.fill",
            initialRequirement: 1000,
            requirement: 1000,
            progress: 0,
            unit: "L",
            isLocked: true,
            dateUnlocked: nil
        ),
        Achievement(
            title: "Green Diet",
            description: "Choose 30 vegetarian meals",
            icon: "leaf",
            initialRequirement: 30,
            requirement: 30,
            progress: 0,
            unit: "meals",
            isLocked: true,
            dateUnlocked: nil
        )
    ]
    
    @Published var streak: Streak
    @Published var showAchievementUnlocked = false
    @Published var lastUnlockedAchievement: Achievement?
    @Published var achievementHistory: [AchievementHistory] = []
    
    let calculator = EmissionCalculator()
    
    private var dailyHabits: [Habit] {
        habits.filter { $0.frequency == .daily }
    }
    
    init() {
        self.streak = Streak(count: 0, lastUpdated: nil, completedTasks: [])
        // ... existing init code ...
        
        // Check if we need to reset daily habits
        checkAndResetDailyProgress()
    }
    
    func checkAndResetDailyProgress() {
        let calendar = Calendar.current
        let currentDate = Date()
        
        guard let lastDate = streak.lastUpdated else {
            streak.lastUpdated = currentDate
            return
        }
        
        if !calendar.isDateInToday(lastDate) {
            let dailyHabits = habits.filter { $0.frequency == .daily }
            let yesterdayCompleted = dailyHabits.allSatisfy { $0.isCompleted }
            
            if !yesterdayCompleted || !calendar.isDateInYesterday(lastDate) {
                streak.count = 0
            }
            
            for index in habits.indices where habits[index].frequency == .daily {
                habits[index].isCompleted = false
            }
            
            streak.completedTasks.removeAll()
            streak.lastUpdated = currentDate
        }
    }
    
    @MainActor func updateStreak(habitId: UUID) {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Add to completed tasks
        streak.completedTasks.insert(habitId)
        
        // Get all daily habits
        let dailyHabits = habits.filter { $0.frequency == .daily }
        
        // Check if all daily habits are completed
        let allDailyHabitsCompleted = dailyHabits.allSatisfy { $0.isCompleted }
        
        if allDailyHabitsCompleted {
            // If this is the first completion or a new day
            if streak.count == 0 || (streak.lastUpdated != nil && !calendar.isDateInToday(streak.lastUpdated!)) {
                withAnimation(.spring(response: 0.3)) {
                    streak.count += 1
                }
                
                // Trigger haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            streak.lastUpdated = currentDate
        }
        
        objectWillChange.send()
    }
    
    func updateTotalCO2Savings() {
        var total = 0.0
        for habit in habits where habit.isCompleted {
            let impact = calculator.calculateEmission(
                activity: habit.activity,
                value: habit.value
            )
            total += abs(impact)
        }
        totalCO2Saved = total
        updateAchievements()
    }
    
    func levelUpAchievement(_ achievement: Achievement) {
        if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
            // Store the completed achievement in history
            achievementHistory.append(AchievementHistory(
                achievement: achievements[index],
                completedDate: Date(),
                level: achievements[index].level,
                co2Impact: calculateCO2Impact(for: achievements[index])
            ))
            
            // Create next level achievement
            let nextLevel = achievement.nextLevel()
            achievements[index] = nextLevel
            
            // Show achievement completion notification
            lastUnlockedAchievement = achievement
            showAchievementUnlocked = true
            
            // Trigger haptic feedback
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
    
    func updateAchievements() {
        checkAndResetDailyProgress()
        
        // Reset all achievements progress first
        for index in achievements.indices {
            achievements[index].progress = 0
        }
        
        // Calculate total progress for each achievement type from all completed habits
        for habit in habits {
            if habit.isCompleted {
                switch habit.activity {
                case "car":
                    if let index = achievements.firstIndex(where: { $0.title == "Cycling Champion" }) {
                        achievements[index].progress += Int(abs(habit.value))
                        checkAchievementCompletion(at: index)
                    }
                    
                case "recycling":
                    if let index = achievements.firstIndex(where: { $0.title == "Waste Warrior" }) {
                        achievements[index].progress += Int(habit.value)
                        checkAchievementCompletion(at: index)
                    }
                    
                case "water":
                    if let index = achievements.firstIndex(where: { $0.title == "Water Saver" }) {
                        achievements[index].progress += Int(abs(habit.value))
                        checkAchievementCompletion(at: index)
                    }
                    
                case "vegetarian_meal":
                    if let index = achievements.firstIndex(where: { $0.title == "Green Diet" }) {
                        achievements[index].progress += Int(habit.value)
                        checkAchievementCompletion(at: index)
                    }
                    
                case "tree_planted":
                    if let index = achievements.firstIndex(where: { $0.title == "Tree Guardian" }) {
                        achievements[index].progress += Int(habit.value)
                        checkAchievementCompletion(at: index)
                    }
                    
                default:
                    break
                }
            }
        }
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    private func checkAchievementCompletion(at index: Int) {
        if achievements[index].progress >= achievements[index].requirement {
            levelUpAchievement(achievements[index])
        }
    }
    
    // Update toggleHabit function in HabitRow
    @MainActor func toggleHabit(_ habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].isCompleted.toggle()
            
            if habits[index].isCompleted {
                updateStreak(habitId: habit.id)
                var updatedStats = habits[index].statistics
                updatedStats.trackCompletion(
                    co2Impact: calculator.calculateEmission(
                        activity: habit.activity,
                        value: habit.value
                    )
                )
                habits[index].statistics = updatedStats
            }
            
            // Update total CO2 savings and achievements
            updateTotalCO2Savings()
            updateAchievements()
        }
    }
    
    // Update the computed properties
    var completedAchievements: [Achievement] {
        achievements.filter { !$0.isLocked }.sorted { $0.dateUnlocked ?? Date() > $1.dateUnlocked ?? Date() }
    }
    
    var nextAchievement: Achievement? {
        achievements.first { $0.isLocked }
    }
    
    private func calculateCO2Impact(for achievement: Achievement) -> Double {
        switch achievement.title {
        case "Cycling Champion":
            return calculator.calculateEmission(activity: "car", value: -Double(achievement.requirement))
        case "Waste Warrior":
            return calculator.calculateEmission(activity: "recycling", value: Double(achievement.requirement))
        case "Water Saver":
            return calculator.calculateEmission(activity: "water", value: -Double(achievement.requirement))
        case "Green Diet":
            return calculator.calculateEmission(activity: "vegetarian_meal", value: Double(achievement.requirement))
        default:
            return 0
        }
    }
    
    func deleteHabit(_ habit: Habit) {
        withAnimation {
            // If the habit was completed, subtract its CO2 impact
            if habit.isCompleted {
                let co2Impact = calculator.calculateEmission(
                    activity: habit.activity,
                    value: habit.value
                )
                totalCO2Saved -= abs(co2Impact)
            }
            
            // Remove the habit
            habits.removeAll { $0.id == habit.id }
            
            // Update achievements
            updateAchievements()
            
            // Update streak if needed
            if habit.isCompleted {
                streak.completedTasks.remove(habit.id)
                // Reset streak if no more completed tasks for today
                if streak.completedTasks.isEmpty {
                    streak.count = 0
                }
            }
            
            // Notify UI of changes
            objectWillChange.send()
        }
    }
}

struct AchievementHistory: Identifiable {
    let id = UUID()
    let achievement: Achievement
    let completedDate: Date
    let level: Int
    let co2Impact: Double
}

struct HabitStatistics: Equatable, Sendable {
    var completionCount: Int = 0
    var lastCompletedDate: Date?
    var streakCount: Int = 0
    var completionHistory: [Date] = []
    var co2Saved: Double = 0
    
    mutating func trackCompletion(co2Impact: Double) {
        completionCount += 1
        let now = Date()
        completionHistory.append(now)
        lastCompletedDate = now
        co2Saved += abs(co2Impact)
        
        // Update streak
        if let last = lastCompletedDate,
           Calendar.current.isDateInYesterday(last) {
            streakCount += 1
        } else {
            streakCount = 1
        }
    }
    
    // Add Equatable conformance
    static func == (lhs: HabitStatistics, rhs: HabitStatistics) -> Bool {
        lhs.completionCount == rhs.completionCount &&
        lhs.lastCompletedDate == rhs.lastCompletedDate &&
        lhs.streakCount == rhs.streakCount &&
        lhs.completionHistory == rhs.completionHistory &&
        lhs.co2Saved == rhs.co2Saved
    }
}

// First, add the EcoTip model
struct EcoTip: Identifiable, Codable {
    let id = UUID()
    let tip: String
    let fact: String
    let category: String
    let impact: String
}

// Update EcoBanner with better design
@available(iOS 18.0, *)
struct EcoBanner: View {
    let tip: EcoTip
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isAnimating ? 10 : -10))
                        .animation(
                            Animation.easeInOut(duration: 1)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Eco Tip")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(tip.tip)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text(tip.impact)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.vertical, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: "34C759"), Color(hex: "30B346")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
        .padding(.horizontal)
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

// Add Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Update StreakAnimation with one-time animation
struct StreakAnimation: View {
    let count: Int
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 1.0 : 0.7)
            
            Text("\(count)")
                .font(.headline)
                .foregroundColor(.orange)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        )
        .onChange(of: count) { newCount in
            if newCount > 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isAnimating = true
                }
                // Reset animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        isAnimating = false
                    }
                }
            }
        }
    }
}

// Add new component for impact comparisons
struct ImpactComparison: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.system(size: 20))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

struct OnboardingScreen: View {
    @Binding var isFirstLaunch: Bool
    @State private var currentPage = 0
    
    let pages = [
        OnboardingPage(
            title: "Welcome to CarbonQuest",
            description: "Your journey to a sustainable future starts here. Track habits, reduce emissions, and make a real impact on our planet.",
            icon: "leaf.circle.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Track Your Impact",
            description: "Monitor your daily eco-friendly habits and see how much CO₂ you're saving with each action.",
            icon: "chart.line.uptrend.xyaxis",
            color: .blue
        ),
        OnboardingPage(
            title: "Earn Achievements",
            description: "Complete challenges and unlock achievements as you build sustainable habits.",
            icon: "trophy.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "Make a Difference",
            description: "Join thousands of others in the quest to create a greener, cleaner planet for future generations.",
            icon: "globe.americas.fill",
            color: .green
        )
    ]
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Bottom section with indicators and button
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Action button
                    Button {
                        withAnimation {
                            isFirstLaunch = false
                        }
                    } label: {
                        Text(currentPage == pages.count - 1 ? "Make Your Impact" : "Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.green.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .background(Color.white)
            }
        }
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundColor(page.color)
                    .scaleEffect(isAnimating ? 1.0 : 0.7)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }
            .padding(.top, 60)
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }
}














 
