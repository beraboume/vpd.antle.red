# Dependencies
Promise= require 'bluebird'

renderer=
  if window.WebGLRenderingContext
    new THREE.WebGLRenderer {antialias:yes}
  else
    new THREE.CanvasRenderer {}

# Setup app
app= angular.module process.env.APP,[
  'ui.router'
  'ngFileUpload'
]
app.constant 'Promise',Promise
app.constant 'renderer',renderer
app.constant 'Stats',Stats# use stats.js

# Include dependencies
require './loaders'
require './stats'

# Publish
module.exports= app
