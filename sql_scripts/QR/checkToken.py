import hmac
import hashlib
from urllib.parse import quote_plus

SECRET_KEY = b"SuperSecretKey123!"  # Must match your app.py

employee_id = "TEST123"
employee_name = "John Doe"
branch_name = "Main Branch"

# URL-encode names
emp_name_encoded = quote_plus(employee_name)
branch_encoded = quote_plus(branch_name)

# Create HMAC token
data_to_sign = f"{employee_id}|{branch_encoded}|{emp_name_encoded}"
token = hmac.new(SECRET_KEY, data_to_sign.encode(), hashlib.sha256).hexdigest()

print("HMAC token:", token)
