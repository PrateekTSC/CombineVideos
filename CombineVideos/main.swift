//
//  main.swift
//  CombineVideos
//
//  Created by Prateek Prakash on 1/4/23.
//

import Foundation
import AVFoundation

let fileNamesOne = ["Solution-1", "Solution-2"]
let fileNamesTwo = ["Solution-3", "Solution-4"]

deletePrevious(fileNamesOne)
deletePrevious(fileNamesTwo)

let assetsOne = buildAssetsOne()
let assetsTwo = buildAssetsTwo()

await combineVideos(assetsOne, outputName: fileNamesOne[0])
await combineVideos(assetsOne, renderX: 1300, renderY: 600, outputName:  fileNamesOne[1])

await combineVideos(assetsTwo, outputName: fileNamesTwo[0])
await combineVideos(assetsTwo, renderX: 1300, renderY: 600, outputName:  fileNamesTwo[1])

func deletePrevious(_ fileNames: [String]) {
   for fileName in fileNames {
      if (FileManager.default.fileExists(atPath: "/Users/p.prakash/Downloads/\(fileName).mp4")) {
         do {
            try FileManager.default.removeItem(at: URL(fileURLWithPath: "/Users/p.prakash/Downloads/\(fileName).mp4"))
            print("Deleted Previous \(fileName)")
         } catch {
            debugPrint(error)
         }
      }
   }
}

func buildAssetsOne() -> [AVURLAsset] {
   let firstAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-1.mp4")
   let secondAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-2.mp4")
   let thirdAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-3.mp4")
   let fourthAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-4.mp4")
   
   return [AVURLAsset(url: firstAssetUrl), AVURLAsset(url: secondAssetUrl),  AVURLAsset(url: thirdAssetUrl), AVURLAsset(url: fourthAssetUrl)]
}

func buildAssetsTwo() -> [AVURLAsset] {
   let firstAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-5.mp4")
   let secondAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-6.mp4")
   
   return [AVURLAsset(url: firstAssetUrl), AVURLAsset(url: secondAssetUrl)]
}

func combineVideos(_ allAssets: [AVURLAsset], outputName: String) async {
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
   
   await combineVideos(allAssets, renderX: xMax, renderY: yMax, outputName: outputName)
}

func combineVideos(_ allAssets: [AVURLAsset], renderX: CGFloat, renderY: CGFloat, outputName: String) async {
   
   let avComposition = AVMutableComposition()
   var insertTime = CMTime.zero
   
   let videoTrack = avComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
   let audioTrack = avComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
   
   // Scales & Translations
   var scaleFactors: [CGFloat] = []
   var xTranslations: [CGFloat] = []
   var yTranslations: [CGFloat] = []
   
   // Determine Scaling & Translating
   for currAsset in allAssets {
      do {
         let assetVideo = try await currAsset.loadTracks(withMediaType: .video)[0]
         let videoSize = try await assetVideo.load(.naturalSize)
         let videoWidth = videoSize.width
         let videoHeight = videoSize.height
         
         let xScale = renderX / videoWidth
         let yScale = renderY / videoHeight
         let scaleFactor = min(xScale, yScale)
         
         print("Scale Factor: \(scaleFactor)")
         scaleFactors += [scaleFactor]
         
         let dX = (renderX - (videoWidth * scaleFactor)) / scaleFactor / 2
         xTranslations += [dX]
         let dY = (renderY - (videoHeight * scaleFactor)) / scaleFactor / 2
         yTranslations += [dY]
         print("Translation: [\(dX), \(dY)]")
      } catch {
         debugPrint(error)
      }
   }
   
   let videoComposition = AVMutableVideoComposition()
   let renderSize = CGSize(width: renderX, height: renderY)
   videoComposition.renderSize = renderSize
   videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
   let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
   
   for (currIndex, currAsset) in allAssets.enumerated() {
      do {
         let assetDuration = try await currAsset.load(.duration)
         let assetVideo = try await currAsset.loadTracks(withMediaType: .video)[0]
         let assetAudio = try await currAsset.loadTracks(withMediaType: .audio)[0]
         let assetRange = CMTimeRangeMake(start: CMTime.zero, duration: assetDuration)
         
         try videoTrack?.insertTimeRange(assetRange, of: assetVideo, at: insertTime)
         try audioTrack?.insertTimeRange(assetRange, of: assetAudio, at: insertTime)
         
         let preferredTransform = try await assetVideo.load(.preferredTransform)
         let scaleBy = scaleFactors[currIndex]
         let dX = xTranslations[currIndex]
         let dY = yTranslations[currIndex]
         let newTransform = preferredTransform.scaledBy(x: scaleBy, y: scaleBy).translatedBy(x: dX, y: dY)
         layerInstruction.setTransform(newTransform, at: insertTime)
         
         insertTime = CMTimeAdd(insertTime, assetDuration)
      } catch {
         debugPrint(error)
      }
   }
   
   let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
   videoCompositionInstruction.layerInstructions = [layerInstruction]
   videoCompositionInstruction.timeRange = CMTimeRange(start: .zero, duration: insertTime)
   videoComposition.instructions = [videoCompositionInstruction]
   
   // Export
   guard let exportSession = AVAssetExportSession(asset: avComposition, presetName: AVAssetExportPresetHighestQuality) else {
      debugPrint("exportSession Error")
      exit(-1)
   }
   exportSession.videoComposition = videoComposition
   exportSession.outputURL = URL(fileURLWithPath: "/Users/p.prakash/Downloads/\(outputName).mp4")
   exportSession.outputFileType = AVFileType.mp4
   await exportSession.export()
   
   print("Completed Export")
}
