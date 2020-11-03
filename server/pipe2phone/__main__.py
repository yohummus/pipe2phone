"""
Main entry script for running the pipe2phone server.
"""

import argparse
import contextlib
import munch
import pathlib
import socket
import sys
import time
import yaml

# Parse the command line
parser = argparse.ArgumentParser(description='Server for the pipe2phone app.')

parser.add_argument('--server', '-s', action='store_true',
                    help='Run the server')

parser.add_argument('--config', '-c', type=pathlib.Path, default=pathlib.Path.home() / '.pipe2phone.yml',
                    metavar='FILE',
                    help='Configuration file; default is ~/.pipe2phone.yml')

args = parser.parse_args()

# Read the configuration file
print(f'Using configuration file {args.config}')
with open(args.config) as f:
    cfg = munch.munchify(yaml.load(f.read(), Loader=yaml.SafeLoader))

# Create the TCP server
listen_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
listen_socket.bind((cfg.server.listen_address, 0))
listen_address, listen_port = listen_socket.getsockname()
listen_socket.listen()
print(f'Listening for pipe2phone clients on {listen_address} port {listen_port}')

# Create the broadcast socket
broadcast_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
broadcast_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
broadcast_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
broadcast_socket.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

broadcast_msg = '\n'.join(['pipe2phone', str(listen_port), cfg.server.title, cfg.server.description])
print(f'Sending broadcasts on port {cfg.server.broadcast_port} once every {cfg.server.broadcast_interval} seconds')

# Send broadcasts
while True:
    try:
        broadcast_socket.sendto(broadcast_msg.encode(), ('<broadcast>', cfg.server.broadcast_port))
    except Exception as e:
        print(f'ERROR: Could not send broadcast: {e}')

    time.sleep(cfg.server.broadcast_interval)
