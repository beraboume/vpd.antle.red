# Dependencies
express= require 'express'
dhs= require 'difficult-http-server'

# Environment
process.env.PORT?= 59798
cwd= __dirname
bundleExternal= yes

# Setup express
app= express()
app.use dhs {cwd,bundleExternal}

# Boot
app.listen process.env.PORT,->
  console.log 'Server running at http://localhost:%s',process.env.PORT
