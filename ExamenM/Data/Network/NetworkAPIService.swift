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
        let requestedCountry = url.query?.components(separatedBy: "country=").last?.components(separatedBy: "&").first ?? "Canada"
        
        print("DEBUG: findAndMap - Requested: \(requestedCountry)")
        print("DEBUG: Available regions in JSON: \(items.map { $0.region })")
        
        // Mapeo de Países a Regiones disponibles en el JSON (Simulación)
        let regionMapping: [String: String] = [
            "Mexico": "Alberta",
            "Canada": "British Columbia",
            "Italy": "Diamond Princess",
            "France": "Grand Princess",
            "Germany": "Manitoba",
            "Japan": "New Brunswick",
            "Brazil": "Newfoundland and Labrador",
            "Argentina": "Northwest Territories",
            "Spain": "Nova Scotia",
            "India": "Nunavut",
            "United Kingdom": "Ontario",
            "USA": "Quebec"
        ]
        
        var item: NinjaCovidResponse?
        
        // 1. Intentar buscar por región mapeada
        if let mappedRegion = regionMapping[requestedCountry] {
            print("DEBUG: Mapping \(requestedCountry) -> \(mappedRegion)")
            item = items.first(where: { $0.region == mappedRegion })
            if item != nil { print("DEBUG: Found by region mapping") }
        } else {
            print("DEBUG: No mapping found for \(requestedCountry)")
        }
        
        // 2. Si no hay mapeo o no se encuentra, buscar por nombre de país (fallback)
        if item == nil {
            print("DEBUG: Falling back to country name search")
            item = items.first(where: { $0.country.lowercased() == requestedCountry.lowercased() })
        }
        
        // 3. Último recurso: devolver el primero
        if item == nil {
            print("DEBUG: Falling back to first item (Alberta)")
            item = items.first
        }
        
        guard let validItem = item else { return nil }
        
        print("DEBUG: Selected item region: \(validItem.region)")
        
        // Pasamos el nombre del país solicitado para que la UI muestre "Mexico" aunque los datos sean de "Alberta"
        return mapToItemDetail(item: validItem, overrideCountryName: requestedCountry)
    }
    
    private func mapToItemDetail(item: NinjaCovidResponse, overrideCountryName: String) -> ItemDetail {
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
            id: overrideCountryName, // Usar el nombre del país como ID
            title: overrideCountryName, // Mostrar el nombre del país solicitado
            description: "Datos simulados para \(overrideCountryName) (Fuente: \(item.region), \(item.country)). Última actualización: \(latestDate)",
            media: Media(primary: imageUrl, secondary: nil),
            attributes: attributes,
            stats: stats,
            history: item.cases // Pasar el historial completo para el filtrado por fecha
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
