import SwiftUI
import SDWebImageSwiftUI
import Charts

struct ComparisonView: View {
    @StateObject var vm = ComparisonViewModel()
    @State private var showSelectionSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                if vm.selectedCountries.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.xaxis")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                        Text("Comparativa de Países")
                            .font(.title2.bold())
                        Text("Selecciona dos o más países para comparar sus estadísticas.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button("Seleccionar Países") {
                            showSelectionSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Header con botón de añadir más
                            HStack {
                                Text("Comparando \(vm.selectedCountries.count) países")
                                    .font(.headline)
                                Spacer()
                                Button("Editar Selección") {
                                    showSelectionSheet = true
                                }
                            }
                            .padding(.horizontal)
                            
                            // 1. Grid de Tarjetas
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 16) {
                                    ForEach(vm.selectedCountries) { item in
                                        ComparisonCard(item: item)
                                            .frame(width: 200)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // 2. Gráficas Comparativas
                            if !vm.selectedCountries.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Análisis Gráfico")
                                        .font(.title3.bold())
                                        .padding(.horizontal)
                                    
                                    ComparisonChartsView(items: vm.selectedCountries)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Comparar")
            .sheet(isPresented: $showSelectionSheet) {
                NavigationView {
                    List(vm.filteredCountries) { item in
                        HStack {
                            Text(item.ref.name)
                            Spacer()
                            if vm.isSelected(item) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task {
                                await vm.toggleSelection(for: item)
                            }
                        }
                    }
                    .searchable(text: $vm.searchText, prompt: "Buscar país")
                    .navigationTitle("Seleccionar Países")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Listo") {
                                showSelectionSheet = false
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if vm.allCountries.isEmpty {
                Task {
                    await vm.loadCatalog()
                }
            }
        }
    }
}

struct ComparisonChartsView: View {
    let items: [ItemBase]
    
    var body: some View {
        VStack(spacing: 30) {
            // Gráfica de Casos Totales
            VStack(alignment: .leading) {
                Text("Casos Totales")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Chart(items) { item in
                    BarMark(
                        x: .value("País", item.ref.name),
                        y: .value("Total", getTotalCases(for: item))
                    )
                    .foregroundStyle(by: .value("País", item.ref.name))
                    .annotation(position: .top) {
                        Text("\(getTotalCases(for: item))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 250)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // Gráfica de Casos Nuevos
            VStack(alignment: .leading) {
                Text("Casos Nuevos")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Chart(items) { item in
                    BarMark(
                        x: .value("País", item.ref.name),
                        y: .value("Nuevos", getNewCases(for: item))
                    )
                    .foregroundStyle(by: .value("País", item.ref.name))
                    .annotation(position: .top) {
                        Text("\(getNewCases(for: item))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 250)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // Gráfica de Tendencia Histórica
            VStack(alignment: .leading) {
                Text("Tendencia Histórica (Últimos 10 días)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Chart(getHistoricalData(items: items), id: \.id) { point in
                    LineMark(
                        x: .value("Fecha", point.date),
                        y: .value("Total", point.value)
                    )
                    .foregroundStyle(by: .value("País", point.country))
                    .symbol(by: .value("País", point.country))
                    
                    PointMark(
                        x: .value("Fecha", point.date),
                        y: .value("Total", point.value)
                    )
                    .foregroundStyle(by: .value("País", point.country))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        if let date = value.as(Date.self) {
                            AxisValueLabel(format: .dateTime.day().month())
                        }
                    }
                }
                .frame(height: 300)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    struct HistoryPoint: Identifiable {
        let id = UUID()
        let country: String
        let date: Date
        let value: Int
    }
    
    func getHistoricalData(items: [ItemBase]) -> [HistoryPoint] {
        var points: [HistoryPoint] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        for item in items {
            guard let history = item.detail?.history else { continue }
            
            // Obtener fechas ordenadas
            let sortedKeys = history.keys.compactMap { formatter.date(from: $0) }.sorted().suffix(10) // Últimos 10 días
            
            for date in sortedKeys {
                let key = formatter.string(from: date)
                if let stats = history[key] {
                    points.append(HistoryPoint(country: item.ref.name, date: date, value: stats.total))
                }
            }
        }
        return points
    }
    
    func getTotalCases(for item: ItemBase) -> Int {
        item.detail?.stats?.first(where: { $0.name == "Casos Totales" })?.value ?? 0
    }
    
    func getNewCases(for item: ItemBase) -> Int {
        item.detail?.stats?.first(where: { $0.name == "Casos Nuevos" })?.value ?? 0
    }
}

struct ComparisonCard: View {
    let item: ItemBase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Bandera
            if let urlStr = item.detail?.media?.primary, let url = URL(string: urlStr) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 120)
                    .clipped()
            } else {
                Color.gray.opacity(0.2)
                    .frame(height: 120)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.ref.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Divider()
                
                if let stats = item.detail?.stats {
                    ForEach(stats, id: \.name) { stat in
                        HStack {
                            Text(stat.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(stat.value)")
                                .font(.caption.bold())
                        }
                    }
                } else {
                    Text("Cargando datos...")
                        .font(.caption)
                }
            }
            .padding(12)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
