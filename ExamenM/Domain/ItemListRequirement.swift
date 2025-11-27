import Foundation

protocol ItemListRequirementProtocol {
    func getItemCatalog(limit: Int?) async -> ItemCatalog?
}

class ItemListRequirement: ItemListRequirementProtocol {
    static let shared = ItemListRequirement()
    let repo: ItemRepository
    
    init(repo: ItemRepository = ItemRepository.shared) {
        self.repo = repo
    }
    
    func getItemCatalog(limit: Int?) async -> ItemCatalog? {
        await repo.getItemCatalog(limit: limit)
    }
}
