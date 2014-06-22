path = require 'path'
_ = require 'underscore'
es = require 'event-stream'
Queue = require 'queue-async'

gulp = require 'gulp'
gutil = require 'gulp-util'
coffee = require 'gulp-coffee'
compile = require 'gulp-compile-js'
modules = require 'gulp-module-system'
rename = require 'gulp-rename'
uglify = require 'gulp-uglify'
header = require 'gulp-header'
mochaPhantomJS = require 'gulp-mocha-phantomjs'
concat = require 'gulp-concat'
shell = require 'gulp-shell'

HEADER = """
/*
  <%= file_name %>
  (c) 2011-2014 Kevin Malakoff.
  Knockback is freely distributable under the MIT license.
  See the following for full license details:
    https://github.com/kmalakoff/knockback/blob/master/LICENSE
  Dependencies: Knockout.js, Backbone.js, and Underscore.js.
    Optional dependency: Backbone.ModelRef.js.
*/\n
"""

moduleToBuildOptions = (module) -> {paths: ["src/#{module}/**/*.coffee"], modules: {type: 'local-shim', file_name: "knockback-#{module}.js", umd: {symbol: "knockback-#{module}", dependencies: ['knockback']}}, destination: './lib/'}

MODULES = ['defaults', 'formatting', 'localization', 'triggering', 'validation']
LIBRARIES = (moduleToBuildOptions(module) for module in MODULES)
LIBRARIES.push moduleToBuildOptions('statistics')

# core and full variants
STACK_PATHS = ['node_modules/underscore/underscore.js', 'node_modules/backbone/backbone.js', 'node_modules/knockout/build/output/knockout-latest.debug.js']
MODULE_ADD_PATHS = _.flatten((["src/#{module}/**/*.coffee", "!src/#{module}/index.coffee"] for module in MODULES))
LIBRARIES.push {paths: ['src/core/**/*.coffee'], modules: {type: 'local-shim', file_name: 'knockback-core.js', umd: {symbol: 'kb', dependencies: ['underscore', 'backbone', 'knockout']}}, destination: './', stack_file_name: 'knockback-core-stack.js'}
LIBRARIES.push {paths: ['src/core/**/*.coffee'].concat(MODULE_ADD_PATHS), modules: {type: 'local-shim', file_name: 'knockback.js', umd: {symbol: 'kb', dependencies: ['underscore', 'backbone', 'knockout']}}, destination: './', stack_file_name: 'knockback-full-stack.js'}

ALL_LIBRARY_FILES = (path.join(library.destination, library.modules.file_name) for library in LIBRARIES)
ALL_LIBRARY_FILES.push path.join(library.destination, library.stack_file_name) for library in LIBRARIES when library.stack_file_name
ALL_LIBRARY_FILES.push library.replace('.js', '.min.js') for library in ALL_LIBRARY_FILES

copyLibraryFiles = (destination, callback) ->
  gulp.src(ALL_LIBRARY_FILES)
    .pipe(gulp.dest((file) -> path.join(destination, path.dirname(file.path).replace(__dirname, '')))).on 'end', callback

cachedBuild = (library) ->
  root_paths = (root_path.replace('/**/*.coffee', '') for root_path in library.paths when root_path.indexOf('/**/*.coffee') >= 0)
  return gulp.src(library.paths)
    .pipe(es.map (file, callback) -> file.path = file.path.replace("#{path.resolve(dir)}/", '') for dir in root_paths; callback(null, file))
    .pipe(compile({coffee: {bare: true}}))
    .pipe(modules(library.modules))
    .pipe(es.map((file, callback) -> console.log "Compiled #{library.modules.file_name}"; callback(null, file)))

cachedStackBuild = (library) ->
  es.merge(gulp.src(STACK_PATHS), cachedBuild(library))
    .pipe(concat(library.stack_file_name))

buildLibrary = (library, callback) ->
  helper = (stream, file_name, callback) ->
    stream
      .pipe(header(HEADER, {file_name: file_name}))
      .pipe(gulp.dest(library.destination))
      .on 'end', callback

  queue = new Queue(1)
  queue.defer (callback) -> helper(cachedBuild(library), library.modules.file_name, callback)
  queue.defer (callback) -> helper(cachedStackBuild(library), library.stack_file_name, callback) if library.stack_file_name
  queue.await (err) -> callback?(err)

minifyLibrary = (library, callback) ->
  helper = (stream, file_name, callback) ->
    stream
      .pipe(uglify())
      .pipe(rename({suffix: '.min'}))
      .pipe(header(HEADER, {file_name: file_name}))
      .pipe(gulp.dest(library.destination))
      .on 'end', callback

  queue = new Queue(1)
  queue.defer (callback) -> helper(cachedBuild(library), library.modules.file_name, callback)
  queue.defer (callback) -> helper(cachedStackBuild(library), library.stack_file_name, callback) if library.stack_file_name
  queue.await (err) -> callback?(err)

gulp.task 'build', -> LIBRARIES.map buildLibrary
gulp.task 'watch', ['build'], -> LIBRARIES.map (library) -> gulp.watch library.paths, -> buildLibrary(library)
gulp.task 'minify', -> LIBRARIES.map (library) -> minifyLibrary(library, ->)
gulp.task 'update_packages', ->
  queue = new Queue(1)
  queue.defer (callback) -> copyLibraryFiles('packages/npm', callback)
  queue.defer (callback) -> copyLibraryFiles('packages/nuget/Content/Scripts', callback)
  queue.await (err) ->
gulp.task 'release', ['build', 'minify', 'update_packages'], ->

gulp.task 'build_tests', ->
  queue = new Queue(1)
  queue.defer (callback) -> buildLibrary {paths: ["test/_examples/**/*.coffee"], modules: {type: 'local-shim', file_name: "_localization_examples.js", umd: {symbol: "knockback-locale-manager", dependencies: ['knockback']}}, destination: './test/_examples/build'}, callback
  queue.defer (callback) ->
    gulp.src('test/**/_bundle-config.coffee')
      .pipe(shell(['./node_modules/.bin/mbundle <%= file.path %>']))
      .on 'end', callback

  queue.defer (callback) ->
    gulp.src('test/**/test*.coffee')
      .pipe(compile({coffee: {bare: true}}))
      .pipe(rename (file_path) -> file_path.dirname += '/build'; file_path)
      .pipe(es.map((file, callback) -> console.log "Compiled #{file.path.split('/').slice(-4).join('/')}"; callback(null, file)))
      .pipe(gulp.dest('./test'))
      .on 'end', callback
  queue.await (err) ->

gulp.task 'test', ['release', 'build_tests'], ->
  gulp.src(['test/**/*.html', '!test/all_tests.html', '!test/issues/**/*.html', '!test/interactive/**/*.html'])
    .pipe(es.map((file, callback) -> console.log "Compiled #{file.path.split('/').slice(-4).join('/')}"; callback(null, file)))
    .pipe(mochaPhantomJS().on 'error', (err) -> gutil.log)