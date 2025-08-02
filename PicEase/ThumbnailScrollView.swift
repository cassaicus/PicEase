import SwiftUI

struct ThumbnailScrollView: View {
    let imageURLs: [URL] // 画像のURL一覧
    @Binding var currentIndex: Int // 現在選択中のインデックス

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack {
                ForEach(Array(imageURLs.enumerated()), id: \.offset) { pair in
                    let index = pair.offset
                    let imageUrl = pair.element
                    
                    let image = ImageCache.shared.image(for: imageUrl) ?? {
                          let img = NSImage(contentsOf: imageUrl) ?? NSImage()
                          ImageCache.shared.setImage(img, for: imageUrl)
                          return img
                      }()
                    
                    
                    
                   //if let image = NSImage(contentsOf: imageUrl) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                            .border(currentIndex == index ? Color.blue : Color.clear, width: 2) // 選択中は白枠
                            .onTapGesture {
                                currentIndex = index
                                NotificationCenter.default.post(name: .thumbnailSelected, object: index) // 通知で選択
                            }
                   // }
                    
                    
                    
                    
                    
                    
                }
            }
            .padding(.horizontal)
        }
    }
}
