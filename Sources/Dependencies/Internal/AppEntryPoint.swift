import Foundation

extension Thread {
  public static var isPreviewAppEntryPoint: Bool {
    guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    else { return false }

    var isPreviewAppEntryPoint = false
    for frame in callStackSymbols.reversed() {
      if !isPreviewAppEntryPoint, frame.containsSymbol("$s7SwiftUI3AppPAAE4mainyyFZ") {
        isPreviewAppEntryPoint = true
      } else if isPreviewAppEntryPoint,
        frame.containsSymbol("$s7SwiftUI6runAppys5NeverOxAA0D0RzlF")
      {
        return false
      }
    }
    return isPreviewAppEntryPoint
  }
}

extension String {
  fileprivate func containsSymbol(_ symbol: String) -> Bool {
    utf8
      .reversed()
      .drop(while: { (48...57).contains($0) })
      .dropFirst(3)
      .starts(with: symbol.utf8.reversed())
  }
}
