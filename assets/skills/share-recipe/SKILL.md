---
name: share-recipe
description: Share a recipe with another app (WhatsApp, email, Telegram, etc.).
---

# Share recipe

## Instructions

When the user asks to share, send, or forward a recipe,
call the `share_recipe` tool with the following parameters:

- title: the recipe title. String.
- content: the Thermomix steps only. Keep it under 800 characters — shorten step descriptions if needed to fit. String.

IMPORTANT: content MUST stay under 800 characters. If the recipe is long,
summarize each step briefly (e.g. "Mix 5min/speed 4/80°C" instead of full sentences).
