"""
Module for the secured server. The secured server is a HTTPS/WSS server that
enables launching scripts and retrieving terminal output. Clients connecting
to it must have the configured SSL certificate installed.
"""

import asyncio
import logging
import ssl

from aiohttp import web

from config import Configuration


class HttpsServer:
    """Secured server for launching scripts and retrieving terminal output"""

    def __init__(self, cfg: Configuration):
        self._cfg = cfg
        self._app = web.Application()
        self._runner = None

        self._setup_routes()

        logging.info(f'Using private key {cfg.private_key_file}')
        logging.info(f'Using SSL certificate {cfg.ssl_cert_file}')
        ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
        ssl_context.load_cert_chain(cfg.ssl_cert_file, cfg.private_key_file, cfg.private_key_password)

        self._runner = web.AppRunner(self._app)
        asyncio.get_event_loop().run_until_complete(self._runner.setup())

        self._site = web.TCPSite(self._runner, cfg.bind_address, cfg.https_port, ssl_context=ssl_context)
        asyncio.get_event_loop().run_until_complete(self._site.start())

        self.port = int(self._site.name[self._site.name.rindex(':') + 1:])
        logging.info(f'Running secured server on {cfg.bind_address} port {self.port}')

    def __del__(self):
        if self._runner:
            asyncio.get_event_loop().run_until_complete(self._runner.cleanup())

    def _setup_routes(self):
        """Sets up the routes for the views"""
        self._app.router.add_get('/', self._view_index)

    async def _view_index(self, req: web.Request) -> web.Response:
        """Index view"""
        return web.Response(text='Hello from secured server')
