/// The three addresses this app links out to, and the one way it opens them.
///
/// **They are in the binary because a rejection put them there** (D384). Apple
/// refused 0.1.3 (10) under guideline 3.1.2(c) on 2026-09-07: an app selling an
/// auto-renewing subscription must carry a functional link to the privacy
/// policy and to the Terms of Use *inside the app*, not only in the store
/// listing. 0.1.2 was refused under the same guideline for the metadata half
/// and fixed there; `doc/store-listing.md` then recorded the requirement as
/// being about "the product page, not the privacy-policy field and nothing in
/// the binary", which is the sentence this file corrects.
///
/// Opening a link needs no `INTERNET` permission and must not introduce one.
/// A VIEW intent hands the address to whichever app already owns browsing, and
/// this bundle still strips the permission from the merge (D357).
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/app_localizations.dart';

/// Where the privacy policy lives.
///
/// The same address is in App Store Connect's privacy field and in
/// `doc/store-listing.md`. Three places, one string, and nothing keeps them in
/// step but this comment — the same shape of gap that D381 closed for the
/// product names.
const String kPrivacyPolicyUrl =
    'https://evict.nl/quadrim/quadrim-privacy-policy';

/// **Apple's standard EULA**, deliberately, rather than a custom one: a custom
/// agreement is a document to keep correct in two languages forever, in
/// exchange for terms this game has no need to vary (store-listing, Terms).
const String kTermsUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

/// The support page. Not a legal requirement, but the third thing a reviewer
/// and a stuck player both look for.
const String kSupportUrl = 'https://evict.nl/quadrim';

/// How a link is actually opened.
///
/// A variable rather than a direct call so a widget test can replace it. There
/// is no browser and no platform channel behind `url_launcher` under
/// `flutter_test`, so a tap would throw `MissingPluginException` and the test
/// would be asserting the plugin rather than the screen.
@visibleForTesting
Future<bool> Function(Uri url) launchExternalUrl =
    (url) => launchUrl(url, mode: LaunchMode.externalApplication);

/// One row that opens [url], and says so when it cannot.
///
/// **The failure is spoken rather than swallowed.** A link that does nothing
/// when tapped is precisely what guideline 3.1.2(c) means by a link that is not
/// functional, and it fails exactly that way on a device with no browser, or if
/// the VIEW query intent ever leaves the Android manifest — neither of which
/// looks like anything at the call site.
class LinkTile extends StatelessWidget {
  const LinkTile({
    super.key,
    required this.icon,
    required this.title,
    required this.url,
  });

  final IconData icon;
  final String title;
  final String url;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        // Decorative: the row already announces where it goes by its title,
        // and a second node reading "open in new" adds nothing by ear.
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => _open(context),
      );

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchExternalUrl(Uri.parse(url));
    } catch (_) {
      // Whatever the platform threw, the player's answer is the same.
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.linkFailed)));
    }
  }
}
