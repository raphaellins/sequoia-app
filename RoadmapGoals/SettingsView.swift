import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var goalStore: GoalStore
    @Environment(\.dismiss) var dismiss
    @State private var showingExportSheet = false
    @State private var showingImportAlert = false
    @State private var showingClearDataAlert = false
    @State private var importData: String = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Data Management")) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                        Text("Export Goals")
                        Spacer()
                        Text("\(goalStore.goals.count) goals")
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        showingExportSheet = true
                    }
                    
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                        Text("Import Goals")
                    }
                    .onTapGesture {
                        showingImportAlert = true
                    }
                    
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear All Data")
                    }
                    .onTapGesture {
                        showingClearDataAlert = true
                    }
                }
                
                Section(header: Text("Data Information")) {
                    HStack {
                        Text("Total Goals")
                        Spacer()
                        Text("\(goalStore.goals.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Active Goals")
                        Spacer()
                        Text("\(goalStore.activeGoals.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Completed Goals")
                        Spacer()
                        Text("\(goalStore.completedGoals.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Overdue Goals")
                        Spacer()
                        Text("\(goalStore.overdueGoals.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Data Safety")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Storage")
                            .font(.headline)
                        Text("Your goals are stored locally on this device using UserDefaults. They are automatically backed up to iCloud if you have iCloud backup enabled.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Loss Scenarios")
                            .font(.headline)
                        Text("• App deletion\n• Device factory reset\n• App reinstallation\n• Rare iOS update issues")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Debug")) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver")
                            .foregroundColor(.orange)
                        Text("Add Test Goals")
                    }
                    .onTapGesture {
                        goalStore.addTestGoals()
                    }
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Current Goals Count")
                        Spacer()
                        Text("\(goalStore.goals.count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(goalStore: goalStore)
        }
        .alert("Import Goals", isPresented: $showingImportAlert) {
            TextField("Paste JSON data here", text: $importData, axis: .vertical)
                .lineLimit(5...10)
            Button("Import") {
                importGoals()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Paste the exported JSON data to restore your goals.")
        }
        .alert("Clear All Data", isPresented: $showingClearDataAlert) {
            Button("Clear All", role: .destructive) {
                goalStore.clearAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all your goals. This action cannot be undone.")
        }
    }
    
    private func importGoals() {
        if goalStore.importGoals(from: importData) {
            importData = ""
            // Show success message
        } else {
            // Show error message
        }
    }
}

struct ExportView: View {
    let goalStore: GoalStore
    @Environment(\.dismiss) var dismiss
    @State private var showingCopyConfirmation = false
    @State private var copyButtonText = "Copy to Clipboard"
    @State private var exportData: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Export Your Goals")
                    .font(.title2)
                    .padding()
                
                Text("Copy this data to backup your goals:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Data Length: \(exportData.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(exportData.isEmpty ? "No data to export" : exportData)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                }
                .padding()
                
                Button(copyButtonText) {
                    copyToClipboard()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
                if showingCopyConfirmation {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Copied to clipboard!")
                            .foregroundColor(.green)
                    }
                    .font(.caption)
                    .padding(.bottom)
                }
                
                Spacer()
            }
            .navigationTitle("Export Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExportData()
            }
        }
    }
    
    private func loadExportData() {
        print("📱 ExportView.loadExportData: Loading data for \(goalStore.goals.count) goals")
        
        if let exported = goalStore.exportGoals() {
            exportData = exported
            print("✅ ExportView.loadExportData: Successfully loaded \(exported.count) characters")
        } else {
            exportData = "No data to export"
            print("❌ ExportView.loadExportData: Failed to load export data")
        }
    }
    
    private func copyToClipboard() {
        guard !exportData.isEmpty else {
            copyButtonText = "No Data"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                copyButtonText = "Copy to Clipboard"
            }
            return
        }
        
        // Try to copy to clipboard
        UIPasteboard.general.string = exportData
        
        // Show success feedback immediately (UIPasteboard is usually reliable)
        copyButtonText = "Copied!"
        showingCopyConfirmation = true
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copyButtonText = "Copy to Clipboard"
            showingCopyConfirmation = false
        }
        
        // Debug: Print to console to verify
        print("📋 Copied \(exportData.count) characters to clipboard")
        print("📋 First 100 characters: \(String(exportData.prefix(100)))")
    }
}

#Preview {
    SettingsView()
        .environmentObject(GoalStore())
}
