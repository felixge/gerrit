load("//tools/bzl:genrule2.bzl", "genrule2")
load("@io_bazel_rules_closure//closure:defs.bzl", "closure_js_library", "closure_js_binary")
load(
    "//tools/bzl:js.bzl",
    "vulcanize",
    "bower_component",
    "js_component",
)

def polygerrit_bundle(name, srcs, outs, app):
  appName = app.split(".html")[0].split("/").pop() # eg: gr-app

  closure_js_binary(
    name = name + "_closure_bin",
    # Known issue: Closure compilation not compatible with Polymer behaviors.
    # See: https://github.com/google/closure-compiler/issues/2042
    compilation_level = "WHITESPACE_ONLY",
    defs = [
      "--polymer_pass",
      "--jscomp_off=duplicate",
      "--force_inject_library=es6_runtime",
    ],
    language = "ECMASCRIPT5",
    deps = [name + "_closure_lib"],
  )

  closure_js_library(
    name = name + "_closure_lib",
    srcs = [appName + ".js"],
    convention = "GOOGLE",
    # TODO(davido): Clean up these issues: http://paste.openstack.org/show/608548
    # and remove this supression
    suppress = ["JSC_UNUSED_LOCAL_ASSIGNMENT"],
    deps = [
      "//lib/polymer_externs:polymer_closure",
      "@io_bazel_rules_closure//closure/library",
    ],
  )

  vulcanize(
    name = appName,
    srcs = srcs,
    app = app,
    deps = ["//polygerrit-ui:polygerrit_components.bower_components"],
  )

  native.filegroup(
    name = name + "_app_sources",
    srcs = [
      name + "_closure_bin.js",
      appName + ".html",
    ],
  )

  native.filegroup(
    name = name + "_css_sources",
    srcs = native.glob(["styles/**/*.css"]),
  )

  native.filegroup(
    name = name + "_top_sources",
    srcs = [
        "favicon.ico",
        "index.html",
    ],
  )

  genrule2(
    name = name,
    srcs = [
      name + "_app_sources",
      name + "_css_sources",
      name + "_top_sources",
      "//lib/fonts:robotofonts",
      "//lib/js:highlightjs_files",
      # we extract from the zip, but depend on the component for license checking.
      "@webcomponentsjs//:zipfile",
      "//lib/js:webcomponentsjs"
    ],
    outs = outs,
    cmd = " && ".join([
      "mkdir -p $$TMP/polygerrit_ui/{styles,fonts,bower_components/{highlightjs,webcomponentsjs},elements}",
      "for f in $(locations " + name + "_app_sources); do ext=$${f##*.}; cp -p $$f $$TMP/polygerrit_ui/elements/"  + appName + ".$$ext; done",
      "cp $(locations //lib/fonts:robotofonts) $$TMP/polygerrit_ui/fonts/",
      "for f in $(locations " + name + "_top_sources); do cp $$f $$TMP/polygerrit_ui/; done",
      "for f in $(locations "+ name + "_css_sources); do cp $$f $$TMP/polygerrit_ui/styles; done",
      "for f in $(locations //lib/js:highlightjs_files); do cp $$f $$TMP/polygerrit_ui/bower_components/highlightjs/ ; done",
      "unzip -qd $$TMP/polygerrit_ui/bower_components $(location @webcomponentsjs//:zipfile) webcomponentsjs/webcomponents-lite.js",
      "cd $$TMP",
      "find . -exec touch -t 198001010000 '{}' ';'",
      "zip -qr $$ROOT/$@ *",
    ]),
  )