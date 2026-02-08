import SwiftUI
import Charts

struct HealthTrackingView: View {
    @Binding var profile: UserProfile
    @State private var showingAddSheet = false
    @State private var showingProfileSheet = false
    
    // Derived Data
    var weightData: [HealthLog] {
        profile.healthLogs.sorted { $0.date < $1.date }
    }
    
    var lastWeight: Double? {
        weightData.last?.weight
    }
    
    // Calculations
    var currentAge: Int? {
        guard let birthDate = profile.birthDate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }
    
    var currentBMI: Double? {
        guard let weight = lastWeight, let heightCm = profile.heightCm, heightCm > 0 else { return nil }
        let heightM = heightCm / 100.0
        return weight / (heightM * heightM)
    }
    
    var currentIMG: Double? {
        guard let bmi = currentBMI, let age = currentAge, let gender = profile.gender else { return nil }
        let genderFactor = (gender == .male) ? 1.0 : 0.0
        return (1.20 * bmi) + (0.23 * Double(age)) - (10.8 * genderFactor) - 5.4
    }
    
    func getIMGCategory(img: Double) -> (String, Color) {
        guard let gender = profile.gender else { return ("Unknown", .gray) }
        
        if gender == .male {
            switch img {
            case ..<8: return ("Essential Fat", .blue)
            case 8..<20: return ("Athletic", .green)
            case 20..<25: return ("Fitness", .mint)
            case 25..<30: return ("Average", .yellow)
            default: return ("Obese", .red)
            }
        } else {
            switch img {
            case ..<21: return ("Essential Fat", .blue)
            case 21..<33: return ("Athletic", .green)
            case 33..<39: return ("Fitness", .mint)
            case 39..<45: return ("Average", .yellow)
            default: return ("Obese", .red)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header & Profile Button
                HStack {
                    VStack(alignment: .leading) {
                        Text("Health & Metrics")
                            .font(.title3)
                            .bold()
                        if let last = lastWeight {
                            Text("\(String(format: "%.1f", last)) kg")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        } else {
                            Text("No data")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button(action: { showingProfileSheet = true }) {
                        VStack {
                            Image(systemName: "person.crop.circle")
                                .font(.title)
                            Text("Profile").font(.caption2)
                        }
                    }
                    .padding(.trailing, 8)
                    
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.themeBlue)
                    }
                }
                .padding(.horizontal)
                
                // IMG Gauge
                if let img = currentIMG, let gender = profile.gender {
                    let (category, color) = getIMGCategory(img: img)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Body Fat Index (IMG)").font(.headline)
                            Spacer()
                            Text(category)
                                .font(.caption).bold()
                                .padding(6)
                                .background(color.opacity(0.2))
                                .foregroundColor(color)
                                .cornerRadius(8)
                        }
                        
                        HStack {
                            ZStack {
                                Circle()
                                    .trim(from: 0.0, to: 0.75)
                                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .rotationEffect(.degrees(135))
                                    .frame(width: 100, height: 100)
                                
                                Circle()
                                    .trim(from: 0.0, to: min(CGFloat(img) / 50.0 * 0.75, 0.75))
                                    .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .rotationEffect(.degrees(135))
                                    .frame(width: 100, height: 100)
                                
                                VStack {
                                    Text(String(format: "%.1f%%", img))
                                        .font(.title3).bold()
                                }
                            }
                            .frame(width: 100, height: 100)
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Based on Deurenberg formula (BMI, Age, Gender).")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                if category == "Athletic" || category == "Fitness" {
                                    Text("Great job! Maintain this level for optimal performance.")
                                        .font(.caption).bold()
                                } else if category == "Average" {
                                    Text("Good. A slight reduction could improve race times.")
                                        .font(.caption)
                                } else {
                                    Text("Focus on nutrition and steady cardio to improve body composition.")
                                        .font(.caption)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(Color.themeCardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Complete your profile (Gender, Height, Birth Date) to see Body Fat analysis.")
                            .font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .onTapGesture { showingProfileSheet = true }
                }
                
                // Chart
                if !weightData.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Weight Trend").font(.headline).padding(.horizontal)
                        Chart {
                            ForEach(weightData) { log in
                                LineMark(
                                    x: .value("Date", log.date),
                                    y: .value("Weight", log.weight)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(Color.themeBlue.gradient)
                                
                                PointMark(
                                    x: .value("Date", log.date),
                                    y: .value("Weight", log.weight)
                                )
                                .foregroundStyle(Color.themeBlue)
                            }
                        }
                        .frame(height: 180)
                        .padding()
                        .background(Color.themeCardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                // Recommendations
                if let rec = getRecommendation() {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "stethoscope.circle.fill")
                            .font(.title2)
                            .foregroundColor(.themeOrange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Coach Insight")
                                .font(.headline)
                            Text(rec)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.themeCardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddHealthLogView(profile: $profile)
        }
        .sheet(isPresented: $showingProfileSheet) {
            ProfileEditView(profile: $profile)
        }
    }
    
    func getRecommendation() -> String? {
        guard weightData.count >= 2 else { return nil }
        let last = weightData.last!
        let prev = weightData[weightData.count - 2]
        
        let diff = last.weight - prev.weight
        if diff < -1.0 {
            return "Sudden weight drop detected (-1kg). Ensure you are hydrating properly after long sessions."
        } else if diff > 1.0 {
            return "Slight increase. Could be water retention or muscle gain. Monitor over next 3 days."
        } else {
            return "Weight is stable. Keep fueling consistently."
        }
    }
}

struct ProfileEditView: View {
    @Binding var profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Biometrics")) {
                    Picker("Gender", selection: Binding(
                        get: { profile.gender ?? .male },
                        set: { profile.gender = $0 }
                    )) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    
                    DatePicker("Birth Date", selection: Binding(
                        get: { profile.birthDate ?? Date() },
                        set: { profile.birthDate = $0 }
                    ), displayedComponents: .date)
                    
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("cm", value: $profile.heightCm, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Button("Done") { dismiss() }
            }
            .navigationTitle("Edit Profile")
        }
    }
}

struct AddHealthLogView: View {
    @Binding var profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    @State private var weightStr = ""
    @State private var bodyFatStr = ""
    @State private var feeling = 5.0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Metrics")) {
                    TextField("Weight (kg)", text: $weightStr)
                        .keyboardType(.decimalPad)
                    TextField("Body Fat % (Optional)", text: $bodyFatStr)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("How do you feel? (1-10)")) {
                    Slider(value: $feeling, in: 1...10, step: 1)
                    Text("Energy Level: \(Int(feeling))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button("Save Log") {
                    save()
                }
                .disabled(weightStr.isEmpty)
            }
            .navigationTitle("Log Health")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    func save() {
        guard let weight = Double(weightStr) else { return }
        let fat = Double(bodyFatStr)
        
        let log = HealthLog(
            date: Date(),
            weight: weight,
            bodyFatPercentage: fat,
            feeling: Int(feeling)
        )
        
        profile.healthLogs.append(log)
        dismiss()
    }
}
