import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SuikaiVideoWatermark") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.suikai.suikai/video_watermark",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "apply" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.watermarkVideo(call: call, result: result)
    }
  }

  private func watermarkVideo(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let sourcePath = arguments["sourcePath"] as? String,
      let logoPath = arguments["logoPath"] as? String,
      let outputPath = arguments["outputPath"] as? String,
      FileManager.default.fileExists(atPath: sourcePath),
      let logoImage = UIImage(contentsOfFile: logoPath),
      let logoCGImage = logoImage.cgImage
    else {
      result(FlutterError(code: "invalid_arguments", message: "A video, logo and output path are required", details: nil))
      return
    }

    let outputURL = URL(fileURLWithPath: outputPath)
    if FileManager.default.fileExists(atPath: outputPath) {
      do {
        try FileManager.default.removeItem(at: outputURL)
      } catch {
        result(FlutterError(code: "output_cleanup_failed", message: error.localizedDescription, details: nil))
        return
      }
    }

    let asset = AVURLAsset(url: URL(fileURLWithPath: sourcePath))
    guard asset.tracks(withMediaType: .video).first != nil else {
      result(FlutterError(code: "missing_video_track", message: "The source has no video track", details: nil))
      return
    }
    let videoComposition = AVMutableVideoComposition(propertiesOf: asset)
    let renderSize = videoComposition.renderSize
    guard renderSize.width > 0, renderSize.height > 0 else {
      result(FlutterError(code: "invalid_video_size", message: "Could not determine video dimensions", details: nil))
      return
    }

    let watermarkWidth = max(1, renderSize.width * 0.08)
    let watermarkHeight = max(1, watermarkWidth * CGFloat(logoCGImage.height) / CGFloat(logoCGImage.width))
    let margin = renderSize.width * 0.03
    let parentLayer = CALayer()
    parentLayer.frame = CGRect(origin: .zero, size: renderSize)
    let videoLayer = CALayer()
    videoLayer.frame = parentLayer.bounds
    let watermarkLayer = CALayer()
    watermarkLayer.contents = logoCGImage
    watermarkLayer.contentsGravity = .resizeAspect
    watermarkLayer.opacity = 0.33
    watermarkLayer.frame = CGRect(
      x: renderSize.width - watermarkWidth - margin,
      y: renderSize.height - watermarkHeight - margin,
      width: watermarkWidth,
      height: watermarkHeight
    )
    parentLayer.addSublayer(videoLayer)
    parentLayer.addSublayer(watermarkLayer)
    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
      postProcessingAsVideoLayer: videoLayer,
      in: parentLayer
    )

    guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
      result(FlutterError(code: "export_unavailable", message: "Could not create a video exporter", details: nil))
      return
    }
    exporter.outputURL = outputURL
    exporter.outputFileType = .mp4
    exporter.videoComposition = videoComposition
    exporter.shouldOptimizeForNetworkUse = true
    exporter.exportAsynchronously { [weak exporter] in
      DispatchQueue.main.async {
        guard let exporter else {
          result(FlutterError(code: "export_lost", message: "Video exporter was released", details: nil))
          return
        }
        guard exporter.status == .completed,
              FileManager.default.fileExists(atPath: outputPath),
              ((try? FileManager.default.attributesOfItem(atPath: outputPath)[.size] as? NSNumber)?.intValue ?? 0) > 0 else {
          try? FileManager.default.removeItem(at: outputURL)
          result(FlutterError(
            code: "watermark_export_failed",
            message: exporter.error?.localizedDescription ?? "Watermark export did not complete",
            details: nil
          ))
          return
        }
        result(outputPath)
      }
    }
  }
}
