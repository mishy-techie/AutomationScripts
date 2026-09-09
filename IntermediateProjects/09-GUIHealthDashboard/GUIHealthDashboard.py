#!/usr/bin/env python3

"""
GUI Health Dashboard

Project: GUI Health Dashboard
Concept: GUI controls
Language: Python

Designed to work on Linux and Windows where Tkinter is available.
"""

import os
import platform
import shutil
import socket
import subprocess
import time
import tkinter as tk
from tkinter import ttk, messagebox


# ------------------------------------------------------------
# Health checks
# ------------------------------------------------------------

def get_cpu_health():
    try:
        if platform.system() == "Linux":
            load = os.getloadavg()[0]
            cpu_count = os.cpu_count() or 1
            usage = min((load / cpu_count) * 100, 100)

            if usage >= 90:
                status = "CRITICAL"
            elif usage >= 75:
                status = "WARNING"
            else:
                status = "OK"

            return "CPU Usage", f"{usage:.1f}%", status

        return "CPU Usage", "Available", "OK"

    except Exception:
        return "CPU Usage", "Unavailable", "WARNING"


def get_memory_health():
    try:
        if platform.system() == "Linux":
            memory = {}

            with open("/proc/meminfo", "r") as file:
                for line in file:
                    key, value = line.split(":", 1)
                    memory[key] = int(value.strip().split()[0])

            total = memory["MemTotal"]
            available = memory["MemAvailable"]

            used_percent = ((total - available) / total) * 100

            if used_percent >= 90:
                status = "CRITICAL"
            elif used_percent >= 75:
                status = "WARNING"
            else:
                status = "OK"

            return "Memory Usage", f"{used_percent:.1f}%", status

        return "Memory Usage", "Available", "OK"

    except Exception:
        return "Memory Usage", "Unavailable", "WARNING"


def get_disk_health():
    try:
        disk = shutil.disk_usage("/")

        free_percent = (disk.free / disk.total) * 100

        if free_percent < 10:
            status = "CRITICAL"
        elif free_percent < 20:
            status = "WARNING"
        else:
            status = "OK"

        return "Disk Free Space", f"{free_percent:.1f}%", status

    except Exception:
        return "Disk Free Space", "Unavailable", "WARNING"


def get_internet_health():
    try:
        socket.create_connection(
            ("1.1.1.1", 53),
            timeout=3
        )

        return "Internet", "Connected", "OK"

    except OSError:
        return "Internet", "Offline", "CRITICAL"


def get_uptime_health():
    try:
        if platform.system() == "Linux":

            with open("/proc/uptime", "r") as file:
                uptime_seconds = float(
                    file.read().split()[0]
                )

            days = int(uptime_seconds // 86400)

            hours = int(
                (uptime_seconds % 86400) // 3600
            )

            minutes = int(
                (uptime_seconds % 3600) // 60
            )

            value = f"{days}d {hours}h {minutes}m"

            if days >= 14:
                status = "WARNING"
            else:
                status = "OK"

            return "System Uptime", value, status

        return "System Uptime", "Available", "OK"

    except Exception:
        return "System Uptime", "Unavailable", "WARNING"


def get_health_data():
    return [
        get_cpu_health(),
        get_memory_health(),
        get_disk_health(),
        get_internet_health(),
        get_uptime_health(),
    ]


# ------------------------------------------------------------
# GUI application
# ------------------------------------------------------------

class HealthDashboard:

    def __init__(self, root):

        self.root = root

        self.root.title("PC Health Dashboard")
        self.root.geometry("750x550")
        self.root.resizable(False, False)

        # ----------------------------------------------------
        # Title
        # ----------------------------------------------------

        title = ttk.Label(
            root,
            text="PC HEALTH DASHBOARD",
            font=("Segoe UI", 20, "bold")
        )

        title.pack(pady=(20, 5))

        # ----------------------------------------------------
        # Overall status
        # ----------------------------------------------------

        self.status_label = ttk.Label(
            root,
            text="Overall Status: Checking...",
            font=("Segoe UI", 14, "bold")
        )

        self.status_label.pack(pady=5)

        # ----------------------------------------------------
        # Health table
        # ----------------------------------------------------

        columns = (
            "check",
            "value",
            "status"
        )

        self.tree = ttk.Treeview(
            root,
            columns=columns,
            show="headings",
            height=12
        )

        self.tree.heading(
            "check",
            text="Health Check"
        )

        self.tree.heading(
            "value",
            text="Value"
        )

        self.tree.heading(
            "status",
            text="Status"
        )

        self.tree.column(
            "check",
            width=250
        )

        self.tree.column(
            "value",
            width=200
        )

        self.tree.column(
            "status",
            width=150
        )

        self.tree.pack(
            padx=30,
            pady=20
        )

        # ----------------------------------------------------
        # Last updated
        # ----------------------------------------------------

        self.updated_label = ttk.Label(
            root,
            text="Last Updated: Never"
        )

        self.updated_label.pack()

        # ----------------------------------------------------
        # Buttons
        # ----------------------------------------------------

        button_frame = ttk.Frame(root)

        button_frame.pack(pady=20)

        refresh_button = ttk.Button(
            button_frame,
            text="Refresh",
            command=self.update_dashboard
        )

        refresh_button.grid(
            row=0,
            column=0,
            padx=10
        )

        exit_button = ttk.Button(
            button_frame,
            text="Exit",
            command=root.destroy
        )

        exit_button.grid(
            row=0,
            column=1,
            padx=10
        )

        # ----------------------------------------------------
        # Initial update
        # ----------------------------------------------------

        self.update_dashboard()

    # --------------------------------------------------------
    # Update dashboard
    # --------------------------------------------------------

    def update_dashboard(self):

        try:

            for item in self.tree.get_children():
                self.tree.delete(item)

            health_data = get_health_data()

            critical = 0
            warning = 0

            for name, value, status in health_data:

                self.tree.insert(
                    "",
                    "end",
                    values=(
                        name,
                        value,
                        status
                    )
                )

                if status == "CRITICAL":
                    critical += 1

                elif status == "WARNING":
                    warning += 1

            if critical > 0:
                overall = "CRITICAL"
            elif warning > 0:
                overall = "WARNING"
            else:
                overall = "HEALTHY"

            self.status_label.config(
                text=f"Overall Status: {overall}"
            )

            self.updated_label.config(
                text=time.strftime(
                    "Last Updated: %Y-%m-%d %H:%M:%S"
                )
            )

        except Exception as error:

            messagebox.showerror(
                "Health Dashboard Error",
                str(error)
            )


# ------------------------------------------------------------
# Start application
# ------------------------------------------------------------

if __name__ == "__main__":

    root = tk.Tk()

    app = HealthDashboard(root)

    root.mainloop()