(function (root) {
    'use strict';

    const LOCALE_INDEX = { koKR: 1, frFR: 2, deDE: 3, zhCN: 4, zhTW: 5, esES: 6, esMX: 7, ruRU: 8 };
    const NAME_TABLES = {
        item_template: { localeTable: 'locales_item', size: 100 },
        creature_template: { localeTable: 'locales_creature', size: 100 },
    };
    const FIRST_OWN_ENTRY = 900000;

    const CRC_TABLE = (function () {
        const table = new Uint32Array(256);
        for (let n = 0; n < 256; n++) {
            let c = n;
            for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
            table[n] = c >>> 0;
        }
        return table;
    })();

    function utf8(text) {
        return new TextEncoder().encode(text);
    }

    function crc32(text) {
        let crc = 0xFFFFFFFF;
        for (const byte of utf8(text)) crc = CRC_TABLE[(crc ^ byte) & 0xFF] ^ (crc >>> 8);
        return (crc ^ 0xFFFFFFFF) >>> 0;
    }

    function unescapeC(body) {
        return body.replace(/\\(x[0-9a-fA-F]{1,2}|[0-7]{1,3}|.)/g, (all, code) => {
            if (code[0] === 'x') return String.fromCharCode(parseInt(code.slice(1), 16));
            if (/^[0-7]/.test(code)) return String.fromCharCode(parseInt(code, 8));
            return { n: '\n', t: '\t', r: '\r', '0': '\0' }[code] ?? code;
        });
    }

    function unescapeLua(body) {
        return body.replace(/\\(\d{1,3}|.)/g, (all, code) => {
            if (/^\d/.test(code)) return String.fromCharCode(parseInt(code, 10));
            return { n: '\n', t: '\t', r: '\r', a: '\x07', b: '\b', f: '\f', v: '\v' }[code] ?? code;
        });
    }

    function escapeLua(text) {
        return text.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\r/g, '\\r').replace(/\t/g, '\\t');
    }

    function readStrings(headerText, sourceText) {
        const ids = new Map();
        for (const m of headerText.matchAll(/^\s*(BONK_STRING_\w+)\s*=\s*(\d+)\s*,/gm)) ids.set(m[1], Number(m[2]));
        const strings = [];
        for (const m of sourceText.matchAll(/\{\s*(BONK_STRING_\w+)\s*,\s*((?:"(?:[^"\\]|\\.)*"\s*)+)\}/g)) {
            const english = [...m[2].matchAll(/"((?:[^"\\]|\\.)*)"/g)].map(part => unescapeC(part[1])).join('');
            if (ids.has(m[1])) strings.push({ id: ids.get(m[1]), name: m[1], english });
        }
        return strings.sort((a, b) => a.id - b.id);
    }

    function firstArgument(text, start) {
        let depth = 0;
        let quote = null;
        for (let i = start; i < text.length; i++) {
            const c = text[i];
            if (quote) {
                if (c === '\\') i++;
                else if (c === quote) quote = null;
                continue;
            }
            if (c === '"' || c === "'") quote = c;
            else if (c === '(' || c === '{' || c === '[') depth++;
            else if (c === ')' || c === '}' || c === ']') {
                if (depth === 0) return text.slice(start, i);
                depth--;
            } else if (c === ',' && depth === 0) return text.slice(start, i);
        }
        return text.slice(start);
    }

    function collectAddonKeys(files) {
        const keys = new Map();
        const add = (key, file, text, index) => {
            const line = text.slice(0, index).split('\n').length;
            if (!keys.has(key)) keys.set(key, { english: unescapeLua(key), where: [] });
            const where = keys.get(key).where;
            if (where.length < 5) where.push(`${file}:${line}`);
        };
        for (const file of Object.keys(files).sort()) {
            if (/^VanillaBonkLocale[A-Z][a-z][A-Z]{2}\.lua$/.test(file)) continue;
            const text = files[file];
            for (const m of text.matchAll(/L\["((?:[^"\\]|\\.)*)"\]/g)) add(m[1], file, text, m.index);
            for (const m of text.matchAll(/VanillaBonkLocale\.Text\(\s*[A-Za-z_.]+,\s*"((?:[^"\\]|\\.)*)"\)/g)) add(m[1], file, text, m.index);
            for (const m of text.matchAll(/(?<![A-Za-z0-9_.:])(?:VanillaBonk)?L\(/g)) {
                const arg = firstArgument(text, m.index + m[0].length);
                for (const s of arg.matchAll(/"((?:[^"\\]|\\.)*)"/g)) {
                    if (/(==|~=)\s*$/.test(arg.slice(0, s.index))) continue;
                    add(s[1], file, text, m.index + m[0].length + s.index);
                }
            }
        }
        return keys;
    }

    function parseLocaleTable(text) {
        const entries = new Map();
        const locale = (text.match(/VanillaBonkLocale\.Register\(\s*"(\w+)"/) || [])[1] || '';
        for (const m of text.matchAll(/^\s*\["((?:[^"\\]|\\.)*)"\]\s*=\s*"((?:[^"\\]|\\.)*)",?\s*$/gm)) entries.set(m[1], unescapeLua(m[2]));
        return { locale, entries };
    }

    function writeLocaleTable(locale, entries, eol) {
        const keys = [...entries.keys()].sort();
        const lines = keys.map(key => `    ["${key}"] = "${escapeLua(entries.get(key))}",`);
        return [`VanillaBonkLocale.Register("${locale}", {`, ...lines, '})', ''].join(eol || '\n');
    }

    function localeFile(locale) {
        return `VanillaBonkLocale${locale.charAt(0).toUpperCase()}${locale.slice(1)}.lua`;
    }

    function ensureTocLine(tocText, locale) {
        const file = localeFile(locale);
        const eol = tocText.includes('\r\n') ? '\r\n' : '\n';
        const lines = tocText.split(/\r?\n/);
        if (lines.includes(file)) return tocText;
        const at = lines.indexOf('VanillaBonkLocale.lua');
        if (at < 0) return tocText;
        lines.splice(at + 1, 0, file);
        return lines.join(eol);
    }

    function keyColumns(field) {
        return Object.keys(field).filter(k => !['table', 'column', 'english', 'translation', 'basis', 'status'].includes(k));
    }

    function fieldId(field) {
        return [field.table, field.column, ...keyColumns(field).map(k => `${k}=${field[k]}`)].join('|');
    }

    function parseServerJson(text) {
        const data = text && text.trim() ? JSON.parse(text) : {};
        return {
            locale: data.locale || '',
            strings: (data.strings || []).map(s => ({ id: s.id, english: s.english || '', translation: s.translation || '' })),
            fields: (data.fields || []).map(f => {
                const copy = {};
                for (const [k, v] of Object.entries(f)) if (k !== 'status' && k !== 'hash') copy[k] = v;
                copy.translation = copy.translation || '';
                return copy;
            }),
        };
    }

    function jsonLine(object, order) {
        const keys = order.filter(k => object[k] !== undefined && object[k] !== '' || k === 'translation' || k === 'english');
        for (const k of Object.keys(object)) if (!keys.includes(k) && object[k] !== undefined && object[k] !== '') keys.push(k);
        return '{ ' + keys.map(k => `${JSON.stringify(k)}: ${JSON.stringify(object[k] ?? '')}`).join(', ') + ' }';
    }

    function tableOrder(table) {
        if (table === 'item_template') return 2;
        if (table === 'creature_template') return 3;
        return 1;
    }

    function compareFields(a, b) {
        if (tableOrder(a.table) !== tableOrder(b.table)) return tableOrder(a.table) - tableOrder(b.table);
        if (a.table !== b.table) return a.table < b.table ? -1 : 1;
        const ka = keyColumns(a);
        for (const k of ka) if (a[k] !== b[k]) return Number(a[k]) - Number(b[k]);
        if (a.column !== b.column) return a.column < b.column ? -1 : 1;
        return 0;
    }

    function writeServerJson(server, eol) {
        const nl = eol || '\n';
        const strings = [...server.strings].sort((a, b) => a.id - b.id)
            .map(s => '    ' + jsonLine({ id: s.id, english: s.english, translation: s.translation }, ['id', 'english', 'translation']));
        const fields = [...server.fields].sort(compareFields).map(f => {
            const keys = keyColumns(f).filter(k => k !== 'basis');
            const record = { table: f.table, column: f.column };
            for (const k of keys) record[k] = f[k];
            record.english = f.english;
            record.translation = f.translation;
            if (f.basis) record.basis = f.basis;
            return '    ' + jsonLine(record, ['table', 'column', ...keys, 'english', 'translation', 'basis']);
        });
        return ['{', `  "locale": ${JSON.stringify(server.locale)},`, '  "strings": [', strings.join(',' + nl), '  ],', '  "fields": [', fields.join(',' + nl), '  ]', '}', ''].join(nl);
    }

    function readColumnSizes(migrationTexts) {
        const sizes = new Map();
        for (const text of migrationTexts) {
            for (const m of text.matchAll(/CREATE TABLE IF NOT EXISTS `(\w+_locale)` \(([\s\S]*?)\n\)/g)) {
                for (const c of m[2].matchAll(/`(\w+)`\s+(VARCHAR\((\d+)\)|TEXT)/g)) {
                    if (c[1] === 'locale') continue;
                    sizes.set(`${m[1]}.${c[1]}`, c[3] ? Number(c[3]) : 65535);
                }
            }
        }
        for (const [table, info] of Object.entries(NAME_TABLES)) {
            sizes.set(`${info.localeTable}.name`, info.size);
            if (table === 'creature_template') sizes.set(`${info.localeTable}.subname`, info.size);
        }
        return sizes;
    }

    function localeColumns(sizes, table) {
        const prefix = `${table}_locale.`;
        return [...sizes.keys()].filter(k => k.startsWith(prefix)).map(k => k.slice(prefix.length));
    }

    function sectionOf(field) {
        return NAME_TABLES[field.table] ? 'names' : 'fields';
    }

    function columnSize(sizes, field) {
        if (NAME_TABLES[field.table]) return sizes.get(`${NAME_TABLES[field.table].localeTable}.${field.column}`) || 100;
        return sizes.get(`${field.table}_locale.${field.column}`);
    }

    function buildModel(input) {
        const server = input.server;
        const byId = new Map(server.strings.map(s => [s.id, s]));
        const stringEntries = input.strings.map(cur => {
            const saved = byId.get(cur.id);
            const record = saved || { id: cur.id, english: cur.english, translation: '' };
            if (!saved) server.strings.push(record);
            const basis = record.translation && record.english !== cur.english ? record.english : '';
            return {
                uid: `s${cur.id}`, section: 'strings', english: cur.english, translation: record.translation, basis,
                context: { id: cur.id, name: cur.name }, members: [record], current: cur.english,
            };
        });
        const current = new Set(input.strings.map(s => s.id));
        const staleStrings = server.strings.filter(s => !current.has(s.id));

        const groups = new Map();
        for (const field of server.fields) {
            const section = sectionOf(field);
            const groupKey = `${section}|${field.table}|${field.column}|${field.english}`;
            if (!groups.has(groupKey)) groups.set(groupKey, []);
            groups.get(groupKey).push(field);
        }
        const nameOf = new Map();
        for (const field of server.fields) if (field.column === 'name') nameOf.set(`${field.table}|${keyColumns(field).map(k => field[k]).join('|')}`, field.english);
        const fieldEntries = [...groups.entries()].map(([groupKey, members]) => {
            const first = members[0];
            const counts = new Map();
            for (const m of members) counts.set(m.translation, (counts.get(m.translation) || 0) + 1);
            const translation = [...counts.entries()].sort((a, b) => b[1] - a[1])[0][0];
            const keys = keyColumns(first);
            const label = keys.map(k => `${k} ${first[k]}`).join(', ');
            const owner = first.column !== 'name' ? nameOf.get(`${first.table}|${keys.map(k => first[k]).join('|')}`) : '';
            return {
                uid: `f${groupKey}`, section: sectionOf(first), english: first.english, translation,
                basis: members.find(m => m.basis)?.basis || '', differ: counts.size > 1,
                context: { table: first.table, column: first.column, label, count: members.length, owner }, members,
            };
        });

        const addonEntries = [];
        const usedKeys = new Set();
        for (const [key, info] of input.addonKeys) {
            usedKeys.add(key);
            addonEntries.push({
                uid: `a${key}`, section: 'addon', english: info.english, translation: input.localeTable.get(key) ?? '', basis: '',
                context: { key, where: info.where }, members: [], key,
            });
        }
        for (const [key, value] of input.localeTable) {
            if (usedKeys.has(key)) continue;
            addonEntries.push({
                uid: `a${key}`, section: 'addon', english: unescapeLua(key), translation: value, basis: '', unused: true,
                context: { key, where: [] }, members: [], key,
            });
        }
        const entries = [...stringEntries, ...fieldEntries, ...addonEntries];
        for (const entry of entries) entry.original = entry.translation;
        return { entries, staleStrings };
    }

    function applyTranslation(entry, translation) {
        entry.translation = translation;
        if (entry.section === 'strings') {
            const record = entry.members[0];
            record.translation = translation;
            if (translation) {
                record.english = entry.current;
                entry.basis = '';
            }
        } else if (entry.section !== 'addon') {
            for (const m of entry.members) {
                m.translation = translation;
                if (translation) delete m.basis;
            }
            if (translation) entry.basis = '';
            entry.differ = false;
        }
    }

    function keepTranslation(entry) {
        if (entry.section === 'strings') entry.members[0].english = entry.current;
        else for (const m of entry.members) delete m.basis;
        entry.basis = '';
    }

    function addonTable(entries) {
        const table = new Map();
        for (const e of entries) if (e.section === 'addon' && e.translation && !e.removed) table.set(e.key, e.translation);
        return table;
    }

    const placeholderList = s => [...new Set(s.match(/\{[\d.]+\}/g) || [])].sort();
    const formatList = s => s.match(/%(?:%|[-0-9.]*[a-zA-Z])/g) || [];
    const count = (s, re) => (s.match(re) || []).length;

    function checkEntry(entry, options) {
        const problems = [];
        const english = entry.english;
        const text = entry.translation;
        if (!text) return problems;
        const add = (level, message) => problems.push({ level, message });
        const ph = [placeholderList(english).join(' '), placeholderList(text).join(' ')];
        if (ph[0] !== ph[1]) add('error', `Placeholders differ: English has ${ph[0] || 'none'}, translation has ${ph[1] || 'none'}`);
        const fm = [formatList(english).join(' '), formatList(text).join(' ')];
        if (fm[0] !== fm[1]) add('error', `Format codes differ: English has ${fm[0] || 'none'}, translation has ${fm[1] || 'none'} (keep them in the same order)`);
        if (count(english, /\|c[0-9a-fA-F]{8}/g) !== count(text, /\|c[0-9a-fA-F]{8}/g) || count(english, /\|r/g) !== count(text, /\|r/g)) add('error', 'Colour codes (|cffxxxxxx … |r) differ from the English');
        if (count(english, /\n|\|n/g) !== count(text, /\n|\|n/g)) add('error', 'Line breaks differ from the English');
        if (count(english, /\^/g) !== count(text, /\^/g)) add('error', 'The ^ separators differ from the English');
        if (entry.section !== 'addon' && text.includes('~') && !english.includes('~')) add('error', 'The ~ character separates addon message fields; it cannot appear in server text');
        if (options && options.sizes && entry.section !== 'strings' && entry.section !== 'addon') {
            const size = columnSize(options.sizes, entry.context);
            if (size && [...text].length > size) add('error', `${[...text].length} characters, the column holds ${size}`);
        }
        if (options && options.glossary && entry.section !== 'names') {
            for (const term of options.glossary) {
                if (!term.en || !term.zh || term.check === false) continue;
                const re = term.re || glossaryPattern(term);
                let source = english;
                for (const phrase of term.except || []) source = source.split(phrase).join(' ');
                if (re.test(source) && !text.includes(term.zh)) add('warning', `Glossary: "${term.en}" is usually ${term.zh}`);
            }
        }
        return problems;
    }

    function glossaryPattern(term) {
        return new RegExp(`(^|[^A-Za-z])${term.en.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}(?![A-Za-z])`, term.anyCase ? 'i' : '');
    }

    function statusOf(entry) {
        if (entry.unused) return 'unused';
        if (!entry.translation) return 'missing';
        if (entry.basis) return 'outdated';
        return 'translated';
    }

    function mergeExport(server, exported) {
        const result = { added: 0, changed: 0, removed: 0 };
        const existing = new Map(server.fields.map(f => [fieldId(f), f]));
        const seen = new Set();
        const fields = [];
        for (const raw of exported.fields || []) {
            const incoming = {};
            for (const [k, v] of Object.entries(raw)) if (k !== 'status' && k !== 'hash') incoming[k] = v;
            const id = fieldId(incoming);
            seen.add(id);
            const old = existing.get(id);
            if (!old) {
                incoming.translation = incoming.translation || '';
                fields.push(incoming);
                result.added++;
            } else if (old.english !== incoming.english) {
                if (old.translation && !old.basis) old.basis = old.english;
                old.english = incoming.english;
                fields.push(old);
                result.changed++;
            } else {
                if (!old.translation && incoming.translation) old.translation = incoming.translation;
                fields.push(old);
            }
        }
        for (const id of existing.keys()) if (!seen.has(id)) result.removed++;
        server.fields = fields;
        return result;
    }

    function sqlString(text) {
        return "'" + text.replace(/\\/g, '\\\\').replace(/'/g, "''") + "'";
    }

    function buildSql(locale, model, sizes, include) {
        const lines = [];
        const loc = LOCALE_INDEX[locale];
        const done = entry => entry.translation && !entry.basis && (!include || include(entry));
        const strings = model.entries.filter(e => e.section === 'strings' && done(e));
        lines.push(`DELETE FROM \`bonk_string_locale\` WHERE \`locale\` = ${sqlString(locale)};`);
        for (let i = 0; i < strings.length; i += 200) {
            lines.push('INSERT INTO `bonk_string_locale` (`entry`, `locale`, `source_hash`, `content`) VALUES\n' +
                strings.slice(i, i + 200).map(e => `(${e.context.id}, ${sqlString(locale)}, ${crc32(e.current)}, ${sqlString(e.translation)})`).join(',\n') + ';');
        }
        const rows = new Map();
        const names = new Map();
        for (const entry of model.entries) {
            if (entry.section !== 'fields' && entry.section !== 'names') continue;
            if (include && !include(entry)) continue;
            for (const field of entry.members) {
                if (!field.translation || field.basis) continue;
                if (NAME_TABLES[field.table]) {
                    const id = `${field.table}|${field.entry}`;
                    if (!names.has(id)) names.set(id, { table: field.table, entry: field.entry, cols: {} });
                    names.get(id).cols[field.column] = field.translation;
                    continue;
                }
                const keys = keyColumns(field);
                const id = `${field.table}|${keys.map(k => field[k]).join('|')}`;
                if (!rows.has(id)) rows.set(id, { table: field.table, keys: keys.map(k => [k, field[k]]), cols: {} });
                rows.get(id).cols[field.column] = field.translation;
            }
        }
        const tables = [...new Set([...sizes.keys()].filter(k => /^bonk_\w+_locale\./.test(k) && !k.startsWith('bonk_string_locale.')).map(k => k.split('.')[0].replace(/_locale$/, '')))].sort();
        for (const table of tables) {
            const columns = localeColumns(sizes, table);
            lines.push(`DELETE FROM \`${table}_locale\` WHERE \`locale\` = ${sqlString(locale)};`);
            const tableRows = [...rows.values()].filter(r => r.table === table);
            if (!tableRows.length) continue;
            const keyNames = tableRows[0].keys.map(k => k[0]);
            const values = tableRows.map(r => `(${r.keys.map(k => Number(k[1])).join(', ')}, ${sqlString(locale)}, ${columns.map(c => sqlString(r.cols[c] || '')).join(', ')})`);
            for (let i = 0; i < values.length; i += 200) {
                lines.push(`INSERT INTO \`${table}_locale\` (${[...keyNames, 'locale', ...columns].map(c => '`' + c + '`').join(', ')}) VALUES\n` + values.slice(i, i + 200).join(',\n') + ';');
            }
        }
        if (loc) {
            for (const [table, info] of Object.entries(NAME_TABLES)) {
                const columns = table === 'creature_template' ? ['name', 'subname'] : ['name'];
                const cols = columns.map(c => `\`${c}_loc${loc}\``);
                lines.push(`UPDATE \`${info.localeTable}\` SET ${cols.map(c => `${c} = ''`).join(', ')} WHERE \`entry\` >= ${FIRST_OWN_ENTRY};`);
                const tableRows = [...names.values()].filter(r => r.table === table).sort((a, b) => a.entry - b.entry);
                for (let i = 0; i < tableRows.length; i += 300) {
                    lines.push(`INSERT INTO \`${info.localeTable}\` (\`entry\`, ${cols.join(', ')}) VALUES\n` +
                        tableRows.slice(i, i + 300).map(r => `(${Number(r.entry)}, ${columns.map(c => sqlString(r.cols[c] || '')).join(', ')})`).join(',\n') +
                        `\nON DUPLICATE KEY UPDATE ${cols.map(c => `${c} = VALUES(${c})`).join(', ')};`);
                }
            }
        }
        return lines.join('\n') + '\n';
    }

    function migrationId(date, after) {
        const d = date || new Date();
        const p = n => String(n).padStart(2, '0');
        const now = `${d.getUTCFullYear()}${p(d.getUTCMonth() + 1)}${p(d.getUTCDate())}${p(d.getUTCHours())}${p(d.getUTCMinutes())}${p(d.getUTCSeconds())}`;
        return after && after >= now ? String(Number(after) + 1) : now;
    }

    function wrapMigration(id, body) {
        return [
            'DROP PROCEDURE IF EXISTS add_migration;',
            'DELIMITER ??',
            'CREATE PROCEDURE `add_migration`()',
            'BEGIN',
            'DECLARE v INT DEFAULT 1;',
            `SET v = (SELECT COUNT(*) FROM \`migrations\` WHERE \`id\`='${id}');`,
            'IF v = 0 THEN',
            `INSERT INTO \`migrations\` VALUES ('${id}');`,
            '',
            body.trim(),
            '',
            'END IF;',
            'END??',
            'DELIMITER ;',
            'CALL add_migration();',
            'DROP PROCEDURE IF EXISTS add_migration;',
            '',
        ].join('\n');
    }

    function similarity(a, b) {
        if (a === b) return 1;
        const x = a.toLowerCase();
        const y = b.toLowerCase();
        if (Math.abs(x.length - y.length) > Math.max(x.length, y.length) / 2) return 0;
        let prev = Array.from({ length: y.length + 1 }, (_, i) => i);
        for (let i = 1; i <= x.length; i++) {
            const row = [i];
            for (let j = 1; j <= y.length; j++) row[j] = Math.min(prev[j] + 1, row[j - 1] + 1, prev[j - 1] + (x[i - 1] === y[j - 1] ? 0 : 1));
            prev = row;
        }
        return 1 - prev[y.length] / Math.max(x.length, y.length, 1);
    }

    function buildMemory(entries) {
        const memory = new Map();
        for (const e of entries) {
            if (!e.translation || e.basis) continue;
            if (!memory.has(e.english)) memory.set(e.english, new Map());
            const uses = memory.get(e.english);
            uses.set(e.translation, (uses.get(e.translation) || 0) + 1);
        }
        return memory;
    }

    function suggestions(entry, entries, memory) {
        const out = [];
        const exact = memory.get(entry.english);
        if (exact) for (const [text] of [...exact.entries()].sort((a, b) => b[1] - a[1])) if (text !== entry.translation) out.push({ text, why: 'same English elsewhere' });
        if (entry.basis && entry.translation) out.push({ text: entry.translation, why: 'translation of the old English', old: entry.basis });
        if (!entry.translation && entry.section === 'addon' && out.length === 0) {
            let best = null;
            for (const other of entries) {
                if (!other.unused || !other.translation) continue;
                const score = similarity(entry.english, other.english);
                if (score >= 0.6 && (!best || score > best.score)) best = { score, other };
            }
            if (best) out.push({ text: best.other.translation, why: 'unused translation of similar text', old: best.other.english });
        }
        return out.slice(0, 3);
    }

    function wordDiff(before, after) {
        const a = before.split(/(\s+)/);
        const b = after.split(/(\s+)/);
        const dp = Array.from({ length: a.length + 1 }, () => new Array(b.length + 1).fill(0));
        for (let i = a.length - 1; i >= 0; i--) for (let j = b.length - 1; j >= 0; j--) dp[i][j] = a[i] === b[j] ? dp[i + 1][j + 1] + 1 : Math.max(dp[i + 1][j], dp[i][j + 1]);
        const parts = [];
        let i = 0;
        let j = 0;
        while (i < a.length && j < b.length) {
            if (a[i] === b[j]) { parts.push({ kind: 'same', text: a[i] }); i++; j++; }
            else if (dp[i + 1][j] >= dp[i][j + 1]) { parts.push({ kind: 'removed', text: a[i] }); i++; }
            else { parts.push({ kind: 'added', text: b[j] }); j++; }
        }
        while (i < a.length) parts.push({ kind: 'removed', text: a[i++] });
        while (j < b.length) parts.push({ kind: 'added', text: b[j++] });
        return parts;
    }

    const Logic = {
        LOCALE_INDEX, crc32, localeFile, unescapeC, unescapeLua, escapeLua, readStrings, collectAddonKeys, parseLocaleTable, writeLocaleTable,
        ensureTocLine, parseServerJson, writeServerJson, readColumnSizes, buildModel, applyTranslation, keepTranslation, addonTable,
        checkEntry, glossaryPattern, statusOf, mergeExport, buildSql, migrationId, wrapMigration, suggestions, buildMemory, wordDiff, fieldId, keyColumns,
    };
    if (typeof module !== 'undefined' && module.exports) module.exports = Logic;
    else root.TranslateLogic = Logic;
})(typeof self !== 'undefined' ? self : this);
