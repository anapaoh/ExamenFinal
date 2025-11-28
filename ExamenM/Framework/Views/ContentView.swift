import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @StateObject var vm = ItemListViewModel()
    
    var body: some View {
        NavigationView {
            List(vm.filteredItems) { item in
                NavigationLink {
                    ItemDetailView(item: item)
                        .onAppear {
                            vm.saveLastViewed(country: item.ref.name)
                        }
                } label: {
                    HStack {
                        if let urlStr = item.detail?.media?.primary, let url = URL(string: urlStr) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                                .cornerRadius(4)
                        } else {
                            Image(systemName: "globe")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                                .foregroundColor(.gray)
                        }
                        
                        Text(item.ref.name)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("COVID-19 Tracker")
            .searchable(text: $vm.searchText, prompt: "Buscar país")
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
