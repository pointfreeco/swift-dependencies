CONFIG = debug
PLATFORM_IOS = iOS Simulator,id=$(call udid_for,iOS,iPhone \d\+ Pro [^M])
PLATFORM_MACOS = macOS
PLATFORM_MAC_CATALYST = macOS,variant=Mac Catalyst
PLATFORM_TVOS = tvOS Simulator,id=$(call udid_for,tvOS,TV)
PLATFORM_WATCHOS = watchOS Simulator,id=$(call udid_for,watchOS,Watch)

default: test

build-all-platforms:
	for platform in \
	  "$(PLATFORM_IOS)" \
	  "$(PLATFORM_MACOS)" \
	  "$(PLATFORM_MAC_CATALYST)" \
	  "$(PLATFORM_TVOS)" \
	  "$(PLATFORM_WATCHOS)"; \
	do \
		xcrun xcodebuild build \
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
		swift:5.10-focal \
		bash -c 'apt-get update && apt-get -y install make && make test-swift'

build-for-static-stdlib:
	@swift build -c debug --static-swift-stdlib
	@swift build -c release --static-swift-stdlib

test-integration:
	xcrun xcodebuild test \
		-scheme "Integration" \
		-destination platform="$(PLATFORM_IOS)" || exit 1; \

build-for-library-evolution:
	swift build \
		-c release \
		--target Dependencies \
		-Xswiftc -emit-module-interface \
		-Xswiftc -enable-library-evolution

	swift build \
		-c release \
		--target DependenciesMacros \
		-Xswiftc -emit-module-interface \
		-Xswiftc -enable-library-evolution \
		-Xswiftc -DRESILIENT_LIBRARIES # Required to build swift-syntax; see https://github.com/swiftlang/swift-syntax/pull/2540

build-for-static-stdlib-docker:
	@docker run \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.9-focal \
		bash -c "swift build -c debug --static-swift-stdlib"
	@docker run \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.9-focal \
		bash -c "swift build -c release --static-swift-stdlib"

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--recursive \
		./Package.swift ./Sources ./Tests/DependenciesTests

.PHONY: test test-swift test-linux build-for-library-evolution format

define udid_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$(NF-3) }')
endef
