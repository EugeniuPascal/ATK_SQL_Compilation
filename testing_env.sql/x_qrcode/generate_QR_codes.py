import pyodbc
import qrcode
import os
import hmac
import hashlib
from urllib.parse import quote_plus
import re

# ----------------------------
# Secret key (hardcoded for testing)
# ----------------------------
SECRET_KEY = b"11cca544-17c1-4095-9645-9422d816fa60"

AZURE_BASE_SCAN_URL = os.environ.get(
    "AZURE_BASE_SCAN_URL",
    "https://e2e-qr-euayd0gnf6c3edas.germanywestcentral-01.azurewebsites.net/scan?"
)

# ----------------------------
# SQL Server connection
# ----------------------------
drivers = pyodbc.drivers()
sql_drivers = [d for d in drivers if "ODBC Driver" in d and "SQL Server" in d]
if not sql_drivers:
    raise RuntimeError("No suitable ODBC SQL Server driver found. Please install one.")

driver = sql_drivers[-1]
conn_str = f"DRIVER={{{driver}}};SERVER=MI-DEV-SQL01;DATABASE=ATK;Trusted_Connection=yes;Encrypt=no;"
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

# ----------------------------
# Fetch employees
# ----------------------------
cursor.execute("SELECT EmployeeID, EmployeeName, BranchName FROM mis.EmployeeQRscans")
employees = cursor.fetchall()
cursor.close()
conn.close()

# ----------------------------
# Output folder
# ----------------------------
base_output_dir = r"C:\QR_Project\QR_Codes"
os.makedirs(base_output_dir, exist_ok=True)

# ----------------------------
# Helper: sanitize filenames
# ----------------------------
def sanitize_filename(name: str) -> str:
    return re.sub(r'[^\w\-]', '_', name)

# ----------------------------
# Generate QR codes
# ----------------------------
for emp in employees:
    emp_id = str(emp.EmployeeID)
    emp_name = emp.EmployeeName
    branch_name = emp.BranchName

    # Generate HMAC token
    data_to_sign = f"{emp_id}|{branch_name}|{emp_name}"
    token = hmac.new(SECRET_KEY, data_to_sign.encode(), hashlib.sha256).hexdigest()

    # URL encode params for QR URL
    qr_url = (
        f"{AZURE_BASE_SCAN_URL}"
        f"employee_id={quote_plus(emp_id)}&"
        f"branch_name={quote_plus(branch_name)}&"
        f"employee_name={quote_plus(emp_name)}&"
        f"token={token}"
    )

    # Generate QR code
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4
    )
    qr.add_data(qr_url)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")

    # Save QR code in branch folder
    safe_branch = sanitize_filename(branch_name)
    branch_folder = os.path.join(base_output_dir, safe_branch)
    os.makedirs(branch_folder, exist_ok=True)

    safe_file = sanitize_filename(f"{emp_id}_{emp_name}_{branch_name}")
    img_path = os.path.join(branch_folder, f"{safe_file}.png")

    # Avoid overwriting existing files
    counter = 1
    original_path = img_path
    while os.path.exists(img_path):
        img_path = original_path.replace(".png", f"_{counter}.png")
        counter += 1

    img.save(img_path)
    print(f"Generated QR: {img_path}")

print(f"\n✅ Secure QR codes generated for {len(employees)} employees in {base_output_dir}")
