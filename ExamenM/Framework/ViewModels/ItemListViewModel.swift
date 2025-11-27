import Foundation
import Combine

class ItemListViewModel: ObservableObject {
    @Published var items = [ItemBase]()
    var listReq: ItemListRequirementProtocol
    var detailReq: ItemDetailRequirementProtocol
    
    init(listReq: ItemListRequirementProtocol = ItemListRequirement.shared,
         detailReq: ItemDetailRequirementProtocol = ItemDetailRequirement.shared) {
        self.listReq = listReq
        self.detailReq = detailReq
    }
    
    @MainActor
    func loadItems(limit: Int? = nil) async {
        // Fetch the catalog (list of countries)
        let result = await listReq.getItemCatalog(limit: limit)
        guard let refs = result?.results else { return }
        
        self.items = [] // Clear existing
        
        for ref in refs {
            // For COVID app, the "ID" is the country name.
            // The URL is ...?country=Name
            // We can extract the name from the ref.name directly.
            let id = ref.name
            
            // We fetch the detail to populate the list with some data (like cases) if needed,
            // or just to have the object ready.
            // The prompt says "Lista navega a Detalle; muestra imagen si existe".
            // We can fetch details lazily or upfront.
            // Given the loop in the prompt example, it fetches detail for EACH item.
            // We will do the same.
            
            let detail = await detailReq.getItemDetail(id: id)
            self.items.append(ItemBase(id: id, ref: ref, detail: detail))
        }
    }
}
