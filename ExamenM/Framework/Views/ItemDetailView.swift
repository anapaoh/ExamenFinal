import SwiftUI
import SDWebImageSwiftUI
import Charts

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
                .padding(.top, 50)
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    // 1. Hero Header (Bandera)
                    if let urlStr = item.detail?.media?.primary, let url = URL(string: urlStr) {
                        WebImage(url: url)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipped()
                            .overlay(
                                LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                            )
                            .overlay(
                                Text(item.detail?.title ?? item.ref.name)
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.white)
                                    .padding()
                                    .shadow(radius: 4),
                                alignment: .bottomLeading
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        // 2. Filtros
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Filtrar Datos")
                                .font(.headline)
                            
                            Picker("Modo", selection: $filterMode) {
                                ForEach(FilterMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            if filterMode == .single {
                                DatePicker("Seleccionar Fecha", selection: $selectedDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                
                                Text("Mostrando datos del: \(formatDate(selectedDate))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Desde")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        DatePicker("", selection: $startDate, displayedComponents: .date)
                                            .labelsHidden()
                                    }
                                    Spacer()
                                    VStack(alignment: .leading) {
                                        Text("Hasta")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        DatePicker("", selection: $endDate, displayedComponents: .date)
                                            .labelsHidden()
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        
                        // 3. Dashboard de Estadísticas (Grid)
                        let stats = displayedStats
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            if let total = stats.first(where: { $0.name.contains("Totales") }) {
                                StatCard(
                                    title: "Casos Totales",
                                    value: "\(total.value)",
                                    icon: "person.3.fill",
                                    color: .blue
                                )
                            }
                            
                            if let new = stats.first(where: { $0.name.contains("Nuevos") }) {
                                StatCard(
                                    title: "Casos Nuevos",
                                    value: "\(new.value)",
                                    icon: "chart.line.uptrend.xyaxis",
                                    color: .orange
                                )
                            }
                        }
                        
                        // 4. Gráfica de Tendencia (Solo si hay historial)
                        if let history = item.detail?.history {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Tendencia (Últimos 14 días)")
                                    .font(.headline)
                                
                                Chart(getChartData(history: history)) { point in
                                    LineMark(
                                        x: .value("Fecha", point.date),
                                        y: .value("Total", point.value)
                                    )
                                    .foregroundStyle(Color.blue.gradient)
                                    .interpolationMethod(.catmullRom)
                                    
                                    AreaMark(
                                        x: .value("Fecha", point.date),
                                        y: .value("Total", point.value)
                                    )
                                    .foregroundStyle(LinearGradient(colors: [.blue.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                                    .interpolationMethod(.catmullRom)
                                }
                                .frame(height: 200)
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day)) { _ in
                                        // Ocultar etiquetas para limpieza visual en móvil
                                    }
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        
                        // 5. Atributos Extra
                        if let attrs = item.detail?.attributes, !attrs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Detalles Adicionales")
                                    .font(.headline)
                                
                                ForEach(attrs.prefix(5), id: \.name) { a in // Solo mostrar primeros 5 para no saturar
                                    HStack {
                                        Text(a.name)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(a.value ?? "—")
                                            .font(.subheadline.bold())
                                    }
                                    Divider()
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            // Inicializar fechas
            if let history = item.detail?.history {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dates = history.keys.compactMap { formatter.date(from: $0) }.sorted()
                
                if let last = dates.last {
                    selectedDate = last
                    endDate = last
                    startDate = Calendar.current.date(byAdding: .day, value: -7, to: last) ?? last
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Int
    }
    
    func getChartData(history: [String: CaseStats]) -> [ChartPoint] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let sortedKeys = history.keys.compactMap { formatter.date(from: $0) }.sorted().suffix(14)
        
        return sortedKeys.compactMap { date in
            let key = formatter.string(from: date)
            guard let val = history[key]?.total else { return nil }
            return ChartPoint(date: date, value: val)
        }
    }
    
    var displayedStats: [StatPair] {
        guard let history = item.detail?.history else { return [] }
        
        if filterMode == .single {
            let key = formatDate(selectedDate)
            if let stats = history[key] {
                return [
                    StatPair(name: "Casos Totales", value: stats.total),
                    StatPair(name: "Casos Nuevos", value: stats.new)
                ]
            }
        } else {
            let startKey = formatDate(startDate)
            let endKey = formatDate(endDate)
            let validKeys = history.keys.filter { key in key >= startKey && key <= endKey }
            
            var sumNew = 0
            for key in validKeys { sumNew += history[key]?.new ?? 0 }
            
            let maxKey = validKeys.max() ?? endKey
            let totalAtEnd = history[maxKey]?.total ?? 0
            
            return [
                StatPair(name: "Casos Totales", value: totalAtEnd),
                StatPair(name: "Casos Nuevos", value: sumNew)
            ]
        }
        return [StatPair(name: "Casos Totales", value: 0), StatPair(name: "Casos Nuevos", value: 0)]
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .minimumScaleFactor(0.5)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
