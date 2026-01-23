# Mindiff Backend - Système d'Authentification

## 📋 Vue d'ensemble

Système d'authentification complet avec JWT pour l'API Mindiff.

## 🔑 Fonctionnalités

- ✅ Inscription d'utilisateur avec validation
- ✅ Connexion avec email/mot de passe
- ✅ Token JWT pour l'authentification
- ✅ Hash sécurisé des mots de passe (bcrypt)
- ✅ Protection des routes avec dépendances
- ✅ Support OAuth2 (compatible Swagger UI)
- ✅ Gestion des rôles (utilisateur actif, superutilisateur)

## 🚀 Installation

### 1. Installer les dépendances

```bash
pip install -r requirements.txt
```

### 2. Configurer les variables d'environnement

Créer un fichier `.env` à la racine du projet :

```bash
cp .env.example .env
```

Modifier le fichier `.env` avec vos paramètres :

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/mindiff

# JWT Configuration
SECRET_KEY=votre-cle-secrete-tres-longue-et-securisee
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Application
DEBUG=True
```

**⚠️ IMPORTANT** : Générer une clé secrète sécurisée :

```bash
openssl rand -hex 32
```

### 3. Configurer la base de données PostgreSQL

```bash
# Installer PostgreSQL si nécessaire
sudo apt install postgresql postgresql-contrib

# Créer la base de données
sudo -u postgres psql
CREATE DATABASE mindiff;
CREATE USER mindiff_user WITH PASSWORD 'votre_mot_de_passe';
GRANT ALL PRIVILEGES ON DATABASE mindiff TO mindiff_user;
\q
```

### 4. Lancer l'application

```bash
uvicorn app.main:app --reload
```

L'API sera accessible sur : http://localhost:8000

Documentation interactive : http://localhost:8000/docs

## 📚 Endpoints API

### Authentification

#### POST `/api/auth/register`
Créer un nouveau compte utilisateur.

**Body:**
```json
{
  "email": "user@example.com",
  "username": "utilisateur",
  "password": "motdepasse123"
}
```

**Response (201):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "utilisateur",
  "is_active": true,
  "is_superuser": false,
  "created_at": "2025-11-28T10:00:00Z",
  "updated_at": null
}
```

#### POST `/api/auth/login`
Connexion et obtention d'un token JWT.

**Body:**
```json
{
  "email": "user@example.com",
  "password": "motdepasse123"
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

#### POST `/api/auth/login/form`
Connexion via OAuth2 form (pour Swagger UI).

**Form data:**
- username: email de l'utilisateur
- password: mot de passe

#### GET `/api/auth/me`
Récupérer les informations de l'utilisateur connecté (protégé).

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "utilisateur",
  "is_active": true,
  "is_superuser": false,
  "created_at": "2025-11-28T10:00:00Z",
  "updated_at": null
}
```

## 🔒 Protection des routes

Pour protéger une route, utiliser les dépendances :

```python
from fastapi import APIRouter, Depends
from app.core.dependencies import get_current_active_user, get_current_superuser
from app.models.user import User

router = APIRouter()

# Route protégée - utilisateur connecté
@router.get("/protected")
async def protected_route(current_user: User = Depends(get_current_active_user)):
    return {"message": f"Hello {current_user.username}"}

# Route protégée - superutilisateur uniquement
@router.get("/admin")
async def admin_route(current_user: User = Depends(get_current_superuser)):
    return {"message": "Admin access"}
```

## 🏗️ Architecture

```
app/
├── api/
│   └── auth.py              # Routes d'authentification
├── core/
│   ├── config.py            # Configuration de l'application
│   ├── security.py          # Fonctions de sécurité (hash, JWT)
│   └── dependencies.py      # Dépendances FastAPI (auth)
├── db/
│   └── database.py          # Configuration SQLAlchemy
├── models/
│   └── user.py              # Modèle User
├── schemas/
│   └── user.py              # Schémas Pydantic
├── services/
│   └── user_service.py      # Logique métier utilisateur
└── main.py                  # Point d'entrée de l'application
```

## 🧪 Tests

Créer des tests dans le dossier `tests/` :

```python
# tests/test_auth.py
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_register():
    response = client.post(
        "/api/auth/register",
        json={
            "email": "test@example.com",
            "username": "testuser",
            "password": "testpass123"
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert data["username"] == "testuser"

def test_login():
    # D'abord créer un utilisateur
    client.post(
        "/api/auth/register",
        json={
            "email": "test2@example.com",
            "username": "testuser2",
            "password": "testpass123"
        }
    )
    
    # Puis se connecter
    response = client.post(
        "/api/auth/login",
        json={
            "email": "test2@example.com",
            "password": "testpass123"
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"
```

## 🔐 Sécurité

- **Hash de mot de passe** : bcrypt avec salt automatique
- **JWT** : Tokens signés avec HS256
- **Expiration** : Les tokens expirent après 30 minutes (configurable)
- **HTTPS** : À configurer en production
- **CORS** : À restreindre en production

## 📝 Bonnes pratiques

1. **En production** :
   - Utiliser HTTPS uniquement
   - Restreindre les origines CORS
   - Utiliser une clé secrète forte et unique
   - Mettre à jour régulièrement les dépendances
   - Activer les logs de sécurité

2. **Gestion des tokens** :
   - Stocker les tokens côté client de manière sécurisée
   - Implémenter un refresh token pour les sessions longues
   - Invalider les tokens lors de la déconnexion

3. **Validation** :
   - Email valide requis
   - Mot de passe minimum 8 caractères
   - Username entre 3 et 50 caractères

## 🚨 Erreurs courantes

- **401 Unauthorized** : Token invalide ou expiré
- **400 Bad Request** : Utilisateur inactif ou données invalides
- **403 Forbidden** : Privilèges insuffisants
- **409 Conflict** : Email ou username déjà utilisé

## 📞 Support

Pour toute question, consultez la documentation interactive : http://localhost:8000/docs

