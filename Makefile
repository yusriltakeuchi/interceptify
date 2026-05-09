build-devtools:
	cd extension/devtools && flutter build web --output=build/web --wasm

build-devtools-release:
	cd extension/devtools && flutter build web --output=build/web --wasm --release

run-devtools:
	cd extension/devtools && flutter run -d chrome --dart-define=use_simulated_environment=true