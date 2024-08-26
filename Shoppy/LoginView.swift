import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Image("Shoppy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.top, 50)
                
                Text("Shoppy")
                    .font(.largeTitle)
                    .padding()
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: login) {
                    Text("Log In")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                
                GoogleSignInButton(action: signInWithGoogle)
                    .padding()
                
                Button("Create an Account") {
                    showingRegister = true
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Login"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
            } else {
                authViewModel.isLoggedIn = true
            }
        }
    }
    
    func signInWithGoogle() {
        print("signInWithGoogle called")
        guard let app = FirebaseApp.app() else {
            print("FirebaseApp not initialized")
            return
        }
        print("FirebaseApp initialized")
        guard let clientID = app.options.clientID else {
            print("No client ID found in Firebase options")
            return
        }
        print("Client ID found: \(clientID)")
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("No client ID found")
            return
        }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("There is no root view controller!")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
                return
            }
            
            guard let signInResult = signInResult else {
                alertMessage = "Sign in failed."
                showingAlert = true
                return
            }
            
            let user = signInResult.user
            guard let idToken = user.idToken?.tokenString else {
                alertMessage = "Failed to get ID token."
                showingAlert = true
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                } else {
                    authViewModel.isLoggedIn = true
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(AuthViewModel())
    }
}
