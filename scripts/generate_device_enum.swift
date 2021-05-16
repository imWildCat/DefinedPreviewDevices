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
  let charactersExceptSpaceToBeRemoved = Set(["-", "*", "(", ")"].map { Character($0) })
  let cleaned = Array(input).filter { !charactersExceptSpaceToBeRemoved.contains($0) }

  let spaceRemovedInput = cleaned.split(separator: " ").map { String($0) }.reduce("") { prev, next in
    if prev.isEmpty {
      return next
    } else if prev.last?.isNumber ?? false, next.first?.isNumber ?? false {
      return "\(prev)_\(next)"
    }
    return prev + [next.first?.uppercased(), String(next.dropFirst())].compactMap { $0 }.joined()
  }

  let first = spaceRemovedInput.first?.lowercased()

  return [first, String(spaceRemovedInput.dropFirst())].compactMap { $0 }.joined()
}

let outputLines: [String] = deviceTypes.map { deviceType in
  let name = deviceType.name
  let caseName = normalizeCaseName(input: name)
  return "case \(caseName) = \"\(name)\""
}

let deviceCodePath = URL(string: "file://\(fileManager.currentDirectoryPath)/Sources/DefinedPreviewDevices/DefinedPreviewDevices+Device.swift")!

var deviceCode: String
do {
  deviceCode = try String(contentsOf: deviceCodePath, encoding: .utf8)
} catch {
  fatalError("\(error)")
}

let startReplaceRange = deviceCode.range(of: "// MARK: Generated code start\n")!
let endReplaceRange = deviceCode.range(of: "\n      // MARK: Generated code end")!

let readableCode = (outputLines.map { "      \($0)" }.joined(separator: "\n") + "\n").replacingOccurrences(of: ".", with: "_")

deviceCode.replaceSubrange(startReplaceRange.upperBound ... endReplaceRange.lowerBound, with: readableCode)

try! deviceCode.write(to: deviceCodePath, atomically: true, encoding: .utf8)

print("Wrote file: \(deviceCodePath)")

