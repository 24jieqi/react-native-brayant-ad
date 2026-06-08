module.exports = {
  dependencies: {
    'react-native-brayant-ad': {
      platforms: {
        android: {
          sourceDir: '../android',
          packageImportPath: "import BrayantAd from 'react-native-brayant-ad';",
          packageInstance: 'new BrayantAdPackage()',
        },
      },
    },
  },
};
