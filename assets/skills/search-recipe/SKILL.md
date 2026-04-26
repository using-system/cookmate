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

After receiving search results, pick the best matching recipe and call `get_recipe_detail` to get the full ingredients and steps:

- recipe_id: the Cookidoo recipe ID of the best match. String.

When you have the full recipe detail, present it as-is. Do NOT adapt, rewrite, or modify the recipe.

## Guidelines

- ALWAYS search before answering a recipe request. No exceptions.
- ALWAYS call `get_recipe_detail` after searching to get the full recipe.
- Present the recipe exactly as returned. Do NOT modify ingredients, quantities, steps, times, or temperatures.
- Do NOT mention Cookidoo to the user unless they explicitly ask about it.
- If `get_recipe_detail` returns an error, present the recipe overview from the search results as-is.
- If search returns no results, and only then, generate a recipe from your own knowledge.
