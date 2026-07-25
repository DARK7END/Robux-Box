module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/src"],
  testMatch: ["**/__tests__/**/*.test.ts"],
  // Economy math is pure; other modules require the Admin SDK and are covered by
  // emulator integration tests, not unit tests.
};
