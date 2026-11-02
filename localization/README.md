# Translations

Each language has a folder here named after its locale (`zhCN`, `deDE`, ...):

- `server.json`: translations of the server's text: the string table in
  `server/core/src/game/Bonk/BonkStrings.cpp`, the text in the Bonk database
  tables, and the names of this game's own items and creatures.
- `glossary.json`: agreed terms. The translation tool warns when the English
  has a term and the translation lacks its agreed form.

The addon's translations live with the addon, in
`Interface/AddOns/HordesOfAzeroth/VanillaBonkLocale<Locale>.lua`, for example
`VanillaBonkLocaleZhCN.lua`. The character screen and the co-op lobby, which
run before the addon loads, have a table of their own in
`Interface/GlueXML/BonkGlueLocale<Locale>.lua`. The tool lists both under
**Addon and glue**; a text used in both places is translated once and written
to both files.

## Translating

```
pwsh tools/translate.ps1 -Locale zhCN
```

This opens the translation tool in the browser. It lists every text with its
English beside it, the translation to edit, the state of each one (missing,
English changed, has problems, translated) and checks for placeholders like
`{1}` and `%s`, colour codes, line breaks, column sizes and the glossary.
**Save** (Ctrl+S) writes `server.json`, the addon file, the glue file and, for
a new language, their lines in the two `.toc` files.

A few addon texts start with a note that ends in `::`, as in
`armor slot::Chest`. The note tells apart texts that are the same in English
but not in every language. Translate only the text after `::`; English shows
it without the note.

To see the translations in game, start the tool with the database client of
the install you play on and use **Apply to database**:

```
pwsh tools/translate.ps1 -Locale zhCN -MariaDb "<install>\server\mariadb\bin\mariadb.exe"
```

Then type `.bonk reload` in game for server and database text. Item and
creature names need a server restart, and the client keeps the names it has
seen in `benilla-config/cache`.

## When the English changes

- Server text and addon text are read from the sources each time the tool
  starts. A translation whose English changed is marked **English changed**
  and shows what changed; edit it, or press **Keep translation** when it
  still fits.
- Database text and names come from the server. Run
  `.bonk strings export <locale>` on a server with the current world
  database, then **Import server export** in the tool. It adds new rows,
  marks rows whose English changed and drops rows that are gone.

## Shipping

**Write migration** saves, then writes a migration into
`server/core/sql/migrations` that replaces every translation of the language
with the finished ones from the tool. Translations with problems and those
whose English changed are left out, so the game shows English for them.
Commit the migration in the server repository and `server.json` and the addon
file in this one.
