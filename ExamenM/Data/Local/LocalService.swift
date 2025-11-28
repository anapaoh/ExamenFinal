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
    
    // MARK: - Last Viewed Country
    func getLastViewedCountry() -> String? {
        UserDefaults.standard.string(forKey: "lastViewedCountry")
    }
    
    func setLastViewedCountry(_ country: String) {
        UserDefaults.standard.set(country, forKey: "lastViewedCountry")
    }
}
