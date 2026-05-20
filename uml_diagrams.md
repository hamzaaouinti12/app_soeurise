# 📊 Soeurise — Spécifications & Diagrammes UML

Ce document regroupe les diagrammes UML modélisant la plateforme **Soeurise** (Application mobile + Backend + Machine Learning). Les diagrammes sont présentés sous forme d'**images visuelles directes** et accompagnés de leur code source en **Mermaid** pour toute modification future.

---

## 1. 👤 Diagramme de Cas d'Utilisation (Use Case)

Ce diagramme décrit les interactions des différents acteurs avec les modules de l'application :
1. **Invitée** (Visiteuse non connectée)
2. **Utilisatrice** (Membre connectée)
3. **Administrateur** (Gestionnaire de la plateforme)
4. **Système ML / ELK** (Analyse de rétention et prédiction du churn)

### 🖼️ Rendu Visuel
![Diagramme de Cas d'Utilisation Général](diagramme%20de%20cas%20d'utilisation.drawio%20(1).png)

<details>
<summary>💻 Voir le code source Mermaid (Modifiable)</summary>

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#1B2A4A', 'primaryTextColor': '#ffffff', 'primaryBorderColor': '#C9A84C', 'lineColor': '#673AB7', 'secondaryColor': '#F5F0E8', 'tertiaryColor': '#673AB7'}}}%%
flowchart LR
    %% Actors definition
    subgraph Acteurs [Acteurs du Système]
        style Acteurs fill:#1B2A4A,stroke:#C9A84C,stroke-width:2px,color:#fff
        Guest["👤 Invitée"]
        User["👩 Utilisatrice (Membre)"]
        Admin["👮 Administrateur"]
        MLSys["🤖 Système ML & ELK"]
    end

    %% Modules Use Cases
    subgraph ModuleAuth [Authentification & Profil]
        style ModuleAuth fill:#F5F0E8,stroke:#1B2A4A,stroke-width:1px
        UC_Register(["S'inscrire"])
        UC_Login(["Se connecter"])
        UC_Profile(["Gérer son Profil & Confidentialité"])
    end

    subgraph ModuleSocial [Flux Social & Interactions]
        style ModuleSocial fill:#F5F0E8,stroke:#1B2A4A,stroke-width:1px
        UC_CreatePost(["Publier un Post"])
        UC_InteractPost(["Interagir (Liker / Commenter)"])
    end

    subgraph ModuleComm [Communautés]
        style ModuleComm fill:#F5F0E8,stroke:#1B2A4A,stroke-width:1px
        UC_CreateComm(["Créer une Communauté"])
        UC_JoinComm(["Rejoindre / S'abonner"])
        UC_ChatComm(["Échanger dans le chat de groupe"])
    end

    subgraph ModuleServices [Masterclasses & Événements]
        style ModuleServices fill:#F5F0E8,stroke:#1B2A4A,stroke-width:1px
        UC_ViewMC(["Suivre les Masterclasses (soeurise.com)"])
        UC_RegisterEvent(["S'inscrire à un Événement"])
        UC_ManageContent(["Gérer le Contenu (Admin)"])
    end

    subgraph ModuleML [Machine Learning & Analytics]
        style ModuleML fill:#F5F0E8,stroke:#1B2A4A,stroke-width:1px
        UC_PredictChurn(["Prédire le Churn (Random Forest)"])
        UC_IngestES(["Ingérer les Données (Elasticsearch)"])
        UC_ViewDashboards(["Consulter les Dashboards (Kibana)"])
    end

    %% Links - Guest
    Guest --> UC_Register
    Guest --> UC_Login

    %% Links - Member
    User --> UC_Login
    User --> UC_Profile
    User --> UC_CreatePost
    User --> UC_InteractPost
    User --> UC_CreateComm
    User --> UC_JoinComm
    User --> UC_ChatComm
    User --> UC_ViewMC
    User --> UC_RegisterEvent

    %% Links - Admin
    Admin --> UC_Login
    Admin --> UC_ManageContent
    Admin --> UC_ViewDashboards

    %% Links - ML System
    MLSys --> UC_PredictChurn
    MLSys --> UC_IngestES
    MLSys --> UC_ViewDashboards
```
</details>

---

## 🔍 Rafinements des Cas d'Utilisation Spécifiques

Voici les détails de raffinement pour les actions principales de l'utilisatrice et de l'administrateur.

### A. Publier un Post
![Raffinement Publier Post](raffinement%20pub%20post.drawio.png)

### B. S'inscrire à un Événement
![Raffinement Inscription Événement](raffinement%20event.drawio.png)

### C. Gérer le Contenu (Administrateur)
![Raffinement Gérer Contenu](raffinement%20gerer%20contenu.drawio.png)

---

## 2. 🗂️ Diagramme de Classes (Class Diagram)

Ce diagramme représente la structure statique du backend de **Soeurise**, basé sur les modèles **Mongoose / MongoDB** identifiés dans le code de l'API.

### 🖼️ Rendu Visuel
![Diagramme de Classes Général](diagramme%20de%20classee.drawio.png)

<details>
<summary>💻 Voir le code source Mermaid (Modifiable)</summary>

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#1B2A4A', 'primaryTextColor': '#ffffff', 'primaryBorderColor': '#C9A84C', 'lineColor': '#673AB7', 'secondaryColor': '#F5F0E8', 'tertiaryColor': '#673AB7'}}}%%
classDiagram
    direction TB

    class User {
        +ObjectId id
        +String firstName
        +String lastName
        +String username
        +String email
        +String passwordHash
        +String avatarUrl
        +String avatarMime
        +String role [user | admin | staff]
        +Boolean isActive
        +String accountPrivacy [public | private]
        +List~ObjectId~ pendingFollowRequests
        +List~ObjectId~ following
        +List~ObjectId~ followers
        +List~ObjectId~ savedPosts
        +List~ObjectId~ blockedUsers
        +toPublic() Object
    }

    class Post {
        +ObjectId id
        +ObjectId author
        +String content
        +List~String~ hashtags
        +String image
        +ObjectId communityId
        +Number likesCount
        +Number commentsCount
        +Number sharesCount
        +Boolean commentsDisabled
        +Boolean isPinned
        +List~ObjectId~ likedBy
        +List~Comment~ comments
        +isLiked() Boolean
        +isSaved() Boolean
    }

    class Comment {
        +ObjectId author
        +String content
        +Date createdAt
        +Boolean isHidden
        +Boolean isPinned
        +List~ObjectId~ likes
        +List~Reply~ replies
    }

    class Group {
        +ObjectId id
        +String name
        +String description
        +String imageUrl
        +String imageMime
        +Boolean isPublic
        +Boolean requiresSubscription
        +ObjectId createdBy
        +toPublic() Object
    }

    class GroupMember {
        +ObjectId id
        +ObjectId groupId
        +ObjectId userId
        +String roleInGroup [owner | moderator | member]
        +String status [pending | active | banned]
        +Date joinedAt
        +toPublic() Object
    }

    class GroupMessage {
        +ObjectId id
        +ObjectId groupId
        +ObjectId senderId
        +String text
        +ObjectId replyTo
        +Boolean isEdited
        +Date editedAt
        +List~Reaction~ reactions
        +List~ObjectId~ seenBy
        +toPublic() Object
    }

    class Subscription {
        +ObjectId id
        +ObjectId groupId
        +ObjectId userId
        +String plan [free | premium | member]
        +String status [active | inactive]
        +Date startedAt
        +Date endedAt
        +toPublic() Object
    }

    class Event {
        +ObjectId id
        +String title
        +Date dateTime
        +String type [online | physical]
        +String location
        +String imageUrl
    }

    class Masterclass {
        +ObjectId id
        +String title
        +String description
        +String instructorName
        +String videoUrl
        +String thumbnailUrl
    }

    %% Relationships
    User "1" --> "*" Post : publie
    User "1" --> "*" Group : crée
    User "1" --> "*" GroupMember : possède l'appartenance
    Group "1" --> "*" GroupMember : contient des membres
    User "1" --> "*" Subscription : possède des abonnements
    Group "1" --> "*" Subscription : a des souscriptions
    User "1" --> "*" GroupMessage : envoie
    Group "1" --> "*" GroupMessage : contient des messages
    Post "1" *-- "*" Comment : contient
    User "1" --> "*" Comment : écrit
    
    %% Self Associations
    User "*" --> "*" User : suit (following)
    User "*" --> "*" User : bloque (blockedUsers)
```
</details>

---

## 3. 🔄 Diagrammes de Séquence (Sequence Diagrams)

Voici les scénarios d'interaction clés représentés en diagrammes de séquence dynamiques.

### A. S'authentifier (Connexion)
*Illustre les vérifications de sécurité, le hachage et le retour du token JWT.*

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'actorBkg': '#1B2A4A', 'actorBorder': '#C9A84C', 'actorTextColor': '#ffffff', 'signalColor': '#673AB7', 'signalTextColor': '#1B2A4A', 'labelBoxBorderColor': '#C9A84C', 'labelBoxBkgColor': '#F5F0E8', 'labelTextColor': '#1B2A4A'}}}%%
sequenceDiagram
    autonumber
    actor Membre as 👩 Membre
    participant App as 📱 Interface (Flutter)
    participant Server as 🔧 API (Node.js)
    database DB as 💾 Base de données (MongoDB)

    Membre->>App: Saisit l'e-mail et le mot de passe
    App->>Server: Requête POST /api/auth/login
    activate Server
    Server->>DB: Recherche l'utilisateur (User.findOne({ email }))
    activate DB
    DB-->>Server: Retourne le profil utilisateur (passwordHash)
    deactivate DB
    
    Note over Server: Vérification du mot de passe avec bcrypt.compare()
    
    alt Identifiants valides
        Note over Server: Génération du JWT Token
        Server-->>App: Code 200 OK + JWT Token + Profil Public
        App->>App: Stockage du token dans shared_preferences
        App-->>Membre: Redirection vers l'Écran d'Accueil
    else Identifiants invalides
        Server-->>App: Code 401 Unauthorized (Erreur de connexion)
        deactivate Server
        App-->>Membre: Affiche "Email ou mot de passe incorrect"
    end
```

### B. S'inscrire à un Événement
### 🖼️ Rendu Visuel
![Diagramme de Séquence Événement](event_Diagram.drawio.png)

<details>
<summary>💻 Voir le code source Mermaid (Modifiable)</summary>

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'actorBkg': '#1B2A4A', 'actorBorder': '#C9A84C', 'actorTextColor': '#ffffff', 'signalColor': '#673AB7', 'signalTextColor': '#1B2A4A', 'labelBoxBorderColor': '#C9A84C', 'labelBoxBkgColor': '#F5F0E8', 'labelTextColor': '#1B2A4A'}}}%%
sequenceDiagram
    autonumber
    actor Membre as 👩 Membre
    participant App as 📱 Application
    participant Server as 🔧 API Node.js
    database DB as 💾 MongoDB

    Membre->>App: Accède à l'onglet "Événements"
    App->>Server: Requête GET /api/events (avec JWT Header)
    activate Server
    Server->>DB: Récupère la liste des événements
    activate DB
    DB-->>Server: Retourne les documents événements
    deactivate DB
    Server-->>App: Code 200 OK + Liste des Événements
    deactivate Server
    App-->>Membre: Affiche les cartes d'événements
    
    Membre->>App: Clique sur le bouton "S'inscrire"
    App->>Server: Requête POST /api/events/:id/register (JWT)
    activate Server
    Server->>DB: Enregistre la participation
    activate DB
    DB-->>Server: Confirmation d'enregistrement
    deactivate DB
    Server-->>App: Code 201 Created (Inscription validée)
    deactivate Server
    App-->>Membre: Affiche un message de succès & Envoie confirmation
```
</details>

### C. Gérer le Contenu (Administrateur)
### 🖼️ Rendu Visuel
![Diagramme de Séquence Gérer le Contenu](contenu_diagram.drawio.png)

<details>
<summary>💻 Voir le code source Mermaid (Modifiable)</summary>

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'actorBkg': '#1B2A4A', 'actorBorder': '#C9A84C', 'actorTextColor': '#ffffff', 'signalColor': '#673AB7', 'signalTextColor': '#1B2A4A', 'labelBoxBorderColor': '#C9A84C', 'labelBoxBkgColor': '#F5F0E8', 'labelTextColor': '#1B2A4A'}}}%%
sequenceDiagram
    autonumber
    actor Admin as 👮 Administrateur
    participant App as 📱 Interface Admin (Flutter)
    participant Server as 🔧 API Node.js
    database DB as 💾 MongoDB

    Admin->>App: Remplit le formulaire de création (Événement/Masterclass)
    App->>Server: Requête POST /api/admin/content (FormData + JWT)
    activate Server
    
    Note over Server: Middleware isAdmin vérifie le rôle de l'utilisateur
    
    alt Est un Administrateur
        Server->>DB: Enregistre le nouveau contenu (Event/Masterclass.save())
        activate DB
        DB-->>Server: Document enregistré
        deactivate DB
        Server-->>App: Code 201 Created (Contenu publié avec succès)
        App-->>Admin: Affiche "Contenu ajouté avec succès"
    else N'est pas un Administrateur (Accès refusé)
        Server-->>App: Code 403 Forbidden (Accès interdit)
        deactivate Server
        App-->>Admin: Affiche un message d'erreur d'autorisation
    end
```
</details>

---

## 💡 Comment intégrer ou modifier ces diagrammes ?

1. **Dans VS Code** : Installez l'extension **Markdown Preview Mermaid Support** pour visualiser directement les diagrammes textuels dans l'aperçu de ce document.
2. **Pour votre rapport LaTeX / Word** : Les images PNG ci-dessus sont également stockées dans votre dossier local sous : `c:\Users\MSI\Downloads\app_soeurise_rayen\diagramme...` pour une insertion facile et directe !
