//
//  main.swift
//  CombineVideos
//
//  Created by Prateek Prakash on 1/4/23.
//

import Foundation
import AVFoundation

let firstAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-1.mp4")
let secondAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-2.mp4")
let thirdAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-3.mp4")

let allAssets = [AVURLAsset(url: firstAssetUrl), AVURLAsset(url: secondAssetUrl)]

let avComposition = AVMutableComposition()
var insertTime = CMTime.zero
var totalDuration = CMTime.zero

let videoTrack = avComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
let audioTrack = avComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

var maxWidth = CGFloat.zero
var maxHeight = CGFloat.zero

let videoComposition = AVMutableVideoComposition()
let renderSize = CGSize(width: 1600, height: 900)
videoComposition.renderSize = renderSize
videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
var layerInstructions: [AVVideoCompositionLayerInstruction] = []

for currAsset in allAssets {
   do {
      let assetDuration = try await currAsset.load(.duration)
      let assetVideo = try await currAsset.loadTracks(withMediaType: .video)[0]
      let assetAudio = try await currAsset.loadTracks(withMediaType: .audio)[0]
      let assetRange = CMTimeRangeMake(start: CMTime.zero, duration: assetDuration)
      
      let videoSize = try await assetVideo.load(.naturalSize)
      let videoWidth = videoSize.width
      let videoHeight = videoSize.height
      print("Video Size: \(videoWidth)x\(videoHeight)")
      maxWidth = max(videoWidth, maxWidth)
      maxHeight = max(videoHeight, maxHeight)
      
      try videoTrack?.insertTimeRange(assetRange, of: assetVideo, at: insertTime)
      try audioTrack?.insertTimeRange(assetRange, of: assetAudio, at: insertTime)
      
      let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetVideo)
      let preferredTransform = try await assetVideo.load(.preferredTransform)
      let newTransform = preferredTransform.scaledBy(x: 1.0, y: 1.0).translatedBy(x: 0.0, y: 0.0)
      layerInstruction.setTransform(newTransform, at: .zero)
      layerInstructions += [layerInstruction]
      
      // insertTime == totalDuration
      insertTime = CMTimeAdd(insertTime, assetDuration)
   } catch {
      debugPrint(error)
   }
}

print("Max Video Size: \(maxWidth)x\(maxHeight)")

let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
videoCompositionInstruction.layerInstructions = layerInstructions
// insertTime == totalDuration
videoCompositionInstruction.timeRange = CMTimeRange(start: .zero, duration: insertTime)
videoComposition.instructions = [videoCompositionInstruction]

guard let exportSession = AVAssetExportSession(asset: avComposition, presetName: AVAssetExportPresetHighestQuality) else {
   debugPrint("exportSession Error")
   exit(-1)
}
exportSession.videoComposition = videoComposition
exportSession.outputURL = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Combined.mp4")
exportSession.outputFileType = AVFileType.mp4
await exportSession.export()
