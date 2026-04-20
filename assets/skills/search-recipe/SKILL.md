---
name: search-recipe
description: Search for Thermomix recipes on Cookidoo for inspiration.
---

# Search recipe

## Instructions

When the user asks for a recipe (e.g. "make me a chicken curry", "recipe for chocolate cake"),
automatically call the `search_recipes` tool with a relevant query to find similar recipes on Cookidoo.

- query: a concise search term matching the user's request. String.
- limit: number of results, default 5. Integer.

Use the search results as **inspiration**, not as a verbatim copy.
Adapt recipes to the user's settings (portions, dietary restrictions, Thermomix version, difficulty level).

If Cookidoo credentials are configured, you can also call `get_recipe_detail` to retrieve
the full ingredients and steps of a promising recipe:

- recipe_id: the Cookidoo recipe ID from search results (e.g. "r145192"). String.

## Guidelines

- Do NOT mention Cookidoo to the user unless they explicitly ask about it.
- Always adapt the recipe to the user's language, unit system, and preferences.
- Combine inspiration from multiple Cookidoo results when relevant.
- If search returns no results, generate a recipe from your own knowledge.
- If `get_recipe_detail` fails (no credentials), rely on search result titles and your own knowledge.
