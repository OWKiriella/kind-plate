import 'package:flutter/material.dart';
import '../utils/app_localizations.dart';

//Widgets that show translated text using AppLocalizations

class TranslatedText extends StatefulWidget {
  final String text;
  final String? translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;

  const TranslatedText(
    this.text, {
    Key? key,
    this.translationKey,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
  }) : super(key: key);

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String? _translatedText;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _translateText();
  }

  @override
  void didUpdateWidget(TranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.translationKey != widget.translationKey) {
      _translateText();
    }
  }

  Future<void> _translateText() async {
    final localizations = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final key = widget.translationKey ?? widget.text;
      final translated = await localizations.translate(
        key,
        fallbackText: widget.text,
      );

      if (mounted) {
        setState(() {
          _translatedText = translated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translatedText = widget.text;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we're still loading or haven't started translation yet,
    // show the original text
    final displayText = _translatedText ?? widget.text;

    return Text(
      displayText,
      style: widget.style,
      textAlign: widget.textAlign,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
      softWrap: widget.softWrap,
    );
  }
}

// A version of the widget that doesn't depend on a StatefulWidget
// Good for places where text doesn't change frequently
class FutureTranslatedText extends StatelessWidget {
  final String text;
  final String? translationKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;

  const FutureTranslatedText(
    this.text, {
    Key? key,
    this.translationKey,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return FutureBuilder<String>(
      future: localizations.translate(
        translationKey ?? text,
        fallbackText: text,
      ),
      initialData: text,
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? text,
          style: style,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
          softWrap: softWrap,
        );
      },
    );
  }
}
