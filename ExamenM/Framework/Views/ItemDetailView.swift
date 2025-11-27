import SwiftUI
import SDWebImageSwiftUI

struct ItemDetailView: View {
    let item: ItemBase
    
    @State private var filterMode: FilterMode = .single
    @State private var selectedDate = Date()
    @State private var startDate = Date()
    @State private var endDate = Date()
    
    enum FilterMode: String, CaseIterable, Identifiable {
        case single = "Día Específico"
        case range = "Rango de Fechas"
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ScrollView {
            if item.detail == nil {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.orange)
                    Text("No hay datos disponibles para \(item.ref.name)")
                        .font(.headline)
                    Text("Por favor verifica la conexión o la API Key.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    if let urlStr = item.detail?.media?.primary, let url = URL(string: urlStr) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                    }
                    
                    Text(item.detail?.title ?? item.ref.name)
                        .font(.title.bold())
                    
                    if let desc = item.detail?.description {
                        Text(desc)
                            .foregroundColor(.secondary)
                    }
                    
                    if let attrs = item.detail?.attributes, !attrs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Atributos")
                                .font(.headline)
                            ForEach(attrs, id: \.name) { a in
                                HStack {
                                    Text(a.name)
                                    Spacer()
                                    Text(a.value ?? "—")
                                        .foregroundColor(.secondary)
                                }
                                Divider()
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    if let history = item.detail?.history {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Filtrar Datos")
                                .font(.headline)
                            
                            Picker("Modo", selection: $filterMode) {
                                ForEach(FilterMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.bottom, 8)
                            
                            if filterMode == .single {
                                DatePicker("Seleccionar Fecha", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                
                                Text("Estadísticas del \(formatDate(selectedDate))")
                                    .font(.headline)
                                    .padding(.top, 8)
                            } else {
                                VStack(spacing: 8) {
                                    DatePicker("Inicio", selection: $startDate, displayedComponents: .date)
                                    DatePicker("Fin", selection: $endDate, displayedComponents: .date)
                                }
                                .datePickerStyle(.compact)
                                
                                Text("Estadísticas del \(formatDate(startDate)) al \(formatDate(endDate))")
                                    .font(.headline)
                                    .padding(.top, 8)
                            }
                            
                            ForEach(displayedStats, id: \.name) { s in
                                VStack(spacing: 4) {
                                    HStack {
                                        Text(s.name)
                                        Spacer()
                                        Text("\(s.value)")
                                            .bold()
                                    }
                                    
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(height: 8)
                                            
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue)
                                                .frame(width: geo.size.width, height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            }
                        }
                    } else if let stats = item.detail?.stats, !stats.isEmpty {
                        // Fallback si no hay historial
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Estadísticas (Más recientes)")
                                .font(.headline)
                            
                            ForEach(stats, id: \.name) { s in
                                VStack(spacing: 4) {
                                    HStack {
                                        Text(s.name)
                                        Spacer()
                                        Text("\(s.value)")
                                            .bold()
                                    }
                                    
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(height: 8)
                                            
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.blue)
                                                .frame(width: geo.size.width, height: 8)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Inicializar fechas con la más reciente disponible
            if let history = item.detail?.history {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dates = history.keys.compactMap { formatter.date(from: $0) }.sorted()
                
                if let last = dates.last {
                    selectedDate = last
                    endDate = last
                    // Por defecto, rango de 7 días atrás
                    startDate = Calendar.current.date(byAdding: .day, value: -7, to: last) ?? last
                }
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    var displayedStats: [StatPair] {
        guard let history = item.detail?.history else {
            return []
        }
        
        if filterMode == .single {
            let key = formatDate(selectedDate)
            if let stats = history[key] {
                return [
                    StatPair(name: "Casos Totales", value: stats.total),
                    StatPair(name: "Casos Nuevos", value: stats.new)
                ]
            }
        } else {
            // Lógica de Rango
            // Casos Nuevos: Suma de 'new' en el rango
            // Casos Totales: Valor de 'total' en la fecha final (acumulado)
            
            let startKey = formatDate(startDate)
            let endKey = formatDate(endDate)
            
            // Filtrar claves dentro del rango
            let validKeys = history.keys.filter { key in
                key >= startKey && key <= endKey
            }
            
            var sumNew = 0
            for key in validKeys {
                sumNew += history[key]?.new ?? 0
            }
            
            // Para total, tomamos el de la fecha fin (o la más cercana disponible en el rango)
            // Si la fecha fin exacta no tiene datos, buscamos la máxima disponible en el rango
            let maxKey = validKeys.max() ?? endKey
            let totalAtEnd = history[maxKey]?.total ?? 0
            
            return [
                StatPair(name: "Casos Totales (al final del periodo)", value: totalAtEnd),
                StatPair(name: "Casos Nuevos (suma del periodo)", value: sumNew)
            ]
        }
        
        return [
            StatPair(name: "Casos Totales", value: 0),
            StatPair(name: "Casos Nuevos", value: 0)
        ]
    }
}
