import requests
import json

# URL de la API
base_url = "https://apimapeo-927498545444.us-central1.run.app"

# Primero hacer login para obtener el token
login_data = {
    "usuario": "admin",  # Cambiar por un usuario real
    "clave": "admin"     # Cambiar por la clave real
}

print("🔐 Intentando login...")
try:
    login_response = requests.post(f"{base_url}/api/auth/login", json=login_data)
    print(f"Status: {login_response.status_code}")
    print(f"Response: {login_response.text}")
    
    if login_response.status_code == 200:
        token = login_response.json().get('access_token')
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
        
        # Probar crear una planta
        planta_data = {
            "id_hilera": 1,
            "planta": 1,
            "ubicacion": "-33.7836829,-70.7396239"
        }
        
        print("\n🌱 Intentando crear planta...")
        print(f"Datos: {json.dumps(planta_data, indent=2)}")
        
        planta_response = requests.post(f"{base_url}/api/plantas/", json=planta_data, headers=headers)
        print(f"Status: {planta_response.status_code}")
        print(f"Response: {planta_response.text}")
        
        # Probar obtener plantas
        print("\n📋 Intentando obtener plantas...")
        plantas_response = requests.get(f"{base_url}/api/plantas/", headers=headers)
        print(f"Status: {plantas_response.status_code}")
        print(f"Response: {plantas_response.text[:500]}...")
        
    else:
        print("❌ Login falló")
        
except Exception as e:
    print(f"❌ Error: {str(e)}") 