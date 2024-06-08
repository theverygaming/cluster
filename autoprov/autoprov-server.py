#!/usr/bin/env python3
import logging
import hashlib
import pathlib
import re
import json
import secrets
import threading
import sqlite3
import datetime
import flask
import waitress
import sillyorm
from sillyorm.dbms import sqlite


# NOTE: this code is very much NOT secure! Basically hands out free keys lol
APP_DATA_PATH = "/var/lib/autoprov-server"
KEY_DATA_PATH = "/var/lib/autoprov-client/keys"


class Sequence(sillyorm.model.Model):
    _name = "sequence"

    name = sillyorm.fields.String(length=255)
    num_next = sillyorm.fields.Integer()

    def create(self, vals):
        if "num_next" not in vals:
            vals["num_next"] = 0
        return super().create(vals)
    
    def get_next(self):
        ret = self.num_next
        self.num_next += 1
        return ret


class Node(sillyorm.model.Model):
    _name = "node"

    validated = sillyorm.fields.Boolean()
    api_key = sillyorm.fields.Text()
    hwid = sillyorm.fields.Text()
    hostname = sillyorm.fields.String(length=255)
    last_seen_time = sillyorm.fields.String(length=255)

env = None
env_lock = threading.Lock()
app = flask.Flask(__name__)

@app.route("/api/register", methods=["POST"])
def route_api_register():
    rdata = flask.request.get_json()
    env_lock.acquire()
    try:
        hwid = hashlib.sha512(json.dumps(rdata["hwinfo"]).encode("utf-8")).hexdigest()
        node = env["node"].search([("hwid", "=", hwid)])
        sequence = env["sequence"].search([("name", "=", "node")])
        if node is None:
            node = env["node"].create({
                "validated": True,
                "api_key": secrets.token_urlsafe(64),
                "hwid": hwid,
                "hostname": f"cluster-node-{sequence.get_next()}",
                "last_seen_time": datetime.datetime.utcnow().isoformat(),
            })
        return {
            "api_key": node.api_key,
        }
    finally:
        env_lock.release()

@app.route("/api/get_prov_values", methods=["POST"])
def route_api_get_prov_values():
    rdata = flask.request.get_json()
    env_lock.acquire()
    try:
        node = env["node"].search([("api_key", "=", rdata["api_key"])])
        node.last_seen_time = datetime.datetime.utcnow().isoformat()
        if not node.validated:
            raise Exception("unauthorized")
        keys = {"sample": "abcde", "sample2": "defg"}
        with open(KEY_DATA_PATH + "/k3s", "r") as f:
            keys["k3s"] = f.read()
        return {
            "hostname": node.hostname,
            "keys": keys
        }
    finally:
        env_lock.release()

@app.route("/api/ping", methods=["POST"])
def route_api_ping():
    rdata = flask.request.get_json()
    env_lock.acquire()
    try:
        node = env["node"].search([("api_key", "=", rdata["api_key"])])
        if not node.validated:
            raise Exception("unauthorized")
        node.last_seen_time = datetime.datetime.utcnow().isoformat()
        return {}
    finally:
        env_lock.release()

@app.route("/", methods=["GET", "POST"])
def route_root():
    env_lock.acquire()
    try:            
        nodes = env["node"].search([])
        ret = "<!DOCTYPE html>\n<html>\n<head>\n<style>\ntable, th, td {\n  border:1px solid black;\n}\n</style>\n</head>\n<body>\n"
        ret += "<h1>Nodes:</h1>\n"
        ret += '<form action="/" method="post">\n<table>\n<tr><th>Hostname</th><th>Hardware ID</th><th>last seen</th><th>Validated?</th>'
        for node in nodes if nodes is not None else []:
            ret += "<tr>"
            ret += f"<td>{node.hostname}</td>"
            ret += f"<td>{node.hwid}</td>"
            ret += f"<td>{node.last_seen_time}</td>"
            ret += f'<td><input type="checkbox" name="node_{node.id}_validated" {"checked readonly" if node.validated else ""} /></td>'
            ret += "</tr>"
        ret += '</table>\n<br>\n<label for="key">Key:</label><input type="password" id="key" name="key"><br><input type="submit" value="Submit">\n</form>\n'
        ret += "\n</body>\n</html>"
        return ret
    finally:
        env_lock.release()

logging.basicConfig(
    format="%(asctime)s %(levelname)s %(name)s: %(message)s", level=logging.DEBUG
)

class CustomSQLiteConnection(sillyorm.dbms.sqlite.SQLiteConnection):
    def __init__(self, *args, **kwargs):
        self._conn = sqlite3.connect(*args, **kwargs)

pathlib.Path(APP_DATA_PATH).mkdir(parents=True, exist_ok=True)

env = sillyorm.Environment(CustomSQLiteConnection(APP_DATA_PATH + "/autoprov.sqlite3", check_same_thread=False).cursor())
env.register_model(Node)
env.register_model(Sequence)

# ensure the node sequence exists
if env["sequence"].search([("name", "=", "node")]) is None:
    env["sequence"].create({"name": "node"})

waitress.serve(app, host="0.0.0.0", port="5851")
