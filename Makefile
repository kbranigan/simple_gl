all: cocoa_gl.temp

DEBUG= -g --std=c++11

OBJECTS_COCOA_GL= \
	AppDelegate.o \
	main.o

cocoa_gl.temp: $(OBJECTS_COCOA_GL)
	g++ $(DEBUG) -Wall `pkg-config --libs --cflags protobuf glib-2.0` -DINC_OPENGL -lcurl `xml2-config --libs` -framework Cocoa -framework OpenGL -L/opt/homebrew/lib -lfreetype $^ -o cocoa_gl.temp
	mkdir -p cocoa_gl.app/Contents/MacOS
	ditto cocoa_gl.temp cocoa_gl.app/Contents/MacOS/Cocoa\ OpenGL
# https://developer.apple.com/documentation/security/updating_mac_software  # (need to use ditto instead of cp)

%.o: %.c %.h
	cc -Wall $*.c -c -o $@
%.o: %.cpp %.hpp
	g++ $(DEBUG) -Wall $*.cpp -c -o $@
%.o: %.mm
	g++ $(DEBUG) -Wall $*.mm -c -o $@
%.o: %.m
	g++ $(DEBUG) -Wall $*.m -c -o $@

main.o: main.mm
	g++ $(DEBUG) -Wall -c $^ -o $@ -Wno-deprecated-declarations -I/opt/homebrew/include
