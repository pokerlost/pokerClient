{{flutter_js}}
{{flutter_build_config}}
const assetBase = new URL('.', document.currentScript.src).href;
const config = {multiViewEnabled: true, assetBase, entrypointBaseUrl: assetBase, canvasKitBaseUrl: assetBase + 'canvaskit/'};
globalThis.pokerFlutter = new Promise((resolve, reject) => {
  _flutter.loader.load({
    config,
    onEntrypointLoaded: async (initializer) => {
      try {
        const runner = await initializer.initializeEngine(config);
        resolve(await runner.runApp());
      } catch (error) { reject(error); }
    },
  }).catch(reject);
});
