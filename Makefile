CONFIG = debug
PLATFORM_IOS = iOS Simulator,id=$(call udid_for,iPhone,iOS-16)
PLATFORM_MACOS = macOS
PLATFORM_MAC_CATALYST = macOS,variant=Mac Catalyst
PLATFORM_TVOS = tvOS Simulator,id=$(call udid_for,TV,tvOS-16)
PLATFORM_WATCHOS = watchOS Simulator,id=$(call udid_for,Watch,watchOS-9)

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

build-for-static-stdlib:
	@swift build -c debug --static-swift-stdlib
	@swift build -c release --static-swift-stdlib

test-integration:
	xcodebuild test \
		-scheme "Integration" \
		-destination platform="$(PLATFORM_IOS)" || exit 1; \

build-for-library-evolution:
	swift build \
		-c release \
		--target Dependencies \
		-Xswiftc -emit-module-interface \
		-Xswiftc -enable-library-evolution

build-for-static-stdlib-docker:
	@docker run \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.8-focal \
		bash -c "swift build -c debug --static-swift-stdlib"
	@docker run \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.8-focal \
		bash -c "swift build -c release --static-swift-stdlib"

format:
	swift format \
		--ignore-unparsable-files \
		--in-place \
		--recursive \
		./Package.swift ./Sources ./Tests

.PHONY: test test-swift test-linux build-for-library-evolution format

define udid_for
$(shell xcrun simctl list --json devices available $(1) | jq -r '.devices | to_entries | map(select(.value | add)) | sort_by(.key) | .[] | select(.key | contains("$(2)")) | .value | last.udid')
endef
