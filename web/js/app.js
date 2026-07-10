const STORAGE = {
  revealed: 'ncpain_revealed',
  bookmarks: 'ncpain_bookmarks',
  imported: 'ncpain_imported',
  examState: 'ncpain_exam_state',
};

const EXAM_LABELS = ['A', 'B', 'C', 'D', 'E', 'F'];

const CATEGORIES = {
  'AI Data Center Design': { icon: '🏢', short: 'AI DC', weight: '5%' },
  'Spectrum Networking': { icon: '🌐', short: 'Spectrum', weight: '30%' },
  'InfiniBand Networking': { icon: '🔌', short: 'IB', weight: '30%' },
  'Kubernetes Integration': { icon: '☸️', short: 'K8s', weight: '5%' },
  'Troubleshooting Tools': { icon: '🔧', short: 'Debug', weight: '20%' },
  'Automation & Configuration': { icon: '⚙️', short: 'Auto', weight: '10%' },
};

let allQuestions = [];
let examQuestions = [];
let examQuestionsLoaded = false;
let examQuestionsPromise = null;
let sessionQuestions = [];
let currentIndex = 0;
let currentTab = 'home';
let filters = { dumpOnly: false, bookmarkOnly: false, shuffle: false, category: null };

const $ = (s) => document.querySelector(s);
let main;
let pageTitle;

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
    const res = await fetch('./data/questions.json?v=DEV');
    const data = await res.json();
    bundled = data.questions || [];
  } catch (e) {
    console.error(e);
  }
  const seen = new Set();
  allQuestions = [];
  for (const q of [...bundled, ...imported]) {
    if (!q || typeof q.question !== 'string') continue;
    const key = q.question.trim().toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    allQuestions.push(q);
  }
}

// Loaded lazily (only once the 모의고사 tab is opened) so the home screen
// doesn't have to wait on ~75KB of exam data most sessions never need.
function loadExamQuestions() {
  if (examQuestionsPromise) return examQuestionsPromise;
  examQuestionsPromise = fetch('./data/exam120.json?v=DEV')
    .then((res) => res.json())
    .then((data) => {
      examQuestions = Array.isArray(data.questions) ? data.questions : [];
    })
    .catch((e) => {
      console.error(e);
      examQuestions = [];
    })
    .finally(() => {
      examQuestionsLoaded = true;
    });
  return examQuestionsPromise;
}

function defaultExamState() {
  return { started: false, finished: false, currentIndex: 0, answers: {}, score: null, shuffle: false, order: [] };
}

function getExamState() {
  const state = loadJSON(STORAGE.examState, defaultExamState());
  return { ...defaultExamState(), ...state };
}

function saveExamState(state) {
  saveJSON(STORAGE.examState, state);
}

// Fisher-Yates: unbiased shuffle, unlike Array#sort(() => Math.random() - 0.5).
function shuffledIndices(count) {
  const arr = Array.from({ length: count }, (_, i) => i);
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

function sequentialIndices(count) {
  return Array.from({ length: count }, (_, i) => i);
}

// Answers are keyed by question id, not position, so shuffling the display
// order never affects grading — it only changes which question shows next.
function ensureExamOrder(state) {
  if (Array.isArray(state.order) && state.order.length === examQuestions.length) {
    return state;
  }
  state.order = state.shuffle ? shuffledIndices(examQuestions.length) : sequentialIndices(examQuestions.length);
  return state;
}

function getOrderedQuestion(state, displayIndex) {
  const realIndex = state.order[displayIndex];
  return examQuestions[realIndex] ?? examQuestions[displayIndex];
}

function isExamAnswerCorrect(q, state) {
  const given = [...(state.answers[q.id] || [])].sort((a, b) => a - b);
  const answer = [...q.correctIndices].sort((a, b) => a - b);
  return given.length === answer.length && given.every((v, i) => v === answer[i]);
}

function getCorrectIndices(q) {
  if (Array.isArray(q.correctIndices) && q.correctIndices.length) return q.correctIndices;
  if (typeof q.correctIndex === 'number') return [q.correctIndex];
  return [0];
}

function getCorrectChoiceTexts(q) {
  const labels = ['A', 'B', 'C', 'D', 'E', 'F'];
  return getCorrectIndices(q)
    .filter((i) => q.choices && q.choices[i] !== undefined)
    .map((i, seq) => ({
      label: labels[seq] || String(seq + 1),
      text: q.choices[i],
    }));
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
      <p class="subtitle">덤프 암기 모드 — Q: 문제와 A: 정답만 표시합니다. (오답 보기 없음)</p>
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
  const bookmarks = getBookmarks();
  const answers = getCorrectChoiceTexts(q);

  const answerHTML = answers.map(({ label, text }) =>
    `<p class="qa-line qa-answer"><strong>${label} :</strong> ${escapeHtml(text)}</p>`
  ).join('');

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
    <div class="flashcard">
      ${multiBadge ? `<div style="margin-bottom:8px">${multiBadge}</div>` : ''}
      <p class="qa-line qa-question"><strong>Q:</strong> ${escapeHtml(q.question)}</p>
      ${answerHTML}
    </div>
    <div class="nav-bar">
      <button class="nav-btn" id="prev-btn">‹ 이전</button>
      <span class="nav-counter">${currentIndex + 1} / ${sessionQuestions.length}</span>
      <button class="nav-btn" id="next-btn">다음 ›</button>
    </div>`;

  bindChips();
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

function markStudied(q) {
  const r = getRevealed();
  if (!r.has(q.id)) {
    r.add(q.id);
    saveJSON(STORAGE.revealed, [...r]);
  }
}

function goNext() {
  vibrate();
  if (!sessionQuestions.length) return;
  markStudied(sessionQuestions[currentIndex]);
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

function renderExam() {
  pageTitle.textContent = '모의고사';

  if (!examQuestionsLoaded) {
    main.innerHTML = '<div class="loading">모의고사 문제 로딩 중…</div>';
    loadExamQuestions().then(() => {
      if (currentTab === 'exam') renderExam();
    });
    return;
  }

  if (!examQuestions.length) {
    main.innerHTML = '<div class="loading">모의고사 문제를 불러올 수 없습니다.<br><small>새로고침해 주세요.</small></div>';
    return;
  }

  const state = getExamState();

  if (state.finished && state.score) {
    renderExamResult(state);
  } else if (!state.started) {
    renderExamIntro(state);
  } else {
    renderExamQuestion(state);
  }
}

function renderExamIntro(state) {
  const answeredCount = Object.keys(state.answers).length;
  const hasProgress = answeredCount > 0;

  main.innerHTML = `
    <div class="card exam-intro">
      <div class="subtitle">📝 실전 모의고사</div>
      <h2 style="margin-top:4px">기출 120제</h2>
      <p class="subtitle">실제 시험처럼 오답 보기도 함께 표시됩니다. 120문제를 모두 풀면 몇 개 맞았는지 채점 결과를 확인할 수 있습니다.</p>
    </div>
    <div class="card">
      <div class="stats">
        <div><div class="num">${examQuestions.length}</div><div class="label">전체 문제</div></div>
        <div><div class="num">${answeredCount}</div><div class="label">답변 완료</div></div>
      </div>
    </div>
    <div class="card exam-shuffle-card">
      <label class="exam-shuffle-toggle">
        <div>
          <div class="exam-shuffle-title">🔀 문제 순서 셔플</div>
          <div class="subtitle">켜면 매번 새로운 순서로 120문제가 출제됩니다.</div>
        </div>
        <input type="checkbox" id="exam-shuffle-checkbox" ${state.shuffle ? 'checked' : ''}>
      </label>
    </div>
    <button class="btn-primary" id="start-exam-btn">${hasProgress ? '이어서 풀기' : '모의고사 시작'}</button>
    ${hasProgress ? '<button class="btn-danger exam-restart-link" id="restart-exam-btn">처음부터 다시 시작</button>' : ''}
  `;

  $('#exam-shuffle-checkbox')?.addEventListener('change', (e) => {
    const s = getExamState();
    s.shuffle = e.target.checked;
    saveExamState(s);
    vibrate();
  });
  $('#start-exam-btn')?.addEventListener('click', () => {
    const s = getExamState();
    s.started = true;
    ensureExamOrder(s);
    saveExamState(s);
    renderExam();
  });
  $('#restart-exam-btn')?.addEventListener('click', () => {
    if (!confirm('처음부터 다시 시작할까요? 진행 상황이 모두 초기화됩니다.')) return;
    saveExamState({ ...defaultExamState(), shuffle: state.shuffle });
    renderExam();
  });
}

function renderExamQuestion(state) {
  ensureExamOrder(state);
  const idx = Math.min(Math.max(state.currentIndex, 0), examQuestions.length - 1);
  const q = getOrderedQuestion(state, idx);
  const selected = new Set(state.answers[q.id] || []);
  const isLast = idx === examQuestions.length - 1;
  const answeredCount = Object.keys(state.answers).length;
  const pct = ((idx + 1) / examQuestions.length) * 100;

  const choicesHTML = q.choices.map((text, i) => {
    const isSelected = selected.has(i);
    return `<button class="exam-choice${isSelected ? ' selected' : ''}" data-index="${i}" type="button">
      <span class="choice-label">${EXAM_LABELS[i] || i + 1}</span>
      <span>${escapeHtml(text)}</span>
    </button>`;
  }).join('');

  const multiBadge = q.isMultiSelect ? '<span class="q-badge multi">복수 정답 (모두 선택)</span>' : '';
  const cat = CATEGORIES[q.category] || { icon: '📋' };

  main.innerHTML = `
    <div class="exam-progress-row">
      <span>${idx + 1} / ${examQuestions.length}</span>
      <span>${answeredCount}개 답변 완료</span>
      <button class="exam-reset-btn" id="exam-reset-btn" type="button">⚙ 처음으로</button>
    </div>
    <div class="progress-bar"><div class="progress-fill" style="width:${pct}%"></div></div>
    <div class="q-header" style="margin-top:12px">
      <div>${cat.icon} ${q.category}</div>
    </div>
    <div class="question-box">${multiBadge}<div style="margin-top:8px">${escapeHtml(q.question)}</div></div>
    <div class="exam-choices">${choicesHTML}</div>
    <div class="nav-bar">
      <button class="nav-btn" id="exam-prev-btn" ${idx === 0 ? 'disabled' : ''}>‹ 이전</button>
      ${isLast
        ? '<button class="btn-primary exam-submit-btn" id="exam-submit-btn">제출하고 채점하기</button>'
        : '<button class="nav-btn" id="exam-next-btn">다음 ›</button>'}
    </div>
  `;

  main.querySelectorAll('.exam-choice').forEach((btn) => {
    btn.addEventListener('click', () => {
      toggleExamChoice(q, Number(btn.dataset.index));
    });
  });
  $('#exam-prev-btn')?.addEventListener('click', () => moveExam(-1));
  $('#exam-next-btn')?.addEventListener('click', () => moveExam(1));
  $('#exam-submit-btn')?.addEventListener('click', submitExam);
  $('#exam-reset-btn')?.addEventListener('click', () => {
    if (!confirm('처음 화면으로 돌아갈까요? 지금까지 답한 내용이 모두 사라집니다.')) return;
    saveExamState({ ...defaultExamState(), shuffle: state.shuffle });
    renderExam();
  });
}

function toggleExamChoice(question, index) {
  const state = getExamState();
  const current = new Set(state.answers[question.id] || []);
  if (question.isMultiSelect) {
    current.has(index) ? current.delete(index) : current.add(index);
  } else {
    current.clear();
    current.add(index);
  }
  state.answers[question.id] = [...current];
  saveExamState(state);
  vibrate();
  renderExamQuestion(state);
}

function moveExam(delta) {
  const state = getExamState();
  const next = state.currentIndex + delta;
  if (next < 0 || next >= examQuestions.length) return;
  state.currentIndex = next;
  saveExamState(state);
  vibrate();
  renderExam();
}

function submitExam() {
  const state = getExamState();
  const unanswered = examQuestions.filter((q) => !(state.answers[q.id] || []).length).length;
  if (unanswered > 0 && !confirm(`아직 ${unanswered}개 문제에 답하지 않았습니다. 그래도 제출할까요?`)) {
    return;
  }

  let correct = 0;
  examQuestions.forEach((q) => {
    if (isExamAnswerCorrect(q, state)) correct++;
  });

  const total = examQuestions.length;
  const percent = Math.round((correct / total) * 1000) / 10;

  state.finished = true;
  state.score = { correct, total, percent };
  saveExamState(state);
  vibrate('success');
  renderExam();
}

function renderExamResult(state) {
  ensureExamOrder(state);
  const { correct, total, percent } = state.score;
  const orderedQuestions = state.order.map((realIndex) => examQuestions[realIndex]).filter(Boolean);
  const wrongList = orderedQuestions.filter((q) => !isExamAnswerCorrect(q, state));

  const wrongHTML = wrongList.map((q) => {
    const givenIndices = state.answers[q.id] || [];
    const choiceText = (i) => (q.choices && q.choices[i] !== undefined ? q.choices[i] : '');

    const givenHTML = givenIndices.length
      ? givenIndices.map((i) =>
          `<div class="review-choice review-wrong-choice"><span class="review-choice-label">${EXAM_LABELS[i] || i + 1}</span>${escapeHtml(choiceText(i))}</div>`
        ).join('')
      : '<div class="review-choice review-wrong-choice">(답변 없음)</div>';

    const correctHTML = q.correctIndices.map((i) =>
      `<div class="review-choice review-correct-choice"><span class="review-choice-label">${EXAM_LABELS[i] || i + 1}</span>${escapeHtml(choiceText(i))}</div>`
    ).join('');

    return `<div class="review-item">
      <p class="review-q">${escapeHtml(q.question)}</p>
      <div class="review-block">
        <div class="review-block-label">❌ 내 답</div>
        ${givenHTML}
      </div>
      <div class="review-block">
        <div class="review-block-label">✅ 정답</div>
        ${correctHTML}
      </div>
    </div>`;
  }).join('');

  main.innerHTML = `
    <div class="card exam-result-card">
      <div class="subtitle">모의고사 결과</div>
      <div class="exam-score-big">${correct}<span>/${total}</span></div>
      <div class="exam-score-percent">${percent}점</div>
      <div class="progress-bar"><div class="progress-fill" style="width:${percent}%"></div></div>
    </div>
    <button class="btn-primary" id="retry-exam-btn">다시 도전하기</button>
    ${wrongList.length
      ? `<div class="card" style="margin-top:16px">
          <h2>틀린 문제 (${wrongList.length}개)</h2>
          ${wrongHTML}
        </div>`
      : '<div class="card" style="margin-top:16px;text-align:center">🎉 전 문제 정답입니다!</div>'}
  `;

  $('#retry-exam-btn')?.addEventListener('click', () => {
    if (!confirm('새로운 모의고사를 시작할까요? 이전 결과는 사라집니다.')) return;
    saveExamState({ ...defaultExamState(), shuffle: state.shuffle });
    renderExam();
  });
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
  else if (tab === 'exam') renderExam();
  else if (tab === 'import') renderImport();
}

async function init() {
  main = $('#main-content');
  pageTitle = $('#page-title');
  if (!main || !pageTitle) return;

  main.innerHTML = '<div class="loading">문제 로딩 중…</div>';
  try {
    await loadQuestions();
    switchTab('home');

    document.querySelectorAll('.tab').forEach((tab) => {
      tab.addEventListener('click', () => switchTab(tab.dataset.tab));
    });
  } catch (e) {
    console.error(e);
    main.innerHTML = '<div class="loading">앱 로딩 실패<br><small>새로고침해 주세요.</small></div>';
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
