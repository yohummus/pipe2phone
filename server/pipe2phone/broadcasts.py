"""
Module for sending UDP broadcast messages for advertising the server for the mobile app.
"""

import socket
import asyncio
import getpass
import hashlib
import json
import logging

from config import Configuration
from http_server import HttpServer
from secure_server import SecureServer

PROTOCOL_VERSION = 1


class Advertiser:
    """Sends advertising broadcast that the mobile app listens too in order to connect"""

    def __init__(self, cfg: Configuration, http_server: HttpServer, secure_server: SecureServer):
        self.port = cfg.advertising_port
        self.interval = cfg.advertising_interval

        # Create the UDP socket
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

        # Create a hash for the certificate
        cert_hash = hashlib.sha256(cfg.ssl_cert_file.read_bytes()).hexdigest()

        # Create the broadcast message
        self._msg = json.dumps([
            'pipe2phone',
            PROTOCOL_VERSION,
            cfg.server_title,
            cfg.server_description,
            getpass.getuser(),
            socket.gethostname(),
            http_server.port,
            secure_server.port,
            cert_hash,
        ]).encode()

        logging.info(f'Sending broadcasts on port {self.port} once every {self.interval} seconds')
        asyncio.get_event_loop().create_task(self._run())

    async def _run(self):
        """Sends advertising broadcasts repeatedly"""
        while True:
            try:
                self._sock.sendto(self._msg, ('<broadcast>', self.port))
            except Exception as e:
                logging.warning(f'Could not send broadcast: {e}')

            await asyncio.sleep(self.interval)
