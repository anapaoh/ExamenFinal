import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @StateObject var vm = ItemListViewModel()
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(vm.filteredItems) { item in
                        NavigationLink {
                            ItemDetailView(item: item)
                                .onAppear {
                                    vm.saveLastViewed(country: item.ref.name)
                                }
                        } label: {
                            CountryCard(item: item)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("COVID-19 Tracker")
            .searchable(text: $vm.searchText, prompt: "Buscar país")
            .background(Color(UIColor.systemGroupedBackground))
        }
        .onAppear {
            print("ContentView: onAppear triggered")
            if vm.items.isEmpty {
                Task {
                    await vm.loadItems()
                }
            }
        }
    }
}

struct CountryCard: View {
    let item: ItemBase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let urlStr = item.detail?.media?.primary, let url = URL(string: urlStr) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 100)
                    .clipped()
            } else {
                ZStack {
                    Color.gray.opacity(0.2)
                    Image(systemName: "globe")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.blue)
                }
                .frame(height: 100)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.ref.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let cases = item.detail?.stats?.first(where: { $0.name == "Cases" })?.value {
                    Text("Casos: \(cases)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Cargando...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
