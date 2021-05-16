// Author: Daohan Chong <wildcat.name@gmail.com>
// Please note that this script can only be run on macOS where Xcode is installed.

import Foundation

// Generated on: <https://app.quicktype.io>
struct DeviceType: Codable {
  // let minRuntimeVersion: Int
  // let bundlePath: String
  // let maxRuntimeVersion: Int
  let name: String
  // let identifier: String
  // let productFamily: ProductFamily
}

enum ProductFamily: String, Codable {
  case appleTV = "Apple TV"
  case appleWatch = "Apple Watch"
  case iPad
  case iPhone
}

struct OutputPayload: Codable {
  let deviceTypes: [DeviceType]

  enum CodingKeys: String, CodingKey {
    case deviceTypes = "devicetypes"
  }
}

let fileManager = FileManager.default

func shell(_ launchPath: String, _ arguments: [String]) -> Data {
  let task = Process()
  task.launchPath = launchPath
  task.arguments = arguments

  let pipe = Pipe()
  task.standardOutput = pipe
  task.launch()

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  return data
}

let deviceTypesData = shell("/usr/bin/xcrun", ["simctl", "list", "devicetypes", "-j"])

let payload = try! JSONDecoder().decode(OutputPayload.self, from: deviceTypesData)
let deviceTypes = payload.deviceTypes

// Generate data

func normalizeCaseName(input: String) -> String {
  let first = input.first?.lowercased()

  let charactersToBeRemoved = Set([" ", "-", "*", "(", ")"].map { Character($0) })
  let others = Array(input).filter { !charactersToBeRemoved.contains($0) }

  return [first, String(others.dropFirst())].compactMap { $0 }.joined()
}

let outputLines: [String] = deviceTypes.map { deviceType in
  let name = deviceType.name
  let caseName = normalizeCaseName(input: name)
  return "case \(caseName) = \"\(name)\""
}

let deviceCodePath = URL(string: "file://\(fileManager.currentDirectoryPath)/Sources/DefinedPreviewDevices/DefinedPreviewDevices+Device.swift")!
print(deviceCodePath)

var deviceCode: String
do {
  deviceCode = try String(contentsOf: deviceCodePath, encoding: .utf8)
} catch {
  fatalError("\(error)")
}

print(outputLines)
print(deviceCode)

let startReplaceRange = deviceCode.range(of: "// MARK: Generated code start\n")!
let endReplaceRange = deviceCode.range(of: "\n      // MARK: Generated code end")!

let readableCode = outputLines.map { "      \($0)" }.joined(separator: "\n") + "\n"

deviceCode.replaceSubrange(startReplaceRange.upperBound...endReplaceRange.lowerBound, with: readableCode)

print(deviceCode)
