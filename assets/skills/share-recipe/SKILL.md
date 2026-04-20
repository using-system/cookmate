---
name: share-recipe
description: Share a recipe with another app (WhatsApp, email, Telegram, etc.).
intent: share
parameters:
  - name: title
    type: string
    description: The recipe title.
  - name: content
    type: string
    description: The full formatted recipe text.
---

# Share recipe

## Instructions

When the user asks to share, send, or forward a recipe,
call the `run_intent` tool with the following exact parameters:

- intent: share
- parameters: A JSON string with the following fields:
  - title: the recipe title. String.
  - content: the full formatted recipe text, including ingredients and steps. String.

Always format the recipe clearly before sharing: title, ingredients list,
and numbered Thermomix steps with temperature, speed and duration.
