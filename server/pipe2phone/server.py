"""
Module for the WebSocket server that the mobile app connects to in order to run scripts and show terminal output.
"""

import websockets
import asyncio
import logging
import pathlib
import ssl

from typing import Optional


class AppServer:
    """Server that the mobile app connects to for running scripts and showing terminal output"""

    def __init__(self, address: str, port: Optional[int], ssl_cert: pathlib.Path, private_key: pathlib.Path,
                 private_key_password: Optional[str]):
        logging.info(f'Using private key {private_key}')
        logging.info(f'Using SSL certificate {ssl_cert}')
        ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ssl_context.load_cert_chain(ssl_cert, private_key, private_key_password)

        self._server = websockets.serve(self._handle_client, address, port, ssl=ssl_context)
        asyncio.get_event_loop().run_until_complete(self._server)

        self.port = self._server.ws_server.server.sockets[0].getsockname()[1]
        logging.info(f'Listening for pipe2phone mobile app clients on {address} port {self.port}')

    async def run(self):
        pass

    async def _handle_client(self, websocket: websockets.server.WebSocketServerProtocol, path: str):
        name = await websocket.recv()
        print(f"< {name}")

        greeting = f"Hello {name}!"

        await websocket.send(greeting)
        print(f"> {greeting}")
