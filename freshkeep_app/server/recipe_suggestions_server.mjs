import { createServer } from 'node:http';

const port = Number.parseInt(process.env.PORT ?? '8787', 10);
const model = process.env.OPENAI_MODEL ?? 'gpt-5';
const allowedOrigin = process.env.ALLOWED_ORIGIN ?? '*';
const apiKey = process.env.OPENAI_API_KEY;
const aiTimeoutMs = Number.parseInt(
  process.env.FRESHKEEP_AI_TIMEOUT_MS ?? '90000',
  10,
);
const enableWebSearch = /^(1|true|yes)$/i.test(
  process.env.FRESHKEEP_ENABLE_WEB_SEARCH ?? 'false',
);
const rateWindows = new Map();
const organizationCache = new Map();

const recipeSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['recipes'],
  properties: {
    recipes: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: [
          'name',
          'description',
          'minutes',
          'calories',
          'servings',
          'origin',
          'sourceUrl',
          'tags',
          'ingredients',
          'steps',
        ],
        properties: {
          name: { type: 'string' },
          description: { type: 'string' },
          minutes: { type: 'integer' },
          calories: { type: 'integer' },
          servings: { type: 'integer' },
          origin: { type: 'string', enum: ['adapted', 'aiGenerated'] },
          sourceUrl: { type: 'string' },
          tags: { type: 'array', items: { type: 'string' } },
          ingredients: {
            type: 'array',
            items: {
              type: 'object',
              additionalProperties: false,
              required: ['name', 'quantity', 'source', 'inventoryItemId'],
              properties: {
                name: { type: 'string' },
                quantity: { type: 'string' },
                source: {
                  type: 'string',
                  enum: ['fridge', 'pantry', 'shopping'],
                },
                inventoryItemId: {
                  anyOf: [{ type: 'string' }, { type: 'null' }],
                },
              },
            },
          },
          steps: { type: 'array', items: { type: 'string' } },
        },
      },
    },
  },
};

const organizationSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['summary', 'assignments'],
  properties: {
    summary: { type: 'string' },
    assignments: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['itemId', 'itemName', 'zone', 'reason', 'size'],
        properties: {
          itemId: { type: 'string' },
          itemName: { type: 'string' },
          zone: {
            type: 'string',
            enum: [
              'topShelf',
              'middleShelf',
              'lowerShelf',
              'highHumidity',
              'lowHumidity',
              'door',
            ],
          },
          reason: { type: 'string' },
          size: { type: 'string', enum: ['small', 'medium', 'large'] },
        },
      },
    },
  },
};

const instructions = `
You are the recipe planner for FreshKeep. Return 4 varied, practical recipes.

Priorities, in order:
1. Obey avoided ingredients, vegetarian, fridge-only, time, must-use, and servings constraints.
2. Use safe, non-expired fridge ingredients, especially items expiring in 0 to 3 days.
3. ${enableWebSearch ? 'Search the web for established recipes when useful, or create an original recipe when no strong online match exists.' : 'Create original recipes directly from the supplied inventory. Do not search the web.'}
4. Minimize shopping ingredients, vary cuisines and meal types, and keep steps concise for a home cook.

Rules:
- A fridge ingredient must reference the exact inventory item ID supplied by the app.
- Never claim an ingredient is in the fridge unless it matches that inventory item.
- Pantry means an ordinary staple such as salt, pepper, cooking oil, or water.
- An inventory item marked outOfFridge is available as a pantry item, not a fridge item.
- Put every other required ingredient in shopping.
- Never include an avoided ingredient, including an obvious derivative.
- Mark vegetarian recipes with the tag "vegetarian".
- Calories are estimates per serving. Do not make medical or allergy-safety claims.
- ${enableWebSearch ? 'For a web-discovered recipe, rewrite and adapt the instructions rather than copying prose, use origin "adapted", and provide the exact source URL returned by web search.' : 'Use origin "aiGenerated" and an empty sourceUrl for every recipe.'}
- ${enableWebSearch ? 'For an original recipe, use origin "aiGenerated" and an empty sourceUrl.' : ''}
- Do not repeat the same recipe idea within a response. Use the request nonce to produce a fresh set on refresh.
`;

const server = createServer(async (request, response) => {
  setCorsHeaders(response);

  if (request.method === 'OPTIONS') {
    response.writeHead(204).end();
    return;
  }

  if (request.method === 'GET' && request.url === '/health') {
    sendJson(response, 200, {
      status: 'ok',
      modelConfigured: Boolean(model),
      apiKeyConfigured: Boolean(apiKey),
    });
    return;
  }

  if (request.method === 'POST' && request.url === '/fridge-organization') {
    await handleFridgeOrganization(request, response);
    return;
  }

  if (request.method !== 'POST' || request.url !== '/recipe-suggestions') {
    sendJson(response, 404, { error: 'Not found.' });
    return;
  }

  if (!withinRateLimit(request.socket.remoteAddress ?? 'unknown')) {
    sendJson(response, 429, { error: 'Too many requests. Try again shortly.' });
    return;
  }

  if (!apiKey) {
    sendJson(response, 503, {
      error: 'The recipe service is not configured.',
    });
    return;
  }

  try {
    const payload = await readJson(request);
    const validatedInput = validateInput(payload);
    const requestBody = {
      model,
      store: false,
      instructions,
      input: JSON.stringify(validatedInput),
      text: {
        format: {
          type: 'json_schema',
          name: 'freshkeep_recipe_suggestions',
          strict: true,
          schema: recipeSchema,
        },
      },
    };
    if (enableWebSearch) {
      Object.assign(requestBody, {
        tools: [{ type: 'web_search', search_context_size: 'low' }],
        tool_choice: 'auto',
        max_tool_calls: 2,
        include: ['web_search_call.action.sources'],
      });
    }
    const openAIResponse = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${apiKey}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify(requestBody),
      signal: AbortSignal.timeout(
        Number.isFinite(aiTimeoutMs) && aiTimeoutMs > 0 ? aiTimeoutMs : 90_000,
      ),
    });

    const result = await openAIResponse.json();
    if (!openAIResponse.ok) {
      const message = result?.error?.message ?? 'OpenAI request failed.';
      throw new Error(message);
    }

    const outputText = extractOutputText(result);
    const generated = JSON.parse(outputText);
    const webSources = enableWebSearch ? collectWebSources(result) : [];
    const recipes = validateRecipes(
      generated.recipes,
      validatedInput,
      webSources,
    );
    if (recipes.length === 0) {
      throw new Error('No generated recipe passed the safety filters.');
    }

    sendJson(response, 200, {
      recipes,
      generatedAt: new Date().toISOString(),
    });
  } catch (error) {
    const status = error instanceof RequestError ? error.status : 502;
    if (status >= 500) {
      const detail = error instanceof Error ? error.message : String(error);
      process.stderr.write(`FreshKeep recipe generation error: ${detail}\n`);
    }
    sendJson(response, status, {
      error: status < 500 ? error.message : 'Recipe generation failed.',
    });
  }
});

server.listen(port, '0.0.0.0', () => {
  process.stdout.write(`FreshKeep recipe service listening on port ${port}\n`);
});

const organizationInstructions = `
You are FreshKeep's refrigerator organization expert. Create a practical plan for the exact refrigerator model and inventory supplied.

Rules:
- Assign every supplied inventory item exactly once using its exact itemId and itemName.
- Only use these refrigerator zones: topShelf, middleShelf, lowerShelf, highHumidity, lowHumidity, door.
- Keep raw meat, poultry, seafood, and anything that could leak on lowerShelf.
- Put leafy greens and vegetables in highHumidity; most fruit in lowHumidity.
- Use door for condiments, beverages, and items that tolerate temperature changes.
- Use topShelf for ready-to-eat foods and leftovers; use middleShelf for dairy, eggs, and everyday items.
- Consider package size and quantity: large or bulky items belong on lowerShelf or a wide drawer when possible.
- Put food expiring soon where it is visible and easy to reach, while preserving food safety.
- Explain the main reason for each placement in one short sentence. Mark size as small, medium, or large.
`;

async function handleFridgeOrganization(request, response) {
  if (!withinRateLimit(request.socket.remoteAddress ?? 'unknown')) {
    sendJson(response, 429, { error: 'Too many requests. Try again shortly.' });
    return;
  }
  if (!apiKey) {
    sendJson(response, 503, { error: 'The AI service is not configured.' });
    return;
  }
  try {
    const input = validateOrganizationInput(await readJson(request));
    const cacheKey = JSON.stringify(input);
    const cached = organizationCache.get(cacheKey);
    if (cached) {
      sendJson(response, 200, cached);
      return;
    }
    const openAIResponse = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${apiKey}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model,
        store: false,
        instructions: organizationInstructions,
        input: JSON.stringify(input),
        text: {
          format: {
            type: 'json_schema',
            name: 'freshkeep_fridge_organization',
            strict: true,
            schema: organizationSchema,
          },
        },
      }),
      signal: AbortSignal.timeout(
        Number.isFinite(aiTimeoutMs) && aiTimeoutMs > 0 ? aiTimeoutMs : 90_000,
      ),
    });
    const result = await openAIResponse.json();
    if (!openAIResponse.ok) {
      throw new Error(result?.error?.message ?? 'OpenAI request failed.');
    }
    const generated = JSON.parse(extractOutputText(result));
    const assignments = validateOrganizationAssignments(generated, input);
    const responsePayload = {
      summary: String(generated.summary ?? 'Organization plan created.').slice(0, 320),
      assignments,
      generatedAt: new Date().toISOString(),
    };
    organizationCache.set(cacheKey, responsePayload);
    if (organizationCache.size > 20) {
      organizationCache.delete(organizationCache.keys().next().value);
    }
    sendJson(response, 200, responsePayload);
  } catch (error) {
    const status = error instanceof RequestError ? error.status : 502;
    if (status >= 500) {
      const detail = error instanceof Error ? error.message : String(error);
      process.stderr.write(`FreshKeep organization error: ${detail}\n`);
    }
    sendJson(response, status, {
      error: status < 500 ? error.message : 'Fridge organization failed.',
    });
  }
}

function validateOrganizationInput(payload) {
  if (!payload || !payload.refrigerator || !Array.isArray(payload.items)) {
    throw new RequestError(400, 'Refrigerator and items are required.');
  }
  const items = payload.items
    .filter((item) => item && typeof item.id === 'string' && typeof item.name === 'string')
    .slice(0, 100)
    .map((item) => ({
      id: item.id.slice(0, 128),
      name: item.name.slice(0, 120),
      quantity: String(item.quantity ?? '').slice(0, 80),
      category: String(item.category ?? '').slice(0, 40),
      storageLocation: item.storageLocation === 'outOfFridge' ? 'outOfFridge' : 'fridge',
      currentZone: String(item.currentZone ?? '').slice(0, 40),
      expirationDate: String(item.expirationDate ?? '').slice(0, 40),
    }));
  if (items.length === 0) throw new RequestError(400, 'At least one item is required.');
  return {
    refrigerator: {
      id: String(payload.refrigerator.id ?? '').slice(0, 120),
      displayName: String(payload.refrigerator.displayName ?? '').slice(0, 200),
      layout: String(payload.refrigerator.layout ?? '').slice(0, 40),
      shelves: Number(payload.refrigerator.shelves ?? 0),
      crisperDrawers: Number(payload.refrigerator.crisperDrawers ?? 0),
      doorBins: Number(payload.refrigerator.doorBins ?? 0),
      freezerLevels: Number(payload.refrigerator.freezerLevels ?? 0),
    },
    items,
  };
}

function validateOrganizationAssignments(generated, input) {
  const itemMap = new Map(input.items.map((item) => [item.id, item]));
  const seen = new Set();
  const assignments = [];
  for (const assignment of generated?.assignments ?? []) {
    if (!assignment || !itemMap.has(assignment.itemId) || seen.has(assignment.itemId)) continue;
    seen.add(assignment.itemId);
    assignments.push({
      itemId: assignment.itemId,
      itemName: itemMap.get(assignment.itemId).name,
      zone: assignment.zone,
      reason: String(assignment.reason ?? 'Recommended for freshness and access.').slice(0, 240),
      size: ['small', 'medium', 'large'].includes(assignment.size) ? assignment.size : 'medium',
    });
  }
  for (const item of input.items) {
    if (seen.has(item.id)) continue;
    assignments.push({
      itemId: item.id,
      itemName: item.name,
      zone: fallbackZone(item.category),
      reason: 'Placed using FreshKeep food-safety defaults.',
      size: 'medium',
    });
  }
  return assignments;
}

function fallbackZone(category) {
  if (category === 'produce') return 'highHumidity';
  if (category === 'protein') return 'lowerShelf';
  if (category === 'dairy') return 'middleShelf';
  if (category === 'beverage') return 'door';
  return 'topShelf';
}

function validateInput(payload) {
  if (!payload || !Array.isArray(payload.items) || !payload.filters) {
    throw new RequestError(400, 'Items and filters are required.');
  }

  const items = payload.items
    .filter(
      (item) =>
        item &&
        typeof item.id === 'string' &&
        typeof item.name === 'string' &&
        Number.isInteger(item.daysUntilExpiration) &&
        item.daysUntilExpiration >= 0,
    )
    .slice(0, 100)
    .map((item) => ({
      id: item.id.slice(0, 128),
      name: item.name.slice(0, 120),
      quantity: String(item.quantity ?? '').slice(0, 80),
      category: String(item.category ?? '').slice(0, 40),
      expirationDate: String(item.expirationDate ?? '').slice(0, 40),
      daysUntilExpiration: item.daysUntilExpiration,
    }));

  if (items.length === 0) {
    throw new RequestError(400, 'At least one non-expired item is required.');
  }

  const inputIds = new Set(items.map((item) => item.id));
  const rawFilters = payload.filters;
  const filters = {
    prioritizeExpiring: rawFilters.prioritizeExpiring !== false,
    fridgeOnly: rawFilters.fridgeOnly === true,
    underThirtyMinutes: rawFilters.underThirtyMinutes === true,
    vegetarian: rawFilters.vegetarian === true,
    mustUseItemIds: Array.isArray(rawFilters.mustUseItemIds)
      ? rawFilters.mustUseItemIds.filter((id) => inputIds.has(id)).slice(0, 20)
      : [],
    avoidedIngredients: Array.isArray(rawFilters.avoidedIngredients)
      ? rawFilters.avoidedIngredients
          .map((value) => String(value).trim().toLowerCase().slice(0, 80))
          .filter(Boolean)
          .slice(0, 30)
      : [],
    servings: [1, 2, 4, 6].includes(rawFilters.servings)
      ? rawFilters.servings
      : 2,
  };

  const requestNonce = String(payload.requestNonce ?? Date.now()).slice(0, 40);
  return { items, filters, requestNonce };
}

function validateRecipes(recipes, input, webSources) {
  if (!Array.isArray(recipes)) return [];
  const itemMap = new Map(input.items.map((item) => [item.id, item]));

  return recipes
    .slice(0, 8)
    .map((recipe, index) =>
      reconcileRecipe(recipe, itemMap, index, webSources),
    )
    .filter((recipe) => recipe !== null)
    .filter((recipe) => passesFilters(recipe, input.filters));
}

function reconcileRecipe(recipe, itemMap, index, webSources) {
  if (
    !recipe ||
    typeof recipe.name !== 'string' ||
    !Array.isArray(recipe.ingredients) ||
    !Array.isArray(recipe.steps) ||
    recipe.ingredients.length === 0 ||
    recipe.steps.length === 0
  ) {
    return null;
  }

  const items = [...itemMap.values()];
  const ingredients = recipe.ingredients.map((ingredient) => {
    let match = itemMap.get(ingredient.inventoryItemId);
    if (!match || !ingredientsMatch(ingredient.name, match.name)) {
      match = items.find((item) => ingredientsMatch(ingredient.name, item.name));
    }

    if (match) {
      return {
        name: String(ingredient.name).slice(0, 120),
        quantity: String(ingredient.quantity ?? '').slice(0, 80),
        source: match.storageLocation === 'fridge' ? 'fridge' : 'pantry',
        inventoryItemId: match.id,
      };
    }

    return {
      name: String(ingredient.name).slice(0, 120),
      quantity: String(ingredient.quantity ?? '').slice(0, 80),
      source: ingredient.source === 'pantry' ? 'pantry' : 'shopping',
      inventoryItemId: null,
    };
  });

  const verifiedSource = verifiedSourceUrl(recipe.sourceUrl, webSources);
  return {
    id: `ai-${Date.now()}-${index}`,
    name: recipe.name.slice(0, 120),
    description: String(recipe.description ?? '').slice(0, 320),
    minutes: clampInteger(recipe.minutes, 1, 720),
    calories: clampInteger(recipe.calories, 0, 5000),
    servings: clampInteger(recipe.servings, 1, 20),
    origin: verifiedSource ? 'adapted' : 'aiGenerated',
    sourceUrl: verifiedSource,
    imageUrl: '',
    tags: Array.isArray(recipe.tags)
      ? recipe.tags.map((tag) => String(tag).toLowerCase().slice(0, 40))
      : [],
    ingredients,
    steps: recipe.steps.slice(0, 20).map((step) => String(step).slice(0, 500)),
    caloriesAreEstimated: true,
  };
}

function passesFilters(recipe, filters) {
  if (filters.underThirtyMinutes && recipe.minutes > 30) return false;
  if (filters.vegetarian && !isVegetarian(recipe)) return false;
  if (
    filters.fridgeOnly &&
    recipe.ingredients.some(
      (ingredient) =>
        ingredient.source === 'shopping' ||
        (ingredient.inventoryItemId && ingredient.source !== 'fridge'),
    )
  ) {
    return false;
  }

  const usedIds = new Set(
    recipe.ingredients.map((ingredient) => ingredient.inventoryItemId).filter(Boolean),
  );
  if (!filters.mustUseItemIds.every((id) => usedIds.has(id))) return false;

  const searchable = normalize(
    `${recipe.name} ${recipe.ingredients.map((item) => item.name).join(' ')}`,
  );
  return !filters.avoidedIngredients.some((item) =>
    searchable.includes(normalize(item)),
  );
}

function isVegetarian(recipe) {
  if (!recipe.tags.includes('vegetarian')) return false;
  const searchable = normalize(
    `${recipe.name} ${recipe.ingredients.map((item) => item.name).join(' ')}`,
  );
  const nonVegetarianTerms = [
    'beef',
    'pork',
    'chicken',
    'turkey',
    'lamb',
    'salmon',
    'tuna',
    'fish',
    'shrimp',
    'prawn',
    'crab',
    'lobster',
    'bacon',
    'ham',
    'sausage',
    'gelatin',
  ];
  return !nonVegetarianTerms.some((term) =>
    new RegExp(`(^| )${term}( |$)`).test(searchable),
  );
}

function extractOutputText(result) {
  for (const output of result.output ?? []) {
    for (const content of output.content ?? []) {
      if (content.type === 'output_text' && typeof content.text === 'string') {
        return content.text;
      }
    }
  }
  throw new Error('OpenAI returned no structured recipe output.');
}

function collectWebSources(result) {
  const sources = new Map();
  const visit = (value) => {
    if (Array.isArray(value)) {
      value.forEach(visit);
      return;
    }
    if (!value || typeof value !== 'object') return;
    if (typeof value.url === 'string') {
      const key = sourceKey(value.url);
      if (key) sources.set(key, value.url);
    }
    Object.values(value).forEach(visit);
  };

  for (const output of result.output ?? []) {
    if (output.type === 'web_search_call') visit(output);
  }
  return sources;
}

function verifiedSourceUrl(requestedUrl, webSources) {
  const key = sourceKey(requestedUrl);
  return key ? String(webSources.get(key) ?? '').slice(0, 500) : '';
}

function sourceKey(value) {
  try {
    const url = new URL(String(value));
    if (!['http:', 'https:'].includes(url.protocol)) return '';
    return `${url.origin}${url.pathname.replace(/\/$/, '')}`;
  } catch {
    return '';
  }
}

function ingredientsMatch(left, right) {
  const a = normalize(left);
  const b = normalize(right);
  if (!a || !b) return false;
  if (a === b || a.includes(b) || b.includes(a)) return true;
  const aTokens = new Set(a.split(' '));
  return b.split(' ').some((token) => aTokens.has(token));
}

function normalize(value) {
  return String(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\b(baby|fresh|atlantic|large|small)\b/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

function clampInteger(value, minimum, maximum) {
  const parsed = Number.isFinite(value) ? Math.round(value) : minimum;
  return Math.min(maximum, Math.max(minimum, parsed));
}

function withinRateLimit(address) {
  const now = Date.now();
  const current = rateWindows.get(address);
  if (!current || current.resetAt <= now) {
    rateWindows.set(address, { count: 1, resetAt: now + 60_000 });
    return true;
  }
  current.count += 1;
  return current.count <= 20;
}

async function readJson(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > 128 * 1024) {
      throw new RequestError(413, 'Request is too large.');
    }
    chunks.push(chunk);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    throw new RequestError(400, 'Request body must be valid JSON.');
  }
}

function setCorsHeaders(response) {
  response.setHeader('access-control-allow-origin', allowedOrigin);
  response.setHeader('access-control-allow-methods', 'GET, POST, OPTIONS');
  response.setHeader('access-control-allow-headers', 'content-type, authorization');
  response.setHeader('vary', 'origin');
  response.setHeader('x-content-type-options', 'nosniff');
}

function sendJson(response, status, value) {
  response.writeHead(status, { 'content-type': 'application/json; charset=utf-8' });
  response.end(JSON.stringify(value));
}

class RequestError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}
