# skybox

Rendering a basic Skybox using Vulkan and the Zig programming language.

## Project Goal

The goals of this project are:
1. familiarity with environment maps in Vulkan;
2. evaluation of the Zig programming language;
3. familiarity with SDL2.

## Remarks

I decided to abandon this project for now.
There seems to be some issue where SDL2 does not detect the VK_KHR_win32_surface extension.
It does not seem worth it to spend the time to figure out what's going wrong.
From reports on the Internet it seems SDL does not always link to the correct Vulkan lib.

Zig does not feel like the right tool for this kind of work either.
It focuses very heavily on type correctness, which in practice means there's a lot of type casts when you're working with >1 library.
The many different pointer and array types compound this problem.
For example, in order to print a C-style string you need to cast it to the special null-terminated character array type.
This is probably fine if you're not interfacing with C code, but it seems like it would be really tedious for a full project.

The Zig compiler is also very particular about things like using return values.
That's great if your focus is on program correctness, but not so great if you're trying to prototype something quickly.

On the plus side, Zig's structs are very nice and the error handling is a big plus too.
The Zig build system is also a big improvement over CMake.
For now, though, I'll stick with C for graphics programs.
