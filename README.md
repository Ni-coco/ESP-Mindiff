# Mindiff Backend

## 📋 Vue d'ensemble

API REST pour la gestion d'exercices de fitness avec système d'authentification JWT.

### Fonctionnalités principales :
- 🔐 **Authentification** : Inscription, connexion et gestion d'utilisateurs avec JWT
- 💪 **Exercices** : CRUD complet pour les exercices de fitness
- 🔍 **Recherche et filtres** : Recherche par nom, filtrage par partie du corps, équipement et muscle ciblé
- 📊 **Import de données** : Script d'import depuis fichiers JSON

## 🚀 Installation

### 1. Installer les dépendances avec uv

Le projet utilise `uv` pour la gestion des dépendances :

```bash
# Installer uv si nécessaire
curl -LsSf https://astral.sh/uv/install.sh | sh

# Installer les dépendances
uv sync
```

Ou avec pip traditionnel :

```bash
pip install -e .
```

### 2. Configurer les variables d'environnement

Créer un fichier `.env` à la racine du projet :

```bash
cp .env.example .env
```

Modifier le fichier `.env` avec vos paramètres :

```env
# Database
# SQLite (pour développement - par défaut)
DATABASE_URL=sqlite:///./mindiff.db
# PostgreSQL (pour production)
# DATABASE_URL=postgresql://user:password@localhost:5432/mindiff

# JWT Configuration
SECRET_KEY=votre-cle-secrete-tres-longue-et-securisee
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Application
DEBUG=True

# Workspace (pour le script d'import)
WORKSPACE_PATH=/chemin/vers/le/projet
```

**⚠️ IMPORTANT** : Générer une clé secrète sécurisée :

```bash
openssl rand -hex 32
```

### 3. Configurer la base de données

#### Option A : SQLite (Développement)
La base de données sera créée automatiquement au démarrage.

#### Option B : PostgreSQL (Production)

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

Puis modifier `DATABASE_URL` dans `.env` :
```env
DATABASE_URL=postgresql://mindiff_user:votre_mot_de_passe@localhost:5432/mindiff
```

### 4. Lancer l'application

```bash
uvicorn app.main:app --reload
```

L'API sera accessible sur : http://localhost:8000

Documentation interactive : http://localhost:8000/docs

## 🏗️ Architecture

```
app/
├── api/
│   ├── auth.py              # Routes d'authentification
│   ├── exercise.py          # Routes pour les exercices
│   └── user.py              # Routes utilisateur
├── core/
│   ├── config.py            # Configuration de l'application
│   ├── security.py          # Fonctions de sécurité (hash, JWT)
│   └── dependencies.py      # Dépendances FastAPI (auth, db)
├── db/
│   └── database.py          # Configuration SQLAlchemy
├── models/
│   ├── user.py              # Modèle User
│   └── exercise.py          # Modèles Exercise, Instruction, SecondaryMuscle, BodyPart
├── schemas/
│   ├── user.py              # Schémas Pydantic User
│   └── exercise.py          # Schémas Pydantic Exercise
├── services/
│   ├── user.py              # Logique métier utilisateur
│   └── exercise.py          # Logique métier exercices
└── main.py                  # Point d'entrée de l'application

scripts/
└── import_exercices.py      # Script d'import de données JSON

alembic/
└── versions/
```

## 🧪 Tests

Lancer les tests avec pytest :

```bash
pytest
```

Exemple de test disponible dans `tests/test_auth.py` pour l'authentification.

## 🔐 Sécurité

- **Hash de mot de passe** : bcrypt avec salt automatique via `passlib`
- **JWT** : Tokens signés avec HS256 via `python-jose`
- **Expiration** : Les tokens expirent après 30 minutes (configurable)
- **HTTPS** : À configurer en production
- **CORS** : Actuellement ouvert à tous (`allow_origins=["*"]`), à restreindre en production

## 📝 Bonnes pratiques

1. **En production** :
   - Utiliser HTTPS uniquement
   - Restreindre les origines CORS dans `app/main.py`
   - Utiliser PostgreSQL au lieu de SQLite
   - Utiliser une clé secrète forte et unique
   - Mettre `DEBUG=False`
   - Configurer un reverse proxy (nginx)
   - Activer les logs de sécurité

2. **Gestion des tokens** :
   - Stocker les tokens côté client de manière sécurisée (pas en localStorage si possible)
   - Implémenter un refresh token pour les sessions longues
   - Invalider les tokens lors de la déconnexion

3. **Validation** :
   - Email valide requis (validé par `email-validator`)
   - Mot de passe minimum 8 caractères
   - Username entre 3 et 50 caractères

## 🛠️ Technologies utilisées

- **FastAPI** : Framework web moderne et performant
- **SQLAlchemy** : ORM pour la gestion de base de données
- **Alembic** : Migrations de base de données
- **Pydantic** : Validation de données et settings
- **python-jose** : Gestion des JWT
- **passlib** : Hash de mots de passe avec bcrypt
- **uvicorn** : Serveur ASGI
