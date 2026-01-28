"""
Firebase Services Activation Script
Uses Firebase REST API to enable Authentication, Firestore, and Storage
"""

import requests
import json

# Firebase Project Configuration
PROJECT_ID = "okulavatar"
API_KEY = "AIzaSyC_EvYSRzTk1Yvfjyxgla-qc-9vtS5mVU4"

def check_auth_providers():
    """Check current Authentication providers"""
    url = f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT_ID}/config?key={API_KEY}"
    
    response = requests.get(url)
    if response.status_code == 200:
        config = response.json()
        print("✅ Authentication API accessible")
        print(f"Project: {config.get('name', 'N/A')}")
        
        sign_in = config.get('signIn', {})
        if sign_in:
            print(f"Email/Password enabled: {sign_in.get('email', {}).get('enabled', False)}")
        return config
    else:
        print(f"❌ Authentication check failed: {response.status_code}")
        print(response.text)
        return None

def enable_email_password():
    """Enable Email/Password authentication"""
    url = f"https://identitytoolkit.googleapis.com/v1/projects/{PROJECT_ID}/config?updateMask=signIn.email.enabled&key={API_KEY}"
    
    payload = {
        "signIn": {
            "email": {
                "enabled": True,
                "passwordRequired": True
            }
        }
    }
    
    response = requests.patch(url, json=payload)
    if response.status_code == 200:
        print("✅ Email/Password authentication enabled")
        return True
    else:
        print(f"❌ Failed to enable Email/Password: {response.status_code}")
        print(response.text)
        return False

def check_firestore():
    """Check Firestore status"""
    # Note: Firestore database creation requires admin SDK or Console
    # We can only verify if it's accessible
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)"
    
    response = requests.get(url)
    if response.status_code == 200:
        print("✅ Firestore database exists")
        print(response.json())
        return True
    elif response.status_code == 404:
        print("⚠️ Firestore database not created yet")
        print("   This must be done via Firebase Console:")
        print("   https://console.firebase.google.com/project/okulavatar/firestore")
        return False
    else:
        print(f"❌ Firestore check failed: {response.status_code}")
        print(response.text)
        return False

def check_storage():
    """Check Cloud Storage bucket"""
    bucket_name = f"{PROJECT_ID}.firebasestorage.app"
    url = f"https://firebasestorage.googleapis.com/v0/b/{bucket_name}"
    
    response = requests.get(url)
    if response.status_code == 200:
        print(f"✅ Storage bucket exists: {bucket_name}")
        return True
    else:
        print(f"⚠️ Storage bucket check: {response.status_code}")
        print("   Bucket might not be initialized via Console")
        return False

def main():
    print("=" * 60)
    print("Firebase Services Activation for KresAI")
    print("=" * 60)
    print()
    
    print("📋 Checking current status...\n")
    
    # Check Authentication
    print("1️⃣ Authentication Service")
    print("-" * 40)
    auth_config = check_auth_providers()
    print()
    
    if auth_config:
        email_enabled = auth_config.get('signIn', {}).get('email', {}).get('enabled', False)
        if not email_enabled:
            print("🔧 Enabling Email/Password authentication...")
            enable_email_password()
            print()
    
    # Check Firestore
    print("2️⃣ Firestore Database")
    print("-" * 40)
    check_firestore()
    print()
    
    # Check Storage
    print("3️⃣ Cloud Storage")
    print("-" * 40)
    check_storage()
    print()
    
    print("=" * 60)
    print("✅ Script complete!")
    print("=" * 60)
    print()
    print("📝 Next Steps:")
    print("1. If Firestore is not created, go to Firebase Console:")
    print("   https://console.firebase.google.com/project/okulavatar/firestore")
    print("   Click 'Create Database' → Test Mode → europe-west1")
    print()
    print("2. If Storage is not enabled, go to:")
    print("   https://console.firebase.google.com/project/okulavatar/storage")
    print("   Click 'Get Started' → Test Mode → europe-west1")
    print()

if __name__ == "__main__":
    main()
