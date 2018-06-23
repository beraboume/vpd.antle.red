# No Dependency

# Publish
app= angular.module process.env.APP
app.factory 'stats',($window)->
  stats= new Stats # via stats.js
  stats.domElement.style.position= 'absolute'
  stats.domElement.style.left= '0px'
  stats.domElement.style.top= '0px'

  $window.document.body.appendChild stats.domElement

  stats
