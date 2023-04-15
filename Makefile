default: build

zip: build
	cd build/ && zip -r PCSX2-Installer.zip PCSX2-1.7/ && cd -

build: clean
	mkdir -p build/PCSX2-1.7/
	@cd include/ && zip -qr ../build/PCSX2-1.7/include.zip * && cd -
	cp -r bin/ install.bat build/PCSX2-1.7/

clean:
	rm -rf build/*
