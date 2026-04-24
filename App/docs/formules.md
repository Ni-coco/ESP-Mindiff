# Formules — Frontend Mindiff

Fichier de référence pour tous les calculs d'affichage implémentés côté application.
Code source : `lib/pages/metrics_page.dart`

> Ces calculs sont **locaux** : ils ne sont jamais envoyés au backend. Ils transforment
> l'historique de poids reçu de l'API en indicateurs lisibles par l'utilisateur.

---

## 1. IMC — Indice de Masse Corporelle

### Formule

```
IMC = poids_kg / (taille_m)²
    = poids_kg / (taille_cm / 100)²
```

### Catégories OMS affichées

| Valeur IMC   | Statut affiché  | Couleur  |
|--------------|-----------------|----------|
| < 18.5       | Insuffisance    | Bleu     |
| 18.5 – 24.9  | Normal          | Vert     |
| 25.0 – 29.9  | Surpoids        | Orange   |
| ≥ 30.0       | Obésité         | Rouge    |

### Exemple

75 kg, 180 cm :
```
IMC = 75 / (1.80)² = 75 / 3.24 ≈ 23.1  → Normal
```

### Données sources

- `poids` : dernier poids réel (source ≠ `carried_forward`) de l'historique, sinon `actual_weight` du profil
- `taille` : `heightCm` du profil ; valeur de repli = 175 cm si non renseigné

---

## 2. Historique IMC

L'historique de l'IMC est calculé à partir de l'historique de poids en appliquant la même formule point par point avec la taille actuelle de l'utilisateur (taille supposée constante).

```
IMC(date) = poids(date) / (taille_cm / 100)²
```

---

## 3. Variation de poids sur 30 jours

Exprimée en pourcentage, elle compare le poids actuel au dernier poids enregistré **avant** J−30.

### Formule

```
variation_% = (poids_actuel − poids_J−30) / poids_J−30 × 100
```

### Détermination de `poids_J−30`

1. On cherche la dernière mesure **strictement antérieure** à `DateTime.now() − 30 jours`
2. Si aucune mesure n'est aussi ancienne → on prend la **première** mesure de l'historique
3. Si l'historique est vide → variation = 0 %

### Affichage

| Résultat      | Texte affiché | Couleur |
|---------------|---------------|---------|
| variation > 0 | `+X.X%`       | Rouge   |
| variation < 0 | `−X.X%`       | Vert    |
| variation = 0 | `0.0%`        | Gris    |

> La couleur est intentionnellement inversée par rapport à une convention financière :
> une prise de poids est affichée en rouge, une perte en vert.

---

## 4. Progression vers l'objectif

La progression dépend de l'objectif déclaré (`sport_objective`).

### Objectif de perte / maintien (`lose_weight`, `maintain`)

```
total      = poids_départ − poids_cible
progression = clamp((poids_départ − poids_actuel) / total × 100, 0, 100)
```

Cas limites :
- Si `total ≤ 0` et `poids_actuel ≤ poids_cible` → 100 %
- Si `total ≤ 0` et `poids_actuel > poids_cible` → 0 %

### Objectif de prise / performance (`build_muscle`, `increase_strength`, `improve_endurance`, `general_fitness`)

```
total      = poids_cible − poids_départ
progression = clamp((poids_actuel − poids_départ) / total × 100, 0, 100)
```

Cas limites :
- Si `total ≤ 0` et `poids_actuel ≥ poids_cible` → 100 %
- Si `total ≤ 0` et `poids_actuel < poids_cible` → 0 %

### Données sources

| Variable        | Source                                       | Repli  |
|-----------------|----------------------------------------------|--------|
| `poids_départ`  | `weightKg` du profil utilisateur             | 80 kg  |
| `poids_cible`   | `target_weight` stocké dans le contrôleur    | 75 kg  |
| `poids_actuel`  | Dernière mesure réelle de l'historique       | voir §1|

---

## 5. Poids moyen

Moyenne arithmétique simple sur la **fenêtre d'affichage** (28 derniers jours max, voir §6).

```
poids_moyen = somme(poids_i) / nombre_de_mesures
```

Si la fenêtre est vide → retourne `poids_actuel`.

---

## 6. Fenêtre d'affichage de l'historique

Le graphique et les statistiques n'affichent que les **28 dernières entrées** de l'historique (≈ 4 semaines de mesures quotidiennes).

```
si len(historique) ≤ 28  → affiche tout l'historique
si len(historique) > 28  → affiche historique[-28:]
```

> Cette fenêtre s'applique au graphique de poids, au graphique d'IMC et au calcul du poids moyen.
> La variation 30 jours (§3) utilise en revanche **tout** l'historique brut pour trouver le point de référence.
