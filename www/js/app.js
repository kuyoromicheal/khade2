async function initNativeApp() {
  const Cap = window.Capacitor;
  if (!Cap?.isNativePlatform?.()) return;

  document.body.classList.add('native-app');

  try {
    const { StatusBar, Style } = Cap.Plugins;
    if (StatusBar) {
      await StatusBar.setStyle({ style: Style?.Light ?? 'LIGHT' });
      await StatusBar.setBackgroundColor({ color: '#2d5c3f' });
    }
    if (Cap.Plugins.SplashScreen) {
      await Cap.Plugins.SplashScreen.hide();
    }
  } catch (_) {
    /* plugins optional */
  }
}

initNativeApp();
