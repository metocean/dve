// Generated by CoffeeScript 1.9.3
var autoprefixer, browserify, buffer, coffee, concat, cssimport, errorify, gulp, gutil, livereload, merge, minifycss, npmpackage, rename, replace, source, sourcemaps, stylus, uglify, watchify;

gulp = require('gulp');

rename = require('gulp-rename');

replace = require('gulp-replace');

concat = require('gulp-concat');

merge = require('merge-stream');

sourcemaps = require('gulp-sourcemaps');

npmpackage = require('./package.json');

livereload = require('gulp-livereload');

livereload({
  auto: false
});

gulp.task('watch', ['watchcoffee', 'html', 'style'], function() {
  livereload.listen();
  gulp.watch('style/*.styl', ['style']);
  return gulp.watch('index.html', ['html']);
});

gulp.task('default', ['style', 'coffee']);

stylus = require('gulp-stylus');

autoprefixer = require('gulp-autoprefixer');

minifycss = require('gulp-minify-css');

cssimport = require('gulp-cssimport');

gulp.task('style', function() {
  var styl;
  return styl = gulp.src('style/dve.styl').pipe(sourcemaps.init()).pipe(stylus()).pipe(autoprefixer({
    browsers: ['last 2 versions', 'ie >= 10']
  })).pipe(cssimport()).pipe(rename(npmpackage.name + "-" + npmpackage.version + ".css")).pipe(gulp.dest('dist')).pipe(minifycss({
    compatibility: '*,-properties.zeroUnits'
  })).pipe(rename(npmpackage.name + "-" + npmpackage.version + ".min.css")).pipe(sourcemaps.write('./')).pipe(gulp.dest('dist')).pipe(livereload());
});

browserify = require('browserify');

source = require('vinyl-source-stream');

buffer = require('vinyl-buffer');

uglify = require('gulp-uglify');

watchify = require('watchify');

errorify = require('errorify');

gutil = require('gulp-util');

coffee = function(options) {
  var browserifyargs, bundler, coffeefirst, compressor, shouldwatch;
  shouldwatch = ((options != null ? options.watch : void 0) != null) && options.watch;
  browserifyargs = {
    entries: './index.coffee',
    debug: true,
    cache: {},
    packageCache: {},
    fullPaths: shouldwatch,
    standalone: 'dve'
  };
  bundler = browserify(browserifyargs);
  if (shouldwatch) {
    bundler = watchify(bundler);
  }
  coffeefirst = function(bundle) {
    var extensions;
    extensions = ['.coffee', '.cson', '.js', '.json'];
    bundle._mdeps.options.extensions = extensions;
    return bundle._extensions = extensions;
  };
  bundler.plugin(coffeefirst).on('error', function() {
    gutil.log.apply(this, arguments);
    return bundler.end();
  });
  if (shouldwatch) {
    bundler.plugin(errorify);
    bundler.transform('caching-coffeeify', {
      global: true
    });
  } else {
    bundler.transform('coffeeify', {
      global: true
    });
  }
  compressor = function() {
    var comp;
    comp = bundler.bundle().on('error', function() {
      gutil.log.apply(this, arguments);
      return comp.end();
    }).pipe(source(npmpackage.name + "-" + npmpackage.version + ".min.js")).pipe(buffer()).pipe(sourcemaps.init({
      loadMaps: true
    }));
    if (!shouldwatch) {
      comp.pipe(uglify());
    }
    return comp.pipe(sourcemaps.write('./')).pipe(gulp.dest('dist')).pipe(livereload());
  };
  if (shouldwatch) {
    bundler.on('update', function(files) {
      var file, i, len;
      for (i = 0, len = files.length; i < len; i++) {
        file = files[i];
        gutil.log("M ." + (file.substr(__dirname.length)));
      }
      return compressor();
    });
  }
  return compressor();
};

gulp.task('coffee', function() {
  return coffee();
});

gulp.task('watchcoffee', function() {
  return coffee({
    watch: true
  });
});

gulp.task('html', function() {
  return gulp.src('index.html').pipe(livereload());
});
