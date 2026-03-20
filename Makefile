.PHONY: release build

release:
	@./scripts/release.sh $(VERSION)

build:
	@xcodebuild \
		-project Sitter.xcodeproj \
		-scheme Sitter \
		-configuration Debug \
		build \
		-quiet
