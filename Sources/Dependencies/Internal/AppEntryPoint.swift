import Foundation

extension Thread {
  public static var isPreviewAppEntryPoint: Bool {
    containsSymbol("$s7SwiftUI3AppPAAE4mainyyFZ")
      && !containsSymbol("$s7SwiftUI6runAppys5NeverOxAA0D0RzlF")
  }

  static func containsSymbol(_ symbol: String) -> Bool {
    func frameContainsSymbol(_ frame: String) -> Bool {
      frame.utf8
        .reversed()
        .drop(while: { (48...57).contains($0) })
        .dropFirst(3)
        .starts(with: symbol.utf8.reversed())
    }
    return callStackSymbols
      .reversed()
      .contains(where: frameContainsSymbol)
  }
}
