import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color("LaunchBackground")
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)

                Text("NCP-AIN")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("AI Networking 암기")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
