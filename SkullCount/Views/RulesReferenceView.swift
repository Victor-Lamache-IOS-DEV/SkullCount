import SwiftUI

public struct RulesReferenceView: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PirateTheme.midnightNavy.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Deck Composition
                        deckCompositionCard
                        
                        // Card Hierarchy
                        hierarchyCard
                        
                        // Scoring Rules Summary
                        scoringRulesCard
                        
                        // Bonuses
                        bonusRulesCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Aide & Règles Skull King")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                        .foregroundColor(PirateTheme.gold)
                }
            }
        }
    }
    
    private var deckCompositionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "menucard.fill")
                    .foregroundColor(PirateTheme.gold)
                Text("Composition de l'Édition Classique (66 cartes)")
                    .font(.headline)
                    .foregroundColor(PirateTheme.gold)
            }
            
            Text("• 52 Cartes de Couleur : 4 couleurs × valeurs 1 à 13.\n  (Noir = Jolly Roger / Atout, Jaune, Rouge, Vert)\n• 5 Pirates : battent toutes les couleurs.\n• 5 Fuites : perdent toujours le pli (sauf si 100% de fuites).\n• 2 Sirènes : battent les cartes de couleur et le Skull King !\n• 1 Scary Mary : se joue soit en Fuite, soit en Pirate.\n• 1 Skull King : bat toutes les couleurs et tous les Pirates.")
                .font(.caption)
                .foregroundColor(PirateTheme.parchment)
                .lineSpacing(4)
        }
        .pirateCard()
    }
    
    private var hierarchyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(PirateTheme.gold)
                Text("Hiérarchie des Cartes Spéciales")
                    .font(.headline)
                    .foregroundColor(PirateTheme.gold)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                hierarchyRow(title: "Sirène 🧜‍♀️ bat le Skull King 👑", desc: "La sirène envoûte le Roi des Pirates et gagne le pli.")
                hierarchyRow(title: "Skull King 👑 bat les Pirates 🏴‍☠️", desc: "Le Skull King terrasse tous les pirates.")
                hierarchyRow(title: "Pirate 🏴‍☠️ bat la Sirène 🧜‍♀️", desc: "Les pirates capturent les sirènes.")
                hierarchyRow(title: "Couleur Noire (Atout) bat Couleurs normales", desc: "En cas d'absence de cartes spéciales.")
            }
        }
        .pirateCard()
    }
    
    private func hierarchyRow(title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(PirateTheme.parchment)
            Text(desc)
                .font(.caption2)
                .foregroundColor(PirateTheme.parchment.opacity(0.7))
        }
        .padding(.vertical, 2)
    }
    
    private var scoringRulesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(PirateTheme.gold)
                Text("Calcul des Scores")
                    .font(.headline)
                    .foregroundColor(PirateTheme.gold)
            }
            
            Text("Si Pari ≥ 1 :\n• Plis == Pari : +20 × Pari (+ bonus éventuels)\n• Plis != Pari : −10 × |Plis − Pari| (aucun bonus)\n\nSi Pari == 0 :\n• Plis == 0 : +10 × Cartes distribuées (+ bonus)\n• Plis ≥ 1 : −10 × Cartes distribuées (aucun bonus)")
                .font(.caption)
                .foregroundColor(PirateTheme.parchment)
                .lineSpacing(4)
        }
        .pirateCard()
    }
    
    private var bonusRulesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(PirateTheme.gold)
                Text("Bonus de Capture (Si activés)")
                    .font(.headline)
                    .foregroundColor(PirateTheme.gold)
            }
            
            Text("Les bonus ne comptent QUE si le joueur a réussi son pari !\n• +30 pts par Pirate capturé par le Skull King (Scary Mary compte comme un pirate).\n• +50 pts si une Sirène capture le Skull King.")
                .font(.caption)
                .foregroundColor(PirateTheme.parchment)
                .lineSpacing(3)
        }
        .pirateCard()
    }
}
