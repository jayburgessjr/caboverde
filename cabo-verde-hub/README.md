# Cabo Verde Hub — Roku Channel

GitHub-ready project for a Roku SceneGraph channel. Includes scripts to build a sideload zip and CI to produce a zip artifact. Packaging into a signed `.pkg` must be done on a Roku device.

## Use with GitHub and VS Code

1. Create an empty repo on GitHub.
2. Download this starter zip and unzip: `cabo-verde-hub/`
3. Initialize and push:
   ```bash
   cd cabo-verde-hub
   git init
   git add -A
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/<your-username>/<your-repo>.git
   git push -u origin main
   ```
4. Open in VS Code and accept recommended extensions.

## Build a sideload zip

```bash
./scripts/zip.sh
# Output: dist/cabo-verde-hub.zip
```

## Sideload to Roku Dev Installer

```bash
export ROKU_IP=192.168.1.50
export DEV_WEB_PASSWORD='your-dev-web-password'
./scripts/sideload.sh ./dist/cabo-verde-hub.zip
```

Or upload the zip via `http://$ROKU_IP` in your browser.

## Package on the device

Use the Packager on the Dev Installer page to generate the signed `.pkg`. Enter the `genkey` password, choose Squashfs (OS 8.0+), and download the `.pkg`.

## Layout

- manifest
- source/
- components/
- images/
- scripts/
- .github/workflows/build-zip.yml
