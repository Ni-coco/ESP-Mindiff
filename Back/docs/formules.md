# Formules — Backend Mindiff

Fichier de référence pour toutes les formules de calcul implémentées côté serveur.
Code source : `app/services/meal_suggestions.py`

---

## 1. BMR — Métabolisme de base (Mifflin-St Jeor)

Le **BMR** (Basal Metabolic Rate) représente les calories brûlées au repos, sans aucune activité.

### Formule

```
BMR = (10 × poids_kg) + (6.25 × taille_cm) − (5 × âge_ans) + constante_genre
```

| Genre  | Constante |
|--------|-----------|
| Homme  | +5        |
| Femme  | −161      |

### Valeur utilisée pour le poids

Le champ `actual_weight` est prioritaire sur `weight` (poids de départ). Cela permet de recalculer le TDEE au fur et à mesure que l'utilisateur perd ou prend du poids.

```python
weight = metrics.actual_weight or metrics.weight
```

### Exemple

Homme, 75 kg, 180 cm, 25 ans :
```
BMR = (10 × 75) + (6.25 × 180) − (5 × 25) + 5
    = 750 + 1125 − 125 + 5
    = 1755 kcal/jour
```

---

## 2. TDEE — Dépense énergétique totale

Le **TDEE** (Total Daily Energy Expenditure) est le BMR ajusté par un multiplicateur d'activité physique, basé sur le nombre de séances sportives par semaine déclaré par l'utilisateur.

### Formule

```
TDEE = round(BMR × multiplicateur_activité)
```

### Table des multiplicateurs

| Sessions / semaine | Niveau d'activité   | Multiplicateur |
|--------------------|---------------------|----------------|
| 0                  | Sédentaire          | 1.200          |
| 1 – 2              | Légèrement actif    | 1.375          |
| 3 – 4              | Modérément actif    | 1.550          |
| 5+                 | Très actif          | 1.725          |

> **Valeur par défaut** : si `sessions_per_week` est `null` en base, on suppose 3 séances (multiplicateur 1.55).

### Exemple (suite)

Homme précédent, 3 séances/semaine :
```
TDEE = round(1755 × 1.55) = round(2720.25) = 2720 kcal/jour
```

---

## 3. Distribution calorique par repas

Les calories restantes de la journée sont réparties entre les slots repas **non encore loggés**.

### Proportions de base

| Slot      | Part du TDEE |
|-----------|-------------|
| breakfast | 25 %        |
| lunch     | 35 %        |
| dinner    | 30 %        |
| snack     | 10 %        |

### Redistribution dynamique

Si l'utilisateur a déjà loggé certains repas, les proportions restantes sont **renormalisées** pour se redistribuer à 100 % sur les slots manquants.

```
proportion_normalisée(slot) = proportion_base(slot) / somme_des_proportions_restantes
calories_cible(slot)        = max(100, round(calories_restantes × proportion_normalisée(slot)))
```

### Exemple

TDEE = 2000 kcal, déjeuner déjà loggé (500 kcal consommées).
Remaining = 1500 kcal. Slots restants : breakfast, dinner, snack.

```
somme_restante = 0.25 + 0.30 + 0.10 = 0.65

breakfast_cible = round(1500 × 0.25/0.65) = round(576.9) = 577 kcal
dinner_cible    = round(1500 × 0.30/0.65) = round(692.3) = 692 kcal
snack_cible     = round(1500 × 0.10/0.65) = round(230.8) = 231 kcal
```

---

## 4. Normalisation par portion (Edamam)

Les recettes Edamam retournent les **macros pour la recette entière**. Elles sont divisées par le nombre de portions (`yield`) pour obtenir les valeurs par portion.

```
calories_portion = round(calories_totales / yield)
protéines_g      = round(PROCNT_total / yield, 1)
lipides_g        = round(FAT_total / yield, 1)
glucides_g       = round(CHOCDF_total / yield, 1)
fibres_g         = round(FIBTG_total / yield, 1)
```

> `yield` est planché à 1 pour éviter une division par zéro : `servings = max(1, recipe.get("yield", 4))`.

### Plage de calories envoyée à Edamam

Pour trouver une recette proche de `target_cal`, on interroge Edamam avec une plage large (facteur ×2 à ×6) correspondant à 2 à 6 portions de la recette entière.

```
cal_min = target_cal × 2
cal_max = target_cal × 6
```

---

## 5. Correspondance objectif → requêtes Edamam

| Objectif (`sport_objective`) | Requêtes de recherche                    | Filtre diète Edamam |
|------------------------------|------------------------------------------|---------------------|
| `lose_weight`                | chicken salad, vegetable soup, grilled fish | low-fat          |
| `build_muscle`               | chicken rice, beef steak, salmon         | high-protein        |
| `increase_strength`          | steak, tuna pasta, chicken potato        | high-protein        |
| `improve_endurance`          | pasta, oatmeal, rice chicken             | balanced            |
| `general_fitness`            | chicken, fish vegetables, turkey         | balanced            |
| `maintain`                   | chicken, fish, pasta                     | balanced            |
| *(non renseigné)*            | chicken, fish, pasta                     | —                   |
