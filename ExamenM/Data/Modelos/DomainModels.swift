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
    var history: [String: CaseStats]? // Full history for date filtering
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
    let cases: Int?
}
