import Foundation

extension Notification.Name {
    /// サムネイルを表示するよう要求する通知。
    static let showThumbnail = Notification.Name("showThumbnail")
    /// サムネイルを非表示にするよう要求する通知。
    static let hideThumbnail = Notification.Name("hideThumbnail")
    /// 指定したインデックスへページを遷移させる通知。
    static let navigateToIndex = Notification.Name("navigateToIndex")
}
