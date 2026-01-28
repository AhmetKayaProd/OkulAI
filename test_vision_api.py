import requests
import json
import base64

# Test Gemini Vision API with schedule image
API_KEY = "AIzaSyDIJ2ugrWmZCjhHH43JG6ll0JbDwGnbup4"
API_URL = f"https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key={API_KEY}"

# Read and encode image
IMAGE_PATH = r"C:\Users\kayaa\.gemini\antigravity\brain\b319239c-7587-428d-97e5-3e8dcd21af1f\weekly_schedule_sample_1769196594370.png"

with open(IMAGE_PATH, "rb") as img_file:
    image_data = base64.b64encode(img_file.read()).decode('utf-8')

prompt = """
Bu görselde bir Kreş/Anaokulu için haftalık ders programı var. 
Lütfen bu programı okuyup JSON formatına çevir.

Çıktı formatı (JSON):
{
  "blocks": [
    {
      "dayOfWeek": 1,
      "startTime": "09:00",
      "endTime": "10:00",
      "label": "Matematik",
      "notes": ""
    }
  ]
}

KURALLAR:
- Görseldeki tüm ders programını oku
- Sadece JSON döndür, açıklama ekleme
- Saatleri HH:mm formatında yaz
- dayOfWeek: 1=Pazartesi, 7=Pazar
- dayOfWeek kullan
- label kısa ve öz olsun
- Eğer görselde notlar/açıklamalar varsa notes alanına ekle
"""

print("🧪 Testing Gemini Vision API with Schedule Image...")
print("=" * 60)

try:
    response = requests.post(
        API_URL,
        headers={"Content-Type": "application/json"},
        json={
            "contents": [{
                "parts": [
                    {"text": prompt},
                    {
                        "inline_data": {
                            "mime_type": "image/png",
                            "data": image_data
                        }
                    }
                ]
            }],
            "generationConfig": {
                "temperature": 0.2,
                "maxOutputTokens": 2048,
            }
        },
        timeout=30
    )
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        text = data['candidates'][0]['content']['parts'][0]['text']
        
        print("\n✅ Vision API Call Successful!")
        print("\n📝 Raw Response:")
        print(text)
        
        # Extract JSON
        cleaned = text.strip()
        if cleaned.startswith('```json'):
            cleaned = cleaned[7:]
        elif cleaned.startswith('```'):
            cleaned = cleaned[3:]
        if cleaned.endswith('```'):
            cleaned = cleaned[:-3]
        cleaned = cleaned.strip()
        
        print("\n🔍 Parsed JSON:")
        parsed = json.loads(cleaned)
        print(json.dumps(parsed, indent=2, ensure_ascii=False))
        
        blocks = parsed.get('blocks', [])
        print(f"\n📊 Result: {len(blocks)} blocks parsed from image")
        
        # Group by day
        days_dict = {}
        for block in blocks:
            day = block['dayOfWeek']
            if day not in days_dict:
                days_dict[day] = []
            days_dict[day].append(block)
        
        day_names = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar']
        
        for day_num in sorted(days_dict.keys()):
            print(f"\n{day_names[day_num - 1]}:")
            for block in days_dict[day_num]:
                print(f"  - {block['startTime']}-{block['endTime']}: {block['label']}")
        
        print("\n✅ IMAGE OCR TEST PASSED - Vision API can read schedules!")
        
    else:
        print(f"\n❌ API Error: {response.status_code}")
        print(response.text)
        
except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
    
print("\n" + "=" * 60)
