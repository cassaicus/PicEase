import SwiftUI

struct ThumbnailScrollView: View {
    let imageURLs: [URL]
    @Binding var currentIndex: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack {
                ForEach(Array(imageURLs.enumerated()), id: \ .offset) { pair in
                    let index = pair.offset
                    let imageUrl = pair.element
                    if let image = NSImage(contentsOf: imageUrl) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                            .border(currentIndex == index ? Color.white : Color.clear, width: 2)
                            .onTapGesture {
                                currentIndex = index
                                NotificationCenter.default.post(name: .thumbnailSelected, object: index)
                            }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
