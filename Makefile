all: cocoa_gl.temp

OBJECTS_COCOA_GL= \
	AppDelegate.o \
	main.o

cocoa_gl.temp: $(OBJECTS_COCOA_GL) cocoa_gl.app/Contents/Resources/English.lproj/MainMenu.nib
	g++ -O3 --std=c++11 -Wall -framework Cocoa -framework OpenGL -L/opt/homebrew/lib $(OBJECTS_COCOA_GL) -o cocoa_gl.temp
	mkdir -p cocoa_gl.app/Contents/MacOS
	ditto cocoa_gl.temp cocoa_gl.app/Contents/MacOS/Cocoa\ OpenGL
# https://developer.apple.com/documentation/security/updating_mac_software  # (need to use ditto instead of cp)

%.o: %.c %.h
	cc -O3 -Wall $*.c -c -o $@
%.o: %.cpp %.hpp
	g++ -O3 --std=c++11 -Wall $*.cpp -c -o $@
%.o: %.mm
	g++ -O3 -Wall $*.mm -c -o $@
%.o: %.m
	g++ -O3 -Wall $*.m -c -o $@

main.o: main.mm
	g++ -O3 --std=c++11 -Wall -c $^ -o $@ -Wno-deprecated-declarations -I/opt/homebrew/include

main.shaders.o: main.shaders.mm
	g++ -O3 --std=c++11 -Wall -c $^ -o $@ -Wno-deprecated-declarations -I/opt/homebrew/include

cocoa_gl.app/Contents/Resources/English.lproj/MainMenu.nib: MainMenu.xib
	ibtool --compile cocoa_gl.app/Contents/Resources/English.lproj/MainMenu.nib MainMenu.xib
