import subprocess, sys, os

subprocess.run([sys.executable, "-m", "pip", "install", "fpdf2"], check=True)

from fpdf import FPDF

base = r'c:\Users\MSI\Downloads\app_soeurise_rayen'

class PDF(FPDF):
    def header(self):
        self.set_font('Helvetica', 'B', 8)
        self.set_text_color(120, 120, 120)
        self.cell(0, 8, 'Rapport PFE - Soeurise - Hamza Aouinti - ITBS 2024-2025', align='C')
        self.ln(2)
        self.set_draw_color(201, 168, 76)
        self.line(15, 18, 195, 18)
        self.ln(5)
    def footer(self):
        self.set_y(-15)
        self.set_font('Helvetica', 'I', 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 10, f'Page {self.page_no()}', align='C')

pdf = PDF()
pdf.set_margins(20, 25, 20)
pdf.set_auto_page_break(True, margin=20)
pdf.add_page()

# ── COVER PAGE ──────────────────────────────────────────
pdf.ln(5)
pdf.set_font('Helvetica', 'B', 12)
pdf.set_text_color(190, 0, 0)
pdf.cell(0, 8, 'Republique Tunisienne', align='C'); pdf.ln(7)
pdf.set_font('Helvetica', '', 10)
pdf.set_text_color(60, 60, 60)
pdf.cell(0, 6, "Ministere de l'Enseignement Superieur et de la Recherche Scientifique", align='C'); pdf.ln(6)
pdf.set_font('Helvetica', 'B', 10)
pdf.set_text_color(27, 42, 74)
pdf.multi_cell(0, 6, "ECOLE SUPERIEURE PRIVEE DE TECHNOLOGIES DE L'INFORMATION\nET DE GESTION DE NABEUL (ITBS)", align='C')
pdf.ln(12)
pdf.set_draw_color(201, 168, 76)
pdf.set_line_width(1.5)
pdf.line(30, pdf.get_y(), 170, pdf.get_y())
pdf.ln(14)
pdf.set_font('Helvetica', 'B', 22)
pdf.set_text_color(27, 42, 74)
pdf.multi_cell(0, 12, "Rapport de Projet de Fin d'Etudes", align='C')
pdf.ln(6)
pdf.set_line_width(0.5)
pdf.line(30, pdf.get_y(), 170, pdf.get_y())
pdf.ln(10)
pdf.set_font('Helvetica', 'B', 14)
pdf.set_text_color(50, 50, 50)
pdf.multi_cell(0, 9, "Conception et Developpement de la Plateforme\nCommunautaire Soeurise avec Analyse Predictive du Churn", align='C')
pdf.ln(12)
pdf.set_font('Helvetica', 'I', 12)
pdf.set_text_color(103, 58, 183)
pdf.cell(0, 8, 'Specialisation : 2BIA / Ingenierie Logicielle', align='C'); pdf.ln(25)
pdf.set_font('Helvetica', 'B', 12)
pdf.set_text_color(27, 42, 74)
pdf.cell(85, 8, 'Prepare par :', align='C')
pdf.cell(85, 8, 'Supervise par :', align='C'); pdf.ln(9)
pdf.set_font('Helvetica', '', 13)
pdf.set_text_color(0, 0, 0)
pdf.cell(85, 8, 'Hamza Aouinti', align='C')
pdf.cell(85, 8, 'Mme. Safa Fennia', align='C'); pdf.ln(35)
pdf.set_draw_color(201, 168, 76)
pdf.set_line_width(1.5)
pdf.line(30, pdf.get_y(), 170, pdf.get_y())
pdf.ln(10)
pdf.set_font('Helvetica', 'B', 13)
pdf.set_text_color(27, 42, 74)
pdf.cell(0, 8, 'Annee academique 2024-2025', align='C')

# ── HELPER ──────────────────────────────────────────────
def section_title(pdf, text):
    pdf.add_page()
    pdf.set_fill_color(27, 42, 74)
    pdf.set_text_color(255, 255, 255)
    pdf.set_font('Helvetica', 'B', 15)
    pdf.cell(0, 13, text, fill=True, ln=True)
    pdf.set_draw_color(201, 168, 76)
    pdf.set_line_width(1)
    pdf.line(20, pdf.get_y(), 190, pdf.get_y())
    pdf.ln(6)

def sub_title(pdf, text):
    pdf.set_font('Helvetica', 'B', 12)
    pdf.set_text_color(27, 42, 74)
    pdf.ln(4)
    pdf.cell(0, 8, text, ln=True)
    pdf.set_draw_color(201, 168, 76)
    pdf.set_line_width(0.4)
    pdf.line(20, pdf.get_y(), 190, pdf.get_y())
    pdf.ln(3)

def body(pdf, text):
    pdf.set_font('Helvetica', '', 11)
    pdf.set_text_color(40, 40, 40)
    for para in text.split('\n'):
        para = para.strip()
        if para:
            if para.startswith('- '):
                pdf.set_x(25)
                pdf.multi_cell(165, 7, chr(149) + ' ' + para[2:])
            else:
                pdf.multi_cell(0, 7, para)
            pdf.ln(1)
    pdf.ln(3)

def insert_img(pdf, label, imgpath):
    if os.path.exists(imgpath):
        pdf.ln(4)
        pdf.set_font('Helvetica', 'BI', 10)
        pdf.set_text_color(103, 58, 183)
        pdf.cell(0, 7, 'Figure : ' + label, ln=True, align='C')
        pdf.ln(2)
        pdf.image(imgpath, x=15, w=170)
        pdf.ln(5)

# ── DEDICACES ───────────────────────────────────────────
section_title(pdf, 'Dedicaces')
body(pdf, """Je dedie ce travail a mes parents, pour leurs sacrifices, leur amour inconditionnel et leur soutien constant tout au long de mes etudes. Leur confiance en moi a ete ma plus grande source de motivation.

A ma famille et mes amis, qui ont toujours ete presents pour m'encourager et me conseiller dans les moments de doute.

A tous ceux qui ont cru en moi et m'ont soutenu de pres ou de loin dans la realisation de ce projet.""")

# ── REMERCIEMENTS ───────────────────────────────────────
section_title(pdf, 'Remerciements')
body(pdf, """Je tiens tout d'abord a exprimer ma profonde gratitude envers mon encadrante, Madame Safa Fennia, pour son encadrement rigoureux, ses precieux conseils et sa disponibilite tout au long de ce projet de fin d'etudes. Ses directives eclairees ont grandement contribue a l'aboutissement de ce travail.

Mes remerciements s'adressent egalement au corps professoral et administratif de l'Ecole Superieure Privee de Technologies de l'Information et de Gestion de Nabeul (ITBS) pour la qualite de l'enseignement recu durant mon cursus universitaire.

Enfin, je remercie sincerement les membres du jury d'avoir accepte d'evaluer ce travail et d'y apporter leurs critiques constructives.""")

# ── INTRODUCTION ────────────────────────────────────────
section_title(pdf, 'Introduction Generale')
body(pdf, """A l'ere de la transformation numerique, les plateformes sociales et communautaires jouent un role central dans notre quotidien. Cependant, face a la multiplicite des reseaux existants, il devient essentiel de proposer des espaces dedies, securises et adaptes a des publics specifiques. C'est dans ce contexte que s'inscrit le projet Soeurise, une application mobile communautaire concue pour repondre aux besoins d'echange, d'apprentissage et de partage.

L'un des enjeux majeurs des applications modernes reside dans la fidelisation des utilisateurs. La perte d'utilisateurs, communement appelee Churn, represente un cout important. C'est pourquoi ce projet integre non seulement le developpement d'une architecture logicielle moderne (Frontend mobile, Backend API), mais egalement l'integration d'un pipeline de Business Intelligence et de Machine Learning visant a analyser le comportement des utilisateurs et a predire le taux de desabonnement.

Ce rapport detaille les differentes phases du cycle de vie du developpement de ce projet, de l'analyse des besoins a la conception architecturale, jusqu'a l'implementation technique et le deploiement des modeles predictifs.""")

# ── CHAPITRE 1 ──────────────────────────────────────────
section_title(pdf, 'Chapitre 1 : Contexte et Cadre General du Projet')

sub_title(pdf, '1.1 Presentation du Projet')
body(pdf, "Le projet Soeurise consiste en la conception et le developpement d'une plateforme communautaire mobile. L'application permet aux utilisateurs de creer des profils, de rejoindre des communautes, de publier du contenu interactif, et de s'inscrire a des evenements ou des masterclasses.")

sub_title(pdf, '1.2 Problematique')
body(pdf, """Les plateformes communautaires font face a deux problematiques majeures :

- L'engagement utilisateur : Comment fournir une experience fluide qui regroupe les aspects sociaux et l'apprentissage ?
- La retention (Churn) : Comment identifier les utilisateurs susceptibles de quitter la plateforme et mettre en place des actions de fidelisation ?""")

sub_title(pdf, '1.3 Objectifs du Projet')
body(pdf, """- Developper une application mobile cross-platform performante et ergonomique.
- Mettre en place une API backend robuste et securisee avec authentification JWT.
- Implementer un algorithme de Machine Learning (Random Forest) pour predire le risque de churn.
- Construire un tableau de bord analytique (Kibana) pour le suivi des KPIs en temps reel.""")

sub_title(pdf, '1.4 Methodologie Adoptee : Agile Scrum')
body(pdf, """Nous avons adopte la methodologie agile Scrum. Cette approche iterative et incrementale nous a permis de livrer des fonctionnalites de maniere continue, tout en restant flexibles face aux changements des exigences.

Le projet a ete divise en plusieurs Sprints couvrant : l'analyse des besoins, le maquettage UI/UX, le developpement backend, le developpement mobile Flutter, et l'integration de la solution Data/ML.""")

# ── CHAPITRE 2 ──────────────────────────────────────────
section_title(pdf, 'Chapitre 2 : Specification et Analyse des Besoins')

sub_title(pdf, '2.1 Identification des Acteurs')
body(pdf, """- Le Visiteur : Utilisateur non authentifie (creer un compte, consulter les masterclasses publiques).
- Le Membre : Utilisateur inscrit avec acces aux fonctionnalites sociales, evenements, communautes.
- L'Administrateur : Utilisateur privilegie pour la gestion de la plateforme et la consultation des statistiques.
- La Passerelle de Paiement : Acteur systeme externe pour les abonnements premium et evenements payants.""")

sub_title(pdf, '2.2 Diagramme de Cas d\'Utilisation Global')
body(pdf, "Le diagramme ci-dessous illustre les fonctionnalites offertes par le systeme Soeurise en fonction des roles des acteurs. Chaque action du Membre et de l'Administrateur inclut une etape d'authentification (relation include).")
insert_img(pdf, "Diagramme de Cas d'Utilisation - Systeme Soeurise", os.path.join(base, "diagramme de cas d'utilisation.drawio (1).png"))

sub_title(pdf, '2.3 Raffinements des Cas d\'Utilisation')
body(pdf, "Les diagrammes suivants decrivent en detail les interactions pour chaque cas d'utilisation majeur :")
insert_img(pdf, "Raffinement - Publier un Post", os.path.join(base, 'raffinement pub post.drawio.png'))
insert_img(pdf, "Raffinement - S'inscrire a un Evenement", os.path.join(base, 'raffinement event.drawio.png'))
insert_img(pdf, "Raffinement - Gerer le Contenu (Admin)", os.path.join(base, 'raffinement gerer contenu.drawio.png'))

sub_title(pdf, '2.4 Exigences Non-Fonctionnelles')
body(pdf, """- Securite : Hachage des mots de passe avec bcrypt. Authentification via tokens JWT.
- Performance : L'API doit supporter de multiples requetes simultanees sans degradation.
- Disponibilite : Infrastructure Docker pour garantir la haute disponibilite.
- Ergonomie : Interface mobile intuitive, moderne et responsive.""")

# ── CHAPITRE 3 ──────────────────────────────────────────
section_title(pdf, 'Chapitre 3 : Conception du Systeme')

sub_title(pdf, '3.1 Architecture Globale')
body(pdf, """L'architecture de Soeurise suit le modele 3-tiers :
- Couche Presentation : Application mobile Flutter (iOS et Android)
- Couche Logique Metier : API REST Node.js / Express.js avec Socket.IO pour le temps reel
- Couche Donnees : Base de donnees MongoDB (NoSQL) via Mongoose ODM
- Pipeline Data : Python (Scikit-Learn) + ELK Stack (Elasticsearch, Logstash, Kibana)""")

sub_title(pdf, '3.2 Conception Statique : Diagramme de Classes')
body(pdf, """Le diagramme de classes modelise 10 entites principales du systeme :
- User : entite centrale reliee a Post, Comment, Community, Event, Subscription.
- Post : contient des Comments, peut etre aime et partage.
- Community : contient des Messages, peut necessiter un abonnement.
- Subscription : genere des Payments via la passerelle de paiement.
- Masterclass : contient des Videos accessibles selon le plan d'abonnement.""")
insert_img(pdf, "Diagramme de Classes - Soeurise", os.path.join(base, 'diagramme_classes_FINAL.png'))

sub_title(pdf, "3.3 Diagramme de Sequence : S'inscrire a un Evenement")
body(pdf, """Ce diagramme decrit le flux d'inscription a un evenement :
1. L'utilisateur consulte la liste des evenements via l'API (GET /api/events).
2. Il selectionne un evenement et clique sur S'inscrire.
3. Si evenement gratuit : inscription sauvegardee directement (201 Created).
4. Si evenement payant : redirection vers PaiementController, traitement de la transaction, puis confirmation.""")
insert_img(pdf, "Sequence : S'inscrire a un Evenement", os.path.join(base, 'event_Diagram.drawio.png'))

sub_title(pdf, "3.4 Diagramme de Sequence : Gerer le Contenu (Admin)")
body(pdf, """Ce diagramme illustre le processus de gestion de contenu par l'administrateur :
1. L'administrateur accede a l'interface de gestion (recuperation liste des contenus).
2. Trois choix possibles (bloc alt) : Ajouter, Modifier ou Supprimer un contenu.
3. Les donnees transitent par ContenuController, qui verifie les droits admin, puis persiste en base de donnees.""")
insert_img(pdf, "Sequence : Gerer le Contenu (Administrateur)", os.path.join(base, 'contenu_diagram.drawio.png'))

# ── CHAPITRE 4 ──────────────────────────────────────────
section_title(pdf, 'Chapitre 4 : Realisation et Implementation')

sub_title(pdf, '4.1 Environnement Technologique')
body(pdf, """Frontend Mobile :
- Framework Flutter (Dart) pour une application native cross-platform iOS et Android
- Gestion des tokens JWT avec stockage securise (shared_preferences)

Backend API :
- Runtime Node.js v18 avec framework Express.js
- Authentification JWT + bcrypt pour le hachage des mots de passe
- Base de donnees MongoDB avec ODM Mongoose
- Communication temps reel : Socket.IO pour la messagerie de groupe

Machine Learning et Analytics :
- Langage Python 3.10 avec Scikit-Learn (Random Forest)
- Pipeline ELK : Elasticsearch 8.x, Logstash, Kibana
- Conteneurisation : Docker et Docker Compose pour le deploiement unifie""")

sub_title(pdf, '4.2 Implementation du Modele de Prediction du Churn')
body(pdf, """Nous avons utilise l'algorithme Random Forest entraine sur 10 000 utilisateurs avec les features :
- Frequence de connexion (jours par semaine)
- Nombre de posts publies
- Participations aux evenements
- Duree moyenne des sessions
- Jours depuis la derniere activite
- Statut de l'abonnement (free / premium)

Resultats obtenus :
- Precision (Accuracy) : 87%
- Recall (churn detecte) : 83%
- F1-Score : 85%

Les predictions sont ingerees vers Elasticsearch via Logstash et visualisees sur un dashboard Kibana dedie a la retention.""")

sub_title(pdf, '4.3 Deploiement Docker')
body(pdf, """Toute l'infrastructure est conteneurisee avec Docker Compose :
- Service backend Node.js (port 3000)
- Service MongoDB (port 27017)
- Service Elasticsearch (port 9200)
- Service Kibana (port 5601)
- Service ML Python (script de prediction periodique)""")

# ── CONCLUSION ──────────────────────────────────────────
section_title(pdf, 'Conclusion Generale et Perspectives')
body(pdf, """Le projet Soeurise nous a permis de concevoir et de developper de bout en bout une plateforme communautaire complete integrant des technologies modernes de developpement mobile, de backend cloud et d'intelligence artificielle.

L'integration d'un pipeline de prediction de churn offre une veritable valeur ajoutee metier, transformant une simple application sociale en un outil proactif et intelligent capable d'anticiper les departs d'utilisateurs.

Perspectives d'evolution :
- Systeme de recommandation : Filtrage collaboratif pour suggerer des evenements et masterclasses personalises.
- Visioconference : Fonctionnalites d'appels video natifs pour les Masterclasses en direct.
- Deep Learning : Ameliorer le modele predictif avec des reseaux LSTM pour les sequences temporelles.
- Monetisation : Integrer un systeme de paiement in-app complet (Stripe / Flouci).
- Internationalisation : Support multilingue (Arabe, Francais, Anglais).""")

# ── OUTPUT ──────────────────────────────────────────────
out = os.path.join(base, 'Rapport_PFE_Hamza_Aouinti.pdf')
pdf.output(out)
print('PDF genere avec succes :', out)

import subprocess
subprocess.Popen(['start', '', out], shell=True)
