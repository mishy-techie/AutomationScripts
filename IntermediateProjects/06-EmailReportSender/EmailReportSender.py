#!/usr/bin/env python3

"""
06-email-report-sender.py

Project: Email Report Sender
Concept: SMTP
Language: Python

Environment variables required:

    SMTP_SERVER
    SMTP_PORT
    SMTP_USERNAME
    SMTP_PASSWORD
    REPORT_EMAIL_FROM
    REPORT_EMAIL_TO
"""

import os
import sys
import smtplib
from pathlib import Path
from email.message import EmailMessage
from datetime import datetime


# =========================================================
# CONFIGURATION
# =========================================================

REPORT_DIRECTORY = (
    Path.home() / "PC-Health-Reports"
)

SMTP_SERVER = os.getenv("SMTP_SERVER")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))

SMTP_USERNAME = os.getenv("SMTP_USERNAME")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")

EMAIL_FROM = os.getenv("REPORT_EMAIL_FROM")
EMAIL_TO = os.getenv("REPORT_EMAIL_TO")


# =========================================================
# VALIDATE CONFIGURATION
# =========================================================

required = {
    "SMTP_SERVER": SMTP_SERVER,
    "SMTP_USERNAME": SMTP_USERNAME,
    "SMTP_PASSWORD": SMTP_PASSWORD,
    "REPORT_EMAIL_FROM": EMAIL_FROM,
    "REPORT_EMAIL_TO": EMAIL_TO,
}

missing = [
    name
    for name, value in required.items()
    if not value
]

if missing:

    print("Missing configuration:")

    for name in missing:
        print(f" - {name}")

    sys.exit(1)


# =========================================================
# FIND LATEST REPORT
# =========================================================

if not REPORT_DIRECTORY.exists():

    print(
        f"Report directory does not exist: "
        f"{REPORT_DIRECTORY}"
    )

    sys.exit(1)


reports = sorted(
    REPORT_DIRECTORY.glob("*.html"),
    key=lambda file: file.stat().st_mtime,
    reverse=True,
)


if not reports:

    print("No HTML report found.")

    print(
        "Run 05-HTMLReportGenerator.ps1 first."
    )

    sys.exit(1)


latest_report = reports[0]


# =========================================================
# DETERMINE HEALTH STATUS
# =========================================================

report_content = latest_report.read_text(
    encoding="utf-8"
)

if "Overall System Health:" in report_content:

    if "Overall System Health:\nCRITICAL" in report_content:
        health_status = "CRITICAL"

    elif "Overall System Health:\nWARNING" in report_content:
        health_status = "WARNING"

    else:
        health_status = "HEALTHY"

else:

    health_status = "UNKNOWN"


# =========================================================
# CREATE EMAIL
# =========================================================

computer_name = os.uname().nodename

subject = (
    f"PC Health Report - "
    f"{computer_name} - "
    f"{health_status}"
)


body = f"""
Hello,

Attached is the latest PC Health Report.

Computer:
{computer_name}

Health Status:
{health_status}

Report Generated:
{datetime.now()}

The complete HTML report is attached.

Regards,
Python Automation
"""


message = EmailMessage()

message["From"] = EMAIL_FROM
message["To"] = EMAIL_TO
message["Subject"] = subject

message.set_content(body)


# =========================================================
# ATTACH HTML REPORT
# =========================================================

message.add_attachment(
    latest_report.read_bytes(),
    maintype="text",
    subtype="html",
    filename=latest_report.name,
)


# =========================================================
# SEND EMAIL
# =========================================================

print()
print("=" * 40)
print("       EMAIL REPORT SENDER")
print("=" * 40)
print()

print(f"SMTP Server : {SMTP_SERVER}")
print(f"SMTP Port   : {SMTP_PORT}")
print(f"From        : {EMAIL_FROM}")
print(f"To          : {EMAIL_TO}")
print(f"Report      : {latest_report.name}")
print(f"Health      : {health_status}")

print()
print("Sending email...")


try:

    with smtplib.SMTP(
        SMTP_SERVER,
        SMTP_PORT
    ) as server:

        server.starttls()

        server.login(
            SMTP_USERNAME,
            SMTP_PASSWORD
        )

        server.send_message(message)

    print()
    print("Email sent successfully!")

except Exception as error:

    print()
    print("Failed to send email.")
    print()
    print(f"Error: {error}")

    sys.exit(1)


print()
print("=" * 40)
print("EMAIL REPORT COMPLETE")
print("=" * 40)
