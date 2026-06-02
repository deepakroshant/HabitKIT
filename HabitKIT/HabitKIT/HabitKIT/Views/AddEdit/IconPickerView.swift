import SwiftUI

let habitIcons: [String] = [
    "🏃", "🏋️", "🧘", "🚴", "🏊", "⚽", "🎸", "🎹", "🎨", "📚",
    "✍️", "💊", "💧", "🥗", "☕", "🛌", "🧹", "💰", "🌿", "🧠",
    "❤️", "🎯", "🏆", "⭐", "🔥", "💡", "🌅", "🎵", "📝", "🧪"
]

struct IconPickerView: View {
    @Binding var selected: String
    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(habitIcons, id: \.self) { icon in
                Text(icon)
                    .font(.system(size: 24))
                    .frame(width: 44, height: 44)
                    .background(selected == icon ? Color.white.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selected == icon ? Color.white.opacity(0.5) : .clear, lineWidth: 1.5)
                    )
                    .onTapGesture { selected = icon }
            }
        }
    }
}
