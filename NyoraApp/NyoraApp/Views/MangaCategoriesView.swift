import SwiftUI
import NyoraEngine

struct MangaCategoriesView: View {
    @EnvironmentObject var model: AppModel
    @State private var newName = ""

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New category", text: $newName)
                    Button("Add") {
                        let n = newName.trimmingCharacters(in: .whitespaces)
                        if !n.isEmpty { model.addCategory(n); newName = "" }
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            Section {
                if model.categories.isEmpty {
                    Text("No categories yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(model.categories) { cat in Text(cat.name) }
                        .onDelete { idx in idx.map { model.categories[$0].id }.forEach(model.deleteCategory) }
                }
            }
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
    }
}
