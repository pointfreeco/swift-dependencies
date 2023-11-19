func _liveValue(_ key: Any.Type) -> Any? {
  (key as? any DependencyKey.Type)?.liveValue
}
