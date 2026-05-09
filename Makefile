build-devtools:
	cd extension/devtools && flutter build web --output=build/web --wasm

build-devtools-release:
	cd extension/devtools && flutter build web --output=build/web --wasm --release