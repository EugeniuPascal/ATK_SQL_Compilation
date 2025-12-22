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
# Environment variables / defaults
# ----------------------------
BASE_PLAY_STORE_URL = os.environ.get(
    "BASE_PLAY_STORE_URL", "https://play.google.com/store/apps/details?id=md.microinvest"
)
BASE_APP_STORE_URL = os.environ.get(
    "BASE_APP_STORE_URL", "https://apps.apple.com/md/app/microinvest/id6469601272"
)

SECRET_KEY = b"11cca544-17c1-4095-9645-9422d816fa60"

TENANT_ID = os.environ.get("TENANT_ID")
CLIENT_ID = os.environ.get("CLIENT_ID")
CLIENT_SECRET = os.environ.get("CLIENT_SECRET")
SITE_ID = os.environ.get("SITE_ID")
LIST_ID = os.environ.get("LIST_ID")

if not all([TENANT_ID, CLIENT_ID, CLIENT_SECRET, SITE_ID, LIST_ID]):
    raise RuntimeError("❌ One or more required environment variables are missing")

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
# SharePoint internal field mapping
# ----------------------------
SHAREPOINT_FIELDS = {
    "title": "Title",
    "employee_id": "empID",
    "employee_name": "empName",
    "branch_name": "ScanDate",
    "scan_time": "IP",
    "client_ip": "UserAgent",
    "user_agent": "RedirectURL",
    "installed": "Notes",
    "created": "Created",
    "modified": "Modified",
    "created_by": "Author",
    "modified_by": "Editor"
}

# ----------------------------
# Get access token
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
# SharePoint logging
# ----------------------------
def create_sharepoint_item(employee_id, employee_name, branch_name, scan_time, client_ip, user_agent, installed=False):
    token = get_access_token()
    if not token:
        logger.warning(f"Skipping SharePoint logging for {employee_id} — no token")
        return

    url = f"https://graph.microsoft.com/v1.0/sites/{SITE_ID}/lists/{LIST_ID}/items"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    installed_value = "Yes" if installed else "No"
    scan_time_value = scan_time.isoformat() + "Z"

    payload = {
        "fields": {
            SHAREPOINT_FIELDS["title"]: f"{employee_id} - {branch_name}"[:255],
            SHAREPOINT_FIELDS["employee_id"]: str(employee_id),
            SHAREPOINT_FIELDS["employee_name"]: str(employee_name),
            SHAREPOINT_FIELDS["branch_name"]: str(branch_name),
            SHAREPOINT_FIELDS["scan_time"]: scan_time_value,
            SHAREPOINT_FIELDS["client_ip"]: str(client_ip),
            SHAREPOINT_FIELDS["user_agent"]: str(user_agent),
            SHAREPOINT_FIELDS["installed"]: installed_value
        }
    }

    logger.info(f"SharePoint payload for {employee_id}: {payload}")

    try:
        r = requests.post(url, json=payload, headers=headers, timeout=10)
        if r.status_code in (200, 201):
            logger.info(f"SharePoint logged successfully: {employee_id}")
        else:
            logger.warning(f"SharePoint response ({employee_id}): {r.status_code}, {r.text}")
    except requests.exceptions.RequestException as e:
        logger.warning(f"SharePoint request failed for {employee_id}: {e}")

# ----------------------------
# Root endpoint
# ----------------------------
@app.route("/")
def index():
    return "QR Scan service is running! Use /scan endpoint.", 200

# ----------------------------
# QR scan endpoint (Android + iOS)
# ----------------------------
@app.route("/scan")
def scan():
    employee_id = request.args.get("employee_id")
    employee_name = request.args.get("employee_name")
    branch_name = request.args.get("branch_name")
    token = request.args.get("token")

    if not all([employee_id, employee_name, branch_name, token]):
        return "Missing parameters", 400

    employee_name = unquote_plus(employee_name)
    branch_name = unquote_plus(branch_name)

    # Verify HMAC
    data_to_sign = f"{employee_id}|{branch_name}|{employee_name}"
    expected_token = hmac.new(SECRET_KEY, data_to_sign.encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(token, expected_token):
        return "Invalid QR code", 403

    client_ip = request.headers.get("X-Forwarded-For", "").split(",")[0] or request.remote_addr
    user_agent = request.headers.get("User-Agent", "unknown")
    scan_time = datetime.utcnow()

    # Log scan
    create_sharepoint_item(employee_id, employee_name, branch_name, scan_time, client_ip, user_agent, installed=False)
    logger.info(f"QR scanned: {employee_id} at {scan_time}, branch {branch_name}")

    # Detect platform
    ua = user_agent.lower()
    if "iphone" in ua or "ipad" in ua or "ipod" in ua:
        redirect_url = BASE_APP_STORE_URL
    else:
        redirect_url = f"{BASE_PLAY_STORE_URL}&referrer=employee_id_{employee_id}_branch_{branch_name}"

    return redirect(redirect_url, code=302)

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

    client_ip = data.get("client_ip") or request.headers.get("X-Forwarded-For", "").split(",")[0] or request.remote_addr
    user_agent = data.get("user_agent") or request.headers.get("User-Agent", "unknown")
    install_time = datetime.utcnow()

    create_sharepoint_item(employee_id, employee_name, branch_name, install_time, client_ip, user_agent, installed=True)
    logger.info(f"App installed: {employee_id} at {install_time}, branch {branch_name}")

    return jsonify({"status": "success"}), 200

# ----------------------------
# ✅ No app.run() — Azure will use gunicorn
# ----------------------------
