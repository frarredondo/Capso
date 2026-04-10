// App/Sources/Camera/CameraPiPView.swift
import SwiftUI
import CameraKit
import SharedKit

struct CameraPiPView: View {
    let cameraManager: CameraManager
    /// Shorter dimension in points. The longer dimension is derived from the shape's aspect ratio.
    let shorterDimension: CGFloat
    let shape: CameraShape
    let mirror: Bool
    let usePresentationChrome: Bool
    let forcedSize: CGSize?

    private var width: CGFloat {
        if let forcedSize { return forcedSize.width }
        return shape.aspectRatio >= 1 ? shorterDimension * shape.aspectRatio : shorterDimension
    }

    private var height: CGFloat {
        if let forcedSize { return forcedSize.height }
        return shape.aspectRatio >= 1 ? shorterDimension : shorterDimension / shape.aspectRatio
    }

    private var clipShape: AnyShape {
        switch shape {
        case .circle:
            return AnyShape(Circle())
        case .square, .landscape, .portrait:
            return AnyShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Rectangle()
                    .fill(.black)
                    .frame(width: width, height: height)

                if let frame = cameraManager.currentFrame {
                    Image(decorative: frame, scale: 2.0)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .scaleEffect(x: mirror ? -1 : 1, y: 1)
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(width: width, height: height)
            .clipShape(clipShape)
            .overlay(
                clipShape.stroke(
                    .white.opacity(usePresentationChrome ? 0.18 : 0.4),
                    lineWidth: usePresentationChrome ? 1.0 : 2.5
                )
            )
            .shadow(
                color: .black.opacity(usePresentationChrome ? 0.18 : 0.5),
                radius: usePresentationChrome ? 4 : 10,
                y: usePresentationChrome ? 1 : 4
            )

        }
        .frame(width: width, height: height)
    }
}
