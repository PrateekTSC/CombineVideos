//
//  main.swift
//  CombineVideos
//
//  Created by Prateek Prakash on 1/4/23.
//

import Foundation
import AVFoundation

// MARK: ASSET SETUP

// URLs
let firstAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-1.mp4")
let secondAssetUrl = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Video-2.mp4")

// AVURLAssets
let firstAsset = AVURLAsset(url: firstAssetUrl)
let secondAsset = AVURLAsset(url: secondAssetUrl)

// MARK: BEGIN COMPOSITION

// Create Composition
let avComposition = AVMutableComposition()

// MARK: FIRST TRACK (VIDEO & AUDIO)

// Add First Video Track (Composition)
guard let compFirstVideoTrack = avComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
   debugPrint("firstVideoTrack Error")
   exit(-1)
}

// Insert First Video Track
do {
   let firstVideoDuration = try await firstAsset.load(.duration)
   let firstVideoTrack = try await firstAsset.loadTracks(withMediaType: .video)[0]
   
   let timeRange = CMTimeRange(start: .zero, duration: firstVideoDuration)
   try compFirstVideoTrack.insertTimeRange(timeRange, of: firstVideoTrack, at: .zero)
} catch {
   debugPrint(error)
   exit(-1)
}

// Add First Audio Track (Composition)
guard let compFirstAudioTrack = avComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
   debugPrint("firstAudioTrack Error")
   exit(-1)
}

do{
   let firstAudioDuration = try await firstAsset.load(.duration)
   let firstAudioTrack = try await firstAsset.loadTracks(withMediaType: .audio)[0]
   
   let timeRange = CMTimeRange(start: .zero, duration: firstAudioDuration)
   try compFirstAudioTrack.insertTimeRange(timeRange, of: firstAudioTrack, at: .zero)
} catch {
   debugPrint(error)
   exit(-1)
}

// MARK: SECOND TRACK (VIDEO & AUDIO)

// Add Second Video Track (Composition)
guard let compSecondVideoTrack = avComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
   debugPrint("secondVideoTrack Error")
   exit(-1)
}

// Insert Second Video Track
do {
   let firstVideoDuration = try await firstAsset.load(.duration)
   let secondVideoDuration = try await secondAsset.load(.duration)
   let secondVideoTrack = try await secondAsset.loadTracks(withMediaType: .video)[0]
   
   let timeRange = CMTimeRange(start: .zero, duration: secondVideoDuration)
   try compSecondVideoTrack.insertTimeRange(timeRange, of: secondVideoTrack, at: firstVideoDuration)
} catch {
   debugPrint(error)
   exit(-1)
}

// Add Second Audio Track (Composition)
guard let compSecondAudioTrack = avComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
   debugPrint("secondAudioTrack Error")
   exit(-1)
}

do{
   let firstAudioDuration = try await firstAsset.load(.duration)
   let secondAudioDuration = try await secondAsset.load(.duration)
   let secondAudioTrack = try await secondAsset.loadTracks(withMediaType: .audio)[0]
   
   let timeRange = CMTimeRange(start: .zero, duration: secondAudioDuration)
   try compSecondAudioTrack.insertTimeRange(timeRange, of: secondAudioTrack, at: firstAudioDuration)
} catch {
   debugPrint(error)
   exit(-1)
}

// MARK: EXPORT COMPOSITION

guard let exportSession = AVAssetExportSession(asset: avComposition, presetName: AVAssetExportPresetHighestQuality) else {
   debugPrint("exportSession Error")
   exit(-1)
}
exportSession.outputURL = URL(fileURLWithPath: "/Users/p.prakash/Downloads/Combined.mp4")
exportSession.outputFileType = AVFileType.mp4
await exportSession.export()

