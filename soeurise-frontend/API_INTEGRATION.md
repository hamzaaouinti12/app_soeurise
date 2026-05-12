// Backend API Integration Guide for Soeurise

/*
ENDPOINTS REQUIS POUR LE BACKEND

=== AUTHENTIFICATION ===
POST   /api/auth/login                  - Connexion utilisateur
POST   /api/auth/register               - Inscription utilisateur
POST   /api/auth/verify-otp             - Vérification OTP
POST   /api/auth/logout                 - Déconnexion
POST   /api/auth/refresh-token          - Rafraîchissement du token
GET    /api/auth/verify-identity        - Vérification d'identité

=== UTILISATEURS ===
GET    /api/users/:id                   - Récupérer profil utilisateur
PUT    /api/users/:id                   - Modifier profil utilisateur
GET    /api/users/:id/followers         - Liste des abonnés
GET    /api/users/:id/following         - Comptes suivis
POST   /api/users/:id/follow            - Suivre un utilisateur
POST   /api/users/:id/unfollow          - Arrêter de suivre

=== PUBLICATIONS (POSTS) ===
GET    /api/posts/feed                  - Récupérer le flux social
GET    /api/posts/:id                   - Récupérer une publication
POST   /api/posts                       - Créer une nouvelle publication
PUT    /api/posts/:id                   - Modifier une publication
DELETE /api/posts/:id                   - Supprimer une publication
POST   /api/posts/:id/like              - Liker une publication
DELETE /api/posts/:id/like              - Retirer un like
POST   /api/posts/:id/share             - Partager une publication

=== COMMENTAIRES ===
GET    /api/posts/:id/comments          - Récupérer les commentaires
POST   /api/posts/:id/comments          - Ajouter un commentaire
DELETE /api/comments/:id                - Supprimer un commentaire
POST   /api/comments/:id/like           - Liker un commentaire

=== COMMUNAUTÉS ===
GET    /api/communities                 - Liste des communautés
GET    /api/communities/:id             - Détails d'une communauté
POST   /api/communities                 - Créer une communauté
PUT    /api/communities/:id             - Modifier une communauté
POST   /api/communities/:id/join        - Rejoindre une communauté
POST   /api/communities/:id/leave       - Quitter une communauté
GET    /api/communities/:id/members     - Liste des membres

=== MESSAGES COMMUNAUTAIRES ===
GET    /api/communities/:id/messages    - Récupérer les messages
POST   /api/communities/:id/messages    - Envoyer un message
DELETE /api/messages/:id                - Supprimer un message

=== MASTERCLASS ===
GET    /api/masterclasses               - Liste des masterclass
GET    /api/masterclasses/:id           - Détails d'une masterclass
POST   /api/masterclasses               - Créer une masterclass
PUT    /api/masterclasses/:id           - Modifier une masterclass
POST   /api/masterclasses/:id/enroll    - S'inscrire à une masterclass
GET    /api/masterclasses/:id/video     - Récupérer l'URL de la vidéo

=== ÉVÉNEMENTS ===
GET    /api/events                      - Liste des événements
GET    /api/events/:id                  - Détails d'un événement
POST   /api/events                      - Créer un événement
PUT    /api/events/:id                  - Modifier un événement
POST   /api/events/:id/register         - S'inscrire à un événement
DELETE /api/events/:id/register         - Se désinscrire
GET    /api/events/:id/attendees        - Liste des participants

=== RECHERCHE ===
GET    /api/search?q=query              - Recherche globale
GET    /api/search/users?q=query        - Recherche utilisateurs
GET    /api/search/communities?q=query  - Recherche communautés

=== NOTIFICATIONS ===
GET    /api/notifications               - Récupérer les notifications
POST   /api/notifications/:id/read      - Marquer comme lu
DELETE /api/notifications/:id           - Supprimer une notification

=== MODÉRATION ===
POST   /api/report/post/:id             - Signaler une publication
POST   /api/report/user/:id             - Signaler un utilisateur
POST   /api/report/comment/:id          - Signaler un commentaire
*/

// EXEMPLE DE RÉPONSE API

// Login Response
/*
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user_id_123",
      "email": "user@example.com",
      "username": "fatima_ahmed",
      "profileImage": "https://cdn.example.com/profiles/user_id_123.jpg",
      "bio": "Entrepreneur et mère de famille",
      "joinDate": "2024-01-01T00:00:00Z"
    }
  }
}
*/

// Posts Feed Response
/*
{
  "success": true,
  "data": {
    "posts": [
      {
        "id": "post_123",
        "author": {
          "id": "user_456",
          "username": "aisha_khan",
          "profileImage": "https://cdn.example.com/profiles/user_456.jpg"
        },
        "content": "Heureuse de partager mon nouveau projet!",
        "images": ["https://cdn.example.com/posts/post_123_img1.jpg"],
        "timestamp": "2024-02-01T10:30:00Z",
        "likes": 24,
        "comments": 5,
        "shares": 2,
        "liked": false
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 100
    }
  }
}
*/

// Communities Response
/*
{
  "success": true,
  "data": {
    "communities": [
      {
        "id": "community_123",
        "name": "Entrepreneuriat Féminin",
        "description": "Pour les femmes entrepreneuses",
        "image": "https://cdn.example.com/communities/community_123.jpg",
        "members": 234,
        "isPrivate": true,
        "createdDate": "2024-01-01T00:00:00Z",
        "isMember": true
      }
    ]
  }
}
*/

// Masterclass Response
/*
{
  "success": true,
  "data": {
    "masterclasses": [
      {
        "id": "masterclass_123",
        "title": "Les bases de l'entrepreneuriat",
        "description": "Apprenez les fondamentaux pour démarrer votre entreprise",
        "instructor": {
          "id": "user_789",
          "name": "Dr. Amina",
          "profileImage": "https://cdn.example.com/profiles/user_789.jpg"
        },
        "thumbnail": "https://cdn.example.com/masterclasses/masterclass_123.jpg",
        "videoUrl": "https://cdn.example.com/videos/masterclass_123.mp4",
        "duration": 3600,
        "createdDate": "2024-01-15T00:00:00Z",
        "enrollmentCount": 156,
        "enrolled": false
      }
    ]
  }
}
*/

// Events Response
/*
{
  "success": true,
  "data": {
    "events": [
      {
        "id": "event_123",
        "title": "Conférence: Entrepreneuriat",
        "description": "Une conférence inspirante sur l'entrepreneuriat féminin",
        "dateTime": "2024-02-15T14:00:00Z",
        "type": "physical",
        "location": "Paris, Centre Culturel",
        "image": "https://cdn.example.com/events/event_123.jpg",
        "capacity": 500,
        "attendees": 342,
        "ticketPrice": 25.00,
        "registered": false
      }
    ]
  }
}
*/

// ERROR RESPONSE FORMAT
/*
{
  "success": false,
  "error": {
    "code": "AUTH_ERROR",
    "message": "Email ou mot de passe incorrect",
    "details": {}
  }
}
*/

// HEADERS REQUIS POUR LES REQUÊTES AUTHENTIFIÉES
/*
Authorization: Bearer <token>
Content-Type: application/json
Accept: application/json
X-API-Version: v1
*/

// EXEMPLE D'IMPLÉMENTATION DANS LE SERVICE
/*
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String _baseUrl = 'https://api.soeurise.com/api';
  static String? _token;

  // Défini le token après connexion
  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Exemple: Récupérer le flux social
  static Future<List<Map<String, dynamic>>> getFeeds({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/feed?page=$page&limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']['posts']);
      } else if (response.statusCode == 401) {
        // Token expiré, rediriger vers login
        throw Exception('Token expiré');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur réseau: $e');
    }
  }

  // Exemple: Créer une publication
  static Future<Map<String, dynamic>> createPost({
    required String content,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/posts'),
        headers: _headers,
        body: jsonEncode({
          'content': content,
          'images': imageUrls ?? [],
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body)['data'];
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création: $e');
    }
  }
}
*/

// CONFIGURATION POUR WORDPRESS REST API
/*
La masterclass peut récupérer des données depuis WordPress via:

GET https://example.com/wp-json/wp/v2/posts?per_page=100

Les données peuvent être mappées comme:
- ID → masterclass.id
- Title → masterclass.title
- Content → masterclass.description
- Featured Image → masterclass.thumbnailUrl
- Custom Field (instructor) → masterclass.instructorName
- Custom Field (video_url) → masterclass.videoUrl
*/

// CONFIGURATION STRIPE (FUTUR)
/*
Pour l'intégration Stripe:

1. Créer une clé API Stripe
2. Implémenter un endpoint pour créer des paiements:
   POST /api/payments/create-intent
   
3. Réponse:
   {
     "clientSecret": "pi_xxx_secret_xxx",
     "amount": 2500,
     "currency": "eur"
   }

4. Utiliser le Flutter package 'flutter_stripe' pour finaliser le paiement
*/
