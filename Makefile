PLATFORM_IOS = iOS Simulator,name=iPhone 11 Pro Max
PLATFORM_MACOS = macOS
PLATFORM_MAC_CATALYST = macOS,variant=Mac Catalyst
PLATFORM_TVOS = tvOS Simulator,name=Apple TV
PLATFORM_WATCHOS = watchOS Simulator,name=Apple Watch Series 7 (45mm)

CONFIG = debug

default: test

build-all-platforms:
	for platform in \
	  "$(PLATFORM_IOS)" \
	  "$(PLATFORM_MACOS)" \
	  "$(PLATFORM_MAC_CATALYST)" \
	  "$(PLATFORM_TVOS)" \
	  "$(PLATFORM_WATCHOS)"; \
	do \
		xcodebuild build \
			-workspace Dependencies.xcworkspace \
			-scheme Dependencies \
			-configuration $(CONFIG) \
			-destination platform="$$platform" || exit 1; \
	done;

test-swift:
	swift test
	swift test -c release

test-linux:
	docker run \
		--rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.7-focal \
		bash -c 'apt-get update && apt-get -y install make && make test-swift'

build-for-library-evolution:
	swift build \
		-c release \
		--target Dependencies \
		-Xswiftc -emit-module-interface \
		-Xswiftc -enable-library-evolution

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--recursive \
		./Package.swift ./Sources ./Tests

.PHONY: test test-swift test-linux build-for-library-evolution format
