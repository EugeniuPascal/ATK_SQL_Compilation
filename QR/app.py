import logging
import sys
import os
from flask import Flask, request, redirect, jsonify
from datetime import datetime
import hmac
import hashlib
import requests
from urllib.parse import unquote_plus
from msal import ConfidentialClientApplication

# ----------------------------
# Logging setup
# ----------------------------
logging.basicConfig(stream=sys.stderr, level=logging.INFO)
logger = logging.getLogger(__name__)

# ----------------------------
# Flask app
# ----------------------------
app = Flask(__name__)

# ----------------------------
# Environment variables
# ----------------------------
BASE_PLAY_STORE_URL = os.environ.get(
    "BASE_PLAY_STORE_URL", "https://play.google.com/store/search?q=microinvest&c=apps"
)
SECRET_KEY = os.environ.get("SECRET_KEY", "11cca544-17c1-4095-9645-9422d816fa60").encode()
TENANT_ID = os.environ["TENANT_ID"]
CLIENT_ID = os.environ["CLIENT_ID"]
CLIENT_SECRET = os.environ["CLIENT_SECRET"]
SITE_ID = os.environ["SITE_ID"]
LIST_ID = os.environ["LIST_ID"]
SCOPE = ["https://graph.microsoft.com/.default"]

# ----------------------------
# MSAL client
# ----------------------------
msal_app = ConfidentialClientApplication(
    client_id=CLIENT_ID,
    client_credential=CLIENT_SECRET,
    authority=f"https://login.microsoftonline.com/{TENANT_ID}"
)

# ----------------------------
# Get access token for Graph
# ----------------------------
def get_access_token():
    try:
        result = msal_app.acquire_token_silent(SCOPE, account=None)
        if not result:
            result = msal_app.acquire_token_for_client(scopes=SCOPE)
        if "access_token" not in result:
            raise Exception(f"Could not obtain access token: {result.get('error_description')}")
        return result["access_token"]
    except Exception as e:
        logger.warning(f"Azure token error: {e}")
        return None

# ----------------------------
# Log scan/install in SharePoint
# ----------------------------
def create_sharepoint_item(employee_id, employee_name, branch_name, scan_time, client_ip, user_agent, installed=False):
    token = get_access_token()
    if not token:
        logger.warning(f"Skipping SharePoint logging for {employee_id} — no token")
        return

    url = f"https://graph.microsoft.com/v1.0/sites/{SITE_ID}/lists/{LIST_ID}/items"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    data = {
        "fields": {
            "EmployeeID": employee_id,
            "EmployeeName": employee_name,
            "BranchName": branch_name,
            "ScanTime": scan_time.isoformat() + "Z",
            "ClientIP": client_ip,
            "UserAgent": user_agent,
            "InstalledApp": installed
        }
    }

    try:
        r = requests.post(url, json=data, headers=headers, timeout=10)
        if r.status_code not in (200, 201):
            logger.warning(f"SharePoint response ({employee_id}): {r.status_code}, {r.text}")
        else:
            logger.info(f"SharePoint logged successfully: {employee_id}")
    except Exception as e:
        logger.warning(f"SharePoint logging failed for {employee_id}: {e}")

# ----------------------------
# Root endpoint
# ----------------------------
@app.route("/")
def index():
    return "QR Scan service is running! Use /scan endpoint.", 200

# ----------------------------
# QR scan endpoint
# ----------------------------
@app.route("/scan")
def scan():
    employee_id = request.args.get("employee_id")
    employee_name = request.args.get("employee_name")
    branch_name = request.args.get("branch_name")
    token = request.args.get("token")

    if not all([employee_id, employee_name, branch_name, token]):
        return "Missing parameters", 400

    # Decode URL params
    employee_name = unquote_plus(employee_name)
    branch_name = unquote_plus(branch_name)

    # Verify HMAC
    data_to_sign = f"{employee_id}|{branch_name}|{employee_name}"
    expected_token = hmac.new(SECRET_KEY, data_to_sign.encode(), hashlib.sha256).hexdigest()

    if not hmac.compare_digest(token, expected_token):
        return "Invalid QR code", 403

    # Capture client info
    client_ip = request.headers.get("X-Forwarded-For", request.remote_addr)
    user_agent = request.headers.get("User-Agent", "unknown")
    scan_time = datetime.utcnow()

    # Log scan
    create_sharepoint_item(employee_id, employee_name, branch_name, scan_time, client_ip, user_agent, installed=False)
    logger.info(f"QR scanned: {employee_id} at {scan_time}, branch {branch_name}")

    # Redirect to Play Store
    play_url = f"{BASE_PLAY_STORE_URL}&referrer=employee_id_{employee_id}"
    return redirect(play_url)

# ----------------------------
# App installed callback
# ----------------------------
@app.route("/app_installed", methods=["POST"])
def app_installed():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Missing JSON body"}), 400

    required_fields = ["employee_id", "employee_name", "branch_name"]
    missing_fields = [f for f in required_fields if f not in data]
    if missing_fields:
        return jsonify({"error": f"Missing fields: {missing_fields}"}), 400

    employee_id = data["employee_id"]
    employee_name = data["employee_name"]
    branch_name = data["branch_name"]

    # Capture IP & User-Agent from request if not sent in JSON
    client_ip = data.get("client_ip") or request.headers.get("X-Forwarded-For", request.remote_addr)
    user_agent = data.get("user_agent") or request.headers.get("User-Agent", "unknown")
    install_time = datetime.utcnow()

    create_sharepoint_item(employee_id, employee_name, branch_name, install_time, client_ip, user_agent, installed=True)
    logger.info(f"App installed: {employee_id} at {install_time}, branch {branch_name}")

    return jsonify({"status": "success"}), 200

# ----------------------------
# Run app
# ----------------------------
if __name__ == "__main__":
    token = get_access_token()
    if token:
        print("✅ Access token retrieved successfully!")
    else:
        print("❌ Failed to get access token")

    # Start Flask app
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    app.run(host="0.0.0.0", port=port)
