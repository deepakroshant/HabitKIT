import SwiftUI

struct ConfettiView: View {
    @Binding var trigger: Int

    @State private var particles: [Particle] = []

    private struct Particle: Identifiable {
        let id = UUID()
        let color: Color
        let isCircle: Bool
        var x: CGFloat
        var y: CGFloat
        var angle: Double = 0
        var opacity: Double = 1
        var scale: CGFloat = 1
    }

    private let palette: [Color] = [
        .green, .mint, Color(red: 1, green: 0.84, blue: 0),
        .orange, .cyan, .pink, Color(red: 0.6, green: 1, blue: 0.6)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Group {
                        if p.isCircle {
                            Circle().fill(p.color).frame(width: 11, height: 11)
                        } else {
                            RoundedRectangle(cornerRadius: 2).fill(p.color).frame(width: 9, height: 9)
                        }
                    }
                    .rotationEffect(.degrees(p.angle))
                    .scaleEffect(p.scale)
                    .opacity(p.opacity)
                    .position(x: p.x, y: p.y)
                }
            }
            .onChange(of: trigger) {
                guard trigger > 0 else { return }
                fire(center: CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.38))
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func fire(center: CGPoint) {
        particles = (0..<30).map { _ in
            Particle(
                color: palette.randomElement()!,
                isCircle: Bool.random(),
                x: center.x + CGFloat.random(in: -8...8),
                y: center.y + CGFloat.random(in: -8...8)
            )
        }

        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.65)) {
                for i in particles.indices {
                    let angle = Double.random(in: 0..<2 * .pi)
                    let dist  = CGFloat.random(in: 70...200)
                    particles[i].x     = center.x + dist * cos(angle)
                    particles[i].y     = center.y + dist * sin(angle)
                    particles[i].angle = Double.random(in: 0...720)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeIn(duration: 0.45)) {
                for i in particles.indices {
                    particles[i].y       += 130
                    particles[i].opacity  = 0
                    particles[i].scale    = 0.3
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            particles = []
        }
    }
}
