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
    
    // Caché para evitar recargar/decodificar el JSON grande en cada llamada (Simulación)
    private var cachedItems: [NinjaCovidResponse]?
    
    // Caché para respuestas de API exitosas
    private var apiCache: [String: ItemDetail] = [:]
    
    func getItemDetail(url: URL) async -> ItemDetail? {
        let countryName = url.query?.components(separatedBy: "country=").last?.components(separatedBy: "&").first ?? "Unknown"
        
        // 1. Revisar caché de API
        if let cached = apiCache[countryName] {
            print("NetworkAPIService: Retornando \(countryName) desde caché de API")
            return cached
        }
        
        // 2. Intentar llamada a API en vivo
        print("NetworkAPIService: Intentando API en vivo para \(countryName)...")
        
        return await withCheckedContinuation { continuation in
            let headers: HTTPHeaders = ["X-Api-Key": apiKey]
            
            AF.request(url, headers: headers).responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let items = try JSONDecoder().decode([NinjaCovidResponse].self, from: data)
                        if let firstItem = items.first {
                            print("NetworkAPIService: Éxito API para \(countryName)")
                            let detail = self.mapToItemDetail(item: firstItem, overrideCountryName: countryName)
                            self.apiCache[countryName] = detail
                            continuation.resume(returning: detail)
                        } else {
                            print("NetworkAPIService: API retornó lista vacía para \(countryName). Usando fallback.")
                            continuation.resume(returning: self.loadLocalSimulation(url: url))
                        }
                    } catch {
                        print("NetworkAPIService: Error decodificando API: \(error). Usando fallback.")
                        continuation.resume(returning: self.loadLocalSimulation(url: url))
                    }
                case .failure(let error):
                    print("NetworkAPIService: Error de red: \(error). Usando fallback.")
                    continuation.resume(returning: self.loadLocalSimulation(url: url))
                }
            }
        }
    }
    
    private func loadLocalSimulation(url: URL) -> ItemDetail? {
        // MODO SIMULACIÓN: Cargar desde JSON local
        
        // 1. Revisar caché local primero
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
            
            // 2. Guardar en caché local
            self.cachedItems = items
            print("NetworkAPIService: Caché local \(items.count) ítems")
            
            return findAndMap(items: items, url: url)
            
        } catch {
            print("NetworkAPIService: Error decodificando JSON local: \(error)")
            return nil
        }
    }
    
    private func findAndMap(items: [NinjaCovidResponse], url: URL) -> ItemDetail? {
        // Extraer nombre del país de la URL
        let requestedCountry = url.query?.components(separatedBy: "country=").last?.components(separatedBy: "&").first ?? "Canada"
        
        print("DEBUG: findAndMap (Local) - Requested: \(requestedCountry)")
        
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
            item = items.first(where: { $0.region == mappedRegion })
        }
        
        // 2. Si no hay mapeo o no se encuentra, buscar por nombre de país (fallback)
        if item == nil {
            item = items.first(where: { $0.country.lowercased() == requestedCountry.lowercased() })
        }
        
        // 3. Último recurso: devolver el primero
        if item == nil {
            item = items.first
        }
        
        guard let validItem = item else { return nil }
        
        // Pasamos el nombre del país solicitado para que la UI muestre "Mexico" aunque los datos sean de "Alberta"
        return mapToItemDetail(item: validItem, overrideCountryName: requestedCountry)
    }
    
    private func mapToItemDetail(item: NinjaCovidResponse, overrideCountryName: String) -> ItemDetail {
        // Mapeo de nombres de países a códigos ISO para las banderas
        let countryCodes: [String: String] = [
            "Mexico": "mx",
            "Canada": "ca",
            "Italy": "it",
            "France": "fr",
            "Germany": "de",
            "Japan": "jp",
            "Brazil": "br",
            "Argentina": "ar",
            "Spain": "es",
            "India": "in",
            "United Kingdom": "gb",
            "USA": "us"
        ]
        
        let code = countryCodes[overrideCountryName] ?? "un" // 'un' for unknown/united nations as fallback
        let imageUrl = "https://flagcdn.com/w320/\(code).png"
        
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
