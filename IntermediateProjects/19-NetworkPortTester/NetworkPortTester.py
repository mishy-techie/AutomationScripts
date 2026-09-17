#!/usr/bin/env python3

"""
Project: Network Port Tester
Concept: TCP Connections
Language: Python 3

Cross-platform:
    Windows / Linux / macOS / GitHub Codespaces

Tests whether TCP ports on a target accept connections.
"""

import json
import socket
import time
from datetime import datetime
from pathlib import Path


# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

TIMEOUT_SECONDS = 2.0

REPORT_DIRECTORY = Path(__file__).resolve().parent / "reports"

REPORT_DIRECTORY.mkdir(
    parents=True,
    exist_ok=True
)

REPORT_FILE = (
    REPORT_DIRECTORY
    / f"port-test-{datetime.now():%Y%m%d-%H%M%S}.json"
)


# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

print()
print("=" * 44)
print("           NETWORK PORT TESTER")
print("=" * 44)
print()


# ------------------------------------------------------------
# Get target
# ------------------------------------------------------------

target = input("Enter hostname or IP address: ").strip()

if not target:
    print("No target specified.")
    raise SystemExit(1)


# ------------------------------------------------------------
# Parse ports
# ------------------------------------------------------------

port_input = input(
    "Enter port(s), e.g. 80 or 80,443 or 20-25: "
).strip()

if not port_input:
    print("No ports specified.")
    raise SystemExit(1)


def parse_ports(value: str) -> list[int]:
    """Parse individual ports and port ranges."""

    ports = set()

    for part in value.split(","):

        part = part.strip()

        if not part:
            continue

        if "-" in part:

            pieces = part.split("-", 1)

            try:
                start = int(pieces[0])
                end = int(pieces[1])
            except ValueError:
                continue

            if start > end:
                start, end = end, start

            for port in range(start, end + 1):

                if 1 <= port <= 65535:
                    ports.add(port)

        else:

            try:
                port = int(part)
            except ValueError:
                continue

            if 1 <= port <= 65535:
                ports.add(port)

    return sorted(ports)


ports = parse_ports(port_input)

if not ports:
    print("No valid ports were supplied.")
    raise SystemExit(1)


# ------------------------------------------------------------
# Test TCP port
# ------------------------------------------------------------

def test_tcp_port(
    hostname: str,
    port: int,
    timeout: float
) -> dict:

    start_time = time.perf_counter()

    try:

        with socket.socket(
            socket.AF_INET,
            socket.SOCK_STREAM
        ) as sock:

            sock.settimeout(timeout)

            result = sock.connect_ex(
                (hostname, port)
            )

        elapsed_ms = round(
            (time.perf_counter() - start_time) * 1000,
            2
        )

        if result == 0:

            return {
                "Target": hostname,
                "Port": port,
                "Status": "OPEN",
                "ResponseTimeMs": elapsed_ms,
                "Error": ""
            }

        return {
            "Target": hostname,
            "Port": port,
            "Status": "CLOSED/FILTERED",
            "ResponseTimeMs": elapsed_ms,
            "Error": ""
        }

    except socket.timeout:

        elapsed_ms = round(
            (time.perf_counter() - start_time) * 1000,
            2
        )

        return {
            "Target": hostname,
            "Port": port,
            "Status": "TIMEOUT",
            "ResponseTimeMs": elapsed_ms,
            "Error": "Connection timed out"
        }

    except socket.gaierror as error:

        elapsed_ms = round(
            (time.perf_counter() - start_time) * 1000,
            2
        )

        return {
            "Target": hostname,
            "Port": port,
            "Status": "DNS ERROR",
            "ResponseTimeMs": elapsed_ms,
            "Error": str(error)
        }

    except OSError as error:

        elapsed_ms = round(
            (time.perf_counter() - start_time) * 1000,
            2
        )

        return {
            "Target": hostname,
            "Port": port,
            "Status": "ERROR",
            "ResponseTimeMs": elapsed_ms,
            "Error": str(error)
        }


# ------------------------------------------------------------
# Run tests
# ------------------------------------------------------------

print()
print(f"Target : {target}")
print(f"Ports  : {', '.join(map(str, ports))}")
print(f"Timeout: {TIMEOUT_SECONDS} seconds")
print()

results = []

for port in ports:

    print(
        f"Testing TCP {target}:{port} ...",
        end="",
        flush=True
    )

    result = test_tcp_port(
        target,
        port,
        TIMEOUT_SECONDS
    )

    results.append(result)

    if result["Status"] == "OPEN":

        print(
            f" OPEN ({result['ResponseTimeMs']} ms)"
        )

    elif result["Status"] == "CLOSED/FILTERED":

        print(" CLOSED/FILTERED")

    else:

        print(
            f" {result['Status']}"
        )


# ------------------------------------------------------------
# Display results
# ------------------------------------------------------------

print()
print("Results")
print("-" * 44)

for result in results:

    print(
        f"{result['Target']}:{result['Port']} "
        f"{result['Status']} "
        f"({result['ResponseTimeMs']} ms)"
    )


# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

open_count = sum(
    result["Status"] == "OPEN"
    for result in results
)

closed_count = sum(
    result["Status"] == "CLOSED/FILTERED"
    for result in results
)

error_count = len(results) - open_count - closed_count

print()
print(f"Open ports      : {open_count}")
print(f"Closed/filtered : {closed_count}")
print(f"Errors/timeouts : {error_count}")


# ------------------------------------------------------------
# Build report
# ------------------------------------------------------------

report = {
    "ComputerName": socket.gethostname(),
    "AuditTime": datetime.now().isoformat(),
    "Target": target,
    "Ports": ports,
    "TimeoutSeconds": TIMEOUT_SECONDS,

    "Summary": {
        "Open": open_count,
        "ClosedFiltered": closed_count,
        "Errors": error_count
    },

    "Results": results
}


# ------------------------------------------------------------
# Export JSON
# ------------------------------------------------------------

with REPORT_FILE.open(
    "w",
    encoding="utf-8"
) as file:

    json.dump(
        report,
        file,
        indent=4
    )


print()
print("=" * 44)
print("          PORT TEST COMPLETE")
print("=" * 44)
print()
print(f"Report: {REPORT_FILE}")
print()