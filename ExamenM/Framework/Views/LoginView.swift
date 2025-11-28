import SwiftUI
import FlowStacks

struct LoginView: View {
    @EnvironmentObject var navigator: FlowNavigator<Screen>
    @StateObject var vm = LoginViewModel()
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("COVID-19 Tracker")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)
            
            Spacer()
            
            Button {
                vm.setCurrentUser()
                navigator.presentCover(.menu)
            } label: {
                Text("Entrar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .onAppear {
            vm.getCurrentUser()
            if vm.isLoggedIn {
                navigator.presentCover(.menu)
            }
        }
    }
}
