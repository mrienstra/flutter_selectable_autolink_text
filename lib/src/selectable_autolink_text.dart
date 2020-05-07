import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'autolink_utils.dart';
import 'highlighted_text_span.dart';
import 'link_attr.dart';
import 'selectable_text_ex.dart';
import 'tap_and_long_press.dart';
import 'text_element.dart';

typedef OnOpenLinkFunction = void Function(String link);
typedef OnTransformLinkFunction = String Function(String link);
typedef OnTransformLinkAttributeFunction = LinkAttribute Function(String text);
typedef OnDebugMatchFunction = void Function(Match match);

class AutoLinkText extends StatefulWidget {
  /// Text to be auto link
  final String text;

  /// Regular expression for link
  /// If null, defaults RegExp([AutoLinkUtils._defaultLinkRegExpPattern]).
  final RegExp linkRegExp;

  /// Transform the display of Link
  /// Called when Link is displayed
  final OnTransformLinkAttributeFunction onTransformDisplayLink;

  /// Called when the user taps on link.
  final OnOpenLinkFunction onTap;

  /// Called when the user long-press on link.
  final OnOpenLinkFunction onLongPress;

  /// Style of link text
  final TextStyle linkStyle;

  /// Style of highlighted link text
  final TextStyle highlightedLinkStyle;

  /// {@macro flutter.widget.Text.style}
  final TextStyle style;

  /// {@macro flutter.widget.Text.strutStyle}
  final StrutStyle strutStyle;

  /// {@macro flutter.widget.Text.textAlign}
  final TextAlign textAlign;

  /// {@macro flutter.widget.Text.textDirection}
  final TextDirection textDirection;

  /// {@macro flutter.widget.Text.maxLines}
  final int maxLines;

  /// {@macro flutter.widget.Text.textWidthBasis}
  final TextWidthBasis textWidthBasis;

  /// For debugging linkRegExp
  final OnDebugMatchFunction onDebugMatch;

  AutoLinkText(
    this.text, {
    Key key,
    String linkRegExpPattern,
    this.onTransformDisplayLink,
    this.onTap,
    this.onLongPress,
    this.linkStyle,
    this.highlightedLinkStyle,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.textWidthBasis,
    this.onDebugMatch,
  })  : linkRegExp =
            RegExp(linkRegExpPattern ?? AutoLinkUtils.defaultLinkRegExpPattern),
        super(key: key);

  @override
  _AutoLinkTextState createState() => _AutoLinkTextState();
}

class _AutoLinkTextState extends State<AutoLinkText> {
  final _gestureRecognizers = <TapAndLongPressGestureRecognizer>[];

  @override
  void dispose() {
    _clearGestureRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: _createTextSpans(),
      ),
      style: widget.style,
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      maxLines: widget.maxLines,
      textWidthBasis: widget.textWidthBasis,
    );
  }

  List<TextElement> _generateElements(String text) {
    if (text.isNotEmpty != true) return [];

    final elements = <TextElement>[];

    final matches = widget.linkRegExp.allMatches(text);

    if (matches.isEmpty) {
      elements.add(TextElement(
        type: TextElementType.text,
        text: text,
      ));
    } else {
      var index = 0;
      matches.forEach((match) {
        if (widget.onDebugMatch != null) {
          widget.onDebugMatch(match);
        }

        if (match.start != 0) {
          elements.add(TextElement(
            type: TextElementType.text,
            text: text.substring(index, match.start),
          ));
        }
        elements.add(TextElement(
          type: TextElementType.link,
          text: match.group(0),
        ));
        index = match.end;
      });

      if (index < text.length) {
        elements.add(TextElement(
          type: TextElementType.text,
          text: text.substring(index),
        ));
      }
    }

    return elements;
  }

  List<TextSpan> _createTextSpans() {
    _clearGestureRecognizers();
    return _generateElements(widget.text).map(
      (e) {
        var isLink = e.type == TextElementType.link;
        final linkAttr = (isLink && widget.onTransformDisplayLink != null)
            ? widget.onTransformDisplayLink(e.text)
            : null;
        final link = linkAttr != null ? linkAttr?.link : e.text;
        isLink &= link != null;

        return HighlightedTextSpan(
          text: linkAttr?.text ?? e.text,
          style: linkAttr?.style ?? (isLink ? widget.linkStyle : widget.style),
          highlightedStyle: isLink
              ? (linkAttr?.highlightedStyle ?? widget.highlightedLinkStyle)
              : null,
          recognizer: isLink ? _createGestureRecognizer(link) : null,
        );
      },
    ).toList();
  }

  TapAndLongPressGestureRecognizer _createGestureRecognizer(String link) {
    if (widget.onTap == null && widget.onLongPress == null) {
      return null;
    }
    final recognizer = TapAndLongPressGestureRecognizer();
    _gestureRecognizers.add(recognizer);
    if (widget.onTap != null) {
      recognizer.onTap = () => widget.onTap(link);
    }
    if (widget.onLongPress != null) {
      recognizer.onLongPress = () => widget.onLongPress(link);
    }
    return recognizer;
  }

  void _clearGestureRecognizers() {
    _gestureRecognizers.forEach((r) => r.dispose());
    _gestureRecognizers.clear();
  }
}
