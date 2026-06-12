import Foundation
import SwiftUI
import NyoraEngine

@MainActor
final class WelcomeViewModel: ObservableObject {
    @Published var locales: [Locale] = []
    @Published var selectedLocales: Set<Locale> = []
    @Published var selectedTypes: Set<ContentType> = [.manga]
    
    @Published var isSigningIn = false
    @Published var errorMessage: String? = nil
    
    private let allSources: [MangaParserSource]
    
    init() {
        self.allSources = SourceRegistry.shared.all
        
        let codes = Set(allSources.compactMap { $0.locale ?? "multi" })
        self.locales = codes.map { Locale(identifier: $0) }.sorted { 
            $0.identifier < $1.identifier 
        }
        
        // Default selection: English + Multi
        self.selectedLocales = Set(locales.filter { 
            $0.identifier == "en" || $0.identifier == "multi" 
        })
    }
    
    func toggleLocale(_ locale: Locale) {
        if selectedLocales.contains(locale) {
            selectedLocales.remove(locale)
        } else {
            selectedLocales.insert(locale)
        }
    }
    
    func toggleType(_ type: ContentType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }
    
    func finishSetup() {
        let enabledLocales = Set(selectedLocales.map(\.identifier))
        let enabledSources = allSources.filter { src in
            let loc = src.locale ?? "multi"
            return enabledLocales.contains(loc) && selectedTypes.contains(src.contentType)
        }
        SourcePrefs.shared.setSourcesEnabledExclusive(Set(enabledSources))
    }
}

extension Locale {
    func getDisplayName() -> String {
        if identifier == "multi" { return "Various languages" }
        return Locale.current.localizedString(forIdentifier: identifier) ?? identifier.uppercased()
    }
}
