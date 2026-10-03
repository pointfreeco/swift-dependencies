import CompilationTesting
import SnapshotTesting
import Testing

@Suite(
  .compilation(
    imports: ["Dependencies", "DependenciesMacros"],
    flags: [
      .languageMode(.v6),
      .define("DEBUG"),
    ],
    record: .failed
  )
)
struct BaseSuite {}
