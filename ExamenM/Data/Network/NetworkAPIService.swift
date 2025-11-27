import Foundation
import Alamofire

class NetworkAPIService {
    static let shared = NetworkAPIService()
    let apiKey = "dVMA4rEgWg82Bbs8p6YwWQ==xVTgwFkE8It1bMsv"
    
    func getCatalog(url: URL, limit: Int?) async -> ItemCatalog? {
        // Hardcoded list of countries for the catalog view
        let countries = ["Mexico", "Canada", "Italy", "France", "Germany", "Japan", "Brazil", "Argentina", "Spain", "India"]
        var results: [ItemRef] = []
        
        // Use a fixed recent date for the "snapshot" or just fetch the country.
        // To make it lighter, we could append a date, but we need to know a valid date with data.
        // COVID data stopped being tracked daily in many places. Let's stick to the country query 
        // but handle the response as we did (finding the latest date in the dictionary).
        // If we want to be safer about data size, we could pick a known past date like 2023-01-01.
        
        for country in countries {
            // URL to fetch details for this country
            // We will not append date here to ensure we get *some* data, 
            // as specific dates might be missing for some countries.
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
            if let jsonStr = String(data: data, encoding: .utf8) {
                print("Raw API Response: \(jsonStr)")
            }
            do {
                // Ninja API returns `[{country, region, cases, deaths, updated}, ...]`
                let items = try JSONDecoder().decode([NinjaCovidResponse].self, from: data)
                
                // Aggregate or pick the best item.
                // Often there is an entry with region="" representing the whole country, or we sum them.
                // Let's try to find region == "" first.
                let mainItem = items.first(where: { $0.region == "" }) ?? items.first
                
                guard let item = mainItem else {
                    print("No items found in response")
                    return nil
                }
                
                return mapToItemDetail(item: item)
                
            } catch {
                debugPrint("Error decoding: \(error)")
                return nil
            }
        case .failure(let err):
            debugPrint("Network Error: \(err.localizedDescription)")
            return nil
        }
    }
    
    private func mapToItemDetail(item: NinjaCovidResponse) -> ItemDetail {
        // Flag URL (using flagcdn)
        let imageUrl = "https://img.freepik.com/free-vector/coronavirus-2019-ncov-virus-background-design_1017-23767.jpg"
        
        // Find the latest date
        // The keys are dates "YYYY-MM-DD"
        let sortedDates = item.cases.keys.sorted().reversed()
        let latestDate = sortedDates.first ?? "Unknown"
        let latestStats = item.cases[latestDate]
        
        let totalCases = latestStats?.total ?? 0
        let newCases = latestStats?.new ?? 0
        
        let attributes = [
            NamedValue(name: "Region", value: item.region.isEmpty ? "All" : item.region),
            NamedValue(name: "Date", value: latestDate)
        ]
        
        let stats = [
            StatPair(name: "Total Cases", value: totalCases),
            StatPair(name: "New Cases", value: newCases)
        ]
        
        return ItemDetail(
            id: item.country,
            title: item.country,
            description: "COVID-19 Statistics for \(latestDate)",
            media: Media(primary: imageUrl, secondary: nil),
            attributes: attributes,
            stats: stats
        )
    }
}

struct NinjaCovidResponse: Codable {
    let country: String
    let region: String
    let cases: [String: CaseStats]
}

struct CaseStats: Codable {
    let total: Int
    let new: Int
}
