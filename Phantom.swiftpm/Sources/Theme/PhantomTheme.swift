import SwiftUI

enum PhantomTheme {
    static let voidBackground = Color(red: 0.04, green: 0.0, blue: 0.06)

    enum Spacing {
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum CornerRadius {
        static let card: CGFloat = 20
        static let button: CGFloat = 12
    }
}
