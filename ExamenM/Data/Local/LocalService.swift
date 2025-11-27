import Foundation

class LocalService {
    static let shared = LocalService()
    
    func getCurrentUser() -> String? {
        UserDefaults.standard.string(forKey: "currentUser")
    }
    
    func setCurrentUser(email: String) {
        UserDefaults.standard.set(email, forKey: "currentUser")
    }
    
    func removeCurrentUser() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}
