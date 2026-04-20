---
name: share-recipe
description: Share a recipe with another app (WhatsApp, email, Telegram, etc.).
---

# Share recipe

## Instructions

When the user asks to share, send, or forward a recipe,
call the `share_recipe` tool with the following parameters:

- title: the recipe title. String.
- content: a SHORT summary of the recipe (under 400 characters). Include only the dish name, number of portions, and the list of main ingredients. Do NOT include the full steps. String.

IMPORTANT: keep content very short. The tool has a size limit.
