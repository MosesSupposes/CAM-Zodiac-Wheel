const { copyFileSync, mkdirSync } = require("node:fs");
const path = require("node:path");

module.exports = {
  base: "./",
  build: {
    target: "esnext",
    assetsDir: ".",
    rollupOptions: {
      input: {
        index: path.resolve(__dirname, "Your zodiac wheel.html"),
        "chart-insights": path.resolve(__dirname, "chart-insights.html")
      }
    }
  },
  plugins: [{
    name: "copy-static-runtime-assets",
    configureServer(server) {
      server.middlewares.use((request, response, next) => {
        if (request.url === "/") request.url = "/Your%20zodiac%20wheel.html";
        next();
      });
    },
    writeBundle(outputOptions) {
      const outputDir = outputOptions.dir || path.resolve(__dirname, "dist");
      const wasmDir = path.join(outputDir, "wasm");
      mkdirSync(wasmDir, { recursive: true });
      copyFileSync(path.resolve(__dirname, "elm.js"), path.join(outputDir, "elm.js"));
      copyFileSync(
        path.resolve(__dirname, "node_modules/@astrologer/ephemera/wasm/ephemeris-1as.wasm"),
        path.join(wasmDir, "ephemeris-1as.wasm")
      );
      copyFileSync(
        path.join(outputDir, "Your zodiac wheel.html"),
        path.join(outputDir, "index.html")
      );
    }
  }]
};