"""
============================================
Public IP Checker (Python)
============================================

This script sends an HTTP request to a public
IP service and displays your public IP.

Skills practiced:
- HTTP requests
- Functions
- Exception handling
- Variables
============================================
"""

# urllib is included with Python, so no installation is needed.
import urllib.request


def get_public_ip():
    """
    Sends a request to api.ipify.org and
    returns the public IP address.
    """

    try:
        # Open a connection to the website
        with urllib.request.urlopen("https://api.ipify.org") as response:

            # Read the response and convert bytes to text
            ip = response.read().decode("utf-8")

            return ip

    except Exception as error:
        print("Unable to retrieve your public IP.")
        print(error)
        return None


# ------------------------
# Main Program
# ------------------------

print("Checking your public IP...\n")

public_ip = get_public_ip()

if public_ip:
    print("Your Public IP Address:")
    print(public_ip)