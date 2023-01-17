//
//  main.swift
//  CombineVideos
//
//  Created by Prateek Prakash on 1/4/23.
//

import Foundation
import AVFoundation

// Delete Previous Combined
if (FileManager.default.fileExists(atPath: "/Users/p.prakash/Downloads/Combined.mp4")) {
   do {
      try FileManager.default.removeItem(at: URL(fileURLWithPath: "/Users/p.prakash/Downloads/Combined.mp4"))
      print("Deleted Previous Combined")
   } catch {
      debugPrint(error)
   }
}

let firstAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-1.mp4")
let secondAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-2.mp4")
let thirdAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-3.mp4")

let allAssets = [AVURLAsset(url: firstAssetUrl), AVURLAsset(url: secondAssetUrl),  AVURLAsset(url: thirdAssetUrl)]

let avComposition = AVMutableComposition()
var insertTime = CMTime.zero

let videoTrack = avComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
let audioTrack = avComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

// Max Dimensions
var xMax = CGFloat.zero
var yMax = CGFloat.zero

// Determine Max Width & Height
for currAsset in allAssets {
   do {
      let assetVideo = try await currAsset.loadTracks(withMediaType: .video)[0]
      let videoSize = try await assetVideo.load(.naturalSize)
      let videoWidth = videoSize.width
      let videoHeight = videoSize.height
      
      print("Video Size: \(videoWidth)x\(videoHeight)")
      
      xMax = max(videoWidth, xMax)
      yMax = max(videoHeight, yMax)
   } catch {
      debugPrint(error)
   }
}

// Scales & Translations
var scaleFactors: [CGFloat] = []

// Determine Scaling
for currAsset in allAssets {
   do {
      let assetVideo = try await currAsset.loadTracks(withMediaType: .video)[0]
      let videoSize = try await assetVideo.load(.naturalSize)
      let videoWidth = videoSize.width
      let videoHeight = videoSize.height
      
      let xScale = xMax / videoWidth
      let yScale = yMax / videoHeight
      let scaleFactor = min(xScale, yScale)
      
      print("Scale Factor: \(scaleFactor)")
      scaleFactors += [scaleFactor]
   } catch {
      debugPrint(error)
   }
}

let videoComposition = AVMutableVideoComposition()
let renderSize = CGSize(width: xMax, height: yMax)
videoComposition.renderSize = renderSize
videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
var layerInstructions: [AVVideoCompositionLayerInstruction] = []

for (currIndex, currAsset) in allAssets.enumerated() {
   do {
      let assetDuration = try await currAsset.load(.duration)
      let assetVideo = try await currAsset.loadTracks(withMediaType: .video)[0]
      let assetAudio = try await currAsset.loadTracks(withMediaType: .audio)[0]
      let assetRange = CMTimeRangeMake(start: CMTime.zero, duration: assetDuration)
      
      try videoTrack?.insertTimeRange(assetRange, of: assetVideo, at: insertTime)
      try audioTrack?.insertTimeRange(assetRange, of: assetAudio, at: insertTime)
      
      let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetVideo)
      let preferredTransform = try await assetVideo.load(.preferredTransform)
      let scaleBy = scaleFactors[currIndex]
      let newTransform = preferredTransform.scaledBy(x: scaleBy, y: scaleBy)
      layerInstruction.setTransform(newTransform, at: .zero)
      layerInstructions += [layerInstruction]
      
      insertTime = CMTimeAdd(insertTime, assetDuration)
   } catch {
      debugPrint(error)
   }
}

let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
videoCompositionInstruction.layerInstructions = layerInstructions
videoCompositionInstruction.timeRange = CMTimeRange(start: .zero, duration: insertTime)
videoComposition.instructions = [videoCompositionInstruction]

// Export
guard let exportSession = AVAssetExportSession(asset: avComposition, presetName: AVAssetExportPresetHighestQuality) else {
   debugPrint("exportSession Error")
   exit(-1)
}
exportSession.videoComposition = videoComposition
exportSession.outputURL = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Combined.mp4")
exportSession.outputFileType = AVFileType.mp4
await exportSession.export()
