all: cocoa_gl.temp

OBJECTS_COCOA_GL= \
	AppDelegate.o \
	main.o

cocoa_gl.temp: $(OBJECTS_COCOA_GL)
	g++ -O3 --std=c++11 -Wall `pkg-config --libs --cflags protobuf glib-2.0` -DINC_OPENGL -lcurl `xml2-config --libs` -framework Cocoa -framework OpenGL -L/opt/homebrew/lib -lfreetype $^ -o cocoa_gl.temp
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
