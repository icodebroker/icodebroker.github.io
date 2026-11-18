// 분류 필터, 검색, 언어 기억
(function () {
  document.querySelectorAll('.lang-switch a[data-lang]').forEach(function (a) {
    a.addEventListener('click', function () {
      try { localStorage.setItem('lang', a.getAttribute('data-lang')); } catch (e) {}
    });
  });

  var grid = document.getElementById('grid');
  if (!grid) { return; }

  var cards = Array.prototype.slice.call(grid.querySelectorAll('.card'));
  var chips = Array.prototype.slice.call(document.querySelectorAll('.chip'));
  var search = document.getElementById('search');
  var empty = document.getElementById('no-results');
  var filter = 'all';

  function apply() {
    var q = (search.value || '').trim().toLowerCase();
    var shown = 0;
    cards.forEach(function (card) {
      var okCat = filter === 'all' || card.getAttribute('data-cat') === filter;
      var okText = !q || card.getAttribute('data-search').toLowerCase().indexOf(q) !== -1;
      card.hidden = !(okCat && okText);
      if (!card.hidden) { shown++; }
    });
    empty.hidden = shown !== 0;
  }

  chips.forEach(function (chip) {
    chip.addEventListener('click', function () {
      filter = chip.getAttribute('data-filter');
      chips.forEach(function (c) {
        var on = c === chip;
        c.classList.toggle('is-on', on);
        c.setAttribute('aria-pressed', on ? 'true' : 'false');
      });
      apply();
    });
  });

  search.addEventListener('input', apply);
})();
