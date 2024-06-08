#!/usr/bin/env python3
import time
import sys
import platform
import subprocess
import uuid
import pathlib
import requests


CONTROL_URL = "http://clustercontrol.local:5851"
KEY_DATA_PATH = "/var/lib/autoprov-client/keys"


def send_json_request(url, json):
    resp = requests.post(url, json=json, timeout=5)
    if resp.status_code == requests.codes.ok:
        return resp.json()
    raise Exception(f"invalid response {resp} {resp.text}")

def initial_setup():
    apikey = send_json_request(
        CONTROL_URL + "/api/register",
        {
            "hwinfo": {
                "platform": {
                    "architecture": platform.architecture(),
                    "machine": platform.machine(),
                    "node": platform.node(),
                    "processor": platform.processor(),
                    "python_build": platform.python_build(),
                    "python_compiler": platform.python_compiler(),
                    "python_branch": platform.python_branch(),
                    "python_implementation": platform.python_implementation(),
                    "python_revision": platform.python_revision(),
                    "python_version": platform.python_version(),
                    "python_version_tuple": platform.python_version_tuple(),
                    "release": platform.release(),
                    "system": platform.system(),
                    "version": platform.version(),
                    "uname": platform.uname(),
                },
                "uuid_getnode": uuid.getnode()
            },
        }
    )["api_key"]

    resp = send_json_request(CONTROL_URL + "/api/get_prov_values", {"api_key": apikey})

    subprocess.run(["hostnamectl", "set-hostname", resp["hostname"]])

    pathlib.Path(KEY_DATA_PATH).mkdir(parents=True, exist_ok=True)

    resp["keys"]["autoprov"] = apikey
    for key, value in resp["keys"].items():
        print(f"{key}: {value}")
        with open(KEY_DATA_PATH + "/" + key, "w") as f:
            f.write(value)

def ping():
    with open(KEY_DATA_PATH + "/autoprov", "r") as f:
        apikey = f.read()
    send_json_request(CONTROL_URL + "/api/ping", {"api_key": apikey})


if len(sys.argv) == 2 and sys.argv[1] == "init":
    initial_setup()
else:
    ping()
