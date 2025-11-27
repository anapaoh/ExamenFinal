import SwiftUI
import SDWebImageSwiftUI

struct ItemDetailView: View {
    let item: ItemBase
    
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
                            Text("Filtrar por Fecha")
                                .font(.headline)
                            
                            DatePicker("Seleccionar Fecha", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            
                            Text("Estadísticas del \(formattedDateKey)")
                                .font(.headline)
                                .padding(.top, 8)
                            
                            ForEach(statsForSelectedDate, id: \.name) { s in
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
            // Establecer la fecha seleccionada a la última disponible en el historial
            if let history = item.detail?.history {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dates = history.keys.compactMap { formatter.date(from: $0) }.sorted()
                if let last = dates.last {
                    selectedDate = last
                }
            }
        }
    }
    
    @State private var selectedDate = Date()
    
    var formattedDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    var statsForSelectedDate: [StatPair] {
        guard let history = item.detail?.history,
              let stats = history[formattedDateKey] else {
            return [
                StatPair(name: "Casos Totales", value: 0),
                StatPair(name: "Casos Nuevos", value: 0)
            ]
        }
        return [
            StatPair(name: "Casos Totales", value: stats.total),
            StatPair(name: "Casos Nuevos", value: stats.new)
        ]
    }
}
