import SwiftUI

struct MenuView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Listado")
                }
            
            ComparisonView()
                .tabItem {
                    Image(systemName: "chart.bar.xaxis")
                    Text("Comparar")
                }

            PerfilView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Perfil")
                }
        }
    }
}
