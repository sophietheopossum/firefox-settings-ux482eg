// --- PERFORMANCE TWEAKS (last tested Hellfire 149, nvidia MX450, wayland) ---
user_pref("about.glean.redesign.enabled", true);
user_pref("accessibility.accesskeycausesactivation", false);
user_pref("accessibility.ariaNotify.enabled", false);
user_pref("accessibility.browsewithcaret_shortcut.enabled", false);
user_pref("accessibility.cache.enabled", false);
user_pref("accessibility.force_disabled", 1);
user_pref("accessibility.typeaheadfind.enablesound", false);
user_pref("accessibility.uia.enable", 0);
// Disables internal automatic updates
user_pref("app.update.auto", false);
// Disables the check for updates entirely
user_pref("app.update.enabled", false);
// Set check interval to 10 years to stop background polling
user_pref("app.update.interval", 315360000);
// Stops the background service from checking while the browser is closed
user_pref("app.update.service.enabled", false);
user_pref("app.update.staging.enabled", false);
user_pref("apz.allow_double_tap_zooming", false);
// Allows seamless scroll handoff from sub-elements to the main page
user_pref("apz.allow_immediate_handoff", true);
user_pref("browser.aiwindow.enabled", true);
// Master switch for the native backup system (Disabled)
user_pref("browser.backup.enabled", false);
user_pref("browser.cache.disk.capacity", 4194304);
user_pref("browser.cache.disk.content_type_media_limit", 102400);
user_pref("browser.cache.disk.max_entry_size", 102400);
user_pref("browser.cache.disk.metadata_chunk_size", 512);
// best as EXT4 partition
user_pref("browser.cache.disk.parent_directory", "~/.cache/hellfire-nc");
user_pref("browser.cache.disk.smart_size.enabled", false);
user_pref("browser.cache.max_shutdown_io_lag", 16);
user_pref("browser.cache.memory.capacity", 1048576);
user_pref("browser.gesture.swipe.left", "");
user_pref("browser.gesture.swipe.right", "");
user_pref("browser.tabs.unloadOnLowMemory", true);
user_pref("content.notify.interval", 100000);
//new  ui
user_pref("browser.nova.enabled", true);
// Enables the new native Cookie Banner blocking
user_pref("cookiebanners.service.mode", 1);
user_pref("cookiebanners.service.mode.privateBrowsing", 1);
user_pref("dom.ipc.processCount", 16);
// Dynamic scaling
user_pref("dom.ipc.processCount.webIsolated", -1);
user_pref("dom.webgpu.wgpu-backend", "vulkan");
user_pref("gfx.blithelper.lut-size.rgb.b", 64);
user_pref("gfx.blithelper.lut-size.rgb.g", 64);
user_pref("gfx.blithelper.lut-size.rgb.r", 64);
user_pref("gfx.blithelper.lut-size.ycbcr.cb", 64);
user_pref("gfx.blithelper.lut-size.ycbcr.cr", 64);
user_pref("gfx.blithelper.lut-size.ycbcr.y", 64);
user_pref("gfx.blithelper.precision", 1);
user_pref("gfx.canvas.accelerated.cache-items", 32768);
user_pref("gfx.canvas.accelerated.cache-size", 4096);
user_pref("gfx.canvas.accelerated.force-enabled", true);
user_pref("gfx.canvas.accelerated.gpu-path-complexity", 256);
user_pref("gfx.canvas.accelerated.gpu-path-size", 128);
user_pref("gfx.canvas.accelerated.max-data-shmems", 2048);
user_pref("gfx.canvas.accelerated.max-draw-target-count", 128);
user_pref("gfx.canvas.accelerated.max-export-surfaces", 32);
user_pref("gfx.canvas.accelerated.min-size", 256);
user_pref("gfx.canvas.accelerated.stroke-to-fill-path", true);
user_pref("gfx.canvas.remote.drop-buffer-limit", 100);
user_pref("gfx.canvas.remote.drop-buffer-milliseconds", 10000);
user_pref("gfx.canvas.remote.event-timeout-ms", 5);
user_pref("gfx.content.skia-font-cache-size", 80);
user_pref("gfx.webgpu.ignore-blocklist", true);
user_pref("gfx.webrender.all", true);
user_pref("gfx.webrender.batched-texture-uploads", true);
user_pref("gfx.webrender.batching.lookback", 20);
user_pref("gfx.webrender.layer-compositor", true);
user_pref("gfx.webrender.precache-shaders", true);
user_pref("gfx.webrender.quality.force-subpixel-aa-where-possible", true);
user_pref("image.cache.size", 104857600);
user_pref("image.mem.max_decoded_image_kb", 512000);
user_pref("layers.acceleration.force-enabled", true);
user_pref("layers.gpu-process.max_restarts", 20);
user_pref("layers.gpu-process.stable.min-uptime-ms", 2000);
// AV1 is heavy; disable to force VP9/H264
user_pref("media.av1.enabled", false);
user_pref("media.ffmpeg.allow-openh264", true);
user_pref("media.ffmpeg.disable-software-fallback", true);
user_pref("media.hardware-video-decoding.force-enabled", true);
user_pref("media.hardware-video-encoding.force-enabled", true);
user_pref("media.navigator.mediadatadecoder_vp8_hardware_enabled", true);
user_pref("network.dns.localDomains", "localhost");
user_pref("network.dnsCacheEntries", 1000);
user_pref("network.http.max-connections", 1800);
user_pref("network.http.max-persistent-connections-per-server", 10);
user_pref("network.http.pacing.requests.enabled", false);
user_pref("network.lna.block_trackers", true);
user_pref("privacy.trackingprotection.content.protection.enabled", true);
user_pref("privacy.trackingprotection.content.protection.test_list_urls", "https://easylist.to/easylist/easylist.txt|https://easylist.to/easylist/easyprivacy.txt|https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/unbreak.txt|https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/privacy.txt|https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/badware.txt|https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/filters.txt|https://raw.githubusercontent.com/uBlockOrigin/uAssets/refs/heads/master/filters/quick-fixes.txt|https://malware-filter.gitlab.io/malware-filter/urlhaus-filter-online.txt")
user_pref("webgl.1.allow-core-profiles", true);
user_pref("webgl.allow-fb-invalidation", true);
user_pref("webgl.allow-immediate-queries", true);
user_pref("webgl.auto-flush.gl", true);
//only good for windows
user_pref("webgl.disable-angle", true);
user_pref("webgl.enable-draft-extensions", true);
user_pref("webgl.enable-privileged-extensions", true);
user_pref("webgl.force-enabled", true);
user_pref("webgl.max-contexts-per-principal", 100);
user_pref("webgl.msaa-force", true);
user_pref("webgl.msaa-samples", 8);
user_pref("webgl.out-of-process.shmem-size", 1048576);
user_pref("widget.disable-swipe-tracker", true);
user_pref("widget.wayland.vsync.enabled", false);

// Hardware Handshake (Fixes the dmabuf SIGSEGV, default behaviour for now)
//user_pref("gfx.webrender.compositor", false);
//user_pref("gfx.x11-egl.force-enabled", false);

//TODO
//gfx?
//dom?
//image?
//browser.cache
//media?
//widget????????????
//network?
//layers?
//browser?
