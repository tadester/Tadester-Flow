module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/tests"],
  clearMocks: true,
  restoreMocks: true,
  resetMocks: false,
  moduleFileExtensions: ["ts", "js", "json"],
};
