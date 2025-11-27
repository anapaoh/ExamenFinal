import Foundation

// Respuesta de “listado”
struct ItemCatalog: Codable {
    var count: Int
    var results: [ItemRef]
}

// Ítem “ligero” de la lista
struct ItemRef: Codable {
    var name: String
    var url: String
}

// Modelo que usa la UI
struct ItemBase: Identifiable {
    var id: String // Changed to String because Country Name is the ID
    var ref: ItemRef
    var detail: ItemDetail?
}

// Detalle del ítem (Adaptado a COVID)
struct ItemDetail: Codable {
    var id: String? // Country name
    var title: String? // Country name
    var description: String? // Region or Date
    var media: Media? // Flag
    var attributes: [NamedValue]? // Cases, Deaths, etc.
    var stats: [StatPair]? // Numeric stats for graphs
}

struct Media: Codable {
    var primary: String?
    var secondary: String?
}

struct NamedValue: Codable {
    var name: String
    var value: String?
}

struct StatPair: Codable {
    var name: String
    var value: Int
}

// Internal struct for API decoding (Ninja API)
struct NinjaCovidItem: Codable {
    let country: String
    let region: String
    let cases: Int? // Sometimes it's a dictionary, sometimes Int. Ninja API for /covid19 usually returns dictionary of dates if no date specified?
    // Let's check the documentation link provided in prompt: https://api-ninjas.com/api/covid19
    // "Returns current day's data for a country."
    // Response: [{ "country": "Canada", "region": "Alberta", "cases": 123, "deaths": 5, "updated": 123456 }]
    // It returns an array of regions.
    
    // We need to aggregate or just show the first one (Country level usually has region="")
    
    // Let's assume we map this to ItemDetail
    
    // Wait, if I request `?country=Canada`, it returns multiple entries (one per region).
    // I should probably sum them up or just take the main one.
    // For simplicity and "snapshot", I will take the first one or the one with region="" if exists.
}

