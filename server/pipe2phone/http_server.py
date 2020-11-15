"""
Module for the HTTP server. It provides general information and the ability for
clients to download the SSL certificate required to connect to the secured
server.
"""

import asyncio
import logging

from aiohttp import web

from config import Configuration


class HttpServer:
    """HTTP server for serving general information and for downloading the SSL certificate"""

    def __init__(self, cfg: Configuration):
        self._cfg = cfg
        self._app = web.Application()
        self._runner = None

        self._setup_routes()

        self._runner = web.AppRunner(self._app)
        asyncio.get_event_loop().run_until_complete(self._runner.setup())

        self._site = web.TCPSite(self._runner, cfg.bind_address, cfg.http_port)
        asyncio.get_event_loop().run_until_complete(self._site.start())

        self.port = int(self._site.name[self._site.name.rindex(':') + 1:])
        logging.info(f'Running HTTP server on {cfg.bind_address} port {self.port}')

    def __del__(self):
        if self._runner:
            asyncio.get_event_loop().run_until_complete(self._runner.cleanup())

    def _setup_routes(self):
        """Sets up the routes for the views"""
        self._app.router.add_get('/', self._view_index)

    async def _view_index(self, req: web.Request) -> web.Response:
        """Index view"""
        return web.Response(text='Hello world')
