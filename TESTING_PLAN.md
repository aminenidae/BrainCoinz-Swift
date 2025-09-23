# Plan de test pour la fonctionnalité Coinz de BrainCoinz

## Objectif
Ce plan de test vise à valider la fonctionnalité du système d'économie Coinz dans l'application BrainCoinz, garantissant que tous les aspects du système fonctionnent correctement selon les spécifications.

## Fonctionnalités à tester

### 1. Authentification
- [ ] Authentification parent avec code d'accès
- [ ] Authentification enfant avec nom
- [ ] Génération de code parent aléatoire
- [ ] Validation de code parent (4-6 chiffres)
- [ ] Persistance de session utilisateur

### 2. Système Coinz
- [ ] Génération de Coinz via les applications d'apprentissage
- [ ] Dépense de Coinz pour débloquer les applications de récompense
- [ ] Cumul des Coinz d'un jour à l'autre
- [ ] Validation des contraintes (apprentissage minimum → solde Coinz → limites quotidiennes)
- [ ] Historique des transactions

### 3. Gestion des objectifs d'apprentissage
- [ ] Création d'objectifs d'apprentissage quotidiens
- [ ] Suivi de la progression vers les objectifs
- [ ] Déblocage automatique des applications de récompense
- [ ] Réinitialisation quotidienne des objectifs

### 4. Contrôles parentaux
- [ ] Attribution de bonus Coinz
- [ ] Application de pénalités Coinz
- [ ] Réinitialisation du solde
- [ ] Augmentation/diminution du solde avec raisons personnalisées
- [ ] Consultation de l'historique des transactions

### 5. Sélection d'applications
- [ ] Sélection des applications d'apprentissage
- [ ] Sélection des applications de récompense
- [ ] Affichage des noms d'applications sélectionnées
- [ ] Effacement des sélections d'applications

### 6. Surveillance de l'activité
- [ ] Suivi du temps passé dans les applications d'apprentissage
- [ ] Suivi du temps passé dans les applications de récompense
- [ ] Application des limites quotidiennes
- [ ] Notifications de progression et d'achèvement

### 7. Interface utilisateur
- [ ] Tableau de bord enfant : affichage du solde Coinz
- [ ] Tableau de bord enfant : indicateurs de report
- [ ] Tableau de bord enfant : cartes d'applications intelligentes
- [ ] Interface parent : gestion de l'économie
- [ ] Interface parent : analytiques d'utilisation

## Scénarios de test

### Scénario 1 : Flux complet de l'enfant
1. L'enfant se connecte avec son nom
2. L'enfant utilise une application d'apprentissage pendant 10 minutes
3. L'enfant gagne 10 Coinz
4. L'enfant tente d'accéder à une application de récompense sans avoir atteint l'objectif d'apprentissage
5. L'enfant complète l'objectif d'apprentissage
6. L'enfant débloque les applications de récompense
7. L'enfant dépense 5 Coinz pour accéder à une application de récompense

### Scénario 2 : Gestion parentale
1. Le parent se connecte avec le code d'accès
2. Le parent consulte le solde Coinz de l'enfant
3. Le parent attribue un bonus de 20 Coinz
4. Le parent consulte l'historique des transactions
5. Le parent applique une pénalité de 5 Coinz
6. Le parent modifie les limites quotidiennes des applications

### Scénario 3 : Report des Coinz
1. L'enfant gagne 15 Coinz en un jour
2. À minuit, le système effectue le report
3. Le lendemain, l'enfant vérifie que les 15 Coinz sont toujours disponibles
4. L'enfant gagne 10 Coinz supplémentaires
5. L'enfant vérifie que le total est de 25 Coinz (15 reportés + 10 nouveaux)

## Tests de performance
- [ ] Temps de réponse pour l'ajout de Coinz
- [ ] Temps de réponse pour la dépense de Coinz
- [ ] Utilisation mémoire pendant les opérations Coinz
- [ ] Performance de l'interface utilisateur avec de nombreux éléments

## Tests de sécurité
- [ ] Validation des entrées pour les ajustements de solde parentaux
- [ ] Protection contre les dépenses non autorisées
- [ ] Persistance sécurisée des données Coinz
- [ ] Intégrité des transactions

## Tests de compatibilité
- [ ] Fonctionnement sur iOS 16.0+
- [ ] Compatibilité avec différents formats d'appareils (iPhone, iPad)
- [ ] Support des modes d'affichage (clair, sombre)
- [ ] Accessibilité (VoiceOver, Dynamic Type)

## Tests de régression
- [ ] Les fonctionnalités existantes continuent de fonctionner après les modifications Coinz
- [ ] Pas de régression dans les fonctionnalités de contrôle parental de base
- [ ] Les données existantes sont migrées correctement

## Critères d'acceptation
- [ ] Tous les tests unitaires passent avec un taux de couverture > 80%
- [ ] Tous les scénarios de test manuels réussissent
- [ ] Aucune fuite mémoire détectée
- [ ] Performance acceptable sur les appareils cibles
- [ ] Conformité aux directives de l'App Store

## Environnement de test
- [ ] iPhone avec iOS 16.0+
- [ ] iPad avec iPadOS 16.0+
- [ ] Xcode 15.0+
- [ ] Appareils physiques (requis pour les API Screen Time)

## Livrables
- [ ] Rapport de test complet
- [ ] Cas de test documentés
- [ ] Bugs identifiés et suivis
- [ ] Recommandations d'amélioration