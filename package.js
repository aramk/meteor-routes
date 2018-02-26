// Meteor package definition.
Package.describe({
  name: 'aramk:routes',
  version: '1.0.0',
  summary: 'Convenient utilities for setting up routes for a Meteor app.',
  git: 'https://github.com/aramk/meteor-routes.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.6.1');
  api.use([
    'coffeescript',
    'underscore',
    'reactive-var@1.0.5',
    'aramk:q@1.0.1',
    'iron:router@1.0.13',
    'urbanetic:utility@2.0.0'
  ], 'client');
  api.imply('iron:router');
  api.export('Routes', 'client');
  api.addFiles([
    'src/Routes.coffee'
  ], 'client');
});
