import 'dart:html' as html;

html.Element? _cursorElement;
String? _previousCursor;
String? _previousPriority;

void setToolbarBrowserCursor(String cursor, double x, double y) {
  // Flutter Web writes its effective cursor to body. The browser can instead
  // hit a text input or semantics element inside flutter-view.
  html.Element? element = html.document.elementFromPoint(x.round(), y.round());
  while (element?.shadowRoot != null) {
    final nested = element!.shadowRoot!.elementFromPoint(x.round(), y.round());
    if (nested == null || identical(nested, element)) break;
    element = nested;
  }
  if (element == null) {
    clearToolbarBrowserCursor();
    return;
  }
  if (!identical(element, _cursorElement)) {
    clearToolbarBrowserCursor();
    _cursorElement = element;
    _previousCursor = element.style.getPropertyValue('cursor');
    _previousPriority = element.style.getPropertyPriority('cursor');
  }
  element.style.setProperty('cursor', cursor, 'important');
}

void clearToolbarBrowserCursor() {
  final element = _cursorElement;
  if (element == null) return;
  if (_previousCursor == null || _previousCursor!.isEmpty) {
    element.style.removeProperty('cursor');
  } else {
    element.style.setProperty('cursor', _previousCursor, _previousPriority);
  }
  _cursorElement = null;
  _previousCursor = null;
  _previousPriority = null;
}
