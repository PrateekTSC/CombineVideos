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

let allAssets = [AVURLAsset(url: firstAssetUrl), AVURLAsset(url: secondAssetUrl)]

let avComposition = AVMutableComposition()
var insertTime = CMTime.zero

let videoTrack = avComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
let audioTrack = avComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

for currAsset in allAssets {
   do {
      let assetDuration = try await currAsset.load(.duration)
      let assetVideo = try await currAsset.loadTracks(withMediaType: .video)[0]
      let assetAudio = try await currAsset.loadTracks(withMediaType: .audio)[0]
      let assetRange = CMTimeRangeMake(start: CMTime.zero, duration: assetDuration)
      
      try videoTrack?.insertTimeRange(assetRange, of: assetVideo, at: insertTime)
      try audioTrack?.insertTimeRange(assetRange, of: assetAudio, at: insertTime)
      
      insertTime = CMTimeAdd(insertTime, assetDuration)
   } catch {
      debugPrint(error)
   }
}

guard let exportSession = AVAssetExportSession(asset: avComposition, presetName: AVAssetExportPresetHighestQuality) else {
   debugPrint("exportSession Error")
   exit(-1)
}
exportSession.outputURL = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Combined.mp4")
exportSession.outputFileType = AVFileType.mp4
await exportSession.export()
