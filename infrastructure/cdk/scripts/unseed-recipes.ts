import * as fs from 'fs';
import * as path from 'path';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, DeleteCommand } from '@aws-sdk/lib-dynamodb';

const TABLE_NAME = 'blw-recipes';
const SEED_FILE = path.resolve(__dirname, '../../../assets/data/seed_recipes.json');

async function main(): Promise<void> {
  const region = process.env.AWS_REGION ?? 'us-east-1';
  const client = new DynamoDBClient({ region });
  const doc = DynamoDBDocumentClient.from(client);

  const raw = fs.readFileSync(SEED_FILE, 'utf-8');
  const recipes: Array<{ id: string; title: string }> = JSON.parse(raw);

  console.log(`Removing ${recipes.length} seeded recipes from ${TABLE_NAME} (${region})`);

  let ok = 0;
  for (const r of recipes) {
    await doc.send(new DeleteCommand({ TableName: TABLE_NAME, Key: { id: r.id } }));
    console.log(`[del] ${r.id}  ${r.title}`);
    ok++;
  }

  console.log(`\nDone. ${ok}/${recipes.length} rows deleted.`);
}

main().catch((err) => {
  console.error('Unseed failed:', err);
  process.exit(1);
});
