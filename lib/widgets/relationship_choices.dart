import '../l10n/app_localizations.dart';

/// Backend-stable relationship keys with localized labels.
class RelationshipChoices {
  static const familyMemberKeys = ['Parent', 'Spouse', 'Child', 'Sibling', 'Other'];
  static const inviteKeys = [
    'Mother',
    'Father',
    'Brother',
    'Sister',
    'Spouse',
    'Child',
    'Friend',
    'Other',
  ];

  static String label(AppLocalizations l10n, String key) {
    switch (key) {
      case 'Parent':
        return l10n.relationshipParent;
      case 'Sibling':
        return l10n.relationshipSibling;
      case 'Mother':
        return l10n.relationshipMother;
      case 'Father':
        return l10n.relationshipFather;
      case 'Brother':
        return l10n.relationshipBrother;
      case 'Sister':
        return l10n.relationshipSister;
      case 'Spouse':
        return l10n.relationshipSpouse;
      case 'Child':
        return l10n.relationshipChild;
      case 'Friend':
        return l10n.relationshipFriend;
      default:
        return l10n.relationshipOther;
    }
  }
}
