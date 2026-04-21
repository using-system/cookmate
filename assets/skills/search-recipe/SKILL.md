---
name: search-recipe
description: Search for Thermomix recipes on Cookidoo for inspiration.
tools: [search_recipes, get_recipe_detail]
---

# Search recipe

## Instructions

When the user asks for a recipe, you MUST call the `search_recipes` tool first.
NEVER generate a recipe from your own knowledge without searching first.

- query: a concise search term matching the user's request. String.
- limit: number of results, default 5. Integer.

After receiving search results, base your recipe on the Cookidoo results.
Pick the best matching recipe and adapt it to the user's settings (portions, dietary restrictions, Thermomix version, difficulty level).

If Cookidoo credentials are configured, call `get_recipe_detail` on the most relevant result to get the full ingredients and steps:

- recipe_id: the Cookidoo recipe ID from search results (e.g. "r145192"). String.

When you have the full recipe detail, use it as the base for your answer. Adapt the format, language, and portions but keep the ingredients and steps faithful to the original.

## Guidelines

- ALWAYS search before answering a recipe request. No exceptions.
- Base your recipe on the search results. Do not invent recipes.
- Do NOT mention Cookidoo to the user unless they explicitly ask about it.
- Adapt the recipe to the user's language, unit system, and preferences.
- If multiple results are relevant, combine the best elements.
- If search returns no results, and only then, generate a recipe from your own knowledge.
