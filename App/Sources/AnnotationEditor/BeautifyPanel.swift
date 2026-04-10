// App/Sources/AnnotationEditor/BeautifyPanel.swift
import SwiftUI

struct BeautifyPanel: View {
    @Binding var settings: BeautifySettings

    // Curated palette: 4 neutrals + 4 soft pastels. The full macOS colour
    // picker is still available next to the swatches for anything else.
    private let presetColors: [Color] = [
        .white,
        Color(nsColor: NSColor(calibratedWhite: 0.96, alpha: 1)),
        Color(nsColor: NSColor(calibratedWhite: 0.18, alpha: 1)),
        .black,
        Color(nsColor: NSColor(srgbRed: 0.729, green: 0.902, blue: 0.992, alpha: 1)), // sky blue
        Color(nsColor: NSColor(srgbRed: 0.996, green: 0.843, blue: 0.663, alpha: 1)), // peach
        Color(nsColor: NSColor(srgbRed: 0.733, green: 0.969, blue: 0.816, alpha: 1)), // mint
        Color(nsColor: NSColor(srgbRed: 0.867, green: 0.839, blue: 0.996, alpha: 1)), // lavender
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Enable background", isOn: $settings.isEnabled)

            if settings.isEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text("Style")
                            .frame(width: 90, alignment: .leading)
                        Picker("", selection: $settings.backgroundStyle) {
                            ForEach(BeautifyBackgroundStyle.allCases) { style in
                                Text(style.label).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .fixedSize()
                        Spacer()
                    }

                    if settings.backgroundStyle == .solid {
                        HStack(spacing: 8) {
                            Text("Background")
                                .frame(width: 90, alignment: .leading)
                            HStack(spacing: 6) {
                                ForEach(Array(presetColors.enumerated()), id: \.offset) { _, color in
                                    Button {
                                        settings.backgroundColor = color
                                    } label: {
                                        Circle()
                                            .fill(color)
                                            .frame(width: 18, height: 18)
                                            .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 0.5))
                                    }
                                    .buttonStyle(.plain)
                                }
                                ColorPicker("", selection: $settings.backgroundColor, supportsOpacity: false)
                                    .labelsHidden()
                            }
                        }
                    }

                    HStack(spacing: 8) {
                        Text("Padding")
                            .frame(width: 90, alignment: .leading)
                        Slider(value: $settings.padding, in: 16...80, step: 1)
                        Text("\(Int(settings.padding))")
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 32, alignment: .trailing)
                    }

                    HStack(spacing: 8) {
                        Text("Corners")
                            .frame(width: 90, alignment: .leading)
                        Slider(value: $settings.cornerRadius, in: 0...24, step: 1)
                        Text("\(Int(settings.cornerRadius))")
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 32, alignment: .trailing)
                    }

                    HStack(spacing: 8) {
                        Toggle("Shadow", isOn: $settings.shadowEnabled)
                            .frame(width: 90, alignment: .leading)
                        Slider(value: $settings.shadowRadius, in: 0...40, step: 1)
                            .disabled(!settings.shadowEnabled)
                        Text("\(Int(settings.shadowRadius))")
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 32, alignment: .trailing)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
    }
}
