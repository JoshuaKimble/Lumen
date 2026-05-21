import '../../profiles/domain/rewrite_tone_preference.dart';

class RewritePersonalization {
  const RewritePersonalization({
    required this.rewriteTone,
    required this.preserveVoice,
  });

  static const defaults = RewritePersonalization(
    rewriteTone: RewriteTonePreference.balanced,
    preserveVoice: true,
  );

  final RewriteTonePreference rewriteTone;
  final bool preserveVoice;

  Map<String, Object?> toApiJson() {
    return {
      'rewriteTone': rewriteTone.storageValue,
      'preserveVoice': preserveVoice,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is RewritePersonalization &&
        other.rewriteTone == rewriteTone &&
        other.preserveVoice == preserveVoice;
  }

  @override
  int get hashCode => Object.hash(rewriteTone, preserveVoice);
}
