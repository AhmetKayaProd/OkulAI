import requests
import json
import sys

# Force UTF-8 encoding for console output
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')

# Test new API key with CORRECT model names
api_key = "AIzaSyBSJ8H2jn2KXiqKra-Bc2xGtWJcungDCQU"

# Based on latest Google AI Studio documentation
endpoints = [
    # Latest models (2024-2025)
    ("gemini-1.5-flash-latest", "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"),
    ("gemini-1.5-pro-latest", "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent"),
    # Stable versions
    ("gemini-1.5-flash", "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"),
    ("gemini-1.5-pro", "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent"),
]

payload = {
    "contents": [{
        "parts": [{"text": "Say 'API key works!' in Turkish"}]
    }]
}

print("=" * 60)
print("GEMINI API KEY TEST")
print("=" * 60)

for i, (model_name, endpoint) in enumerate(endpoints, 1):
    url = f"{endpoint}?key={api_key}"
    
    print(f"\n[{i}/{len(endpoints)}] Testing: {model_name}")
    
    try:
        response = requests.post(
            url,
            headers={'Content-Type': 'application/json'},
            json=payload,
            timeout=15
        )
        
        print(f"    Status: {response.status_code}")
        
        if response.status_code == 200:
            print(f"    [SUCCESS] Model works!")
            data = response.json()
            # Extract response text
            try:
                text = data['candidates'][0]['content']['parts'][0]['text']
                print(f"    AI Response: {text}")
            except:
                pass
            print("\n" + "=" * 60)
            print(f"WORKING MODEL: {model_name}")
            print(f"URL: {endpoint}")
            print("=" * 60)
            break
        else:
            print(f"    [FAILED]")
            try:
                error_data = response.json()
                error_msg = error_data.get('error', {}).get('message', '')[:80]
                print(f"    Error: {error_msg}")
            except:
                print(f"    Error: {response.text[:80]}")
    except Exception as e:
        print(f"    [ERROR] {str(e)[:80]}")

print("\n" + "=" * 60)
print("Test completed")
print("=" * 60)
