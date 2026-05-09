// NAME: Christian Spotify
// AUTHOR: khanhas
// DESCRIPTION: Auto skip explicit songs. Toggle in Profile menu.

/// <reference path="../globals.d.ts" />

(async function ChristianSpotify() {
	if (!DT.LocalStorage) {
		setTimeout(ChristianSpotify, 1000);
		return;
	}
	await new Promise((res) => DT.Events.webpackLoaded.on(res));

	let isEnabled = DT.LocalStorage.get("ChristianMode") === "1";

	new DT.Menu.Item("Christian mode", isEnabled, (self) => {
		isEnabled = !isEnabled;
		DT.LocalStorage.set("ChristianMode", isEnabled ? "1" : "0");
		self.setState(isEnabled);
	}).register();

	DT.Player.addEventListener("songchange", () => {
		if (!isEnabled) return;
		const data = DT.Player.data || DT.Queue;
		if (!data) return;

		const isExplicit = data.item.metadata.is_explicit;
		if (isExplicit === "true") {
			DT.Player.next();
		}
	});
})();
