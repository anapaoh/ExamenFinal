import Foundation
import Alamofire

class NetworkAPIService {
    static let shared = NetworkAPIService()
    let apiKey = "dVMA4rEgWg82Bbs8p6YwWQ==xVTgwFkE8It1bMsv"
    
    func getCatalog(url: URL, limit: Int?) async -> ItemCatalog? {
        // Hardcoded list of countries for the catalog view
        let countries = ["Mexico", "Canada", "Italy", "France", "Germany", "Japan", "Brazil", "Argentina", "Spain", "India"]
        var results: [ItemRef] = []
        
        for country in countries {
            // URL to fetch details for this country
            let countryUrl = "https://api.api-ninjas.com/v1/covid19?country=\(country)"
            results.append(ItemRef(name: country, url: countryUrl))
        }
        
        return ItemCatalog(count: results.count, results: results)
    }
    
    func getItemDetail(url: URL) async -> ItemDetail? {
        let headers: HTTPHeaders = ["X-Api-Key": apiKey]
        
        let response = await AF.request(url, method: .get, headers: headers)
            .validate()
            .serializingData()
            .response
        
        switch response.result {
        case .success(let data):
            do {
                // Ninja API returns `[{country, region, cases, deaths, updated}, ...]`
                let items = try JSONDecoder().decode([NinjaCovidResponse].self, from: data)
                
                // Aggregate or pick the best item.
                // Often there is an entry with region="" representing the whole country, or we sum them.
                // Let's try to find region == "" first.
                let mainItem = items.first(where: { $0.region == "" }) ?? items.first
                
                guard let item = mainItem else { return nil }
                
                return mapToItemDetail(item: item)
                
            } catch {
                debugPrint("Error decoding: \(error)")
                return nil
            }
        case .failure(let err):
            debugPrint(err.localizedDescription)
            return nil
        }
    }
    
    private func mapToItemDetail(item: NinjaCovidResponse) -> ItemDetail {
        // Flag URL (using flagcdn)
        // Need country code. Since we only have name, we might need a map or just use a placeholder.
        // For simplicity, we'll use a generic image or try to guess.
        // Let's use a generic COVID image for all.
        let imageUrl = "https://img.freepik.com/free-vector/coronavirus-2019-ncov-virus-background-design_1017-23767.jpg"
        
        let attributes = [
            NamedValue(name: "Region", value: item.region.isEmpty ? "All" : item.region),
            NamedValue(name: "Updated", value: "\(item.updated)") // simplistic date
        ]
        
        let stats = [
            StatPair(name: "Cases", value: item.cases),
            StatPair(name: "Deaths", value: item.deaths)
        ]
        
        return ItemDetail(
            id: item.country,
            title: item.country,
            description: "COVID-19 Statistics",
            media: Media(primary: imageUrl, secondary: nil),
            attributes: attributes,
            stats: stats
        )
    }
}

struct NinjaCovidResponse: Codable {
    let country: String
    let region: String
    let cases: Int
    let deaths: Int
    let updated: Int // Timestamp
}
