import SwiftUI

struct ThumbnailScrollView: View {
    let imageURLs: [URL]
    @Binding var currentIndex: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: true) {
                HStack {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { pair in
                        let index = pair.offset
                        let imageUrl = pair.element

                        ThumbnailImageView(url: imageUrl)
                            .frame(width: 80, height: 80)
                            .clipped()
                            .border(currentIndex == index ? Color.blue : Color.clear, width: 2)
                            .onTapGesture {
                                currentIndex = index
                                NotificationCenter.default.post(name: .thumbnailSelected, object: index)
                            }
                            .id(index)
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: currentIndex) { newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(currentIndex, anchor: .center)
                }
            }
        }
    }
}
