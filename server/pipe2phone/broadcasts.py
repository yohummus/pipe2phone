"""
Module for sending UDP broadcast messages for advertising the server for the mobile app.
"""

import socket
import asyncio
import logging
import json

from config import Configuration
from http_server import HttpServer
from https_server import HttpsServer

PROTOCOL_VERSION = 1


class Advertiser:
    """Sends advertising broadcast that the mobile app listens too in order to connect"""

    def __init__(self, cfg: Configuration, http_server: HttpServer, https_server: HttpsServer):
        self.port = cfg.advertising_port
        self.interval = cfg.advertising_interval

        # Create the UDP socket
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

        # Create the broadcast message
        self._msg = json.dumps([
            'pipe2phone',
            PROTOCOL_VERSION,
            cfg.server_title,
            cfg.server_description,
            http_server.port,
            https_server.port
        ]).encode()

        logging.info(f'Sending broadcasts on port {self.port} once every {self.interval} seconds')
        asyncio.run(self._run())

    async def _run(self):
        """Sends advertising broadcasts repeatedly"""
        while True:
            try:
                self._sock.sendto(self._msg, ('<broadcast>', self.port))
            except Exception as e:
                logging.warning(f'Could not send broadcast: {e}')

            await asyncio.sleep(self.interval)
