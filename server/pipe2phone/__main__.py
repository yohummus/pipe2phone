#!/user/bin/env python
# PYTHON_ARGCOMPLETE_OK

"""
Main entry script for running the pipe2phone server.
"""

import asyncio
import contextlib
import sys
import logging

from config import Configuration
from http_server import HttpServer
from https_server import HttpsServer
from broadcasts import Advertiser

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

# Parse the configuration
cfg = Configuration(sys.argv)

# Debugging mode
if cfg.debug:
    logging.warning('Debugging mode enabled')
    logging.root.setLevel(logging.DEBUG)

# Create the HTTP server, the secured server and the broadcast sender
http_server = HttpServer(cfg)
https_server = HttpsServer(cfg)
advertiser = Advertiser(cfg, http_server, https_server)

# Run until we receive SIGINT
with contextlib.suppress(KeyboardInterrupt):
    asyncio.get_event_loop().run_forever()
