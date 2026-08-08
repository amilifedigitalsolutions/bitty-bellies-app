// Draft legal copy for the in-app Privacy Policy and Terms of Service
// screens. This is a starting point tailored to what the app actually
// does (AWS-backed storage, community recipe content, optional child
// profiles entered by the parent, opt-in marketing email) — it has not
// been reviewed by a lawyer and should be before shipping to real users.
class LegalText {
  LegalText._();

  static const String lastUpdated = 'August 7, 2026';

  static const String privacyPolicy = '''
Last updated: $lastUpdated

Bitty Bellies ("we", "us", "our") provides a mobile app where parents and caregivers can discover, save, and share baby- and toddler-friendly recipes. This policy explains what information we collect, how we use it, and the choices you have.

1. Information We Collect

Account information: when you create an account we collect your email address, first and last name, date of birth, and password (stored securely by Amazon Cognito — we never see or store your password in plain text).

Profile information: bio, avatar photo, country/region, cultural background, and cooking style, if you choose to add them.

Child information: if you add a child to personalize recipe recommendations, we store the name and birthdate you enter for that child. This information is provided by you, the parent or caregiver — children do not create their own accounts or interact with the app directly.

Content you create: recipes, photos, comments, questions, ratings, and reports you submit.

Usage information: basic app usage data (such as screens viewed and features used) to help us understand what's working and fix what isn't.

2. How We Use Information

To provide the app's core features — saving recipes, personalizing recommendations by child age, letting you share and discover recipes from other parents.

To send you a welcome email when you sign up, and — only if you opt in at sign-up — occasional recipe inspiration, brand updates, or promotional email. You can unsubscribe at any time via the link in any marketing email.

To keep the community safe — reviewing reports of inappropriate content and enforcing our Terms of Service.

To improve the app based on aggregate usage patterns.

3. How Information Is Stored and Shared

Your information is stored on Amazon Web Services (AWS) infrastructure (Cognito, AppSync, DynamoDB, and S3). We do not sell your personal information to third parties. We share information only with service providers who help us run the app (such as AWS) and only to the extent needed to provide the service.

Recipes, comments, and other content you choose to post publicly are visible to other users of the app. Your child's name and birthdate are never shown publicly — they're used only to personalize your own experience.

4. Children's Privacy

Bitty Bellies is intended for use by parents and caregivers who are at least 13 years old. The app is not directed to children, and we do not knowingly collect personal information directly from children. Information about a child (name, birthdate) is entered by the parent or caregiver account holder for their own use in personalizing recommendations.

5. Your Choices

You can edit or delete your profile information at any time from the app. You can opt out of marketing email at any time. To request deletion of your account and associated data, contact us using the details below.

6. Security

We use industry-standard safeguards (including AWS-managed encryption and authentication) to protect your information. No method of storage or transmission is 100% secure, so we can't guarantee absolute security.

7. Changes to This Policy

We may update this policy from time to time. If we make material changes, we'll let you know in the app or by email.

8. Contact Us

Questions about this policy? Email us at support@bittybellies.com.
''';

  static const String termsOfService = '''
Last updated: $lastUpdated

These Terms of Service ("Terms") govern your use of the Bitty Bellies app. By creating an account, you agree to these Terms.

1. Eligibility

You must be at least 13 years old to create a Bitty Bellies account. If you're adding information about your child, you must be their parent or legal guardian.

2. Your Account

You're responsible for keeping your login credentials secure and for all activity under your account. Provide accurate information when you sign up.

3. Community Content

You retain ownership of the recipes, photos, comments, and other content you post ("Your Content"). By posting, you grant Bitty Bellies a non-exclusive, worldwide, royalty-free license to host, display, and distribute Your Content within the app so other users can discover it.

You agree not to post content that is illegal, hateful, harassing, infringes someone else's rights, or is spam.

4. Safety Disclaimer

Recipes and feeding suggestions on Bitty Bellies are shared by community members, not medical or nutrition professionals. They are not medical advice. Always consult your pediatrician or health visitor before introducing new foods, and pay close attention to allergen and choking-hazard information — you know your child's needs best.

5. Reporting and Moderation

If you see content that violates these Terms, please report it using the flag icon. We may remove content or suspend accounts that violate these Terms at our discretion.

6. Termination

You may stop using the app and delete your account at any time. We may suspend or terminate accounts that violate these Terms.

7. Disclaimers

The app is provided "as is" without warranties of any kind. We don't guarantee that recipes shared by the community are accurate, safe for every child, or free of errors.

8. Limitation of Liability

To the fullest extent permitted by law, Bitty Bellies is not liable for any indirect, incidental, or consequential damages arising from your use of the app.

9. Changes to These Terms

We may update these Terms from time to time. Continuing to use the app after changes take effect means you accept the updated Terms.

10. Contact Us

Questions about these Terms? Email us at support@bittybellies.com.
''';
}
