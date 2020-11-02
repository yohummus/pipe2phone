"""
Main entry script for running the pipe2phone server.
"""

import socket
import time

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)

# server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

while True:
    print('Sending broadcast...')
    sock.sendto(b'Hello World!', ('<broadcast>', 17788))
    time.sleep(1)
