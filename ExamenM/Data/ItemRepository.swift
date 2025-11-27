import Foundation

struct Api {
    static let base = "https://api.api-ninjas.com/v1"
    struct routes {
        static let items = "/covid19"
    }
}

protocol ItemAPIProtocol {
    func getItemCatalog(limit: Int?) async -> ItemCatalog?
    func getItemDetail(id: String) async -> ItemDetail? // Changed ID to String for Country Name
}

class ItemRepository: ItemAPIProtocol {
    static let shared = ItemRepository()
    let nservice: NetworkAPIService
    
    init(nservice: NetworkAPIService = NetworkAPIService.shared) {
        self.nservice = nservice
    }
    
    func getItemCatalog(limit: Int?) async -> ItemCatalog? {
        // The URL here is just a placeholder because NetworkAPIService mocks the catalog logic
        await nservice.getCatalog(url: URL(string: "\(Api.base)\(Api.routes.items)")!, limit: limit)
    }
    
    func getItemDetail(id: String) async -> ItemDetail? {
        // id is the Country Name
        // We need to encode it properly
        let encodedId = id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? id
        let urlString = "\(Api.base)\(Api.routes.items)?country=\(encodedId)"
        return await nservice.getItemDetail(url: URL(string: urlString)!)
    }
}
