"""
Module for the WebSocket server that the mobile app connects to in order to run scripts and show terminal output.
"""

import websockets
import asyncio
import logging


class AppServer:
    """Server that the mobile app connects to for running scripts and showing terminal output"""

    def __init__(self, listen_address: str):
        self._server = websockets.serve(self._handle_client, listen_address)
        asyncio.get_event_loop().run_until_complete(self._server)

        self.listen_port = self._server.ws_server.server.sockets[0].getsockname()[1]
        logging.info(f'Listening for pipe2phone mobile app clients on {listen_address} port {self.listen_port}')

    async def run(self):
        pass

    async def _handle_client(self, websocket: websockets.server.WebSocketServerProtocol, path: str):
        name = await websocket.recv()
        print(f"< {name}")

        greeting = f"Hello {name}!"

        await websocket.send(greeting)
        print(f"> {greeting}")
