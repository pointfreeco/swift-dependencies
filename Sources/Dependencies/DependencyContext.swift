//
//  DependencyContext.swift
//  Dependencies
//
//  Created by Robert Nash on 03/02/2026.
//  Copyright © 2026 ABA Systems. All rights reserved.
//

/// A context for a collection of ``DependencyValues``.
///
/// There are three distinct contexts that dependencies can be loaded from:
///
///   * ``live``: The default context.
///   * ``preview``: A context for Xcode previews.
///   * ``test``: A context for tests.
public enum DependencyContext: Sendable {
  /// The default, "live" context for dependencies.
  case live

  /// A "preview" context for dependencies.
  case preview

  /// A "test" context for dependencies.
  case test
}
