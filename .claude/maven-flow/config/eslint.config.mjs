// ============================================================================
// MAVEN ESLINT CONFIGURATION
// Feature-based architecture enforcement with eslint-plugin-boundaries
// ============================================================================

import boundaries from 'eslint-plugin-boundaries';

export default [
  {
    plugins: {
      boundaries,
    },
    rules: {
      // Enforce entry points
      'boundaries/entry-point': [
        'error',
        {
          'default': 'disallow',
          'rules': [
            {
              'default': 'allow',
              'match': {
                'types': ['shared'],
                'modes': ['direct'],
              },
            },
            {
              'default': 'allow',
              'match': {
                'types': ['features'],
                'from': ['app', 'features'],
              },
            },
          ],
        },
      ],

      // No unknown files (everything must be categorized)
      'boundaries/no-unknown-files': [
        'error',
        {
          'default': 'disallow',
          'allow': ['types', 'features', 'shared', 'app'],
        },
      ],

      // No unknown types (all imports must be categorized)
      'boundaries/no-unknown': [
        'error',
        {
          'default': 'disallow',
          'allow': ['types', 'features', 'shared', 'app'],
        },
      ],

      // Import rules - enforce one-way data flow
      'boundaries/allow': [
        'error',
        {
          'default': 'disallow',
          'rules': [
            // Shared can only import from shared
            {
              'from': 'shared',
              'allow': ['shared'],
            },
            // Features can import from shared and their own feature
            {
              'from': 'features',
              'allow': ['features', 'shared'],
            },
            // App can import from features and shared
            {
              'from': 'app',
              'allow': ['features', 'shared'],
            },
          ],
        },
      ],

      // Disallow cross-feature imports
      'boundaries/disallow': [
        'error',
        {
          'default': 'allow',
          'rules': [
            {
              'from': 'features',
              'disallow': ['features'],
              'message': 'Cross-feature imports not allowed. Use shared/ or move to shared.',
            },
            {
              'from': 'shared',
              'disallow': ['features', 'app'],
              'message': 'Shared code cannot import from features or app.',
            },
          ],
        },
      ],
    },

    settings: {
      'boundaries/elements': [
        // Type: Shared - Global code used by all features
        {
          'type': 'shared',
          'mode': 'file',
          'pattern': 'src/shared/**/*',
          'capture': ['shared'],
        },

        // Type: Features - Feature-specific isolated code
        {
          'type': 'features',
          'mode': 'folder',
          'pattern': 'src/features/**/*',
          'capture': ['feature'],
        },

        // Type: App - Route pages and layouts
        {
          'type': 'app',
          'mode': 'file',
          'pattern': 'src/app/**/*',
        },

        // Type: Types - Global type definitions
        {
          'type': 'types',
          'mode': 'file',
          'pattern': 'src/types/**/*',
        },
      ],
    },
  },

  // TypeScript rules
  {
    files: ['**/*.ts', '**/*.tsx'],
    rules: {
      // Disallow 'any' types
      '@typescript-eslint/no-explicit-any': 'error',

      // Enforce return types
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',

      // Type checking
      '@typescript-eslint/no-unsafe-assignment': 'warn',
      '@typescript-eslint/no-unsafe-member-access': 'warn',
      '@typescript-eslint/no-unsafe-call': 'warn',
      '@typescript-eslint/no-unsafe-return': 'warn',
    },
  },

  // React rules
  {
    files: ['**/*.jsx', '**/*.tsx'],
    rules: {
      'react/jsx-no-leaked-render': 'error',
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
    },
  },

  // Import rules
  {
    rules: {
      // Disallow relative imports (enforce @ aliases)
      'no-restricted-imports': [
        'error',
        {
          'patterns': [
            {
              'group': ['../*', '../../*'],
              'message': 'Use @ path aliases instead of relative imports.',
            },
          ],
        },
      ],
    },
  },
];
