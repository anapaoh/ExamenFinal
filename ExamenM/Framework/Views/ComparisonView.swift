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
                            
                            // Gráficas Comparativas
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
        }
    }
    
    func getTotalCases(for item: ItemBase) -> Int {
        item.detail?.stats?.first(where: { $0.name == "Casos Totales" })?.value ?? 0
    }
    
    func getNewCases(for item: ItemBase) -> Int {
        item.detail?.stats?.first(where: { $0.name == "Casos Nuevos" })?.value ?? 0
    }
}
