import SwiftUI

struct ColorPickerView: View {
    @Binding var selectedHex: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(habitColors, id: \.self) { color in
                let hex = color.toHex()
                Button(action: { selectedHex = hex }) {
                    Circle()
                        .fill(color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: selectedHex == hex ? 2.5 : 0)
                        )
                        .scaleEffect(selectedHex == hex ? 1.15 : 1.0)
                        .animation(.spring(duration: 0.2), value: selectedHex)
                }
            }
        }
    }
}
