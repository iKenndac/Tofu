import Foundation
import SwiftUI

@available(iOS 16.0, *)
struct BigButtonStyle: ButtonStyle {

    let type: ButtonType

    enum ButtonType {
        case primary
        case secondary

        var backgroundColor: Color {
            switch self {
            case .primary: return .accentColor
            case .secondary: return .dimmedSomething
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .primary
            }
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 50.0, maxHeight: 50.0)
            .contentShape(RoundedRectangle(cornerRadius: 8.0))
            .padding(.horizontal, 20.0)
            .font(.body.bold())
            .foregroundColor(type.foregroundColor.opacity(configuration.isPressed ? 0.6 : 1.0))
            .background(type.backgroundColor.opacity(configuration.isPressed ? 0.6 : 1.0))
            .cornerRadius(8.0)
            .clipShape(RoundedRectangle(cornerRadius: 8.0))
    }
}
