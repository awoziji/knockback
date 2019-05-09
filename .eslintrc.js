module.exports = {
  extends: ['airbnb-base', 'prettier'],
  plugins: ['import'],
  parser: 'babel-eslint',
  env: {
    browser: true,
    es6: true,
    node: true,
    mocha: true
  },
  rules: {
    'max-len': ['error', 200, 2],
    'comma-dangle': 'off',
    'no-underscore-dangle': 'off',
    'prefer-destructuring': 'off',
    'import/no-unresolved': 'off',
    'global-require': 'off',
    'no-nested-ternary': 'off',
    'import/no-extraneous-dependencies': 'off',
    'no-plusplus': 'off',
    'class-methods-use-this': 'off',
    'no-bitwise': 'off',
    'no-use-before-define': 'off',
    'no-new': 'off',
    'func-names': 'off',
    'no-param-reassign': 'off',
    'no-unused-expressions': 'off',
    'no-new-func': 'off',
    'no-restricted-syntax': ['off', "BinaryExpression[operator='in']"],
    'no-console': 'off',
    'no-debugger': 'warn',
    'new-cap': 'off',
    'no-undef': 'off',
    'no-await-in-loop': 'off',
    'import/no-dynamic-require': 'off',

    camelcase: 'off'
  }
};
