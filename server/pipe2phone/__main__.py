"""
Main entry script for running the pipe2phone service.
"""

import argparse
import contextlib
import munch
import pathlib
import socket
import sys
import time
import yaml
import json
import threading
import websockets
import asyncio
import logging
from typing import Any, List

from broadcasts import BroadcastSender
from server import AppServer


def parse_command_line(argv: List[str]) -> Any:
    """Parses the command line"""
    parser = argparse.ArgumentParser(description='Server for the pipe2phone app.')

    parser.add_argument('--server', '-s', action='store_true',
                        help='Run the server')

    parser.add_argument('--config', '-c', type=pathlib.Path, default=pathlib.Path.home() / '.pipe2phone.yml',
                        metavar='FILE',
                        help='Configuration file; default is ~/.pipe2phone.yml')

    args = parser.parse_args()
    return args


def main(argv: List[str]) -> None:
    # Setup logging
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

    # Parse the command line and read the configuration file
    args = parse_command_line(argv)
    logging.info(f'Using configuration file {args.config}')
    with open(args.config) as f:
        cfg = munch.munchify(yaml.load(f.read(), Loader=yaml.SafeLoader))

    # Create the app server and the broadcast sender
    app_server = AppServer(cfg.server.listen_address)

    protocol_version = 1
    broadcast_sender = BroadcastSender(cfg.server.broadcast_port, cfg.server.broadcast_interval, protocol_version,
                                       app_server.listen_port, cfg.server.title, cfg.server.description)

    # Run all the services
    async def run_services():
        await asyncio.gather(app_server.run(), broadcast_sender.run())

    asyncio.get_event_loop().run_until_complete(run_services())


# Startup
main(sys.argv)
