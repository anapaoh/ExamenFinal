import SwiftUI
import SDWebImageSwiftUI

struct ContentView: View {
    @StateObject var vm = ItemListViewModel()
    
    var body: some View {
        NavigationView {
            List(vm.items) { item in
                NavigationLink {
                    ItemDetailView(item: item)
                } label: {
                    HStack {
                        if let urlStr = item.detail?.media?.primary, let url = URL(string: urlStr) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                        } else {
                            // Fallback icon if no image
                            Image(systemName: "globe")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(item.ref.name)
                                .font(.headline)
                            if let cases = item.detail?.stats?.first(where: { $0.name == "Cases" })?.value {
                                Text("Casos: \(cases)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("COVID-19 Tracker")
        }
        .onAppear {
            Task {
                await vm.loadItems(limit: 200)
            }
        }
    }
}
