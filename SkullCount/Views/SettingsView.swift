import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .commaSeparatedText] }
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.text = String(decoding: data, as: UTF8.self)
        } else {
            self.text = ""
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

public struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allGames: [Game]
    @Query private var allPlayers: [Player]
    
    @State private var showingExportSheet: Bool = false
    @State private var exportDocument: TextDocument? = nil
    @State private var exportFileName: String = "skullking-export.json"
    
    @State private var showingFileImporter: Bool = false
    @State private var importMode: ExportImportService.ImportMode = .mergeByUUID
    @State private var showingReplaceAlert: Bool = false
    @State private var pendingImportData: Data? = nil
    
    @State private var statusMessage: String = ""
    @State private var showingStatusAlert: Bool = false
    
    // Hidden Demo Data trigger
    @State private var demoTapCount: Int = 0
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PirateTheme.midnightNavy.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Data Statistics Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Base locale")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(PirateTheme.gold)
                            
                            HStack {
                                Text("\(allPlayers.count) joueurs enregistrés")
                                Spacer()
                                Text("\(allGames.count) parties")
                            }
                            .font(.subheadline)
                            .foregroundColor(PirateTheme.parchment)
                        }
                        .pirateCard()
                        
                        // Export Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sauvegarde et Export")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(PirateTheme.gold)
                            
                            Button(action: exportJSON) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up.fill")
                                    Text("Exporter tout l'historique (JSON)")
                                }
                                .font(.headline)
                                .foregroundColor(PirateTheme.midnightNavy)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(RoundedRectangle(cornerRadius: 12).fill(PirateTheme.gold))
                            }
                            
                            Button(action: exportCSV) {
                                HStack {
                                    Image(systemName: "tablecells.badge.ellipsis")
                                    Text("Exporter les manches (CSV)")
                                }
                                .font(.subheadline)
                                .foregroundColor(PirateTheme.gold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(RoundedRectangle(cornerRadius: 10).fill(PirateTheme.deepNavy))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(PirateTheme.gold, lineWidth: 1))
                            }
                        }
                        .pirateCard()
                        
                        // Import Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Restauration et Import")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(PirateTheme.gold)
                            
                            Button(action: {
                                importMode = .mergeByUUID
                                showingFileImporter = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text("Importer un fichier JSON (Fusion)")
                                }
                                .font(.subheadline)
                                .foregroundColor(PirateTheme.emerald)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(RoundedRectangle(cornerRadius: 10).fill(PirateTheme.deepNavy))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(PirateTheme.emerald, lineWidth: 1))
                            }
                            
                            Button(action: {
                                importMode = .fullReplace
                                showingReplaceAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                                    Text("Remplacement complet (Écraser)")
                                }
                                .font(.caption)
                                .foregroundColor(PirateTheme.crimson)
                            }
                        }
                        .pirateCard()
                        
                        // App Info & Secret Demo Data Generator
                        VStack(spacing: 6) {
                            Text("SkullCount v1.0.0")
                                .font(.caption)
                                .foregroundColor(PirateTheme.parchment.opacity(0.6))
                                .onTapGesture {
                                    demoTapCount += 1
                                    if demoTapCount >= 5 {
                                        demoTapCount = 0
                                        DemoDataGenerator.generateDemoData(modelContext: modelContext, gameCount: 20)
                                        statusMessage = "20 parties de test et 8 joueurs pirates générés avec succès !"
                                        showingStatusAlert = true
                                    }
                                }
                            
                            Text("100% Hors-ligne • Données conservées localement")
                                .font(.caption2)
                                .foregroundColor(PirateTheme.parchment.opacity(0.4))
                        }
                        .padding(.top, 16)
                    }
                    .padding()
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .fileExporter(
                isPresented: $showingExportSheet,
                document: exportDocument,
                contentType: exportFileName.hasSuffix(".csv") ? .commaSeparatedText : .json,
                defaultFilename: exportFileName
            ) { result in
                switch result {
                case .success(let url):
                    statusMessage = "Fichier exporté avec succès vers \(url.lastPathComponent)"
                    showingStatusAlert = true
                case .failure(let error):
                    statusMessage = "Erreur lors de l'export : \(error.localizedDescription)"
                    showingStatusAlert = true
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    handleImport(url: url)
                case .failure(let error):
                    statusMessage = "Erreur sélection fichier : \(error.localizedDescription)"
                    showingStatusAlert = true
                }
            }
            .alert("Écraser toutes les données ?", isPresented: $showingReplaceAlert) {
                Button("Continuer", role: .destructive) {
                    showingFileImporter = true
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cette action va supprimer tous les joueurs et toutes les parties existantes pour les remplacer par le contenu du fichier JSON importé.")
            }
            .alert("Information", isPresented: $showingStatusAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(statusMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func exportJSON() {
        do {
            let data = try ExportImportService.shared.exportFullJSON(modelContext: modelContext)
            let str = String(decoding: data, as: UTF8.self)
            let dateStr = ISO8601DateFormatter().string(from: Date()).prefix(10)
            exportFileName = "skullking-export-\(dateStr).json"
            exportDocument = TextDocument(text: str)
            showingExportSheet = true
        } catch {
            statusMessage = "Erreur d'exportation : \(error.localizedDescription)"
            showingStatusAlert = true
        }
    }
    
    private func exportCSV() {
        do {
            let csv = try ExportImportService.shared.exportRoundEntriesCSV(modelContext: modelContext)
            let dateStr = ISO8601DateFormatter().string(from: Date()).prefix(10)
            exportFileName = "skullking-rounds-\(dateStr).csv"
            exportDocument = TextDocument(text: csv)
            showingExportSheet = true
        } catch {
            statusMessage = "Erreur d'exportation CSV : \(error.localizedDescription)"
            showingStatusAlert = true
        }
    }
    
    private func handleImport(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            statusMessage = "Impossible d'accéder au fichier sécurisé."
            showingStatusAlert = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let (playersCount, gamesCount) = try ExportImportService.shared.importJSON(data: data, mode: importMode, modelContext: modelContext)
            statusMessage = "Import réussi ! \(playersCount) joueur(s) et \(gamesCount) partie(s) synchronisés."
            showingStatusAlert = true
        } catch {
            statusMessage = "Échec de l'import : \(error.localizedDescription)"
            showingStatusAlert = true
        }
    }
}
