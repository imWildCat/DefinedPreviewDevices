#if canImport(SwiftUI)
  import SwiftUI

  @available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
  public extension View {
    func previewDevice(_ device: DefinedPreviewDevices.Device) -> some View {
      let device: PreviewDevice? = PreviewDevice(device: device)
      return previewDevice(device)
    }
  }
#endif
