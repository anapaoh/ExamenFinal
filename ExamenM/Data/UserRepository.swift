import Foundation

protocol UserServiceProtocol {
    func getCurrentUser() -> String?
    func setCurrentUser(email: String)
    func removeCurrentUser()
    
    func getLastViewedCountry() -> String?
    func setLastViewedCountry(_ country: String)
}

class UserRepository: UserServiceProtocol {
    static let shared = UserRepository()
    var localService: LocalService
    
    init(localService: LocalService = LocalService.shared) {
        self.localService = localService
    }
    
    func getCurrentUser() -> String? {
        localService.getCurrentUser()
    }
    
    func setCurrentUser(email: String) {
        localService.setCurrentUser(email: email)
    }
    
    func removeCurrentUser() {
        localService.removeCurrentUser()
    }
    
    func getLastViewedCountry() -> String? {
        localService.getLastViewedCountry()
    }
    
    func setLastViewedCountry(_ country: String) {
        localService.setLastViewedCountry(country)
    }
}
