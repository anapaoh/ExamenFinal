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
    
    private var cachedItems: [NinjaCovidResponse]?
    
    func getItemDetail(url: URL) async -> ItemDetail? {
        // SIMULATION MODE: Load from local JSON
        
        // 1. Check cache first
        if let cached = cachedItems {
            return findAndMap(items: cached, url: url)
        }
        
        print("NetworkAPIService: Loading local simulation data (200_covid.json)")
        
        guard let fileUrl = Bundle.main.url(forResource: "200_covid", withExtension: "json") else {
            print("NetworkAPIService: Error - 200_covid.json not found in Bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            let items = try JSONDecoder().decode([NinjaCovidResponse].self, from: data)
            
            // 2. Save to cache
            self.cachedItems = items
            print("NetworkAPIService: Cached \(items.count) items")
            
            return findAndMap(items: items, url: url)
            
        } catch {
            print("NetworkAPIService: Error decoding local JSON: \(error)")
            return nil
        }
    }
    
    private func findAndMap(items: [NinjaCovidResponse], url: URL) -> ItemDetail? {
        // Extract country name from URL
        let requestedCountry = url.query?.components(separatedBy: "country=").last?.components(separatedBy: "&").first
        
        let item: NinjaCovidResponse?
        if let req = requestedCountry {
            // Try to find exact match (case insensitive)
            item = items.first(where: { $0.country.lowercased() == req.lowercased() }) ?? items.first
        } else {
            item = items.first
        }
        
        guard let validItem = item else { return nil }
        
        return mapToItemDetail(item: validItem)
    }
    
    private func mapToItemDetail(item: NinjaCovidResponse) -> ItemDetail {
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
