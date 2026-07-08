const STORAGE = {
  revealed: 'ncpain_revealed',
  bookmarks: 'ncpain_bookmarks',
  imported: 'ncpain_imported',
};

const CATEGORIES = {
  'AI Data Center Design': { icon: '🏢', short: 'AI DC', weight: '5%' },
  'Spectrum Networking': { icon: '🌐', short: 'Spectrum', weight: '30%' },
  'InfiniBand Networking': { icon: '🔌', short: 'IB', weight: '30%' },
  'Kubernetes Integration': { icon: '☸️', short: 'K8s', weight: '5%' },
  'Troubleshooting Tools': { icon: '🔧', short: 'Debug', weight: '20%' },
  'Automation & Configuration': { icon: '⚙️', short: 'Auto', weight: '10%' },
};

let allQuestions = [];
let sessionQuestions = [];
let currentIndex = 0;
let currentTab = 'home';
let filters = { dumpOnly: false, bookmarkOnly: false, shuffle: false, category: null };

const $ = (s) => document.querySelector(s);
const main = $('#main-content');
const pageTitle = $('#page-title');

function loadJSON(key, fallback) {
  try { return JSON.parse(localStorage.getItem(key)) ?? fallback; }
  catch { return fallback; }
}

function saveJSON(key, val) {
  localStorage.setItem(key, JSON.stringify(val));
}

function getRevealed() { return new Set(loadJSON(STORAGE.revealed, [])); }
function getBookmarks() { return new Set(loadJSON(STORAGE.bookmarks, [])); }

function toast(msg) {
  const el = $('#toast');
  el.textContent = msg;
  el.hidden = false;
  setTimeout(() => { el.hidden = true; }, 2500);
}

function vibrate(type = 'light') {
  if (navigator.vibrate) {
    navigator.vibrate(type === 'success' ? [10, 50, 10] : 10);
  }
}

async function loadQuestions() {
  const imported = loadJSON(STORAGE.imported, []);
  let bundled = [];
  try {
    const res = await fetch('./data/questions.json');
    const data = await res.json();
    bundled = data.questions || [];
  } catch (e) {
    console.error(e);
  }
  const seen = new Set();
  allQuestions = [];
  for (const q of [...bundled, ...imported]) {
    const key = q.question.trim().toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    allQuestions.push(q);
  }
}

function getFiltered() {
  let items = [...allQuestions];
  const bookmarks = getBookmarks();
  if (filters.bookmarkOnly) items = items.filter((q) => bookmarks.has(q.id));
  else if (filters.dumpOnly) items = items.filter((q) => q.source === 'Dump');
  else if (filters.category) items = items.filter((q) => q.category === filters.category);
  if (filters.shuffle) items.sort(() => Math.random() - 0.5);
  return items;
}

function progress() {
  const revealed = getRevealed();
  if (!allQuestions.length) return 0;
  const count = allQuestions.filter((q) => revealed.has(q.id)).length;
  return count / allQuestions.length;
}

function sourceCounts() {
  const c = { Dump: 0, 'Official Topic': 0, Practice: 0 };
  allQuestions.forEach((q) => { if (c[q.source] !== undefined) c[q.source]++; });
  return c;
}

function renderHome() {
  pageTitle.textContent = 'NCP-AIN';
  const pct = Math.round(progress() * 100);
  const bookmarks = getBookmarks();
  const counts = sourceCounts();

  let categoryHTML = '';
  for (const [name, meta] of Object.entries(CATEGORIES)) {
    const count = allQuestions.filter((q) => q.category === name).length;
    categoryHTML += `
      <button class="category-row" data-category="${name}">
        <span class="category-icon">${meta.icon}</span>
        <div style="flex:1">
          <div>${name}</div>
          <div class="category-meta">시험 비중 ${meta.weight} · ${count}문제</div>
        </div>
        <span>›</span>
      </button>`;
  }

  main.innerHTML = `
    <div class="card">
      <div class="subtitle">✓ NVIDIA Certified Professional</div>
      <h2 style="margin-top:4px">AI Networking (NCP-AIN)</h2>
      <p class="subtitle">덤프 암기 모드 — 문제와 보기만 표시하고 정답을 확인하세요.</p>
    </div>
    <div class="card">
      <div style="display:flex;justify-content:space-between;align-items:center">
        <h2>학습 진행률</h2>
        <strong style="color:var(--green)">${pct}%</strong>
      </div>
      <div class="progress-bar"><div class="progress-fill" style="width:${pct}%"></div></div>
      <div class="stats">
        <div><div class="num">${allQuestions.length}</div><div class="label">전체</div></div>
        <div><div class="num">${bookmarks.size}</div><div class="label">북마크</div></div>
        <div><div class="num">6</div><div class="label">카테고리</div></div>
      </div>
    </div>
    <div class="card"><h2>시험 범위</h2>${categoryHTML}</div>
    <div class="card">
      <h2>문제 출처</h2>
      <div style="display:flex;justify-content:space-between;padding:6px 0"><span>Dump</span><span>${counts.Dump}</span></div>
      <div style="display:flex;justify-content:space-between;padding:6px 0"><span>Official Topic</span><span>${counts['Official Topic']}</span></div>
      <div style="display:flex;justify-content:space-between;padding:6px 0"><span>Practice</span><span>${counts.Practice}</span></div>
    </div>`;

  main.querySelectorAll('.category-row').forEach((btn) => {
    btn.addEventListener('click', () => {
      filters = { dumpOnly: false, bookmarkOnly: false, shuffle: false, category: btn.dataset.category };
      currentIndex = 0;
      switchTab('study');
    });
  });
}

function renderStudy() {
  pageTitle.textContent = '암기 학습';
  sessionQuestions = getFiltered();
  if (currentIndex >= sessionQuestions.length) currentIndex = 0;

  const chip = (label, active, cat = null) =>
    `<button class="chip${active ? ' active' : ''}" data-chip="${label}"${cat ? ` data-cat="${cat}"` : ''}>${label}</button>`;

  let chipsHTML = chip('전체', !filters.dumpOnly && !filters.bookmarkOnly && !filters.category);
  chipsHTML += chip('기출', filters.dumpOnly);
  chipsHTML += chip('북마크', filters.bookmarkOnly);
  chipsHTML += chip(filters.shuffle ? '셔플 ON' : '셔플 OFF', filters.shuffle);
  for (const [name, meta] of Object.entries(CATEGORIES)) {
    chipsHTML += chip(meta.short, filters.category === name, name);
  }

  if (!sessionQuestions.length) {
    main.innerHTML = `<div class="chips">${chipsHTML}</div><div class="loading">문제 없음</div>`;
    bindChips();
    return;
  }

  const q = sessionQuestions[currentIndex];
  const revealed = getRevealed();
  const bookmarks = getBookmarks();
  const isRevealed = revealed.has(q.id);
  const labels = ['A','B','C','D','E','F'];

  let choicesHTML = q.choices.map((text, i) => {
    const correct = isRevealed && q.correctIndices.includes(i);
    return `<div class="choice${correct ? ' correct' : ''}">
      <span class="choice-label">${labels[i] || i+1}</span>
      <span>${escapeHtml(text)}</span>
      ${correct ? ' ✓' : ''}
    </div>`;
  }).join('');

  const multiBadge = q.isMultiSelect ? '<span class="q-badge multi">복수 정답</span>' : '';
  const cat = CATEGORIES[q.category] || { icon: '📋' };

  main.innerHTML = `
    <div class="chips">${chipsHTML}</div>
    <div id="round-banner" hidden class="round-banner">한 바퀴 완료! 처음부터 다시 시작합니다.</div>
    <div class="q-header">
      <div>
        <div>Q${currentIndex + 1} / ${sessionQuestions.length}</div>
        <div>${cat.icon} ${q.category}</div>
      </div>
      <div style="text-align:right">
        <button id="bookmark-btn" style="border:none;background:none;font-size:1.2rem;cursor:pointer">${bookmarks.has(q.id) ? '🔖' : '☆'}</button>
        <div class="q-badge">${q.source}</div>
      </div>
    </div>
    <div class="question-box">${multiBadge}<div style="margin-top:8px">${escapeHtml(q.question)}</div></div>
    ${choicesHTML}
    ${isRevealed
      ? `<div class="answer-box">✓ 정답: ${q.answerKey || q.correctIndices.map(i => labels[i]).join(', ')}</div>`
      : `<button class="btn-primary" id="reveal-btn">👁 정답 보기</button>`}
    <div class="nav-bar">
      <button class="nav-btn" id="prev-btn">‹ 이전</button>
      <span class="nav-counter">${currentIndex + 1} / ${sessionQuestions.length}</span>
      <button class="nav-btn" id="next-btn">다음 ›</button>
    </div>`;

  bindChips();
  $('#reveal-btn')?.addEventListener('click', () => {
    const r = getRevealed();
    r.add(q.id);
    saveJSON(STORAGE.revealed, [...r]);
    vibrate('success');
    renderStudy();
  });
  $('#bookmark-btn')?.addEventListener('click', () => {
    const b = getBookmarks();
    b.has(q.id) ? b.delete(q.id) : b.add(q.id);
    saveJSON(STORAGE.bookmarks, [...b]);
    renderStudy();
  });
  $('#prev-btn')?.addEventListener('click', goPrev);
  $('#next-btn')?.addEventListener('click', goNext);

  let touchStartX = 0;
  main.addEventListener('touchstart', (e) => { touchStartX = e.touches[0].clientX; }, { once: true });
  main.addEventListener('touchend', (e) => {
    const dx = e.changedTouches[0].clientX - touchStartX;
    if (dx < -50) goNext();
    else if (dx > 50) goPrev();
  }, { once: true });
}

function bindChips() {
  main.querySelectorAll('.chip').forEach((chip) => {
    chip.addEventListener('click', () => {
      const label = chip.dataset.chip;
      if (label === '전체') filters = { dumpOnly: false, bookmarkOnly: false, shuffle: false, category: null };
      else if (label === '기출') filters = { dumpOnly: true, bookmarkOnly: false, shuffle: false, category: null };
      else if (label === '북마크') filters = { dumpOnly: false, bookmarkOnly: true, shuffle: false, category: null };
      else if (label.startsWith('셔플')) filters.shuffle = !filters.shuffle;
      else if (chip.dataset.cat) filters = { dumpOnly: false, bookmarkOnly: false, shuffle: filters.shuffle, category: chip.dataset.cat };
      currentIndex = 0;
      renderStudy();
    });
  });
}

function goNext() {
  vibrate();
  if (!sessionQuestions.length) return;
  if (currentIndex >= sessionQuestions.length - 1) {
    currentIndex = 0;
    vibrate('success');
    renderStudy();
    const banner = $('#round-banner');
    if (banner) { banner.hidden = false; setTimeout(() => { banner.hidden = true; }, 2000); }
  } else {
    currentIndex++;
    renderStudy();
  }
}

function goPrev() {
  vibrate();
  if (!sessionQuestions.length) return;
  currentIndex = currentIndex <= 0 ? sessionQuestions.length - 1 : currentIndex - 1;
  renderStudy();
}

function renderImport() {
  pageTitle.textContent = '덤프 관리';
  main.innerHTML = `
    <div class="card import-section">
      <h3>덤프 JSON 가져오기</h3>
      <p class="subtitle">JSON 파일을 선택하면 암기 목록에 추가됩니다.</p>
      <label class="file-btn">📄 JSON 파일 선택
        <input type="file" id="file-input" accept=".json,application/json">
      </label>
    </div>
    <div class="card">
      <button class="btn-danger" id="clear-import">🗑 가져온 덤프 삭제</button>
    </div>
    <div class="card">
      <h3>📱 iPhone 설치 팁</h3>
      <p class="subtitle">Safari에서 이 페이지를 열고<br><strong>공유 → 홈 화면에 추가</strong>하면 앱처럼 사용할 수 있습니다.</p>
    </div>`;

  $('#file-input').addEventListener('change', async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    try {
      const text = await file.text();
      const data = JSON.parse(text);
      const incoming = data.questions || [];
      const existing = loadJSON(STORAGE.imported, []);
      const merged = [...existing, ...incoming];
      saveJSON(STORAGE.imported, merged);
      await loadQuestions();
      toast(`${incoming.length}개 문제를 가져왔습니다.`);
    } catch {
      toast('가져오기 실패');
    }
    e.target.value = '';
  });

  $('#clear-import').addEventListener('click', async () => {
    if (!confirm('가져온 덤프를 삭제할까요?')) return;
    localStorage.removeItem(STORAGE.imported);
    await loadQuestions();
    toast('가져온 덤프가 삭제되었습니다.');
  });
}

function escapeHtml(s) {
  const d = document.createElement('div');
  d.textContent = s;
  return d.innerHTML;
}

function switchTab(tab) {
  currentTab = tab;
  document.querySelectorAll('.tab').forEach((t) => t.classList.toggle('active', t.dataset.tab === tab));
  if (tab === 'home') renderHome();
  else if (tab === 'study') renderStudy();
  else if (tab === 'import') renderImport();
}

async function init() {
  main.innerHTML = '<div class="loading">문제 로딩 중…</div>';
  await loadQuestions();
  switchTab('home');

  document.querySelectorAll('.tab').forEach((tab) => {
    tab.addEventListener('click', () => switchTab(tab.dataset.tab));
  });

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('./sw.js').catch(() => {});
  }
}

init();
