import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_trailing.dart';
import 'package:appflowy/shared/version_checker/version_checker.dart';
import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/feature_flags/mobile_feature_flag_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/widgets.dart';

class AboutSettingGroup extends StatelessWidget {
  const AboutSettingGroup({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MobileSettingGroup(
      groupTitle: LocaleKeys.settings_mobile_about.tr(),
      settingItemList: [
        MobileSettingItem(
          name: LocaleKeys.settings_mobile_privacyPolicy.tr(),
          trailing: MobileSettingTrailing(
            text: '',
          ),
          onTap: () => afLaunchUrlString('https://appflowy.com/privacy'),
        ),
        MobileSettingItem(
          name: LocaleKeys.settings_mobile_termsAndConditions.tr(),
          trailing: MobileSettingTrailing(
            text: '',
          ),
          onTap: () => afLaunchUrlString('https://appflowy.com/terms'),
        ),
        if (kDebugMode)
          MobileSettingItem(
            name: 'Feature Flags',
            trailing: MobileSettingTrailing(
              text: '',
            ),
            onTap: () {
              context.push(FeatureFlagScreen.routeName);
            },
          ),
        MobileSettingItem(
          name: LocaleKeys.settings_mobile_version.tr(),
          trailing: MobileSettingTrailing(
            text:
                '${ApplicationInfo.applicationVersion} (${ApplicationInfo.buildNumber})',
          ),
          onTap: () async {
            final latest = await versionChecker.fetchLatestVersion();
            if (!context.mounted) {
              return;
            }
            if (latest != null) {
              ApplicationInfo.latestVersionNotifier.value = latest;
            }
            final newer = ApplicationInfo.isUpdateAvailable;
            final install = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(newer ? 'Update ready' : 'Up to date'),
                content: Text(
                  newer
                      ? 'Nota $latest is ready. Download it and tap Install.'
                      : 'Nota ${ApplicationInfo.applicationVersion} is the latest.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Close'),
                  ),
                  if (newer)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Download'),
                    ),
                ],
              ),
            );
            if (install == true) {
              await versionChecker.checkForUpdate();
            }
          },
        ),
      ],
    );
  }
}
