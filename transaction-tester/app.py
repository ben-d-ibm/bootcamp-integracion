import os
import uuid

import psycopg2
import psycopg2.extras
import requests
from flask import Flask, jsonify, request

app = Flask(__name__, static_folder="static", static_url_path="")

DB_HOST = os.environ.get("DB_HOST", "postgres")
DB_PORT = os.environ.get("DB_PORT", "5432")
DB_NAME = os.environ.get("DB_NAME", "bootcamp_db")
DB_USER = os.environ.get("DB_USER", "bootcamp_user")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "bootcamp_pass")


@app.get("/")
def index():
    return app.send_static_file("index.html")


@app.get("/api/cuentas")
def cuentas():
    try:
        conn = psycopg2.connect(
            host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD
        )
    except psycopg2.OperationalError as e:
        return jsonify({"error": str(e)}), 502

    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                "SELECT numero_cuenta, nombre, apellido, tipo_cuenta, saldo "
                "FROM clientes ORDER BY id"
            )
            rows = cur.fetchall()
        return jsonify(rows)
    finally:
        conn.close()


@app.post("/api/enviar")
def enviar():
    data = request.get_json()
    body = {
        "numero_cuenta": data["numero_cuenta"],
        "monto": data["monto"],
        "trx_id": str(uuid.uuid4()),
    }
    try:
        resp = requests.post(data["url"], json=body, timeout=15)
        return jsonify(
            {"ok": True, "sent": body, "status_code": resp.status_code, "response_body": resp.text}
        )
    except requests.RequestException as e:
        return jsonify({"ok": False, "sent": body, "error": str(e)})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
