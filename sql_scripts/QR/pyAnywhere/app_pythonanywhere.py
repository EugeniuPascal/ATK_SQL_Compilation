import logging
import sys
from flask import Flask, request, redirect, jsonify
from datetime import datetime
import hmac, hashlib, requests
from urllib.parse import unquote_plus
from msal import ConfidentialClientApplication

# ----------------------------
# Logging setup
# ----------------------------
logging.basicConfig(stream=sys.stderr, level=logging.DEBUG)
logger = logging.getLogger()

# ----------------------------
# Flask app
# ----------------------------
app = Flask(__name__)

# ----------------------------
# Play Store & QR secret
# ----------------------------
BASE_PLAY_STORE_URL = "https://play.google.com/store/search?q=microinvest&c=apps"
SECRET_KEY = b"SuperSecretKey123!"  # Must match QR generator

# ----------------------------
# MSAL / Microsoft Graph configuration
# ----------------------------
TENANT_ID = "your-tenant-id"
CLIENT_ID = "your-client-id"
CLIENT_SECRET = "your-client-secret"
SCOPE = ["https://graph.microsoft.com/.default"]

SITE_ID = "your-site-id"
LIST_ID = "your-list-id"

# MSAL client
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
        r = requests.post(url, json=data, headers=headers)
        logger.info(f"SharePoint response ({employee_id}): {r.status_code} {r.text}")
    except Exception as e:
        logger.warning(f"SharePoint logging failed for {employee_id}: {e}")

# ----------------------------
# QR scan endpoint
# ----------------------------
@app.route("/scan")
def scan():
    employee_id = request.args.get("employee_id")
    employee_name = request.args.get("employee_name")
    branch_name = request.args.get("branch_name")
    token = request.args.get("token")

    logger.debug(f"/scan called with employee_id={employee_id}, employee_name={employee_name}, branch_name={branch_name}, token={token}")

    if not all([employee_id, employee_name, branch_name, token]):
        logger.warning("Missing parameters in /scan request")
        return "Missing parameters", 400

    # Decode URL params
    employee_name = unquote_plus(employee_name)
    branch_name = unquote_plus(branch_name)

    # Verify HMAC
    data_to_sign = f"{employee_id}|{branch_name}|{employee_name}"
    expected_token = hmac.new(SECRET_KEY, data_to_sign.encode(), hashlib.sha256).hexdigest()
    logger.debug(f"Expected HMAC: {expected_token}")

    if not hmac.compare_digest(token, expected_token):
        logger.warning(f"Invalid QR code! Received token={token}")
        return "Invalid QR code", 403

    # Capture client info
    client_ip = request.headers.get("X-Forwarded-For", request.remote_addr)
    user_agent = request.headers.get("User-Agent")
    scan_time = datetime.utcnow()
    logger.info(f"Valid scan: employee_id={employee_id}, branch={branch_name}, IP={client_ip}, time={scan_time}")

    # Log scan
    create_sharepoint_item(employee_id, employee_name, branch_name, scan_time, client_ip, user_agent, installed=False)

    # Redirect to Play Store
    play_url = f"{BASE_PLAY_STORE_URL}&referrer=employee_id_{employee_id}"
    logger.debug(f"Redirecting to Play Store URL: {play_url}")
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
    if not all(field in data for field in required_fields):
        return jsonify({"error": f"Missing fields: {required_fields}"}), 400

    employee_id = data["employee_id"]
    employee_name = data["employee_name"]
    branch_name = data["branch_name"]
    client_ip = data.get("client_ip", "unknown")
    user_agent = data.get("user_agent", "unknown")
    install_time = datetime.utcnow()
    logger.info(f"App installed callback: {employee_id}, {branch_name}, IP={client_ip}")

    create_sharepoint_item(employee_id, employee_name, branch_name, install_time, client_ip, user_agent, installed=True)
    return jsonify({"status": "success"}), 200

# ----------------------------
# Run locally
# ----------------------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True) 
