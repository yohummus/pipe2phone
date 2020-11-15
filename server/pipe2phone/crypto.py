"""
Cryptography-related functionality.
"""

from OpenSSL import crypto


def generate_private_key(bits=2048) -> bytes:
    """Generates a random private key"""
    pkey = crypto.PKey()
    pkey.generate_key(crypto.TYPE_RSA, bits)
    return crypto.dump_privatekey(crypto.FILETYPE_PEM, pkey)


def generate_certificate(private_key: bytes, *,
                         email_address='root@localhost',
                         common_name='localhost',
                         country_name='US',
                         locality_name='New York City',
                         state_or_province_name='New York',
                         organization_name='Pipe2phone',
                         organization_unit_name='Default',
                         serial_number=0,
                         validity_start_in_seconds=0,
                         validity_end_in_seconds=10 * 365 * 24 * 60 * 60,
                         ) -> bytes:
    """Generates a self-signed SSL certificate"""
    cert = crypto.X509()
    cert.get_subject().emailAddress = email_address
    cert.get_subject().CN = common_name
    cert.get_subject().C = country_name
    cert.get_subject().L = locality_name
    cert.get_subject().ST = state_or_province_name
    cert.get_subject().O = organization_name
    cert.get_subject().OU = organization_unit_name
    cert.set_serial_number(serial_number)
    cert.gmtime_adj_notBefore(validity_start_in_seconds)
    cert.gmtime_adj_notAfter(validity_end_in_seconds)
    cert.set_issuer(cert.get_subject())

    pkey = crypto.load_privatekey(crypto.FILETYPE_PEM, private_key)
    cert.set_pubkey(pkey)
    cert.sign(pkey, 'sha512')

    return crypto.dump_certificate(crypto.FILETYPE_PEM, cert)
