import Foundation
import Alamofire

class NetworkAPIService {
    static let shared = NetworkAPIService()
    let apiKey = "dVMA4rEgWg82Bbs8p6YwWQ==xVTgwFkE8It1bMsv"
    
    func getCatalog(url: URL, limit: Int?) async -> ItemCatalog? {
        // Lista fija de países para la vista de catálogo
        let countries = ["Mexico", "Canada", "Italy", "France", "Germany", "Japan", "Brazil", "Argentina", "Spain", "India"]
        var results: [ItemRef] = []
        
        for country in countries {
            // URL para obtener detalles de este país
            // No agregaremos la fecha aquí para asegurar que obtenemos *algunos* datos,
            // ya que fechas específicas podrían faltar para algunos países.
            let countryUrl = "https://api.api-ninjas.com/v1/covid19?country=\(country)"
            results.append(ItemRef(name: country, url: countryUrl))
        }
        
        return ItemCatalog(count: results.count, results: results)
    }
    
    // Caché para evitar recargar/decodificar el JSON grande en cada llamada
    private var cachedItems: [NinjaCovidResponse]?
    
    func getItemDetail(url: URL) async -> ItemDetail? {
        // MODO SIMULACIÓN: Cargar desde JSON local
        
        // 1. Revisar caché primero
        if let cached = cachedItems {
            return findAndMap(items: cached, url: url)
        }
        
        print("NetworkAPIService: Cargando datos de simulación local (200_covid.json)")
        
        guard let fileUrl = Bundle.main.url(forResource: "200_covid", withExtension: "json") else {
            print("NetworkAPIService: Error - 200_covid.json no encontrado en el Bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            let items = try JSONDecoder().decode([NinjaCovidResponse].self, from: data)
            
            // 2. Guardar en caché
            self.cachedItems = items
            print("NetworkAPIService: Caché \(items.count) ítems")
            
            return findAndMap(items: items, url: url)
            
        } catch {
            print("NetworkAPIService: Error decodificando JSON local: \(error)")
            return nil
        }
    }
    
    private func findAndMap(items: [NinjaCovidResponse], url: URL) -> ItemDetail? {
        // Extraer nombre del país de la URL
        let requestedCountry = url.query?.components(separatedBy: "country=").last?.components(separatedBy: "&").first
        
        let item: NinjaCovidResponse?
        if let req = requestedCountry {
            // Intentar encontrar coincidencia exacta (sin distinguir mayúsculas/minúsculas)
            item = items.first(where: { $0.country.lowercased() == req.lowercased() }) ?? items.first
        } else {
            item = items.first
        }
        
        guard let validItem = item else { return nil }
        
        return mapToItemDetail(item: validItem)
    }
    
    private func mapToItemDetail(item: NinjaCovidResponse) -> ItemDetail {
        let imageUrl = "https://img.freepik.com/free-vector/coronavirus-2019-ncov-virus-background-design_1017-23767.jpg"
        
        // Ordenar fechas descendente
        let sortedDates = item.cases.keys.sorted().reversed()
        
        // Obtener la más reciente para estadísticas
        let latestDate = sortedDates.first ?? "Desconocida"
        let latestStats = item.cases[latestDate]
        
        let totalCases = latestStats?.total ?? 0
        let newCases = latestStats?.new ?? 0
        
        // Mapear historial a atributos (Top 10 días)
        var attributes = [NamedValue(name: "Región", value: item.region.isEmpty ? "Todas" : item.region)]
        
        for date in sortedDates.prefix(10) {
            if let data = item.cases[date] {
                let val = "Total: \(data.total) | Nuevos: \(data.new)"
                attributes.append(NamedValue(name: date, value: val))
            }
        }
        
        let stats = [
            StatPair(name: "Casos Totales", value: totalCases),
            StatPair(name: "Casos Nuevos", value: newCases)
        ]
        
        return ItemDetail(
            id: item.country,
            title: item.country,
            description: "Estadísticas COVID-19 (Últimos 10 días)",
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
