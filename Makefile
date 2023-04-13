default: build

zip: build
	mkdir -p build/archive/
	cd build/ && zip -qr archive/PCSX2-Installer.zip * -x archive/

build: clean
	@cd include/ && zip -qr ../build/include.zip * && cd -
	cp -r bin/ install.bat build/

clean:
	rm -rf build/*
