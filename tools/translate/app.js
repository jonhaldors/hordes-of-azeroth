(function () {
    'use strict';

    const L = window.TranslateLogic;
    const token = location.hash.slice(1);
    const PAGE_SIZE = 40;
    const SECTION_LABELS = { strings: 'Server text', fields: 'Database text', names: 'Name', addon: 'Addon' };
    const STATUS_LABELS = { missing: 'Missing', outdated: 'English changed', problem: 'Problem', translated: 'Translated', unused: 'Unused' };
    const $ = id => document.getElementById(id);

    const state = {
        locale: '', info: null, server: null, strings: [], addonKeys: null, sizes: null, glossary: [], toc: '',
        eol: { server: '\n', addon: '\n' }, model: null, byUid: new Map(), problems: new Map(), filtered: [], page: 0,
        structural: false, focused: null, busy: false,
    };

    function escapeHtml(text) {
        return String(text).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    function renderText(text) {
        const all = String(text);
        const lead = all.match(/^ +/);
        const trail = all.length > (lead ? lead[0].length : 0) ? all.match(/ +$/) : null;
        const middle = all.slice(lead ? lead[0].length : 0, trail ? all.length - trail[0].length : all.length);
        const spaces = run => run ? `<span class="sp" title="${run[0].length === 1 ? 'a space' : run[0].length + ' spaces'}">${'␣'.repeat(run[0].length)}</span>` : '';
        return spaces(lead) + middle.split(/(\{[\d.]+\}|%(?:%|[-0-9.]*[a-zA-Z])|\|c[0-9a-fA-F]{8}|\|r|\|n|\n)/).map(part => {
            if (!part) return '';
            if (part === '\n' || part === '|n') return `<span class="nl">${part === '|n' ? '|n' : ''}↵</span>\n`;
            if (/^\{[\d.]+\}$|^%/.test(part)) return `<span class="ph">${escapeHtml(part)}</span>`;
            if (/^\|c[0-9a-fA-F]{8}$|^\|r$/.test(part)) return `<span class="code">${escapeHtml(part)}</span>`;
            return escapeHtml(part);
        }).join('') + spaces(trail);
    }

    async function api(path, options) {
        const opts = options || {};
        const headers = Object.assign({ 'X-Token': token }, opts.headers || {});
        return fetch(path, Object.assign({}, opts, { headers }));
    }

    async function getFile(name) {
        const response = await api(`/api/file?name=${encodeURIComponent(name)}`);
        return response.ok ? response.text() : '';
    }

    async function postFile(name, text) {
        const response = await api(`/api/file?name=${encodeURIComponent(name)}`, { method: 'POST', body: text, headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
        if (!response.ok) throw new Error(`Could not save ${name}: ${await response.text()}`);
        return response.json();
    }

    function toast(message) {
        const box = $('toast');
        box.textContent = message;
        box.classList.add('show');
        clearTimeout(toast.timer);
        toast.timer = setTimeout(() => box.classList.remove('show'), 3500);
    }

    function dialog(title, body, withCancel) {
        return new Promise(resolve => {
            const box = $('dialog');
            $('dialog-title').textContent = title;
            $('dialog-body').textContent = body;
            $('dialog-cancel').hidden = !withCancel;
            box.onclose = () => resolve(box.returnValue === 'ok');
            box.returnValue = '';
            box.showModal();
        });
    }

    function pickFile() {
        return new Promise(resolve => {
            const input = $('import-file');
            input.value = '';
            input.onchange = () => {
                const file = input.files[0];
                if (!file) return resolve('');
                file.text().then(resolve, () => resolve(''));
            };
            input.click();
        });
    }

    function problemsOf(entry) {
        if (!state.problems.has(entry.uid)) {
            const list = L.checkEntry(entry, { sizes: state.sizes, glossary: state.glossary });
            if (entry.differ) list.push({ level: 'warning', message: 'Rows with this English have different translations; editing sets all of them' });
            state.problems.set(entry.uid, list);
        }
        return state.problems.get(entry.uid);
    }

    const hasErrors = entry => problemsOf(entry).some(p => p.level === 'error');

    function statusOf(entry) {
        const status = L.statusOf(entry);
        if ((status === 'translated' || status === 'outdated') && hasErrors(entry)) return 'problem';
        return status;
    }

    const edited = entry => entry.translation !== entry.original || entry.removed;

    function haystack(entry) {
        if (!entry.haystack) {
            const c = entry.context;
            entry.haystack = [entry.english, c.name, c.id, c.table, c.column, c.label, c.owner, (c.where || []).join(' ')].filter(Boolean).join('\n').toLowerCase();
        }
        return entry.haystack + '\n' + entry.translation.toLowerCase();
    }

    function applyFilters() {
        const section = $('section').value;
        const status = $('status').value;
        const search = $('search').value.trim().toLowerCase();
        state.filtered = state.model.entries.filter(entry => {
            if (entry.removed) return false;
            if (section !== 'all' && entry.section !== section) return false;
            if (status === 'edited' && !edited(entry)) return false;
            if (status === 'problem' && !problemsOf(entry).length) return false;
            if (!['all', 'edited', 'problem'].includes(status) && statusOf(entry) !== status) return false;
            if (status === 'all' && entry.unused && section !== 'addon') return false;
            return !search || haystack(entry).includes(search);
        });
        state.page = Math.min(state.page, Math.max(0, Math.ceil(state.filtered.length / PAGE_SIZE) - 1));
    }

    function contextLabel(entry) {
        const c = entry.context;
        if (entry.section === 'strings') return `${c.name} · #${c.id}`;
        if (entry.section === 'addon') return c.where.length ? c.where.join(', ') : 'no longer used by the addon';
        return [`${c.table}.${c.column}`, c.label, c.count > 1 ? `×${c.count} rows` : '', c.owner].filter(Boolean).join(' · ');
    }

    function diffHtml(before, after) {
        return L.wordDiff(before, after).map(p => p.kind === 'same' ? escapeHtml(p.text) : `<span class="${p.kind}">${escapeHtml(p.text)}</span>`).join('');
    }

    function dynamicHtml(entry, memory) {
        const status = statusOf(entry);
        const problems = problemsOf(entry);
        const parts = { status, meta: '', changed: '', problems: '', suggest: '' };
        parts.meta = `<span class="status ${status}">${STATUS_LABELS[status]}</span>` + (edited(entry) ? '<span class="edited" title="Not saved yet">● edited</span>' : '');
        if (entry.basis) {
            parts.changed = `<div class="changed"><span class="label">English changed:</span><span class="diff">${diffHtml(entry.basis, entry.english)}</span></div>`;
        }
        if (problems.length) {
            parts.problems = '<ul class="problems">' + problems.map(p => `<li class="${p.level}">${escapeHtml(p.message)}</li>`).join('') + '</ul>';
        }
        const tips = memory ? L.suggestions(entry, state.model.entries, memory) : [];
        if (tips.length) {
            parts.suggest = '<div class="suggest">' + tips.map((t, i) => `<button class="small" data-action="use" data-index="${i}">${escapeHtml(t.text)}</button><span class="why">${escapeHtml(t.why)}${t.old ? ': ' + escapeHtml(t.old) : ''}</span>`).join('') + '</div>';
        }
        entry.tips = tips;
        return parts;
    }

    function cardHtml(entry, memory) {
        const d = dynamicHtml(entry, memory);
        const actions = [
            entry.section === 'strings' ? '<button class="small" data-action="uses">Where used</button>' : '',
            '<button class="small" data-action="copy">Copy English</button>',
            entry.basis && entry.translation ? '<button class="small" data-action="keep" title="The translation still fits the new English (Ctrl+Enter)">Keep translation</button>' : '',
            entry.unused ? '<button class="small" data-action="remove">Remove</button>' : '',
        ].join('');
        return `<article class="entry ${d.status}" data-uid="${escapeHtml(entry.uid)}">
<div class="meta"><span class="tag">${SECTION_LABELS[entry.section]}</span><span class="where">${escapeHtml(contextLabel(entry))}</span><span class="dyn-meta">${d.meta}</span><span class="spacer"></span>${actions}</div>
<div class="pair"><div class="english">${renderText(entry.english)}</div><div><textarea rows="${Math.min(8, Math.max(2, Math.ceil(entry.english.length / 60)))}" spellcheck="false" lang="${escapeHtml(state.locale.slice(0, 2))}">${escapeHtml(entry.translation)}</textarea></div></div>
<div class="dyn-changed">${d.changed}</div><div class="dyn-problems">${d.problems}</div><div class="dyn-suggest">${d.suggest}</div><div class="uses" hidden></div>
</article>`;
    }

    function refreshCard(card, entry) {
        const d = dynamicHtml(entry, L.buildMemory(state.model.entries));
        card.className = `entry ${d.status}`;
        card.querySelector('.dyn-meta').innerHTML = d.meta;
        card.querySelector('.dyn-changed').innerHTML = d.changed;
        card.querySelector('.dyn-problems').innerHTML = d.problems;
        card.querySelector('.dyn-suggest').innerHTML = d.suggest;
    }

    function renderList() {
        const list = $('list');
        const total = state.filtered.length;
        const pages = Math.max(1, Math.ceil(total / PAGE_SIZE));
        const start = state.page * PAGE_SIZE;
        const shown = state.filtered.slice(start, start + PAGE_SIZE);
        const memory = L.buildMemory(state.model.entries);
        list.innerHTML = shown.length ? shown.map(e => cardHtml(e, memory)).join('') : '<p class="empty">Nothing matches these filters.</p>';
        $('count').textContent = `${total} ${total === 1 ? 'entry' : 'entries'}`;
        $('page').textContent = `Page ${state.page + 1} of ${pages}`;
        $('prev').disabled = state.page === 0;
        $('next').disabled = state.page >= pages - 1;
    }

    function renderProgress() {
        const section = $('section').value;
        const counts = { translated: 0, missing: 0, outdated: 0, problem: 0, total: 0 };
        let dirty = 0;
        for (const entry of state.model.entries) {
            if (edited(entry)) dirty++;
            if (entry.unused || entry.removed || (section !== 'all' && entry.section !== section)) continue;
            counts.total++;
            counts[statusOf(entry)]++;
        }
        const done = counts.total ? Math.floor(100 * counts.translated / counts.total) : 0;
        $('progress').innerHTML = `<span><b>${done}%</b> done</span><span><b>${counts.translated}</b> translated</span><span><b>${counts.missing}</b> missing</span>` +
            `<span><b>${counts.outdated}</b> English changed</span><span><b>${counts.problem}</b> with problems</span>`;
        state.dirty = dirty + (state.structural ? 1 : 0);
        $('save').disabled = state.busy || !state.dirty;
        $('save').textContent = dirty ? `Save (${dirty})` : 'Save';
    }

    function refresh(keepPage) {
        if (!keepPage) state.page = 0;
        applyFilters();
        renderList();
        renderProgress();
    }

    function renderGlossary() {
        const search = $('glossary-search').value.trim().toLowerCase();
        $('glossary-list').innerHTML = state.glossary
            .filter(t => !search || `${t.en} ${t.zh} ${t.note || ''}`.toLowerCase().includes(search))
            .map(t => `<li data-zh="${escapeHtml(t.zh)}" title="Click to insert">${escapeHtml(t.en)} → <span class="zh">${escapeHtml(t.zh)}</span>${t.note ? `<span class="note">${escapeHtml(t.note)}</span>` : ''}</li>`)
            .join('') || '<li>No glossary for this language yet.</li>';
    }

    function insertAtCursor(textarea, text) {
        const start = textarea.selectionStart;
        textarea.value = textarea.value.slice(0, start) + text + textarea.value.slice(textarea.selectionEnd);
        textarea.selectionStart = textarea.selectionEnd = start + text.length;
        textarea.dispatchEvent(new Event('input', { bubbles: true }));
        textarea.focus();
    }

    function entryOf(element) {
        const card = element.closest('.entry');
        return card ? [card, state.byUid.get(card.dataset.uid)] : [null, null];
    }

    function onInput(event) {
        if (event.target.tagName !== 'TEXTAREA') return;
        const [card, entry] = entryOf(event.target);
        if (!entry) return;
        L.applyTranslation(entry, event.target.value);
        state.problems.delete(entry.uid);
        refreshCard(card, entry);
        cancelAnimationFrame(onInput.frame);
        onInput.frame = requestAnimationFrame(renderProgress);
    }

    async function onClick(event) {
        const button = event.target.closest('button[data-action]');
        if (!button) return;
        const [card, entry] = entryOf(button);
        if (!entry) return;
        const textarea = card.querySelector('textarea');
        const action = button.dataset.action;
        if (action === 'copy') {
            textarea.value = entry.english;
            textarea.dispatchEvent(new Event('input', { bubbles: true }));
        } else if (action === 'use') {
            textarea.value = entry.tips[Number(button.dataset.index)].text;
            textarea.dispatchEvent(new Event('input', { bubbles: true }));
        } else if (action === 'keep') {
            L.keepTranslation(entry);
            state.structural = true;
            state.problems.delete(entry.uid);
            refreshCard(card, entry);
            button.remove();
            renderProgress();
        } else if (action === 'remove') {
            entry.removed = true;
            state.structural = true;
            card.remove();
            renderProgress();
        } else if (action === 'uses') {
            const box = card.querySelector('.uses');
            if (!box.hidden) { box.hidden = true; return; }
            const response = await api(`/api/usage?name=${encodeURIComponent(entry.context.name)}`);
            const uses = response.ok ? await response.json() : [];
            box.textContent = uses.length ? uses.map(u => `${u.file}:${u.line}  ${u.text}`).join('\n') : 'Not used in the Bonk sources.';
            box.hidden = false;
        }
    }

    function focusSibling(textarea, step) {
        const all = [...$('list').querySelectorAll('textarea')];
        const next = all[all.indexOf(textarea) + step];
        if (next) {
            next.focus();
            next.closest('.entry').scrollIntoView({ block: 'nearest' });
        }
    }

    async function save() {
        if (state.busy || !state.dirty) return;
        const broken = state.model.entries.filter(e => edited(e) && hasErrors(e)).length;
        if (broken && !(await dialog('Save with problems?', `${broken} edited ${broken === 1 ? 'entry has' : 'entries have'} problems. They are saved, but the database and the migration leave them out until they are fixed.`, true))) return;
        state.busy = true;
        renderProgress();
        try {
            const server = { locale: state.locale, strings: state.server.strings.filter(s => s.translation), fields: state.server.fields };
            await postFile('server', L.writeServerJson(server, state.eol.server));
            await postFile('addon', L.writeLocaleTable(state.locale, L.addonTable(state.model.entries), state.eol.addon));
            const toc = L.ensureTocLine(state.toc, state.locale);
            if (toc !== state.toc) {
                await postFile('toc', toc);
                state.toc = toc;
            }
            for (const entry of state.model.entries) entry.original = entry.translation;
            state.model.entries = state.model.entries.filter(e => !e.removed);
            state.structural = false;
            toast('Saved');
        } catch (error) {
            await dialog('Saving failed', error.message);
        } finally {
            state.busy = false;
            refresh(true);
        }
    }

    function buildSql() {
        return L.buildSql(state.locale, state.model, state.sizes, entry => !hasErrors(entry));
    }

    async function applyToDatabase() {
        if (!(await dialog('Apply to the local database', `Writes every finished ${state.locale} translation into the local world database, replacing the ${state.locale} rows there. Unsaved edits are included.`, true))) return;
        const response = await api('/api/apply', { method: 'POST', body: buildSql(), headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
        if (!response.ok) return dialog('Could not apply', await response.text());
        const result = await response.json();
        if (!result.ok) return dialog('The database reported an error', result.output);
        await dialog('Applied', `${result.output ? result.output + '\n\n' : ''}In game, .bonk reload shows the new server and database text. Item and creature names need a server restart, and the client caches names: delete benilla-config/cache to see new ones.`);
    }

    async function writeMigration() {
        if (!(await dialog('Write a server migration', `Saves your work, then writes a migration to ${state.info.migrations} that replaces every ${state.locale} translation with the finished ones from this tool. Commit it in the server repository.`, true))) return;
        if (state.dirty) await save();
        if (state.dirty) return;
        const id = L.migrationId(new Date(), state.info.lastMigration);
        const response = await api(`/api/migration?id=${id}`, { method: 'POST', body: L.wrapMigration(id, buildSql()), headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
        if (!response.ok) return dialog('Could not write the migration', await response.text());
        const result = await response.json();
        await dialog('Migration written', result.written);
    }

    function rebuild() {
        const originals = new Map(state.model.entries.map(e => [e.uid, e.original]));
        const table = new Map();
        for (const e of state.model.entries) if (e.section === 'addon' && e.translation && !e.removed) table.set(e.key, e.translation);
        state.model = L.buildModel({ server: state.server, strings: state.strings, addonKeys: state.addonKeys, localeTable: table });
        for (const e of state.model.entries) e.original = originals.has(e.uid) ? originals.get(e.uid) : '';
        state.byUid = new Map(state.model.entries.map(e => [e.uid, e]));
        state.problems.clear();
    }

    async function importExport() {
        let text = '';
        if (state.info.files.export && await dialog('Import server export', `Use ${state.info.exportFile}?\n\nCancel picks another file.`, true)) text = await getFile('export');
        if (!text) text = await pickFile();
        if (!text) return;
        let data;
        try {
            data = JSON.parse(text);
        } catch (error) {
            return dialog('Not an export', error.message);
        }
        if (data.locale && data.locale !== state.locale && !(await dialog('Different language', `This export is for ${data.locale}; the tool is open for ${state.locale}. Its English is the same, so it can still be merged.`, true))) return;
        const result = L.mergeExport(state.server, data);
        rebuild();
        state.structural = true;
        refresh();
        await dialog('Export merged', `${result.added} new, ${result.changed} with changed English (marked "English changed"), ${result.removed} no longer in the game (dropped).\n\nServer text always comes from BonkStrings.cpp, so the export's strings are not used.`);
    }

    async function load() {
        if (!token) {
            $('list').innerHTML = '<p class="empty">Open the tool through tools/translate.ps1, which prints the address with its access token.</p>';
            return;
        }
        const response = await api('/api/info');
        if (!response.ok) {
            $('list').innerHTML = `<p class="empty">${escapeHtml(await response.text())}</p>`;
            return;
        }
        state.info = await response.json();
        state.locale = state.info.locale;
        $('locale').textContent = state.locale;
        document.title = `HoA translations · ${state.locale}`;
        const addonNames = await (await api('/api/addon')).json();
        const [header, source, serverText, glossaryText, addonText, toc, tables, ...addonTexts] = await Promise.all([
            getFile('strings-h'), getFile('strings-cpp'), getFile('server'), getFile('glossary'), getFile('addon'), getFile('toc'),
            api('/api/locale-tables').then(r => r.text()),
            ...addonNames.map(name => api(`/api/addon-file?name=${encodeURIComponent(name)}`).then(r => r.text())),
        ]);
        const addonFiles = {};
        addonNames.forEach((name, i) => { addonFiles[name] = addonTexts[i]; });
        state.eol.server = serverText.includes('\r\n') ? '\r\n' : '\n';
        state.eol.addon = addonText.includes('\r\n') ? '\r\n' : '\n';
        state.toc = toc;
        state.server = L.parseServerJson(serverText);
        state.server.locale = state.locale;
        state.strings = L.readStrings(header, source);
        state.addonKeys = L.collectAddonKeys(addonFiles);
        state.sizes = L.readColumnSizes([tables]);
        state.glossary = glossaryText ? (JSON.parse(glossaryText).terms || []) : [];
        for (const term of state.glossary) if (term.en && term.check !== false) term.re = L.glossaryPattern(term);
        state.model = L.buildModel({ server: state.server, strings: state.strings, addonKeys: state.addonKeys, localeTable: L.parseLocaleTable(addonText).entries });
        state.byUid = new Map(state.model.entries.map(e => [e.uid, e]));
        $('apply').disabled = !state.info.database;
        if (!state.info.database) $('apply').title = 'No MariaDB client found; start the tool with -MariaDb <path to mariadb.exe>';
        if (!state.strings.length) toast('No server strings found: is the server submodule checked out?');
        renderGlossary();
        refresh();
    }

    $('list').addEventListener('input', onInput);
    $('list').addEventListener('click', onClick);
    $('list').addEventListener('focusin', event => { if (event.target.tagName === 'TEXTAREA') state.focused = event.target; });
    $('list').addEventListener('keydown', event => {
        if (event.target.tagName !== 'TEXTAREA') return;
        if (event.altKey && (event.key === 'ArrowDown' || event.key === 'ArrowUp')) {
            event.preventDefault();
            focusSibling(event.target, event.key === 'ArrowDown' ? 1 : -1);
        } else if (event.ctrlKey && event.key === 'Enter') {
            event.preventDefault();
            const [card, entry] = entryOf(event.target);
            const keep = card && card.querySelector('button[data-action="keep"]');
            if (entry && keep) keep.click();
            focusSibling(event.target, 1);
        }
    });
    for (const id of ['section', 'status']) $(id).addEventListener('change', () => refresh());
    $('search').addEventListener('input', () => {
        clearTimeout(load.search);
        load.search = setTimeout(() => refresh(), 200);
    });
    $('prev').addEventListener('click', () => { state.page--; renderList(); window.scrollTo(0, 0); });
    $('next').addEventListener('click', () => { state.page++; renderList(); window.scrollTo(0, 0); });
    $('save').addEventListener('click', save);
    $('import').addEventListener('click', importExport);
    $('apply').addEventListener('click', applyToDatabase);
    $('migration').addEventListener('click', writeMigration);
    $('glossary-toggle').addEventListener('click', () => {
        const panel = $('glossary');
        panel.hidden = !panel.hidden;
        $('glossary-toggle').setAttribute('aria-pressed', String(!panel.hidden));
    });
    $('glossary-search').addEventListener('input', renderGlossary);
    $('glossary-list').addEventListener('mousedown', event => event.preventDefault());
    $('glossary-list').addEventListener('click', event => {
        const item = event.target.closest('li[data-zh]');
        if (!item) return;
        const active = document.activeElement;
        const target = active && active.tagName === 'TEXTAREA' && $('list').contains(active) ? active : state.focused;
        if (target && document.body.contains(target)) insertAtCursor(target, item.dataset.zh);
        else toast('Click into a translation first');
    });
    document.addEventListener('keydown', event => {
        if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 's') {
            event.preventDefault();
            save();
        }
    });
    window.addEventListener('beforeunload', event => {
        if (state.dirty) {
            event.preventDefault();
            event.returnValue = '';
        }
    });

    load().catch(error => {
        $('list').innerHTML = `<p class="empty">Could not load: ${escapeHtml(error.message)}</p>`;
    });
})();
