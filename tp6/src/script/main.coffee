slinky_require "testfile.js"

window.Tp =
  debugging: on

  log: (args...) -> if @debugging then console.log.apply(console, args)

  modules: {}
