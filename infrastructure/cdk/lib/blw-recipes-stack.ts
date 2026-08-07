import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as appsync from 'aws-cdk-lib/aws-appsync';
import * as ses from 'aws-cdk-lib/aws-ses';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as path from 'path';

export class BlwRecipesStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ──────────────────────────────────────────────────────────────────────
    // Cognito — Auth
    // ──────────────────────────────────────────────────────────────────────

    const userPool = new cognito.UserPool(this, 'BLWUserPool', {
      userPoolName: 'blw-recipes-users',
      selfSignUpEnabled: true,
      signInAliases: { email: true },
      autoVerify: { email: true },
      standardAttributes: {
        email: { required: true, mutable: true },
        fullname: { required: true, mutable: true },
      },
      // Set by the client at sign-up time from a (default-unchecked) opt-in
      // checkbox — read by WelcomeEmailLambda below to decide whether to
      // add the new user to the marketing contact list.
      customAttributes: {
        marketingOptIn: new cognito.BooleanAttribute({ mutable: true }),
      },
      passwordPolicy: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireDigits: true,
        requireSymbols: false,
      },
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    const userPoolClient = userPool.addClient('BLWMobileClient', {
      userPoolClientName: 'blw-recipes-mobile',
      authFlows: {
        userSrp: true,
        userPassword: false, // use SRP only
      },
      preventUserExistenceErrors: true,
    });

    // Moderators group
    new cognito.CfnUserPoolGroup(this, 'ModeratorsGroup', {
      userPoolId: userPool.userPoolId,
      groupName: 'Moderators',
      description: 'Content moderation team',
    });

    // Admins group
    new cognito.CfnUserPoolGroup(this, 'AdminsGroup', {
      userPoolId: userPool.userPoolId,
      groupName: 'Admins',
      description: 'Platform administrators',
    });

    const identityPool = new cognito.CfnIdentityPool(this, 'BLWIdentityPool', {
      identityPoolName: 'blwrecipes',
      allowUnauthenticatedIdentities: true, // guest browsing
      cognitoIdentityProviders: [{
        clientId: userPoolClient.userPoolClientId,
        providerName: userPool.userPoolProviderName,
      }],
    });

    // IAM roles for the Identity Pool
    const unauthRole = new iam.Role(this, 'CognitoUnauthRole', {
      assumedBy: new iam.FederatedPrincipal(
        'cognito-identity.amazonaws.com',
        {
          StringEquals: { 'cognito-identity.amazonaws.com:aud': identityPool.ref },
          'ForAnyValue:StringLike': { 'cognito-identity.amazonaws.com:amr': 'unauthenticated' },
        },
        'sts:AssumeRoleWithWebIdentity',
      ),
    });
    unauthRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['appsync:GraphQL'],
      resources: [`arn:aws:appsync:${this.region}:${this.account}:apis/*/types/Query/fields/*`],
    }));

    const authRole = new iam.Role(this, 'CognitoAuthRole', {
      assumedBy: new iam.FederatedPrincipal(
        'cognito-identity.amazonaws.com',
        {
          StringEquals: { 'cognito-identity.amazonaws.com:aud': identityPool.ref },
          'ForAnyValue:StringLike': { 'cognito-identity.amazonaws.com:amr': 'authenticated' },
        },
        'sts:AssumeRoleWithWebIdentity',
      ),
    });
    authRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['appsync:GraphQL'],
      resources: [`arn:aws:appsync:${this.region}:${this.account}:apis/*/*`],
    }));

    new cognito.CfnIdentityPoolRoleAttachment(this, 'IdentityPoolRoles', {
      identityPoolId: identityPool.ref,
      roles: {
        unauthenticated: unauthRole.roleArn,
        authenticated: authRole.roleArn,
      },
    });

    // ──────────────────────────────────────────────────────────────────────
    // S3 — Recipe media storage
    // ──────────────────────────────────────────────────────────────────────

    const mediaBucket = new s3.Bucket(this, 'BLWMediaBucket', {
      bucketName: `blw-recipes-media-${this.account}-${this.region}`,
      cors: [{
        allowedMethods: [s3.HttpMethods.GET, s3.HttpMethods.PUT, s3.HttpMethods.POST, s3.HttpMethods.DELETE],
        allowedOrigins: ['*'],
        allowedHeaders: ['*'],
      }],
      blockPublicAccess: new s3.BlockPublicAccess({
        blockPublicAcls: false,
        blockPublicPolicy: false,
        ignorePublicAcls: false,
        restrictPublicBuckets: false,
      }),
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Public read for recipe images, user-specific write
    mediaBucket.addToResourcePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      principals: [new iam.AnyPrincipal()],
      actions: ['s3:GetObject'],
      resources: [`${mediaBucket.bucketArn}/public/*`],
    }));

    // Authenticated users can upload/replace recipe cover photos — matches
    // the public/ prefix the read policy above already covers.
    mediaBucket.grantPut(authRole, 'public/*');
    mediaBucket.grantDelete(authRole, 'public/*');

    // ──────────────────────────────────────────────────────────────────────
    // DynamoDB tables
    // ──────────────────────────────────────────────────────────────────────

    const recipesTable = new dynamodb.Table(this, 'RecipesTable', {
      tableName: 'blw-recipes',
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true },
    });

    // GSI: by creator
    recipesTable.addGlobalSecondaryIndex({
      indexName: 'byCreatorId',
      partitionKey: { name: 'creatorId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'createdAt', type: dynamodb.AttributeType.STRING },
    });

    // GSI: by status (for moderators)
    recipesTable.addGlobalSecondaryIndex({
      indexName: 'byStatus',
      partitionKey: { name: 'status', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'createdAt', type: dynamodb.AttributeType.STRING },
    });

    // GSI: by cuisine
    recipesTable.addGlobalSecondaryIndex({
      indexName: 'byCuisine',
      partitionKey: { name: 'cuisine', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'savedCount', type: dynamodb.AttributeType.NUMBER },
    });

    const usersTable = new dynamodb.Table(this, 'UsersTable', {
      tableName: 'blw-users',
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true },
    });

    const commentsTable = new dynamodb.Table(this, 'CommentsTable', {
      tableName: 'blw-recipe-comments',
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    commentsTable.addGlobalSecondaryIndex({
      indexName: 'byRecipeId',
      partitionKey: { name: 'recipeId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'createdAt', type: dynamodb.AttributeType.STRING },
    });

    const feedbackTable = new dynamodb.Table(this, 'FeedbackTable', {
      tableName: 'blw-recipe-feedback',
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    feedbackTable.addGlobalSecondaryIndex({
      indexName: 'byRecipeId',
      partitionKey: { name: 'recipeId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'createdAt', type: dynamodb.AttributeType.STRING },
    });

    const reportsTable = new dynamodb.Table(this, 'ReportsTable', {
      tableName: 'blw-recipe-reports',
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    reportsTable.addGlobalSecondaryIndex({
      indexName: 'byStatus',
      partitionKey: { name: 'status', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'createdAt', type: dynamodb.AttributeType.STRING },
    });

    const savedRecipesTable = new dynamodb.Table(this, 'SavedRecipesTable', {
      tableName: 'blw-saved-recipes',
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    savedRecipesTable.addGlobalSecondaryIndex({
      indexName: 'byUserId',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'savedAt', type: dynamodb.AttributeType.STRING },
    });

    // childId + "FOLDER#recipeId" as a composite sort key — unlike
    // SavedRecipesTable's synthetic id (which needs a list-then-find before
    // every delete), this lets both per-child and per-folder queries
    // (via begins_with) and deletes address the item directly, no lookup.
    const childFoldersTable = new dynamodb.Table(this, 'ChildFoldersTable', {
      tableName: 'blw-child-folders',
      partitionKey: { name: 'childId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'folderKey', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Monetization placeholder table (empty for MVP)
    const monetizationTable = new dynamodb.Table(this, 'MonetizationTable', {
      tableName: 'blw-monetization-placements',
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // ──────────────────────────────────────────────────────────────────────
    // AppSync GraphQL API
    // ──────────────────────────────────────────────────────────────────────

    const api = new appsync.GraphqlApi(this, 'BLWApi', {
      name: 'blw-recipes-api',
      schema: appsync.SchemaFile.fromAsset(
        path.join(__dirname, '../../../lib/data/graphql/schema.graphql')
      ),
      authorizationConfig: {
        defaultAuthorization: {
          authorizationType: appsync.AuthorizationType.USER_POOL,
          userPoolConfig: { userPool },
        },
        additionalAuthorizationModes: [
          { authorizationType: appsync.AuthorizationType.IAM }, // for guest access
        ],
      },
      logConfig: {
        fieldLogLevel: appsync.FieldLogLevel.ERROR,
      },
    });

    // DynamoDB data sources
    const recipesDS = api.addDynamoDbDataSource('RecipesDS', recipesTable);
    const usersDS = api.addDynamoDbDataSource('UsersDS', usersTable);
    const commentsDS = api.addDynamoDbDataSource('CommentsDS', commentsTable);
    const feedbackDS = api.addDynamoDbDataSource('FeedbackDS', feedbackTable);
    const reportsDS = api.addDynamoDbDataSource('ReportsDS', reportsTable);
    const savedDS = api.addDynamoDbDataSource('SavedDS', savedRecipesTable);
    const childFoldersDS = api.addDynamoDbDataSource('ChildFoldersDS', childFoldersTable);

    // ──────────────────────────────────────────────────────────────────────
    // AppSync Resolvers
    // ──────────────────────────────────────────────────────────────────────

    // ── Queries ──

    usersDS.createResolver('GetUserProfile', {
      typeName: 'Query',
      fieldName: 'getUserProfile',
      requestMappingTemplate: appsync.MappingTemplate.dynamoDbGetItem('id', 'id'),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    recipesDS.createResolver('GetRecipe', {
      typeName: 'Query',
      fieldName: 'getRecipe',
      requestMappingTemplate: appsync.MappingTemplate.dynamoDbGetItem('id', 'id'),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    recipesDS.createResolver('ListRecipes', {
      typeName: 'Query',
      fieldName: 'listRecipes',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "Scan",
  #if($context.args.filter)
    "filter": $util.transform.toDynamoDBFilterExpression($context.args.filter),
  #end
  "limit": $util.defaultIfNull($context.args.limit, 20),
  #if($context.args.nextToken)
    "nextToken": "$context.args.nextToken"
  #end
}
`),
      responseMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "items": $util.toJson($context.result.items),
  #if($context.result.nextToken)
    "nextToken": "$context.result.nextToken"
  #end
}
`),
    });

    recipesDS.createResolver('RecipesByCreatorId', {
      typeName: 'Query',
      fieldName: 'recipesByCreatorId',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "Query",
  "index": "byCreatorId",
  "query": {
    "expression": "creatorId = :creatorId",
    "expressionValues": {
      ":creatorId": $util.dynamodb.toDynamoDBJson($context.args.creatorId)
    }
  },
  "limit": $util.defaultIfNull($context.args.limit, 20),
  #if($context.args.nextToken)
    "nextToken": "$context.args.nextToken"
  #end
}
`),
      responseMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "items": $util.toJson($context.result.items),
  #if($context.result.nextToken)
    "nextToken": "$context.result.nextToken"
  #end
}
`),
    });

    commentsDS.createResolver('CommentsByRecipeId', {
      typeName: 'Query',
      fieldName: 'commentsByRecipeId',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "Query",
  "index": "byRecipeId",
  "query": {
    "expression": "recipeId = :recipeId",
    "expressionValues": {
      ":recipeId": $util.dynamodb.toDynamoDBJson($context.args.recipeId)
    }
  },
  "limit": $util.defaultIfNull($context.args.limit, 50),
  #if($context.args.nextToken)
    "nextToken": "$context.args.nextToken"
  #end
}
`),
      responseMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "items": $util.toJson($context.result.items),
  #if($context.result.nextToken)
    "nextToken": "$context.result.nextToken"
  #end
}
`),
    });

    feedbackDS.createResolver('FeedbackByRecipeId', {
      typeName: 'Query',
      fieldName: 'feedbackByRecipeId',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "Query",
  "index": "byRecipeId",
  "query": {
    "expression": "recipeId = :recipeId",
    "expressionValues": {
      ":recipeId": $util.dynamodb.toDynamoDBJson($context.args.recipeId)
    }
  },
  "limit": $util.defaultIfNull($context.args.limit, 50),
  #if($context.args.nextToken)
    "nextToken": "$context.args.nextToken"
  #end
}
`),
      responseMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "items": $util.toJson($context.result.items),
  #if($context.result.nextToken)
    "nextToken": "$context.result.nextToken"
  #end
}
`),
    });

    savedDS.createResolver('SavedRecipesByUserId', {
      typeName: 'Query',
      fieldName: 'savedRecipesByUserId',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "Query",
  "index": "byUserId",
  "query": {
    "expression": "userId = :userId",
    "expressionValues": {
      ":userId": $util.dynamodb.toDynamoDBJson($context.args.userId)
    }
  },
  "limit": $util.defaultIfNull($context.args.limit, 50),
  #if($context.args.nextToken)
    "nextToken": "$context.args.nextToken"
  #end
}
`),
      responseMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "items": $util.toJson($context.result.items),
  #if($context.result.nextToken)
    "nextToken": "$context.result.nextToken"
  #end
}
`),
    });

    childFoldersDS.createResolver('ChildRecipeFoldersByChild', {
      typeName: 'Query',
      fieldName: 'childRecipeFoldersByChild',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "Query",
  "query": {
    "expression": "childId = :childId",
    "expressionValues": {
      ":childId": $util.dynamodb.toDynamoDBJson($context.args.childId)
    }
  },
  "limit": $util.defaultIfNull($context.args.limit, 50),
  #if($context.args.nextToken)
    "nextToken": "$context.args.nextToken"
  #end
}
`),
      responseMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "items": $util.toJson($context.result.items),
  #if($context.result.nextToken)
    "nextToken": "$context.result.nextToken"
  #end
}
`),
    });

    // ── Mutations: UserProfile ──

    usersDS.createResolver('CreateUserProfile', {
      typeName: 'Mutation',
      fieldName: 'createUserProfile',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "PutItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($util.defaultIfNullOrBlank($context.args.input.id, $util.autoId()))
  },
  "attributeValues": $util.dynamodb.toMapValuesJson($context.args.input),
  "condition": {
    "expression": "attribute_not_exists(id)"
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    usersDS.createResolver('UpdateUserProfile', {
      typeName: 'Mutation',
      fieldName: 'updateUserProfile',
      // Explicit SET expression rather than the $util.dynamodb.toMapValuesJson
      // shorthand used elsewhere — that shorthand broke specifically once a
      // nested list-of-objects field (children) was mixed with plain
      // nullable scalars in the same update ("Unsupported element" error).
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
#set($input = $util.map.copyAndRemoveAllKeys($context.args.input, ["id"]))
#set($expNames = {})
#set($expValues = {})
#set($setParts = [])
#foreach($key in $input.keySet())
  #set($namePlaceholder = "#$key")
  #set($valuePlaceholder = ":$key")
  $util.qr($expNames.put($namePlaceholder, $key))
  $util.qr($expValues.put($valuePlaceholder, $util.dynamodb.toDynamoDB($input[$key])))
  $util.qr($setParts.add("$namePlaceholder = $valuePlaceholder"))
#end
#set($setExpression = "")
#foreach($part in $setParts)
  #if($foreach.count > 1)#set($setExpression = "$setExpression, $part")#else#set($setExpression = "$part")#end
#end
{
  "version": "2017-02-28",
  "operation": "UpdateItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
  },
  "update": {
    "expression": "SET $setExpression",
    "expressionNames": $util.toJson($expNames),
    "expressionValues": $util.toJson($expValues)
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // ── Mutations: Recipe ──

    recipesDS.createResolver('CreateRecipe', {
      typeName: 'Mutation',
      fieldName: 'createRecipe',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "PutItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($util.defaultIfNullOrBlank($context.args.input.id, $util.autoId()))
  },
  "attributeValues": $util.dynamodb.toMapValuesJson($context.args.input),
  "condition": {
    "expression": "attribute_not_exists(id)"
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    recipesDS.createResolver('UpdateRecipe', {
      typeName: 'Mutation',
      fieldName: 'updateRecipe',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "UpdateItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($context.args.input.id)
  },
  #set($input = $util.map.copyAndRemoveAllKeys($context.args.input, ["id"]))
  "update": $util.dynamodb.toMapValuesJson($input),
  "condition": {
    "expression": "creatorId = :creatorId",
    "expressionValues": {
      ":creatorId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
    }
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    recipesDS.createResolver('DeleteRecipe', {
      typeName: 'Mutation',
      fieldName: 'deleteRecipe',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "DeleteItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($context.args.input.id)
  },
  "condition": {
    "expression": "creatorId = :creatorId",
    "expressionValues": {
      ":creatorId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
    }
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // ── Mutations: Comments ──

    commentsDS.createResolver('CreateRecipeComment', {
      typeName: 'Mutation',
      fieldName: 'createRecipeComment',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "PutItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($util.defaultIfNullOrBlank($context.args.input.id, $util.autoId()))
  },
  "attributeValues": $util.dynamodb.toMapValuesJson($context.args.input),
  "condition": {
    "expression": "attribute_not_exists(id)"
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    commentsDS.createResolver('UpdateRecipeComment', {
      typeName: 'Mutation',
      fieldName: 'updateRecipeComment',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "UpdateItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($context.args.input.id)
  },
  "update": {
    "expression": "SET body = :body, updatedAt = :updatedAt",
    "expressionValues": {
      ":body": $util.dynamodb.toDynamoDBJson($context.args.input.body),
      ":updatedAt": $util.dynamodb.toDynamoDBJson($util.time.nowISO8601())
    }
  },
  "condition": {
    "expression": "authorId = :authorId",
    "expressionValues": {
      ":authorId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
    }
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    commentsDS.createResolver('DeleteRecipeComment', {
      typeName: 'Mutation',
      fieldName: 'deleteRecipeComment',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "DeleteItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($context.args.input.id)
  },
  "condition": {
    "expression": "authorId = :authorId",
    "expressionValues": {
      ":authorId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
    }
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // ── Mutations: Feedback ──

    feedbackDS.createResolver('CreateRecipeFeedback', {
      typeName: 'Mutation',
      fieldName: 'createRecipeFeedback',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "PutItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($util.defaultIfNullOrBlank($context.args.input.id, $util.autoId()))
  },
  "attributeValues": $util.dynamodb.toMapValuesJson($context.args.input),
  "condition": {
    "expression": "attribute_not_exists(id)"
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // ── Mutations: Saved Recipes ──

    savedDS.createResolver('CreateSavedRecipe', {
      typeName: 'Mutation',
      fieldName: 'createSavedRecipe',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "PutItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($util.defaultIfNullOrBlank($context.args.input.id, $util.autoId()))
  },
  "attributeValues": $util.dynamodb.toMapValuesJson($context.args.input),
  "condition": {
    "expression": "attribute_not_exists(id)"
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    savedDS.createResolver('DeleteSavedRecipe', {
      typeName: 'Mutation',
      fieldName: 'deleteSavedRecipe',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "DeleteItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($context.args.input.id)
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // ── Mutations: Child Recipe Folders ──

    childFoldersDS.createResolver('CreateChildRecipeFolder', {
      typeName: 'Mutation',
      fieldName: 'createChildRecipeFolder',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
#set($folderKey = "$context.args.input.folder#$context.args.input.recipeId")
#set($values = $context.args.input)
$util.qr($values.put("parentId", $ctx.identity.sub))
#if(!$values.createdAt)
  $util.qr($values.put("createdAt", $util.time.nowISO8601()))
#end
{
  "version": "2017-02-28",
  "operation": "PutItem",
  "key": {
    "childId": $util.dynamodb.toDynamoDBJson($context.args.input.childId),
    "folderKey": $util.dynamodb.toDynamoDBJson($folderKey)
  },
  "attributeValues": $util.dynamodb.toMapValuesJson($values),
  "condition": {
    "expression": "attribute_not_exists(folderKey)"
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    childFoldersDS.createResolver('DeleteChildRecipeFolder', {
      typeName: 'Mutation',
      fieldName: 'deleteChildRecipeFolder',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
#set($folderKey = "$context.args.input.folder#$context.args.input.recipeId")
{
  "version": "2017-02-28",
  "operation": "DeleteItem",
  "key": {
    "childId": $util.dynamodb.toDynamoDBJson($context.args.input.childId),
    "folderKey": $util.dynamodb.toDynamoDBJson($folderKey)
  },
  "condition": {
    "expression": "parentId = :parentId",
    "expressionValues": {
      ":parentId": $util.dynamodb.toDynamoDBJson($ctx.identity.sub)
    }
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // ── Mutations: Reports ──

    reportsDS.createResolver('CreateRecipeReport', {
      typeName: 'Mutation',
      fieldName: 'createRecipeReport',
      requestMappingTemplate: appsync.MappingTemplate.fromString(`
{
  "version": "2017-02-28",
  "operation": "PutItem",
  "key": {
    "id": $util.dynamodb.toDynamoDBJson($util.defaultIfNullOrBlank($context.args.input.id, $util.autoId()))
  },
  "attributeValues": $util.dynamodb.toMapValuesJson($context.args.input),
  "condition": {
    "expression": "attribute_not_exists(id)"
  }
}
`),
      responseMappingTemplate: appsync.MappingTemplate.dynamoDbResultItem(),
    });

    // ──────────────────────────────────────────────────────────────────────
    // SES — Email sending
    // ──────────────────────────────────────────────────────────────────────

    // Easy DKIM domain identity — deploying this does NOT make sending work
    // by itself. AWS generates 3 DKIM CNAME records (output below as
    // SESDkimRecords) that must be added to bittybellies.com's DNS; the
    // domain shows as "pending" in the SES console until those propagate
    // and AWS verifies them. Also note: a new SES account starts in
    // sandbox mode (can only send to individually-verified recipient
    // addresses) until production access is requested via AWS Support —
    // that's a separate, manual step, not something CDK can do.
    const sesIdentity = new ses.EmailIdentity(this, 'SESIdentity', {
      identity: ses.Identity.domain('bittybellies.com'),
    });

    // Marketing contact list — populated from the sign-up opt-in checkbox,
    // not the SES sandbox/production-access identity above. Modeled with a
    // topic (rather than a flat list) from the start, so future campaigns
    // (e.g. "new recipes" vs. "product announcements") can layer in without
    // restructuring; today sign-up only offers the one topic.
    const subscribersListName = 'bitty-bellies-subscribers';
    const subscribersList = new ses.CfnContactList(this, 'SubscribersList', {
      contactListName: subscribersListName,
      description: 'Users who opted in to marketing email at sign-up.',
      topics: [
        {
          topicName: 'product-updates',
          displayName: 'Recipe inspiration, brand promotions, & app updates',
          description: 'New recipes, features, and occasional announcements from Bitty Bellies.',
          defaultSubscriptionStatus: 'OPT_IN',
        },
      ],
    });

    // Lambda for email sharing
    const emailLambda = new lambda.Function(this, 'EmailShareLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
        const ses = new SESClient({ region: process.env.AWS_REGION });

        exports.handler = async (event) => {
          const { toEmail, recipeTitle, recipeUrl } = event;
          await ses.send(new SendEmailCommand({
            Source: process.env.FROM_EMAIL,
            Destination: { ToAddresses: [toEmail] },
            Message: {
              Subject: { Data: \`Baby-led weaning recipe: \${recipeTitle}\` },
              Body: {
                Text: { Data: \`Check out this BLW recipe: \${recipeUrl}\` },
                Html: { Data: \`<p>Check out this baby-led weaning recipe: <a href="\${recipeUrl}">\${recipeTitle}</a></p><p><em>Always supervise your baby during feeding.</em></p>\` }
              }
            }
          }));
          return { success: true };
        };
      `),
      environment: {
        FROM_EMAIL: 'noreply@bittybellies.com',
      },
    });

    emailLambda.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['ses:SendEmail', 'ses:SendRawEmail'],
      resources: ['*'],
    }));

    // Cognito Post Confirmation trigger — fires right after a new user
    // confirms their email, so this is genuinely "as soon as they sign up"
    // rather than on every sign-in. Must always return `event` unmodified;
    // Cognito uses the return value to continue the auth flow, so a thrown
    // error here would block the user's account confirmation entirely —
    // the SES send is wrapped in try/catch specifically so a failed welcome
    // email can never fail someone's sign-up.
    const welcomeEmailLambda = new lambda.Function(this, 'WelcomeEmailLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
        const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
        const { SESv2Client, CreateContactCommand } = require('@aws-sdk/client-sesv2');
        const ses = new SESClient({ region: process.env.AWS_REGION });
        const sesv2 = new SESv2Client({ region: process.env.AWS_REGION });

        exports.handler = async (event) => {
          const email = event.request.userAttributes.email;
          const name = event.request.userAttributes.name || 'there';

          try {
            await ses.send(new SendEmailCommand({
              Source: process.env.FROM_EMAIL,
              Destination: { ToAddresses: [email] },
              Message: {
                Subject: { Data: 'Welcome to Bitty Bellies!' },
                Body: {
                  Text: { Data: \`Hi \${name},\\n\\nWelcome to Bitty Bellies -- real recipes, from real parents, just like you.\\n\\nExplore baby-led weaning recipes shared by parents around the world, or share your own favorite.\\n\\nHappy feeding!\\nThe Bitty Bellies team\` },
                  Html: { Data: \`<p>Hi \${name},</p><p>Welcome to Bitty Bellies &mdash; real recipes, from real parents, just like you.</p><p>Explore baby-led weaning recipes shared by parents around the world, or share your own favorite.</p><p>Happy feeding!<br/>The Bitty Bellies team</p>\` }
                }
              }
            }));
          } catch (err) {
            console.error('Failed to send welcome email', err);
          }

          // Sign-up's opt-in checkbox — Cognito custom attributes always
          // arrive as strings, so this is a literal 'true' check, not a
          // boolean. Also wrapped separately in its own try/catch: a
          // failure here should never take down the welcome email above,
          // or the sign-up confirmation itself.
          if (event.request.userAttributes['custom:marketingOptIn'] === 'true') {
            try {
              await sesv2.send(new CreateContactCommand({
                ContactListName: process.env.CONTACT_LIST_NAME,
                EmailAddress: email,
                TopicPreferences: [{ TopicName: 'product-updates', SubscriptionStatus: 'OPT_IN' }],
                UnsubscribeAll: false,
              }));
            } catch (err) {
              console.error('Failed to add contact to marketing list', err);
            }
          }

          return event;
        };
      `),
      environment: {
        FROM_EMAIL: 'welcome@bittybellies.com',
        CONTACT_LIST_NAME: subscribersListName,
      },
    });

    welcomeEmailLambda.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['ses:SendEmail', 'ses:SendRawEmail'],
      resources: ['*'],
    }));

    // AWS::SES::ContactList has no CloudFormation-generated ARN attribute
    // (its reference type only exposes contactListName), so it's built by
    // hand following SES's documented contact-list ARN format.
    const subscribersListArn = `arn:${cdk.Aws.PARTITION}:ses:${this.region}:${this.account}:contact-list/${subscribersListName}`;

    welcomeEmailLambda.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['ses:CreateContact', 'ses:PutContact'],
      resources: [subscribersListArn],
    }));
    // Ensures the contact list exists before the Lambda that references its
    // name/ARN is created — CDK doesn't infer this dependency automatically
    // since the reference is inside an inline string template, not a typed
    // CDK token passed directly into a construct prop it tracks.
    welcomeEmailLambda.node.addDependency(subscribersList);

    userPool.addTrigger(cognito.UserPoolOperation.POST_CONFIRMATION, welcomeEmailLambda);

    // ──────────────────────────────────────────────────────────────────────
    // Stack outputs
    // ──────────────────────────────────────────────────────────────────────

    new cdk.CfnOutput(this, 'UserPoolId', { value: userPool.userPoolId });
    new cdk.CfnOutput(this, 'UserPoolClientId', { value: userPoolClient.userPoolClientId });
    new cdk.CfnOutput(this, 'IdentityPoolId', { value: identityPool.ref });
    new cdk.CfnOutput(this, 'AppSyncEndpoint', { value: api.graphqlUrl });
    new cdk.CfnOutput(this, 'AppSyncApiId', { value: api.apiId });
    new cdk.CfnOutput(this, 'S3BucketName', { value: mediaBucket.bucketName });
    new cdk.CfnOutput(this, 'Region', { value: this.region });

    // Add these 3 as CNAME records on bittybellies.com's DNS after deploy —
    // SES shows the domain as "verified" once they've propagated and AWS
    // has checked them (can take up to 72h, usually much faster).
    sesIdentity.dkimRecords.forEach((record, i) => {
      new cdk.CfnOutput(this, `SESDkimRecord${i + 1}Name`, { value: record.name });
      new cdk.CfnOutput(this, `SESDkimRecord${i + 1}Value`, { value: record.value });
    });
  }
}
