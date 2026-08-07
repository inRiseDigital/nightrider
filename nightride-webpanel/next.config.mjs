/** @type {import('next').NextConfig} */
const nextConfig = {
  // The panel is entirely client-side (Firebase runs in the browser, no route
  // handlers or server actions), so we emit a plain static site into `out/`.
  // Netlify publishes that folder directly — see netlify.toml at the repo root.
  output: "export",

  // Static export has no server, so the Image Optimization API is unavailable.
  images: { unoptimized: true },

  // Emit `admin/dashboard/index.html` rather than `admin/dashboard.html`, so
  // Netlify resolves `/admin/dashboard` without a trailing-slash redirect.
  trailingSlash: true,
};

export default nextConfig;
