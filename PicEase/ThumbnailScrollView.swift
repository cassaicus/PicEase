
import SwiftUI
import ImageIO

struct ThumbnailScrollView: View {
    let imageURLs: [URL]
    @Binding var currentIndex: Int
    @Binding var isThumbnailVisible: Bool
    @State private var thumbnails: [URL: NSImage] = [:]
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: true) {
                LazyHStack(spacing: 8) {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                        
                        
                        
                        
                        
                        
                        let isSelected = index == currentIndex
                        ZStack {
                            if let image = thumbnails[url] {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipped()
                        .border(isSelected ? Color.blue : Color.clear, width: 2)
                        .id(index) // ← ScrollViewReader で使うための ID
                        .onTapGesture {
                            currentIndex = index
                            NotificationCenter.default.post(name: .thumbnailSelected, object: index)
                        }
                        .onAppear {
                            if thumbnails[url] == nil {
                                loadThumbnailAsync(for: url)
                            }
                        }
                        
                        
                        
                        
                        
                        
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: currentIndex) { oldValue, newIndex in
                    withAnimation {
                        scrollProxy.scrollTo(newIndex, anchor: .center)
                    }
            }
            .task(id: isThumbnailVisible) {
                if isThumbnailVisible {
                        scrollProxy.scrollTo(currentIndex, anchor: .center)
                }
                
            }
        }
    }
    
    
    
    // MARK: - Retina対応サムネイル生成（2xサイズで読み込み）
    func loadThumbnailAsync(for url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let targetSize = CGSize(width: 80, height: 80)
            let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0
            let pixelSize = CGSize(width: targetSize.width * scaleFactor, height: targetSize.height * scaleFactor)
            
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }
            
            let options: [NSString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: max(pixelSize.width, pixelSize.height),
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            
            if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                let image = NSImage(cgImage: cgImage, size: targetSize)
                DispatchQueue.main.async {
                    thumbnails[url] = image
                }
            }
        }
    }
}








//import SwiftUI
//import ImageIO
//
//struct ThumbnailScrollView: View {
//    let imageURLs: [URL]
//    @Binding var currentIndex: Int
//    @State private var thumbnails: [URL: NSImage] = [:]
//
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: true) {
//            LazyHStack(spacing: 8) {
//                ForEach(imageURLs, id: \.self) { url in
//                    let image = thumbnails[url]
//                    ZStack {
//                        if let image = image {
//                            Image(nsImage: image)
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                        } else {
//                            Color.gray // ローディング中プレースホルダー
//                        }
//                    }
//                    .frame(width: 80, height: 80)
//                    .clipped()
//                    .border(currentIndexImageURL == url ? Color.blue : Color.clear, width: 2)
//                    .onTapGesture {
//                        if let index = imageURLs.firstIndex(of: url) {
//                            currentIndex = index
//                            NotificationCenter.default.post(name: .thumbnailSelected, object: index)
//                        }
//                    }
//                    .onAppear {
//                        if thumbnails[url] == nil {
//                            loadThumbnailAsync(for: url)
//                        }
//                    }
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//
//    // 現在表示中の画像URLを取得
//    var currentIndexImageURL: URL? {
//        guard imageURLs.indices.contains(currentIndex) else { return nil }
//        return imageURLs[currentIndex]
//    }
//
//    func loadThumbnailAsync(for url: URL) {
//        DispatchQueue.global(qos: .userInitiated).async {
//            let thumb = loadThumbnail(from: url, targetSize: CGSize(width: 80, height: 80))
//            DispatchQueue.main.async {
//                thumbnails[url] = thumb
//            }
//        }
//    }
//
//    func loadThumbnail(from url: URL, targetSize: CGSize) -> NSImage? {
//        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
//        let options: [NSString: Any] = [
//            kCGImageSourceCreateThumbnailFromImageAlways: true,
//            kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height),
//            kCGImageSourceCreateThumbnailWithTransform: true
//        ]
//        if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
//            return NSImage(cgImage: cgImage, size: targetSize)
//        }
//        return nil
//    }
//}
//
//
//

//import SwiftUI
//
//struct ThumbnailScrollView: View {
//    let imageURLs: [URL]
//    @Binding var currentIndex: Int
//
//    var body: some View {
//        ScrollViewReader { proxy in
//            ScrollView(.horizontal, showsIndicators: true) {
//                HStack {
//                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { pair in
//                        let index = pair.offset
//                        let imageUrl = pair.element
//
//                        ThumbnailImageView(url: imageUrl)
//                            .frame(width: 80, height: 80)
//                            .clipped()
//                            .border(currentIndex == index ? Color.blue : Color.clear, width: 2)
//                            .onTapGesture {
//                                currentIndex = index
//                                NotificationCenter.default.post(name: .thumbnailSelected, object: index)
//                            }
//                            .id(index)
//                    }
//                }
//                .padding(.horizontal)
//            }
//            .onChange(of: currentIndex) { newIndex in
//                withAnimation {
//                    proxy.scrollTo(newIndex, anchor: .center)
//                }
//            }
//            .onAppear {
//                DispatchQueue.main.async {
//                    proxy.scrollTo(currentIndex, anchor: .center)
//                }
//            }
//        }
//    }
//}
