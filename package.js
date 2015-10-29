// Meteor package definition.
Package.describe({
  name: 'aramk:routes',
  version: '0.2.2',
  summary: 'Convenient utilities for setting up routes for a Meteor app.',
  git: 'https://github.com/aramk/meteor-routes.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@0.9.0');
  api.use([
    'coffeescript',
    'underscore',
    'reactive-var@1.0.5',
    'aramk:q@1.0.1',
    'aramk:utility@0.8.3',
    'iron:router@1.0.7'
  ], 'client');
  api.imply('iron:router');
  api.export('Routes', 'client');
  api.addFiles([
    'src/Routes.coffee'
  ], 'client');
});
