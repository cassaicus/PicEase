import SwiftUI

struct ThumbnailHintIconView: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "rectangle.grid.2x2")
                .font(.largeTitle)
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
