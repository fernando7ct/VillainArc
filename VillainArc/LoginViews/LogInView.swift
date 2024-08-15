import SwiftUI
import AuthenticationServices
import Firebase
import CryptoKit

struct LogInView: View {
    @AppStorage("isSignedIn") var isSignedIn = false
    @Environment(\.modelContext) private var context
    @State private var downloadingData = false
    @State private var showCompleteProfileView = false
    @State private var nonce: String?
    @State private var userName: String = ""
    @State private var dateJoined: Date = Date()
    
    var body: some View {
        if !downloadingData {
            if showCompleteProfileView {
                CompleteProfileView(userID: Auth.auth().currentUser?.uid ?? "", name: userName, dateJoined: dateJoined)
            } else {
                VStack {
                    Spacer()
                    Text("Villain Arc")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                    SignInWithAppleButton(.signIn, onRequest: { request in
                        let nonce = randomNonceString()
                        self.nonce = nonce
                        request.requestedScopes = [.email, .fullName]
                        request.nonce = sha256(nonce)
                    }, onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            loginWithFirebase(authorization)
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    })
                    .clipShape(Capsule())
                    .frame(maxHeight: 50)
                    .padding()
                }
                .background(BackgroundView())
            }
        } else {
            ProgressView("Loading...")
        }
    }
    
    func loginWithFirebase(_ authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = self.nonce else {
                print("Invalid state: A login callback was received, but no login request was sent.")
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            userName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName)
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error {
                    print(error.localizedDescription)
                } else {
                    downloadingData = true
                    if let user = authResult?.user {
                        DataManager.shared.checkUserDataComplete { success in
                            downloadingData = false
                            if success {
                                DataManager.shared.downloadUserData(userID: user.uid, context: context) { success in
                                    if success {
                                        isSignedIn = true
                                    }
                                }
                            } else {
                                DataManager.shared.fetchUserDateJoined(userID: user.uid) { date in
                                    dateJoined = date ?? Date()
                                    showCompleteProfileView = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

#Preview {
    LogInView()
}
