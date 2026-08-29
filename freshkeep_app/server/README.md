# FreshKeep recipe service

This small Node.js service keeps the OpenAI API key outside the Flutter app. It
uses structured output to create recipes from the live fridge inventory and can
use OpenAI web search to discover source recipes. Web-derived source URLs are
verified against the tool results before being returned to the app. It requires
Node.js 18 or newer and has no package dependencies.

## Local development

```powershell
$env:OPENAI_API_KEY='your-server-side-key'
$env:OPENAI_MODEL='gpt-5'
node server/recipe_suggestions_server.mjs
```

In a debug build, FreshKeep automatically connects to
`http://10.0.2.2:8787/recipe-suggestions` on the Android emulator and
`http://127.0.0.1:8787/recipe-suggestions` on desktop, web, and the iOS
simulator. Once the server is running, start FreshKeep normally:

```powershell
flutter run
```

For a deployed server or release build, supply its HTTPS URL with
`--dart-define=FRESHKEEP_RECIPE_API_URL=https://example.com/recipe-suggestions`.
Production deployments should set `ALLOWED_ORIGIN`, add user authentication at
the gateway, and store `OPENAI_API_KEY` in the hosting platform's secret manager.
Never pass the OpenAI key through `--dart-define`.
