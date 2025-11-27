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
        print("ItemListViewModel: loadItems called")
        // Fetch the catalog (list of countries)
        let result = await listReq.getItemCatalog(limit: limit)
        guard let refs = result?.results else {
            print("ItemListViewModel: No results in catalog")
            return
        }
        
        print("ItemListViewModel: Found \(refs.count) countries. Fetching details...")
        
        self.items = [] // Clear existing
        
        for ref in refs {
            let id = ref.name
            print("ItemListViewModel: Fetching detail for \(id)")
            
            let detail = await detailReq.getItemDetail(id: id)
            if detail == nil {
                print("ItemListViewModel: Detail is nil for \(id)")
            } else {
                print("ItemListViewModel: Detail received for \(id)")
            }
            self.items.append(ItemBase(id: id, ref: ref, detail: detail))
        }
        print("ItemListViewModel: Finished loading items")
    }
}
