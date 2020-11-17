"""
Module for all configuration-related functionality such as parsing the command
line, reading the configuration file and creating a default configuration.
"""

import argcomplete
import logging
import munch
import shutil
import sys
import yaml

from argparse import ArgumentParser
from pathlib import Path
from typing import Any, List, Optional

from crypto import generate_private_key, generate_certificate

CONFIG_TEMPLATE_FILE = Path(__file__).parent / 'config/pipe2phone.yml'
DEFAULT_CONFIG_DIR = Path('~/.pipe2phone')
DEFAULT_CONFIG_FILENAME = 'pipe2phone.yml'
DEFAULT_SSL_KEY_FILENAME = 'private_key.pem'
DEFAULT_SSL_CERT_FILENAME = 'cert.pem'


class Configuration:
    """Configuration of the pipe2phone application"""

    def __init__(self, argv: List[str]):
        # Command line arguments
        args = self._parse_command_line(argv)
        self.debug: bool = args.debug
        self.serve: bool = args.serve
        self.config_file: Path = args.config.expanduser()
        self.config_dir: Path = self.config_file.parent

        # Create a default configuration file if it doesn't exist and no custom path has been set
        default_config_file = DEFAULT_CONFIG_DIR.expanduser() / DEFAULT_CONFIG_FILENAME
        if not self.config_file.exists() and self.config_file == default_config_file:
            self._create_default_configuration()

        # Check if the configuration file exists
        if not self.config_file.exists():
            sys.exit(f'ERROR: Configuration file {self.config_file} does not exist.')

        # Load the configuration file
        logging.info(f'Using configuration file {self.config_file}')
        self._yaml = munch.munchify(yaml.load(self.config_file.read_text(), Loader=yaml.SafeLoader))

    @property
    def server_title(self) -> str:
        """Title of the server as it appears on the connection page of the mobile app"""
        return self._yaml.server_title

    @property
    def server_description(self) -> str:
        """Description of the server as it appears on the connection page of the mobile app"""
        return self._yaml.server_title

    @property
    def server_password(self) -> str:
        """Password of the server required when connecting via the mobile app"""
        return self._yaml.server_title

    @property
    def bind_address(self) -> str:
        """Network address that the HTTP/HTTPS/WSS servers listenon """
        return self._yaml.bind_address

    @property
    def http_port(self) -> int:
        """Port that the unsecured HTTP server (for general info & downloading the certificate) listens on"""
        return self._yaml.http_port or 0

    @property
    def secure_port(self) -> int:
        """Port that the secure server (for running scripts and getting terminal output) listens on"""
        return self._yaml.secure_port or 0

    @property
    def private_key_file(self) -> Path:
        """Absolute path to the private SSL key file"""
        return self._resolve_path(self._yaml.private_key)

    @property
    def private_key_password(self) -> Optional[str]:
        """Password to decrypt the private SSL key or None if no password was specified"""
        return self._yaml.private_key_password

    @property
    def ssl_cert_file(self) -> Path:
        """Absolute path to the SSL certificate file"""
        return self._resolve_path(self._yaml.ssl_cert)

    @property
    def advertising_port(self) -> int:
        """UDP broadcast port used for advertising"""
        return self._yaml.advertising_port

    @property
    def advertising_interval(self) -> float:
        """Time between advertising broadcasts"""
        return self._yaml.advertising_interval

    def _resolve_path(self, path_str: str) -> Path:
        """Resolves the given path string relative to the configuration file unless it is absolute"""
        path = Path(path_str).expanduser()
        if not path.is_absolute():
            path = self.config_dir / path

        path = path.resolve()
        if not path.exists():
            sys.exit(f'ERROR: File does not exist: {path}')

        return path

    @staticmethod
    def _parse_command_line(argv: List[str]) -> Any:
        """Parses the command line"""
        parser = ArgumentParser(description='Server for the pipe2phone app.')

        parser.add_argument('--serve', '-s', action='store_true',
                            help='Run the server')

        default_config_file = DEFAULT_CONFIG_DIR / DEFAULT_CONFIG_FILENAME
        parser.add_argument('--config', '-c', type=Path, default=default_config_file, metavar='FILE',
                            help=f'Configuration file; default is {default_config_file}')

        parser.add_argument('--debug', action='store_true',
                            help='Enabled debugging')

        argcomplete.autocomplete(parser)
        return parser.parse_args(argv[1:])

    @staticmethod
    def _create_default_configuration() -> None:
        """Creates the default configuration file and generates an SSL certificate"""
        config_dir = DEFAULT_CONFIG_DIR.expanduser()
        if config_dir.exists():
            sys.exit(f'ERROR: Directory {config_dir} already exists. Delete it to create a new configuration.')

        logging.info(f'Creating default configuration in {config_dir}...')
        config_dir.mkdir()

        config_file = config_dir / DEFAULT_CONFIG_FILENAME
        shutil.copyfile(CONFIG_TEMPLATE_FILE, config_file)
        logging.info(f'Created {config_file.name}')

        private_key = generate_private_key()
        private_key_file = config_dir / DEFAULT_SSL_KEY_FILENAME
        private_key_file.touch(mode=0o600)
        private_key_file.write_bytes(private_key)
        logging.info(f'Created private SSL key in {private_key_file.name}')

        cert = generate_certificate(private_key)
        cert_file = config_dir / DEFAULT_SSL_CERT_FILENAME
        cert_file.touch(mode=0o600)
        cert_file.write_bytes(cert)
        logging.info(f'Created SSL certificate in {cert_file.name}')
