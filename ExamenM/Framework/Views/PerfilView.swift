import SwiftUI
import FlowStacks

struct PerfilView: View {
    @StateObject var vm = PerfilViewModel()
    @EnvironmentObject var navigator: FlowNavigator<Screen>
    
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
            
            Text(vm.email == "Invitado" ? "Usuario Invitado" : vm.email)
                .font(.title2.bold())
            
            Button {
                vm.logOut()
                navigator.goBackToRoot()
            } label: {
                Label("Cerrar sesión", systemImage: "power")
                    .foregroundColor(.red)
                    .font(.headline)
            }
        }
        .onAppear { vm.getCurrentUser() }
        .padding()
    }
}
