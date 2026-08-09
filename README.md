# Bitty Bellies

> A recipe app where parents share what's worked for their families, from around the world.

---

## Overview

Bitty Bellies is a cross-platform mobile app (Flutter) backed by AWS that lets parents discover, save, share, and upload recipes from cultures around the world. Guest users can browse freely; accounts unlock saving, uploading, commenting, and sharing.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Mobile | Flutter 3.x (iOS + Android) |
| State management | Riverpod 2 |
| Navigation | GoRouter |
| Auth | Amazon Cognito (email/password; Apple/Google behind feature flags) |
| API | AWS AppSync (GraphQL) |
| Database | Amazon DynamoDB |
| Storage | Amazon S3 |
| Email | Amazon SES + Lambda |
| Infrastructure | AWS CDK (TypeScript) |
| Analytics | Abstraction layer (swap in Pinpoint, PostHog, Amplitude) |

---

## Project Structure

```
blw_recipes/
├── lib/
│   ├── main.dart                     # App entry, Amplify init
│   ├── core/
│   │   ├── analytics/                # Analytics abstraction
│   │   ├── constants/                # AppConstants (ages, cuisines, allergens, etc.)
│   │   ├── errors/                   # AppError sealed class
│   │   ├── router/                   # GoRouter config + AppShell (bottom nav)
│   │   ├── theme/                    # AppTheme, AppColors
│   │   ├── utils/                    # Result<T>, FeatureFlags
│   │   └── widgets/                  # Shared widgets (ErrorView, AppTextField)
│   ├── domain/
│   │   ├── models/                   # Recipe, UserProfile, RecipeComment, etc.
│   │   └── repositories/             # Abstract repository interfaces
│   ├── data/
│   │   ├── datasources/remote/       # AmplifyConfig
│   │   ├── graphql/                  # schema.graphql, queries.dart
│   │   └── repositories/             # Concrete implementations
│   └── presentation/
│       ├── auth/                     # Login, Register, Confirm, ForgotPassword
│       ├── home/                     # Home/feed screen
│       ├── recipe/                   # RecipeDetail, RecipeCard widget
│       ├── search/                   # Search + filter screen
│       ├── upload/                   # Multi-step recipe upload flow
│       ├── profile/                  # Profile, SavedRecipes
│       ├── settings/                 # Settings screen
│       └── splash/                   # Splash screen
├── assets/
│   ├── data/seed_recipes.json        # Sample recipes (5 global cuisines)
│   ├── images/
│   └── icons/
└── infrastructure/
    └── cdk/                          # AWS CDK TypeScript stack
        ├── bin/app.ts
        └── lib/blw-recipes-stack.ts  # Cognito, AppSync, DynamoDB, S3, SES
```

---

## Prerequisites

- Flutter 3.41+ (`flutter --version`)
- Dart 3.11+
- Node.js 18+ (for CDK)
- AWS CLI configured (`aws configure`)
- AWS CDK CLI (`npm install -g aws-cdk`)

---

## Local Setup

### 1. Install Flutter dependencies

```bash
cd blw_recipes
flutter pub get
```

### 2. Deploy AWS infrastructure (first time)

```bash
cd infrastructure/cdk
npm install
npm run build
cdk bootstrap   # only needed once per AWS account/region
cdk deploy
```

Copy the output values:
- `UserPoolId`
- `UserPoolClientId`
- `IdentityPoolId`
- `AppSyncEndpoint`
- `S3BucketName`

### 3. Configure Amplify

Edit `lib/data/datasources/remote/amplify_config.dart` and replace all `REPLACE_WITH_*` placeholders with the values from step 2.

```dart
"PoolId": "us-east-1_XXXXXXXXX",         // UserPoolId
"AppClientId": "XXXXXXXXXXXXXXXXX",        // UserPoolClientId
"endpoint": "https://xxxxx.appsync-api.us-east-1.amazonaws.com/graphql",
"bucket": "blw-recipes-media-123456789-us-east-1",
```

### 4. Run the app

```bash
flutter run
```

---

## Environment Variables

| Variable | Description | Where |
|----------|-------------|-------|
| Cognito User Pool ID | From CDK output `UserPoolId` | `amplify_config.dart` |
| Cognito App Client ID | From CDK output `UserPoolClientId` | `amplify_config.dart` |
| Cognito Identity Pool ID | From CDK output `IdentityPoolId` | `amplify_config.dart` |
| AppSync Endpoint | From CDK output `AppSyncEndpoint` | `amplify_config.dart` |
| S3 Bucket Name | From CDK output `S3BucketName` | `amplify_config.dart` |
| SES From Email | Your verified SES sender email | `blw-recipes-stack.ts` → `emailLambda` env |

> **Security**: Never commit real AWS keys or client secrets. `amplify_config.dart` contains AppSync endpoints and Cognito pool IDs (non-secret, safe to include in the app binary), but IAM credentials should never be embedded.

---

## AWS Setup Notes

### Cognito

- User Pool is created with email/password auth and SRP flow.
- Email verification is enabled.
- `Moderators` and `Admins` groups are pre-created.
- Apple/Google sign-in is behind a `FeatureFlag` — add OAuth provider config to CDK when ready.

### AppSync

- GraphQL schema is at `lib/data/graphql/schema.graphql`.
- Primary auth: Cognito User Pools.
- Secondary auth: IAM (for unauthenticated/guest access to public read operations).
- DynamoDB data sources are connected with GSIs for efficient filtering.

### DynamoDB

All tables use on-demand billing. Key GSIs per table:

| Table | GSIs |
|-------|------|
| Recipes | `byCreatorId`, `byStatus`, `byCuisine` |
| Comments | `byRecipeId` |
| Feedback | `byRecipeId` |
| Questions | `byRecipeId` |
| Reports | `byStatus` |
| SavedRecipes | `byUserId` |

> For search/filtering at scale: replace DynamoDB scan-based filters with Amazon OpenSearch Service. The `FeatureFlags.openSearch` flag controls the code path.

### S3

Recipe photos are stored under `public/` prefix. The bucket policy allows public GET on `public/*` so images are directly URL-accessible.

### SES

1. Verify your sender domain in the AWS SES console.
2. Update `FROM_EMAIL` in `blw-recipes-stack.ts`.
3. If in SES sandbox, request production access before real users can receive emails.

---

## Feature Flags

All flags are in `lib/core/utils/feature_flags.dart`. Set to `true` to enable:

| Flag | Description |
|------|-------------|
| `sponsoredRecipes` | Sponsored recipe collections |
| `premiumCollections` | Premium meal plan collections |
| `subscriptionTier` | Subscription paywall |
| `affiliateLinks` | Ingredient affiliate links |
| `ads` | Ad placements |
| `googleSignIn` | Google OAuth |
| `appleSignIn` | Apple Sign In |
| `openSearch` | Switch from DynamoDB filters to OpenSearch |
| `privateMessaging` | Private DMs between users |

---

## Data Models

All models are in `lib/domain/models/`. Key models:

- `Recipe` — full recipe with ingredients, steps, safety info, classifications
- `RecipeIngredient` — name, quantity, unit, notes
- `RecipeStep` — stepNumber, instruction, tip
- `RecipeMedia` — S3-hosted images
- `RecipeComment` — threaded community comments
- `RecipeFeedback` — rating + "I tried this" notes
- `RecipeQuestion` — public Q&A with optional creator answer
- `RecipeReport` — moderation reports
- `SavedRecipe` — user bookmarks
- `UserProfile` — display name, bio, country, cultural background
- `RecipeFilter` — search/filter parameters

---

## Sample Data

`assets/data/seed_recipes.json` contains 5 community-representative sample recipes:

1. Japanese Sweet Potato Wedges
2. West African Groundnut Stew
3. Turkish Lentil Kofta
4. Indian Moong Dal Cheela Pancakes
5. Mexican Avocado & Black Bean Toast

To seed these into DynamoDB, use the AWS CLI or write a Lambda seeder.

---

## What's Built (MVP)

- [x] Guest browsing (no account required)
- [x] Recipe feed with cuisine quick-filter chips
- [x] Full-text search + multi-dimension filter screen
- [x] Recipe detail with tabs: Recipe / Comments / Questions
- [x] Allergen and choking hazard tags on every recipe card and detail page
- [x] Safety disclaimer on home feed and recipe pages
- [x] Save / unsave recipes (auth-gated)
- [x] Share recipe via native share sheet
- [x] Report recipe / comment / question
- [x] Multi-step recipe upload (5 steps: basics, categories, ingredients, instructions, safety)
- [x] Auth: email/password, confirm email, forgot password
- [x] User profile with edit sheet
- [x] Saved recipes screen
- [x] Settings screen
- [x] AWS CDK infrastructure: Cognito, AppSync, DynamoDB (8 tables with GSIs), S3, SES Lambda
- [x] AppSync GraphQL schema with auth rules
- [x] Analytics abstraction layer
- [x] Feature flags for all monetization paths

---

## What Remains (Post-MVP)

- [ ] Wire AppSync resolvers (connect schema to DynamoDB data sources via VTL or JS resolvers)
- [ ] Upload recipe photos to S3 (Amplify Storage integration in upload flow)
- [ ] Push notifications (Amazon SNS or Firebase via Amplify)
- [ ] Email sharing Lambda deployment and SES domain verification
- [ ] Moderator dashboard (web or admin mobile view)
- [ ] Apple Sign In + Google Sign In (behind feature flags)
- [ ] OpenSearch for advanced full-text search
- [ ] Feedback rating aggregate calculations (Lambda trigger on DynamoDB stream)
- [x] Pagination (infinite scroll with `nextToken`) — Search results and Browse A-Z now paginate for real; see the 2026-08-08 backlog note below for what this replaced.
- [ ] Deep linking (share recipe URLs that open the app)
- [ ] Internationalisation (i18n) — Arabic, Hindi, Turkish, etc.
- [ ] Accessibility audit (screen readers, dynamic text sizes)
- [ ] CI/CD pipeline (GitHub Actions → CDK deploy → TestFlight/Play Store)
- [ ] Analytics provider wired up (Pinpoint / PostHog)
- [ ] Monetization (ads, subscriptions, sponsored recipes — gated behind feature flags)

---

## Production Readiness Backlog (2026-08-07 audit)

Blockers — app store submission cannot proceed without these:

- [ ] **SES production access** — account is still in sandbox (`ProductionAccessEnabled: false`); welcome/marketing emails only reach verified addresses until AWS approves the support case.
- [x] **Real Privacy Policy & Terms of Service** — in-app screens now live at `/privacy-policy` and `/terms-of-service`, linked from Settings and the sign-up consent text (draft copy, not lawyer-reviewed).
- [x] **Support contact address** — Privacy Policy, Terms of Service, and Settings' "Contact us" tile (now a working `mailto:` link) all point to `AppConstants.supportEmail` (samreenaziz@amilifedigitalsolutions.com), a real inbox. Revisit if a dedicated support@bittybellies.com is ever set up later — it's a one-line change in `app_constants.dart`.

2026-08-08 fix: real pagination for Search — `RecipeRepository.getRecipes()` was already accepting a `nextToken` parameter but discarding the response's `nextToken`, and the A-Z browse list had a hardcoded `limit: 200`. Past that cap, recipes silently stopped appearing with no error and no way to reach them. Fixed: `getRecipes()` now returns a `RecipePage` (items + nextToken); `_SearchResults` and `_AlphabeticalBrowseList` in `search_screen.dart` are backed by new `StateNotifier`-based providers (`recipeSearchProvider`, `recipeBrowseProvider` in `recipe_provider.dart`) that load more on scroll via `nextToken`, with no fixed ceiling.

Data durability:

- [ ] Point-in-time recovery on the remaining DynamoDB tables (`CommentsTable`, `FeedbackTable`, `ReportsTable`, `SavedRecipesTable`, `ChildFoldersTable`, `MonetizationTable` — only `RecipesTable`/`UsersTable` have it today)

Content safety:

- [ ] Reviewer/moderator workflow to actually act on `ReportsTable` submissions (reports are captured but nothing reads them)

Testing & CI:

- [ ] Real unit/widget/integration test coverage (only the Flutter-generated boilerplate exists today)
- [ ] CI pipeline (`.github/workflows` is empty — `flutter analyze`/builds are all manual)

Observability:

- [ ] Crash reporting (Sentry or Firebase Crashlytics)
- [ ] Analytics provider wired into `analytics_service.dart` (currently a `TODO`)
- [ ] CloudWatch alarms on Lambdas / DynamoDB throttling / AppSync errors

Environments:

- [ ] Dev/staging AWS environment separate from the current single "everything is prod" setup

Store submission:

- [ ] App Store / Play Store listing assets (screenshots, description, keywords) and a release pipeline (e.g. fastlane)

Other:

- [ ] Accessibility pass (`Semantics()` unused anywhere in `lib/`)
- [ ] Offline/connectivity handling beyond what's in `main.dart`
- [ ] Rate limiting / abuse prevention on upload and comment mutations
- [ ] Remove leftover `TODO` in `recipe_repository_impl.dart:474` (real API Gateway call once Lambda is deployed)

---

## Handoff Notes

- The repo is structured for clean handoff. Each vertical (auth, home, recipe, upload, profile) is self-contained in `presentation/`.
- New screens go in the appropriate `presentation/` subfolder with a matching provider file.
- GraphQL operations are centralised in `lib/data/graphql/queries.dart` — add new queries/mutations there.
- Amplify config is the only file that needs environment-specific values. Consider generating it in CI rather than committing the filled version.
- Feature flags are a single file — safe to search/grep for the flag name to find all gated code.
