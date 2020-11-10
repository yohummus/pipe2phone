"""
Module for sending UDP broadcast messages for advertising the server for the mobile app.
"""

import threading
import socket
import asyncio
import logging
import json


class BroadcastSender:
    """Sends advertising broadcast that the mobile app listens too in order to connect"""

    def __init__(self, broadcast_port: int, broadcast_interval: float, protocol_version: int,
                 server_port: int, server_title: str, server_description: str):
        self.broadcast_port = broadcast_port
        self.broadcast_interval = broadcast_interval

        # Create the UDP socket
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

        # Create the broadcast message
        self._msg = json.dumps(['pipe2phone', protocol_version, server_port, server_title, server_description]).encode()

    async def run(self):
        logging.info(f'Sending broadcasts on port {self.broadcast_port} once every {self.broadcast_interval} seconds')

        while True:
            try:
                self._sock.sendto(self._msg, ('<broadcast>', self.broadcast_port))
            except Exception as e:
                logging.warning(f'Could not send broadcast: {e}')

            await asyncio.sleep(self.broadcast_interval)
