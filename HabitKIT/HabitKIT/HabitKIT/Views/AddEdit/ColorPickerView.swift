import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedHex: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(habitColors, id: \.self) { color in
                    let hex = color.toHex()
                    Circle()
                        .fill(color)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: selectedHex == hex ? 3 : 0)
                        )
                        .scaleEffect(selectedHex == hex ? 1.18 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: selectedHex)
                        .onTapGesture { selectedHex = hex }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
