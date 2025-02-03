import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Button("Sign in") {
                // Handle sign in
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))

            Button("Sign out") {
                // Handle sign out
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 2))
        }
        .padding()
    }
}