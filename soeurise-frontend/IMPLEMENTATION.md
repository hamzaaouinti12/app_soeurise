# Soeurise - Application Complète Flutter

## Vue d'ensemble

Soeurise est une application mobile Flutter conçue pour créer une communauté sécurisée, inclusive et engageante pour les femmes musulmanes. L'application intègre un flux social type Twitter/X, des communautés privées, des masterclass, des événements et bien plus encore.

## Architecture

### Structure du Projet

```
lib/
├── main.dart          # Point d'entrée principal et tous les écrans
├── models.dart        # Classes de modèles de données
├── services.dart      # Services API, authentification et validation
└── constants.dart     # Constantes et configuration de l'application
```

## Fonctionnalités Principales

### 1. **Authentification (Login Page)**
- Connexion par email et mot de passe
- Interface de connexion minimaliste et épurée
- Support pour OTP et vérification SMS (à intégrer)
- Navigation vers le tableau de bord principal après connexion réussie

### 2. **Flux Social (Home Screen)**
- Affichage d'une liste verticale de publications
- Chaque publication contient:
  - Photo de profil
  - Nom d'utilisateur
  - Contenu textuel
  - Image optionnelle
  - Timestamp
- Actions sociales:
  - Like (avec compteur)
  - Commentaires
  - Partage
- Bouton flottant pour créer une nouvelle publication

### 3. **Communautés (Communities Screen)**
- Liste des communautés rejointes
- Chaque communauté affiche:
  - Image/avatar
  - Nom et description
  - Nombre de membres
- Accès aux salons de discussion privés
- Interface de messagerie avec:
  - Champ de saisie
  - Bouton d'envoi
  - Historique des messages

### 4. **Masterclass (Masterclass Screen)**
- Liste verticale des cours disponibles
- Chaque carte de masterclass contient:
  - Miniature vidéo
  - Titre du cours
  - Brève description
  - Nom de l'instructeur
  - Date de création
- Écran de détails avec:
  - Description complète
  - Bouton pour accéder au contenu vidéo
  - Informations détaillées

### 5. **Événements (Events Screen)**
- Liste des événements disponibles
- Chaque événement affiche:
  - Image promotionnelle
  - Titre de l'événement
  - Date et heure
  - Type (physique ou en ligne)
  - Lieu/Lien
  - Bouton "Réserver"
- Support futur pour intégration Stripe

### 6. **Profil Utilisateur (Profile Screen)**
- Section d'informations personnelles:
  - Photo de profil
  - Nom d'utilisateur
  - Email
  - Bouton "Modifier le profil"
- Historique:
  - Activités
  - Événements auxquels l'utilisateur a participé
  - Progression des masterclass
  - Communautés
- Bouton "Déconnexion"

### 7. **Création de Publication (Post Creation Screen)**
- Champ texte: "Ce qui se passe?"
- Option pour ajouter une image
- Bouton "Publier"
- Option "Ignorer" pour annuler

## Thème et Design

### Dark Mode
- Couleur primaire: Deep Purple (#673AB7)
- Couleur secondaire: Light Purple (#B19CD9)
- Fond: #121212
- Texte principal: Blanc
- Texte secondaire: Gris clair (#B3B3B3)

### Navigation Inférieure
- 5 onglets principaux visibles sur tous les écrans:
  1. Accueil (Home)
  2. Communautés (Communities)
  3. Masterclass (Masterclass)
  4. Événements (Events)
  5. Profil (Profile)

## Architecture Technique

### Frontend
- **Framework**: Flutter (Dart)
- **État**: StatefulWidget/StatelessWidget
- **Navigation**: Navigator et MaterialPageRoute

### Backend (À intégrer)
- **Framework**: Node.js / Express
- **Base de données**: MongoDB
- **API REST**: Endpoints pour tous les modules

### Authentification
- Email / Mot de passe
- OTP SMS (à implémenter)
- JWT Tokens (à implémenter)

### Sécurité
- Vérification d'identité (Selfie/ID) - à implémenter
- Modération stricte des communautés
- Chiffrement des données sensibles

## Fichiers Principaux

### `main.dart`
Contient:
- Classes de modèles (`Post`, `Community`, `Masterclass`, `Event`)
- Page de connexion (`LoginPage`)
- Application principale avec navigation (`MainApp`)
- 5 écrans principaux
- Écran de création de publication

### `models.dart`
Défini les structures de données:
- `User`: Informations utilisateur
- `Post`: Données de publication
- `Message`: Messages communautaires
- `Comment`: Commentaires sur les publications
- `Community`: Données communautaires
- `Masterclass`: Données des cours
- `Event`: Données des événements

### `services.dart`
Services pour:
- Authentification (`AuthenticationService`)
- Requêtes API (`ApiService`)
- Validation de formulaires (`ValidationService`)
- Notifications (`NotificationService`)

### `constants.dart`
Contient:
- Couleurs de l'application (`AppColors`)
- Styles de texte (`AppTextStyles`)
- Espacements (`AppSpacing`)
- Configuration API (`ApiConfig`)
- Messages (`AppMessages`)
- Drapeaux de fonctionnalités (`FeatureFlags`)

## Installation et Exécution

### Prérequis
- Flutter SDK >= 3.0
- Dart >= 3.0

### Installation
```bash
flutter pub get
```

### Exécution
```bash
flutter run
```

### Build
```bash
flutter build apk        # Pour Android
flutter build ios        # Pour iOS
flutter build web        # Pour Web
```

## Prochaines Étapes

1. **Intégration Backend**
   - Connecter l'API Node.js/Express
   - Implémenter les endpoints pour tous les modules
   - Gérer l'authentification JWT

2. **Authentification Avancée**
   - Implémenter l'OTP SMS
   - Ajouter la vérification d'identité (selfie/ID)
   - Support pour les réseaux sociaux (Google, Apple)

3. **Paiements**
   - Intégrer Stripe pour la billetterie des événements
   - Implémenter les mécanismes de paiement sécurisés

4. **Fonctionnalités Sociales**
   - Système de notifications en temps réel
   - Système de suivi (follow/unfollow)
   - Recherche et découverte

5. **Modération**
   - Système de modération automatique
   - Signalement du contenu inapproprié
   - Gestion des utilisateurs

6. **Performances**
   - Mise en cache des données
   - Lazy loading des images
   - Optimisation de la base de données

## Support et Documentation

Pour plus d'informations, consultez:
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design Guidelines](https://material.io/design)

## Licence

Propriétaire - Projet Soeurise

## Auteurs

Développement Frontend: Équipe de développement Flutter
