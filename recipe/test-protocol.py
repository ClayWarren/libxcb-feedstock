"""Exercise installed libxcb clients against a bounded local X11 protocol peer."""
import socket
import struct
import subprocess
import sys
import threading


def read_exact(sock, size):
    data = bytearray()
    while len(data) < size:
        block = sock.recv(size - len(data))
        if not block:
            raise EOFError(f"Connection closed after {len(data)}/{size} bytes")
        data.extend(block)
    return bytes(data)


def exercise(executable):
    errors, requests = [], []
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        listener.settimeout(15)
        port = listener.getsockname()[1]
        assert port >= 6000, port

        def server():
            try:
                with listener.accept()[0] as conn:
                    conn.settimeout(15)
                    hello = read_exact(conn, 12)
                    endian = {b"l": "<", b"B": ">"}[hello[:1]]
                    major, minor, auth_name, auth_data = struct.unpack_from(endian + "HHHH", hello, 2)
                    assert (major, minor) == (11, 0)
                    read_exact(conn, (auth_name + 3) // 4 * 4 + (auth_data + 3) // 4 * 4)
                    # Minimal valid setup: no roots or pixmap formats are needed by these requests.
                    conn.sendall(struct.pack(endian + "BBHHHIIIIHHBBBBBBBB4x",
                                             1, 0, 11, 0, 8, 1, 0x200000, 0xfffff, 0,
                                             0, 65535, 0, 0, 0, 0, 32, 32, 8, 255))
                    sequence = 0
                    while True:
                        first = conn.recv(1)
                        if not first:
                            break
                        header = first + read_exact(conn, 3)
                        opcode, minor_opcode, length = struct.unpack(endian + "BBH", header)
                        assert 1 <= length <= 64, length
                        body = read_exact(conn, length * 4 - 4)
                        sequence += 1
                        requests.append(opcode)
                        reply = bytearray(32)
                        struct.pack_into(endian + "BBHI", reply, 0, 1, 0, sequence, 0)
                        if opcode == 43:  # GetInputFocus
                            struct.pack_into(endian + "I", reply, 8, 0x12345678)
                        elif opcode == 98:  # QueryExtension
                            name_len = struct.unpack_from(endian + "H", body)[0]
                            name = body[4:4 + name_len]
                            assert name in (b"RENDER", b"BIG-REQUESTS"), name
                            if name == b"RENDER":
                                reply[8:12] = bytes((1, 139, 0, 0))
                        elif opcode == 139:  # Render QueryVersion
                            assert minor_opcode == 0
                            assert struct.unpack(endian + "II", body) == (0, 11)
                            struct.pack_into(endian + "II", reply, 8, 0, 11)
                        else:
                            raise AssertionError(f"Unexpected X11 opcode {opcode}")
                        conn.sendall(reply)
            except BaseException as exc:
                errors.append(exc)

        thread = threading.Thread(target=server, daemon=True)
        thread.start()
        subprocess.run([executable, f"127.0.0.1:{port - 6000}"], check=True, timeout=20)
        thread.join(timeout=5)
        assert not thread.is_alive(), "Protocol peer did not finish"
        if errors:
            raise errors[0]
        assert {43, 98, 139} <= set(requests), requests
        print(f"PASS: {executable} exchanged X11 requests {requests}", flush=True)


for executable in sys.argv[1:]:
    exercise(executable)
