#include <stdio.h>
#include <string.h>

#define HASXDMAUTH 1
#include <X11/Xdmcp.h>

int main(void)
{
    unsigned char wire[6] = {0};
    XdmcpBuffer buffer = {wire, (int) sizeof(wire), 0, 0};
    XdmcpHeader written = {XDM_PROTOCOL_VERSION, QUERY, 0};
    XdmcpHeader read = {0};
    ARRAY8 array = {0};
    unsigned char auth_input[8] = {0, 1, 2, 3, 4, 5, 6, 7};
    unsigned char auth_key[8] = {7, 6, 5, 4, 3, 2, 1, 0};
    unsigned char wrapped[8] = {0};
    unsigned char unwrapped[8] = {0};

    if (!XdmcpWriteHeader(&buffer, &written))
        return 1;

    buffer.count = buffer.pointer;
    buffer.pointer = 0;
    if (!XdmcpReadHeader(&buffer, &read))
        return 1;
    if (read.version != written.version || read.opcode != written.opcode ||
        read.length != written.length)
        return 1;

    /* Exercise the DLL's private Winsock linkage without opening a socket. */
    if (XdmcpFlush(-1, &buffer, NULL, 0) != FALSE)
        return 1;

    XdmcpWrap(auth_input, auth_key, wrapped, sizeof(auth_input));
    XdmcpUnwrap(wrapped, auth_key, unwrapped, sizeof(wrapped));
    if (memcmp(auth_input, unwrapped, sizeof(auth_input)) != 0)
        return 1;

    if (!XdmcpAllocARRAY8(&array, 3))
        return 1;
    array.data[0] = 1;
    array.data[1] = 2;
    array.data[2] = 3;
    if (array.length != 3 || array.data[2] != 3)
        return 1;

    XdmcpDisposeARRAY8(&array);
    puts("libXdmcp native API smoke test passed.");
    return 0;
}
