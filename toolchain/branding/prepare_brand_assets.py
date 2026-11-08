#!/usr/bin/env python3
"""Package the approved Miora v2 artwork for Flutter, Android and iOS (macOS)."""
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / 'design/branding/miora-v2'


def resize(source, target, width, height=None):
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['sips', '-z', str(height or width), str(width),
                    str(source), '--out', str(target)], check=True,
                   stdout=subprocess.DEVNULL)


def main():
    logo = MASTER / 'logo-master.png'
    lockup = MASTER / 'launch-lockup.png'
    resize(logo, ROOT / 'biz/assets/brand/miora-logo-v2.png', 512)
    for module in ('debug', 'dis'):
        res = ROOT / module / 'android/app/src/main/res'
        for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                              ('xxhdpi', 144), ('xxxhdpi', 192)]:
            resize(logo, res / f'mipmap-{density}/miora_launcher.png', size)
        # At xxxhdpi this lockup has an intrinsic size of 240 x 286 dp.
        resize(lockup, res / 'drawable-xxxhdpi/miora_launch_lockup.png', 960, 1145)
        catalog = ROOT / module / 'ios/Runner/Assets.xcassets'
        resize(logo, catalog / 'AppIcon.appiconset/miora_v2_1024.png', 1024)
        contents_path = catalog / 'AppIcon.appiconset/Contents.json'
        contents = json.loads(contents_path.read_text())
        contents['images'][0]['filename'] = 'miora_v2_1024.png'
        contents_path.write_text(json.dumps(contents, indent=2) + '\n')
        launch = catalog / 'MioraLaunchV2.imageset'
        launch.mkdir(parents=True, exist_ok=True)
        for scale in (1, 2, 3):
            resize(lockup, launch / f'miora-launch@{scale}x.png', 240 * scale, 286 * scale)
        (launch / 'Contents.json').write_text(json.dumps({
            'images': [{'idiom': 'universal', 'scale': f'{scale}x',
                        'filename': f'miora-launch@{scale}x.png'} for scale in (1, 2, 3)],
            'info': {'author': 'xcode', 'version': 1}
        }, indent=2) + '\n')


if __name__ == '__main__':
    main()
