import requests
import time

BASE_URL = "http://127.0.0.1:8000"

def test_api():
    print("🧪 Testing Backend API...")
    
    # 1. Register
    print("\n1. Testing Registration...")
    email = f"test_{int(time.time())}@example.com"
    password = "password123"
    payload = {
        "email": email,
        "password": password,
        "full_name": "Test User"
    }
    try:
        response = requests.post(f"{BASE_URL}/register", json=payload)
        if response.status_code == 200:
            print(f"✅ Registration successful: {response.json()}")
        else:
            print(f"❌ Registration failed: {response.text}")
            return
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return

    # 2. Login
    print("\n2. Testing Login...")
    login_payload = {
        "username": email,
        "password": password
    }
    token = None
    try:
        response = requests.post(f"{BASE_URL}/token", data=login_payload)
        if response.status_code == 200:
            token = response.json()["access_token"]
            print(f"✅ Login successful. Token: {token[:20]}...")
        else:
            print(f"❌ Login failed: {response.text}")
            return
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return

    # 3. Get Profile
    print("\n3. Testing Get Profile...")
    headers = {"Authorization": f"Bearer {token}"}
    try:
        response = requests.get(f"{BASE_URL}/users/me", headers=headers)
        if response.status_code == 200:
            print(f"✅ Profile retrieved: {response.json()}")
        else:
            print(f"❌ Get Profile failed: {response.text}")
    except Exception as e:
        print(f"❌ Connection failed: {e}")

    # 4. Get Stats
    print("\n4. Testing Get Stats...")
    try:
        response = requests.get(f"{BASE_URL}/stats", headers=headers)
        if response.status_code == 200:
            print(f"✅ Stats retrieved: {response.json()}")
        else:
            print(f"❌ Get Stats failed: {response.text}")
    except Exception as e:
        print(f"❌ Connection failed: {e}")

if __name__ == "__main__":
    test_api()
