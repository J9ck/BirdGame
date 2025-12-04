//
//  VirtualJoystick.swift
//  BirdGame3
//
//  Wolf-style virtual joystick for movement control
//

import SwiftUI

/// A virtual joystick control for touch-based movement input
/// Provides smooth 360-degree directional control
struct VirtualJoystick: View {
    // MARK: - Properties
    
    /// Binding to the direction vector output (-1 to 1 for both axes)
    @Binding var direction: CGVector
    
    /// Size of the joystick base
    var baseSize: CGFloat = 120
    
    /// Size of the joystick knob
    var knobSize: CGFloat = 50
    
    /// Base color when idle
    var baseIdleColor: Color = .gray.opacity(0.3)
    
    /// Base color when active
    var baseActiveColor: Color = .gray.opacity(0.5)
    
    /// Knob color
    var knobColor: Color = .white
    
    // MARK: - State
    
    @State private var knobOffset: CGSize = .zero
    @State private var isActive: Bool = false
    
    // MARK: - Computed Properties
    
    private var maxKnobOffset: CGFloat {
        (baseSize - knobSize) / 2
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(isActive ? baseActiveColor : baseIdleColor)
                .frame(width: baseSize, height: baseSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            // Direction indicators
            joystickDirectionIndicators
            
            // Knob
            Circle()
                .fill(knobColor.opacity(isActive ? 1.0 : 0.7))
                .frame(width: knobSize, height: knobSize)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                .offset(knobOffset)
                .animation(.spring(response: 0.15, dampingFraction: 0.8), value: knobOffset)
        }
        .gesture(joystickDragGesture)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Movement Joystick")
        .accessibilityHint("Drag to move your bird")
    }
    
    // MARK: - Subviews
    
    private var joystickDirectionIndicators: some View {
        ZStack {
            // Up indicator
            Triangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 10, height: 8)
                .offset(y: -baseSize / 2 + 15)
            
            // Down indicator
            Triangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 10, height: 8)
                .rotationEffect(.degrees(180))
                .offset(y: baseSize / 2 - 15)
            
            // Left indicator
            Triangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 10, height: 8)
                .rotationEffect(.degrees(-90))
                .offset(x: -baseSize / 2 + 15)
            
            // Right indicator
            Triangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 10, height: 8)
                .rotationEffect(.degrees(90))
                .offset(x: baseSize / 2 - 15)
        }
    }
    
    // MARK: - Gestures
    
    private var joystickDragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                isActive = true
                triggerHaptic(.light)
                
                // Calculate offset clamped to circular boundary
                let translation = value.translation
                let distance = sqrt(translation.width * translation.width + 
                                  translation.height * translation.height)
                
                if distance <= maxKnobOffset {
                    knobOffset = translation
                } else {
                    // Clamp to circle edge
                    let angle = atan2(translation.height, translation.width)
                    knobOffset = CGSize(
                        width: cos(angle) * maxKnobOffset,
                        height: sin(angle) * maxKnobOffset
                    )
                }
                
                // Update direction binding (normalized -1 to 1)
                direction = CGVector(
                    dx: knobOffset.width / maxKnobOffset,
                    dy: -knobOffset.height / maxKnobOffset // Invert Y for game coordinates
                )
            }
            .onEnded { _ in
                // Spring back to center
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    knobOffset = .zero
                    isActive = false
                }
                direction = .zero
            }
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VirtualJoystick(direction: .constant(.zero))
    }
}
