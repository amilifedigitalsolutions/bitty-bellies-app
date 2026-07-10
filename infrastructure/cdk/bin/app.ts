#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { BlwRecipesStack } from '../lib/blw-recipes-stack';

const app = new cdk.App();
new BlwRecipesStack(app, 'BlwRecipesStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION ?? 'us-east-1',
  },
  description: 'BLW Recipes — AWS backend (Cognito, AppSync, DynamoDB, S3, SES)',
});
