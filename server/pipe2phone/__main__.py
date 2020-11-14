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
import shutil
import contextlib
from typing import Any, List

from broadcasts import BroadcastSender
from server import AppServer
from crypto import generate_private_key, generate_certificate

CONFIG_TEMPLATE_FILE = pathlib.Path(__file__).parent / 'pipe2phone.yml'
DEFAULT_CONFIG_DIR = pathlib.Path('~/.pipe2phone')
DEFAULT_CONFIG_FILE = DEFAULT_CONFIG_DIR / 'pipe2phone.yml'
DEFAULT_SSL_KEY_FILE = DEFAULT_CONFIG_DIR / 'private_key.pem'
DEFAULT_SSL_CERT_FILE = DEFAULT_CONFIG_DIR / 'cert.pem'


class CommandLineArgs:
    """Command line arguments"""
    run_server: bool
    config_file: pathlib.Path


def parse_command_line(argv: List[str]) -> CommandLineArgs:
    """Parses the command line"""
    parser = argparse.ArgumentParser(description='Server for the pipe2phone app.')

    parser.add_argument('--server', '-s', action='store_true', dest='run_server',
                        help='Run the server')

    parser.add_argument('--config', '-c', type=pathlib.Path, default=DEFAULT_CONFIG_FILE, metavar='FILE',
                        dest='config_file',
                        help=f'Configuration file; default is {DEFAULT_CONFIG_FILE}')

    args = parser.parse_args()
    args.config_file = args.config_file.expanduser()

    return args


def create_default_configuration(args: CommandLineArgs) -> None:
    """Creates the default configuration file and generates an SSL certificate"""
    folder = args.config_file.parent
    if folder.exists():
        sys.exit(f'ERROR: Configuration directory {folder} already exists. Delete it to create a new configuration.')

    logging.info(f'Creating default configuration in {DEFAULT_CONFIG_DIR}...')
    folder.mkdir()
    shutil.copyfile(CONFIG_TEMPLATE_FILE, DEFAULT_CONFIG_FILE.expanduser())
    logging.info(f'Created {DEFAULT_CONFIG_FILE.name}')

    private_key = generate_private_key()
    DEFAULT_SSL_KEY_FILE.expanduser().touch(mode=0o600)
    DEFAULT_SSL_KEY_FILE.expanduser().write_bytes(private_key)
    logging.info(f'Created private SSL key in {DEFAULT_SSL_KEY_FILE}')

    cert = generate_certificate(private_key)
    DEFAULT_SSL_CERT_FILE.expanduser().touch(mode=0o600)
    DEFAULT_SSL_CERT_FILE.expanduser().write_bytes(cert)
    logging.info(f'Created SSL certificate in {DEFAULT_SSL_CERT_FILE}')


def resolveConfigPath(config_file: pathlib.Path, pathStr: str) -> pathlib.Path:
    """Resolves the given path string from the configuration file"""

    path = pathlib.Path(pathStr).expanduser()
    if not path.is_absolute():
        path = config_file.parent / path

    path = path.resolve()
    if not path.exists():
        sys.exit(f'ERROR: File does not exist: {path}')

    return path


def main(argv: List[str]) -> None:
    """Entry function"""

    # Setup logging
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

    # Parse the command line and read the configuration file
    args = parse_command_line(argv)
    if not args.config_file.exists():
        if args.config_file == DEFAULT_CONFIG_FILE.expanduser():
            create_default_configuration(args)
        else:
            sys.exit(f'ERROR: Configuration file {args.config_file} does not exist.')

    logging.info(f'Using configuration file {args.config_file}')
    with open(args.config_file) as f:
        cfg = munch.munchify(yaml.load(f.read(), Loader=yaml.SafeLoader))

    # Create the app server and the broadcast sender
    app_server = AppServer(address=cfg.server.listen_address,
                           port=cfg.server.listen_port,
                           ssl_cert=resolveConfigPath(args.config_file, cfg.server.ssl_cert),
                           private_key=resolveConfigPath(args.config_file, cfg.server.private_key),
                           private_key_password=cfg.server.private_key_password)

    protocol_version = 1
    broadcast_sender = BroadcastSender(broadcast_port=cfg.server.broadcast_port,
                                       broadcast_interval=cfg.server.broadcast_interval,
                                       protocol_version=protocol_version,
                                       server_port=app_server.port,
                                       server_title=cfg.server.title,
                                       server_description=cfg.server.description)

    # Run all the services
    async def run_services():
        await asyncio.gather(app_server.run(), broadcast_sender.run())

    with contextlib.suppress(KeyboardInterrupt):
        asyncio.get_event_loop().run_until_complete(run_services())


# Startup
main(sys.argv)
