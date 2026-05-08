build-devtools:
	cd extension/devtools && flutter build web --pwa-strategy=none --output=build/web

build-devtools-release:
	cd extension/devtools && flutter build web --pwa-strategy=none --output=build/web --release