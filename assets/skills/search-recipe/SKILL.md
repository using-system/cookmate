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

When you have the full recipe detail, adapt it to the user's settings (portions, dietary restrictions, Thermomix version, difficulty level, unit system, language). Keep the ingredients, quantities, and steps faithful to the original — only adjust portions and units according to the user's preferences.

## Guidelines

- ALWAYS search before answering a recipe request. No exceptions.
- ALWAYS call `get_recipe_detail` after searching to get the full recipe.
- Base your recipe on the detail results. Do NOT invent ingredients or steps.
- Do NOT change cooking temperatures, Thermomix speeds, or cooking times.
- Do NOT add or remove ingredients unless the user's dietary restrictions require it.
- When adjusting portions, scale all quantities proportionally.
- Do NOT mention Cookidoo to the user unless they explicitly ask about it.
- If `get_recipe_detail` returns an error, present the recipe overview from the search results as-is.
- If search returns no results, and only then, generate a recipe from your own knowledge.
