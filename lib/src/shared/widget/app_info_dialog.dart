import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zapcall/assets.dart';

class AppInfoDialog extends HookWidget {
  const AppInfoDialog({
    super.key,
  });

  static const _repoLink = 'https://github.com/albinpk/zapcall';
  static const _linkedLink = 'https://www.linkedin.com/in/albinpk';

  @override
  Widget build(BuildContext context) {
    final result = useMemoized(PackageInfo.fromPlatform);
    final packageInfo = useFuture(result);

    return Dialog(
      child: SizedBox(
        width: 600,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ZapCall',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (packageInfo.hasData) Text('v${packageInfo.data?.version}'),
              const SizedBox(height: 10),
              const Text(
                'ZapCall is a real-time video calling app built with Flutter and '
                'WebRTC, offering seamless, low-latency communication across all platforms.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // me
              Text(
                'Created & Maintained by',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Albin',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => launchUrl(Uri.parse(_repoLink)),
                    icon: SizedBox.square(
                      dimension: 30,
                      child: Image.asset(Assets.icons.githubPNG),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => launchUrl(Uri.parse(_linkedLink)),
                    icon: SizedBox.square(
                      dimension: 30,
                      child: Image.asset(Assets.icons.linkedinPNG),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
