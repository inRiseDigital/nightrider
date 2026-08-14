import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: false,
    testTimeout: 30000,
    hookTimeout: 30000,
    teardownTimeout: 30000,
    // Tests share documents/paths across a single running emulator instance
    // (started once by `firebase emulators:exec`), so they must not race each
    // other: force one worker, one file at a time, no test-level concurrency.
    fileParallelism: false,
    pool: 'threads',
    poolOptions: {
      threads: {
        singleThread: true,
      },
    },
    sequence: {
      concurrent: false,
    },
  },
});
