import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var messageAlert = ""
    @Published var showAlert = false
    var userReq: UserRequirementProtocol
    
    init(userReq: UserRequirementProtocol = UserRequirement.shared) {
        self.userReq = userReq
    }
    
    @MainActor
    func setCurrentUser() {
        // Ya no pedimos correo, entramos como Invitado por defecto
        userReq.setCurrentUser(email: "Invitado")
        isLoggedIn = true
    }
    
    @MainActor
    func getCurrentUser() {
        isLoggedIn = userReq.getCurrentUser() != nil
    }
}
