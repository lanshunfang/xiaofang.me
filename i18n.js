
(function() {
  console.group('Found text without i18n:');
  var nodeIterator = document.createNodeIterator(
    // Node to use as root
    document.body,

    // Only consider nodes that are text nodes (nodeType 3)
    NodeFilter.SHOW_TEXT,

    // Object containing the function to use for the acceptNode method
    // of the NodeFilter
    { acceptNode: function(node) {

      var parentNode = node.parentNode;
      var papaNode = parentNode.parentNode;
      var $parentNode = $(parentNode);
      var classStringOfParent = parentNode.getAttribute('class');
      var getDataBindStringOfParent = parentNode.getAttribute('data-bind');
      var closestDataBindString = $parentNode.closest('[data-bind]').attr('data-bind');
      var getDataBindStringOfPapa = papaNode.getAttribute('data-bind');
      var $closestOjComponentNode = $parentNode.closest('.oj-component-initnode');
      var closestOjComponentNodeDataBindString = $closestOjComponentNode.attr('data-bind');

      var isEmpty = /^\s*$/.test(node.data);
      var isContainsI18nAlready = getDataBindStringOfParent && getDataBindStringOfParent.match('i18n');
      var isTextFromVm = getDataBindStringOfParent && getDataBindStringOfParent.match('text');
      var isHtmlFromVm = getDataBindStringOfParent && getDataBindStringOfParent.match('html');
      var isOjTreeNode = classStringOfParent && classStringOfParent.match('oj-tree');
      var isScript = parentNode.tagName && parentNode.tagName.match('SCRIPT');
      var isStyle = parentNode.tagName && parentNode.tagName.match('STYLE');
      var isOjButton = papaNode && getDataBindStringOfPapa && getDataBindStringOfPapa.match('ojButton');
      var isFormEditorContentEditable= $parentNode.is('.ossa-editor-transformed') || $parentNode.closest('.ossa-editor-transformed').length;
      var isOjComponentOjInputDateTime =  closestOjComponentNodeDataBindString && closestOjComponentNodeDataBindString.match('ojInputDateTime');
      var isRequiredAsterisk =  node.data === '*';
      var isI18nTemplateString = closestDataBindString && closestDataBindString.match(/i18n\s*\:/)


      if ( !isEmpty
        && !isContainsI18nAlready
        && !isTextFromVm
        && !isHtmlFromVm
        && !isOjTreeNode
        && !isScript
        && !isStyle
        && !isOjButton
        && !isFormEditorContentEditable
        && !isOjComponentOjInputDateTime
        && !isRequiredAsterisk
        && !isI18nTemplateString
      ) {
        return NodeFilter.FILTER_ACCEPT;
      }
    }
    },
    false
  );

// Show the content of every non-empty text node that is a child of root
  var node;

  while ((node = nodeIterator.nextNode())) {
    console.log(node.parentNode);
  }
  console.log('-----------------------------------------');
  console.log('');
  console.log('');
  console.log('');
  console.log('');
  console.log('');
  console.log('');
  console.log('-----------------------------------------');

  console.groupEnd();
})();


;(function() {
  console.group('Found element title attribute without i18n');
  var nodeIterator = document.createNodeIterator(
    // Node to use as root
    document.body,

    // Only consider nodes that are text nodes (nodeType 3)
    NodeFilter.SHOW_ELEMENT,

    // Object containing the function to use for the acceptNode method
    // of the NodeFilter
    { acceptNode: function(node) {

      var classString = node.getAttribute('class');
      var dataBindString = node.getAttribute('data-bind');
      var $node = $(node);
      var $closestOjComponentNode = $node.closest('.oj-component-initnode');
      var closestOjComponentNodeDataBindString = $closestOjComponentNode.attr('data-bind');

      var isAlreadyI18nAttr = dataBindString && dataBindString.match('i18n-attr');
      var isTitleFromDataBindAttr = dataBindString && dataBindString.match(/attr\s*\:\s*\{.*title/gm);
      var isHasTitle= node.getAttribute('title');
      var isAppIcon= classString && classString.match('app-icon');
      var isTypedIcon= classString && classString.match('typed-icon');
      var isOjTree= classString && classString.match('oj-tree');
      var isOjComponentOjInputDateTime =  closestOjComponentNodeDataBindString && closestOjComponentNodeDataBindString.match('ojInputDateTime');


      if (
        isHasTitle
        && !isAlreadyI18nAttr
        && !isAppIcon
        && !isTypedIcon
        && !isOjTree
        && !isTitleFromDataBindAttr
        && !isOjComponentOjInputDateTime
      ) {
        return NodeFilter.FILTER_ACCEPT;
      }
    }
    },
    false
  );

// Show the content of every non-empty text node that is a child of root
  var node;

  while ((node = nodeIterator.nextNode())) {
    console.log(node);
  }
  console.groupEnd();
})();