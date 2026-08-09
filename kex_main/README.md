# KolibriOS KEX example

Build with automatically calculated memory size:

```powershell
c-- -KEX main.c
```

The result is `main.kex`. The generated startup calls
`int main(dword argc, dword argv)`. Since C-- does not use C pointer syntax,
read an argument pointer with `DSDWORD[argv + index * 4]`.
`argv[0]` is the application path, and the remaining entries are parsed from
the KolibriOS parameter string. `argv[argc]` is zero.

KolibriOS may represent the path as `/\x03/...`, where byte `3` marks a
UTF-8 path. The example prints `argv[0]` unchanged, including this marker.

The `final_addr` header field is the exact end of the generated file image.
The automatic `MEMSIZE` contains that image, BSS, parameter/path and `argv`
buffers, the configured stack, and a 64 KiB heap reserve, rounded up to 4096
bytes.

To override the calculated total memory size:

```powershell
c-- -KEX -MEM=1048576 main.c
```

`-MEM` is optional and its value is rounded up to 4096 bytes. Compilation
fails if the requested size cannot contain the image, BSS, argument buffers,
and stack.
