import Foundation
import Combine

class ComparisonViewModel: ObservableObject {
    @Published var allCountries: [ItemBase] = []
    @Published var selectedCountries: [ItemBase] = []
    @Published var searchText = ""
    
    var listReq: ItemListRequirementProtocol
    var detailReq: ItemDetailRequirementProtocol
    
    var filteredCountries: [ItemBase] {
        if searchText.isEmpty {
            return allCountries
        } else {
            return allCountries.filter { $0.ref.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    init(listReq: ItemListRequirementProtocol = ItemListRequirement.shared,
         detailReq: ItemDetailRequirementProtocol = ItemDetailRequirement.shared) {
        self.listReq = listReq
        self.detailReq = detailReq
    }
    
    @MainActor
    func loadCatalog() async {
        let result = await listReq.getItemCatalog(limit: nil)
        guard let refs = result?.results else { return }
        
        self.allCountries = refs.map { ItemBase(id: $0.name, ref: $0, detail: nil) }
    }
    
    @MainActor
    func toggleSelection(for item: ItemBase) async {
        if let index = selectedCountries.firstIndex(where: { $0.id == item.id }) {
            selectedCountries.remove(at: index)
        } else {
            // Fetch detail if needed before adding
            var newItem = item
            if newItem.detail == nil {
                newItem.detail = await detailReq.getItemDetail(id: newItem.id)
            }
            selectedCountries.append(newItem)
        }
    }
    
    func isSelected(_ item: ItemBase) -> Bool {
        selectedCountries.contains(where: { $0.id == item.id })
    }
}
