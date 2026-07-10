class RecipeQueries {
  RecipeQueries._();

  static const listRecipes = r'''
    query ListRecipes($filter: ModelRecipeFilterInput, $limit: Int, $nextToken: String) {
      listRecipes(filter: $filter, limit: $limit, nextToken: $nextToken) {
        items {
          id title description creatorId creatorName creatorAvatarUrl
          ageStage texture cuisine cultureRegion mealCategories dietTypes
          allergens prepTimeMinutes cookTimeMinutes servings
          savedCount commentCount feedbackCount questionCount averageRating
          isSponsored isPremium status publishedAt createdAt updatedAt
          media { items { id url isCover sortOrder } }
        }
        nextToken
      }
    }
  ''';

  static const getRecipe = r'''
    query GetRecipe($id: ID!) {
      getRecipe(id: $id) {
        id title description creatorId creatorName creatorAvatarUrl
        ingredients steps
        ageStage texture cuisine cultureRegion mealCategories dietTypes
        allergens prepTimeMinutes cookTimeMinutes servings
        chokingHazardNotes safetyNotes storageReheatingNotes creatorNotes
        tags savedCount commentCount feedbackCount questionCount averageRating
        isSponsored isPremium status moderationNote publishedAt createdAt updatedAt
        media { items { id url s3Key isCover sortOrder type } }
      }
    }
  ''';

  static const recipesByCreator = r'''
    query RecipesByCreator($creatorId: ID!, $limit: Int, $nextToken: String) {
      recipesByCreatorId(creatorId: $creatorId, limit: $limit, nextToken: $nextToken) {
        items {
          id title description ageStage texture cuisine status
          savedCount commentCount averageRating createdAt updatedAt
          media { items { id url isCover sortOrder } }
        }
        nextToken
      }
    }
  ''';

  static const getComments = r'''
    query GetComments($recipeId: ID!, $limit: Int, $nextToken: String) {
      commentsByRecipeId(recipeId: $recipeId, limit: $limit, nextToken: $nextToken) {
        items {
          id recipeId authorId authorName authorAvatarUrl body
          parentCommentId isDeleted isHidden likeCount createdAt updatedAt
        }
        nextToken
      }
    }
  ''';

  static const getFeedback = r'''
    query GetFeedback($recipeId: ID!, $limit: Int, $nextToken: String) {
      feedbackByRecipeId(recipeId: $recipeId, limit: $limit, nextToken: $nextToken) {
        items {
          id recipeId authorId authorName authorAvatarUrl
          rating triedIt babyReaction modifications notes createdAt updatedAt
        }
        nextToken
      }
    }
  ''';

  static const getQuestions = r'''
    query GetQuestions($recipeId: ID!, $limit: Int, $nextToken: String) {
      questionsByRecipeId(recipeId: $recipeId, limit: $limit, nextToken: $nextToken) {
        items {
          id recipeId authorId authorName authorAvatarUrl
          question isAnsweredByCreator creatorAnswer answeredAt isHidden createdAt updatedAt
        }
        nextToken
      }
    }
  ''';

  static const getSavedRecipes = r'''
    query GetSavedRecipes($userId: ID!, $limit: Int, $nextToken: String) {
      savedRecipesByUserId(userId: $userId, limit: $limit, nextToken: $nextToken) {
        items {
          id userId recipeId savedAt
        }
        nextToken
      }
    }
  ''';

  static const getUserProfile = r'''
    query GetUserProfile($id: ID!) {
      getUserProfile(id: $id) {
        id displayName email bio avatarUrl country region
        culturalBackground cookingStyle savedRecipesCount uploadedRecipesCount
        isVerifiedCreator isModerator isAdmin isActive createdAt updatedAt
      }
    }
  ''';
}

class RecipeMutations {
  RecipeMutations._();

  static const createRecipe = r'''
    mutation CreateRecipe($input: CreateRecipeInput!) {
      createRecipe(input: $input) {
        id title description creatorId creatorName status createdAt
      }
    }
  ''';

  static const updateRecipe = r'''
    mutation UpdateRecipe($input: UpdateRecipeInput!) {
      updateRecipe(input: $input) {
        id title description status updatedAt
      }
    }
  ''';

  static const deleteRecipe = r'''
    mutation DeleteRecipe($input: DeleteRecipeInput!) {
      deleteRecipe(input: $input) { id }
    }
  ''';

  static const createComment = r'''
    mutation CreateComment($input: CreateRecipeCommentInput!) {
      createRecipeComment(input: $input) {
        id recipeId authorId authorName body parentCommentId createdAt
      }
    }
  ''';

  static const deleteComment = r'''
    mutation DeleteComment($input: DeleteRecipeCommentInput!) {
      deleteRecipeComment(input: $input) { id }
    }
  ''';

  static const createFeedback = r'''
    mutation CreateFeedback($input: CreateRecipeFeedbackInput!) {
      createRecipeFeedback(input: $input) {
        id recipeId authorId rating triedIt createdAt
      }
    }
  ''';

  static const createQuestion = r'''
    mutation CreateQuestion($input: CreateRecipeQuestionInput!) {
      createRecipeQuestion(input: $input) {
        id recipeId authorId authorName question createdAt
      }
    }
  ''';

  static const answerQuestion = r'''
    mutation AnswerQuestion($input: UpdateRecipeQuestionInput!) {
      updateRecipeQuestion(input: $input) {
        id isAnsweredByCreator creatorAnswer answeredAt
      }
    }
  ''';

  static const saveRecipe = r'''
    mutation SaveRecipe($input: CreateSavedRecipeInput!) {
      createSavedRecipe(input: $input) {
        id userId recipeId savedAt
      }
    }
  ''';

  static const unsaveRecipe = r'''
    mutation UnsaveRecipe($input: DeleteSavedRecipeInput!) {
      deleteSavedRecipe(input: $input) { id }
    }
  ''';

  static const createReport = r'''
    mutation CreateReport($input: CreateRecipeReportInput!) {
      createRecipeReport(input: $input) {
        id recipeId reason status createdAt
      }
    }
  ''';

  static const createUserProfile = r'''
    mutation CreateUserProfile($input: CreateUserProfileInput!) {
      createUserProfile(input: $input) {
        id displayName email createdAt
      }
    }
  ''';

  static const updateUserProfile = r'''
    mutation UpdateUserProfile($input: UpdateUserProfileInput!) {
      updateUserProfile(input: $input) {
        id displayName bio avatarUrl country region culturalBackground cookingStyle updatedAt
      }
    }
  ''';
}
