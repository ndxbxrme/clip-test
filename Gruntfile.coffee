module.exports = (grunt) ->
  require('load-grunt-tasks') grunt
  grunt.initConfig
    express:
      web:
        options:
          script: 'app/test.js'
    watch:
      coffee:
        files: ['src/**/*.coffee', 'src/**/*.styl', 'src/**/*.pug']
        tasks: ['build']
    coffee:
      options:
        sourceMap: true
      default:
        files: [{
          expand: true
          cwd: 'src'
          src: ['**/*.coffee']
          dest: 'app'
          ext: '.js'
        }]
    pug:
      options:
        pretty: true
      default:
        files: [
          expand: true
          cwd: 'src'
          src: ['**/*.pug']
          dest: 'app'
          ext: '.html'
        ]
    stylus:
      default:
        files:
          "app/app.css": "src\/**\/*.styl"
    copy:
      build:
        files: [
          expand: true
          cwd: 'files'
          dest: 'build'
          src: [
            '**/*.*'
          ]
        ]
    clean:
      build: 'app'
    nodeunit:
      tests: ['build/test/**/*.js']
  grunt.registerTask 'build', [
    'clean:build'
    'copy:build'
    'coffee'
    'pug'
    'stylus'
  ]
  grunt.registerTask 'default', [
    'build'
    'watch'
  ]
  grunt.registerTask 'test', [
    'build'
    'nodeunit'
  ]