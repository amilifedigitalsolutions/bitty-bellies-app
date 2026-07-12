import * as fs from 'fs';
import * as path from 'path';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';

const TABLE_NAME = 'blw-recipes';
const SEED_FILE = path.resolve(__dirname, '../../../assets/data/seed_recipes.json');

type SeedRecipe = {
  id: string;
  title: string;
  description: string;
  creatorId: string;
  creatorName: string;
  creatorAvatarUrl: string | null;
  ingredients: unknown;
  steps: unknown;
  prepTimeMinutes: number;
  cookTimeMinutes: number;
  servings?: number;
  ageStage: string;
  texture: string;
  cuisine: string;
  cultureRegion?: string | null;
  mealCategories?: string[];
  dietTypes?: string[];
  allergens?: string[];
  chokingHazardNotes?: string | null;
  safetyNotes?: string | null;
  storageReheatingNotes?: string | null;
  creatorNotes?: string | null;
  status?: string;
  tags?: string[];
  savedCount?: number;
  commentCount?: number;
  feedbackCount?: number;
  questionCount?: number;
  averageRating?: number;
  isSponsored?: boolean;
  isPremium?: boolean;
  createdAt?: string;
  publishedAt?: string;
};

async function main(): Promise<void> {
  const region = process.env.AWS_REGION ?? 'us-east-1';
  const client = new DynamoDBClient({ region });
  const doc = DynamoDBDocumentClient.from(client, {
    marshallOptions: { removeUndefinedValues: true },
  });

  const raw = fs.readFileSync(SEED_FILE, 'utf-8');
  const recipes: SeedRecipe[] = JSON.parse(raw);
  const now = new Date().toISOString();

  console.log(`Seeding ${recipes.length} recipes into ${TABLE_NAME} (${region})`);

  let ok = 0;
  for (const r of recipes) {
    const item: Record<string, unknown> = {
      ...r,
      // AWSJSON fields must be stringified for AppSync clients to consume them
      // as JSON strings — matches how the AppSync resolver writes them.
      ingredients: typeof r.ingredients === 'string' ? r.ingredients : JSON.stringify(r.ingredients),
      steps: typeof r.steps === 'string' ? r.steps : JSON.stringify(r.steps),
      createdAt: r.createdAt ?? now,
      updatedAt: now,
    };
    if (item.status === 'PUBLISHED' && !r.publishedAt) {
      item.publishedAt = now;
    }

    await doc.send(new PutCommand({ TableName: TABLE_NAME, Item: item }));
    console.log(`[ok] ${r.id}  ${r.title}`);
    ok++;
  }

  console.log(`\nDone. ${ok}/${recipes.length} recipes written.`);
}

main().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
