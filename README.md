# Zig-STB-Image

Zig build of the [STB image library](https://github.com/nothings/stb/blob/5736b15f7ea0ffb08dd38af21067c314d6a3aae9/stb_image.h).

The definitions have been split out of the header file and into a C source file, allowing
Zig to include the header w/o needing to transpile the entire library (instead, the C
compiler is used to compile it into a static library that Zig can link to).
