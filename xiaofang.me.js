
notifyParentLoading();

jQuery(window).on('message', function (msg) {
  if (msg.type === 'wechat_unblocker') {
    debugger;
    updateParent()
  }
});

jQuery(function () {
  var $ = jQuery;
  var parent = window.parent;
  if (!parent) return;

  setTimeout(function () {
    updateParent();
  }, 200);

  $('body').on('click', 'a', function (e) {
    var $a = $(this);
    var href = $a.attr('href')
    if (/\/\//.test(href) && !/xiaofang\.me/.test(href)) {
      updateParent(true, href);
      e.preventDefault();
    }
  })
});


function notifyParentLoading() {

  var parent = window.parent;
  if (!parent) return;

  parent.postMessage({
    msgTitle: 'connected'
  }, '*');
}
function updateParent(isReplaceHref, href) {

  var $ = jQuery;

  var parent = window.parent;
  if (!parent) return;

  var $featuredImg = $('.wp-post-image:first');

  if (!$featuredImg.length) {
    $featuredImg = $('.size-large:first')
  }

  if (!$featuredImg.length) {
    $featuredImg = $('.size-full:first')
  }

  if (!$featuredImg.length) {
    var area = 0;
    $('img').each(function () {
      var w = parseInt($(this).attr('width')) || 1;
      var h = parseInt($(this).attr('height')) || 1;
      var _area = w * h;
      if (_area > area) {
        area = _area;
        $featuredImg = $(this)
      }
    });
  }

  parent.postMessage({
    title: document.title,
    url: href || location.href,
    path: location.path,
    search: location.search,
    hash: location.hash,
    isReplaceHref: isReplaceHref,
    imgSrc: $featuredImg.attr('src')
  }, '*');
}
