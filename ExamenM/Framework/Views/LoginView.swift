import SwiftUI
import FlowStacks

struct LoginView: View {
    @EnvironmentObject var navigator: FlowNavigator<Screen>
    @StateObject var vm = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Correo Electrónico", text: $vm.email)
                .multilineTextAlignment(.center)
                .keyboardType(.emailAddress)
                .padding()
                .font(.title3)
                .textInputAutocapitalization(.never)
            
            Divider()
            
            Button {
                vm.setCurrentUser()
                navigator.presentCover(.menu)
            } label: {
                Text("Acceder")
            }
            .padding()
        }
        .onAppear {
            vm.getCurrentUser()
            if !vm.email.isEmpty {
                navigator.presentCover(.menu)
            }
        }
        .padding()
        .alert(isPresented: $vm.showAlert) {
            Alert(title: Text("Oops!"), message: Text(vm.messageAlert))
        }
    }
}
