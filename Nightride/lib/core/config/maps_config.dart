/// Google Maps API key — injected at build time via local.properties.
/// See android/local.properties.example for setup instructions.
const String kGoogleMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: '',
);

/// Yelp Fusion API key — free tier, 500 calls/day, no credit card.
/// Get yours at: https://docs.developer.yelp.com/
/// Add to your .env as: YELP_API_KEY=your_key_here
const String kYelpApiKey = String.fromEnvironment(
  'YELP_API_KEY',
  defaultValue: '',
);
