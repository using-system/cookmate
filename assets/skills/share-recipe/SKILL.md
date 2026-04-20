---
name: share-recipe
description: Share a recipe with another app (WhatsApp, email, Telegram, etc.).
---

# Share recipe

## Instructions

When the user asks to share, send, or forward a recipe,
call the `share_recipe` tool with the following parameters:

- title: the recipe title. String.
- content: the full formatted recipe text, including ingredients and steps. String.

Always format the recipe clearly before sharing: title, ingredients list,
and numbered Thermomix steps with temperature, speed and duration.
