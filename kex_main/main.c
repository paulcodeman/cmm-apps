inline fastcall void debug_string(EDX)
{
    $push eax
    $push ebx
    $push ecx
    $mov eax, 63
    $mov ebx, 1
next_character:
    $mov ecx, DSDWORD[edx]
    $or cl, cl
    $jz debug_done
    $int 0x40
    $inc edx
    $jmp next_character
debug_done:
    $pop ecx
    $pop ebx
    $pop eax
}

inline fastcall void debug_character(ECX)
{
    $push eax
    $push ebx
    $mov eax, 63
    $mov ebx, 1
    $int 0x40
    $pop ebx
    $pop eax
}

int main(dword argc, dword argv)
{
    dword index;
    dword argument;

    debug_string("KEX command line arguments:");
    debug_character(10);
    for (index = 0; index < argc; index++) {
        argument = DSDWORD[argv + index * 4];
        /* KolibriOS may prefix UTF-8 paths in argv[0] with slash, byte 3, slash. */
        debug_string(argument);
        debug_character(10);
    }
    return 0;
}
